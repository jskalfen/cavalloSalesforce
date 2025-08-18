public without sharing class DocusignOppContoller {

    @InvocableMethod(label='Send Document Docusign' description='Send Document Docusign')
    public static void sendDocusign(List<String> oppIds) {
        List<Quote> qList = 
            [
                SELECT 
                Id,
                ContactId,
                Contact.Name,
                Contact.Email,
                Opportunity.OwnerId,
                OpportunityId,
                Opportunity.Docusign_EnvelopId__c
            FROM Quote
            WHERE OpportunityId IN :oppIds];

        for(Quote q: qList){
            // creating attachment
            Id attachmentId;
            if(Test.isRunningTest()){
                attachmentId =  [ SELECT Id,Body,Name FROM Attachment Limit 1][0].Id;   
            }else{
                ApexPages.StandardController sc = new ApexPages.StandardController(q);
                QuotePDFControllerVAR quotePDFControllerVARObj = new QuotePDFControllerVAR(sc);
                attachmentId = quotePDFControllerVARObj.savePDF();
            }
            
            //Id attachmentId = '00P2v00002qlqsr';
            Attachment attachmentObj = 
                [
                    SELECT Id,Body,Name FROM Attachment WHERE Id=: attachmentId
                ];

            String account; 
            String initial = '';
            DocusignApiKeys__c creds = DocusignApiKeys__c.getOrgDefaults();
            String endpoint = creds.API_URL__c+'/restapi/v2.1/accounts/'+creds.Account__c+'/envelopes';     

            String status; 
            String email; 
            String recipients = ''; 
            Integer i = 1; 

            Map<String,String> signersKeyPairMap = new Map<String,String>();
    
            if(q.Opportunity.Docusign_EnvelopId__c == null){ 
                String Name = q.Contact.Name; 
                if(recipients != '') 
                    recipients = recipients + ','; 
    
                recipients = recipients + '{'+ 
                                            ' "email": "'+q.Contact.Email+'",'+ 
                                            ' "name": "'+Name+'",'+ 
                                            ' "recipientId":"'+i+'",'+                                         
                                            ' "tabs": {'+ 
                                                ' "signHereTabs": [{'+ 
                                                    ' "anchorString":"zzzzz",'+ 
                                                    ' "anchorXOffset": "0",'+ 
                                                    ' "anchorYOffset": "0",'+ 
                                                    ' "anchorIgnoreIfNotPresent": "false",'+ 
                                                    ' "anchorUnits": "inches"'+ 
                                                ' }],'+ 
                                                ' "dateSignedTabs": [{'+ 
                                                    ' "anchorString": "zzzzz",'+ 
                                                    ' "anchorXOffset": "0",'+ 
                                                    ' "fontSize": "Size14",'+ 
                                                    ' "fontColor": "Black",'+ 
                                                    ' "anchorYOffset": "0",'+ 
                                                    ' "anchorIgnoreIfNotPresent": "false",'+ 
                                                    ' "xPosition": "100",'+ 
                                                    ' "yPosition": "72",'+ 
                                                    ' "anchorUnits": "inches"'+ 
                                                ' }]'+ 
                                            ' }'+ 
    
                                        ' }'; 
    
                if(!signersKeyPairMap.containsKey(Name)){
                    signersKeyPairMap.put(Name,String.valueof(i)); 
                    i++; 
                }
                //forming payload with the document and recipients. 
                String body =  '{"envelopeDefinition" : {'+ 
                                    ' "status":"sent",'+             
                                    ' "enableWetSign": "false",'+             
                                    ' "emailBlurb":"",'+             
                                    ' "emailSubject": "'+attachmentObj.Name+'",'+             
                                    ' "enforceSignerVisibility":"True",'+             
                                    ' "documents": [{'+             
                                        ' "name": "'+attachmentObj.Name+'",'+             
                                        ' "documentId":"'+i+'",'+             
                                        ' "order":"1",'+             
                                        ' "documentBase64":"'+EncodingUtil.base64Encode(attachmentObj.Body)+'"'+             
                                    ' }],'+             
                                    '"recipients": {'+             
                                        ' "signers" : ['+recipients+']'+             
                                    ' }'+             
                                '}}'; 
        
                String viewBody = '{'+             
                                        '"returnUrl": "https://www.docusign.com/devcenter"'+             
                                    '}';             
                //String header = '--'+boundary+'\nContent-Type: application/json\nContent-Disposition: form-data';             
                //String jsonBody = header +'\n\n'+body+'\n\n--'+boundary+'--'; 
                String jsonBody = body;             
                System.debug(jsonBody);
                //Callout to Docusign.             
                HttpRequest req = new HttpRequest();             
                req.setHeader('Authorization', 'Bearer '+ creds.AccessToken__c+''+creds.AccessToken2__c+''+creds.AccessToken3__c);             
                req.setHeader('Accept','application/json');             
                //req.setHeader('Host','demo.docusign.net');             
                //req.setHeader('Content-Length', ''+EncodingUtil.base64Encode(attachmentObj.Body).length());             
                req.setHeader('Content-Type','application/json');             
                req.setEndpoint(endpoint);             
                req.setMethod('POST');              
                req.setBody(jsonBody);             
                Http http = new Http();             
                HTTPResponse res;             
                try{             
                    if(recipients != ''){  
                        String envelopeId;           
                        res = http.send(req);             
                        system.debug('response 1'+res.getBody());             
                        //Docusign status record creation.             
                        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped (res.getBody());             
                        if((String) results.get('envelopeId') != '') {           
                            envelopeId = (String) results.get('envelopeId');  
                        }           
                        if((String) results.get('status') == 'Sent' || (String) results.get('status') == 'Created'){             
                            status = 'Agreement sent';   
                            Opportunity oppObj = new Opportunity();
                            oppObj.Id = q.OpportunityId;
                            oppObj.Docusign_EnvelopId__c = envelopeId;
                            update oppObj;
                        }             
                        else{            
                            status = (String) results.get('errorCode'); 
                        } 
                    }
                }catch(Exception e){ 
                    System.debug('Exception : '+e);
                }

                
            }
        } 
    }
}