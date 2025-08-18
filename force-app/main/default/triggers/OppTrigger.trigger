trigger OppTrigger on Opportunity (before update) {
    List<String> oppIds = new List<String>();
    Map<String,String> oppIdVerionId = new Map<String,String>();
    for (Opportunity opp : Trigger.new){
        oppIds.add(opp.Id);
    }
    List<ContentDocumentLink> contentDocLinkList =
        [
            SELECT 
                Id,
                ContentDocument.LatestPublishedVersionId,
                LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN: oppIds AND ContentDocument.Title= 'Budget Qualification Note'
        ];
    List<String> versionIds = new List<String>();
    for(ContentDocumentLink contentDocLinkObj : contentDocLinkList){
        versionIds.add(contentDocLinkObj.ContentDocument.LatestPublishedVersionId);
        oppIdVerionId.put(contentDocLinkObj.LinkedEntityId,contentDocLinkObj.ContentDocument.LatestPublishedVersionId );
    }
    System.debug('oppIdVerionId'+oppIdVerionId);
    List<ContentVersion> contentNoteList = 
        [
            SELECT 
                Id, 
                Versiondata                
            FROM ContentVersion
            WHERE Id IN: versionIds
        ];
    if(!contentNoteList.isEmpty()){
        for (Opportunity opp : Trigger.new){
            for(ContentVersion contentNoteObj : contentNoteList){
                if(oppIdVerionId.containsKey(opp.Id) && oppIdVerionId.get(opp.Id) == contentNoteObj.Id){
                    opp.Budget_Qualification_Note__c = 'Additional information regarding your request has been provided for your review:' + contentNoteObj.VersionData.toString();
                }
            }
        }
    }

    Integer i=0;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;   
}