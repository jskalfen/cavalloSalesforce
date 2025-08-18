public class EinsteinBotPreChatInfoGather {
  public class TranscriptInput {
    @InvocableVariable(required=true)
    public ID routableID;
  }
  
  public class PrechatInfoOutput {
    @InvocableVariable(required=true)
    public String sFirstName;
    @InvocableVariable(required=true)
    public String sLastName;
    @InvocableVariable(required=true)
    public String sEmail;
  }

  @InvocableMethod(label='Get Prechat Info')
  public static List<PrechatInfoOutput> getPrechatInfo(List<TranscriptInput> transcripts) {

    List<PrechatInfoOutput> prechatInfos = new List<PrechatInfoOutput>();
  
    for (TranscriptInput transcript : transcripts) {
    
      // Query for the transcript record based on the ID
      LiveChatTranscript transcriptRecord = [SELECT Name, First_Name__c, Last_Name__c, Email__c
                                             FROM LiveChatTranscript 
                                             WHERE Id = :transcript.routableID 
                                             LIMIT 1];
      
      // Store the first name in an output variable
      PrechatInfoOutput prechatData = new PrechatInfoOutput();
      prechatData.sFirstName = transcriptRecord.First_Name__c;
      prechatData.sLastName = transcriptRecord.Last_Name__c;
	  prechatData.sEmail = transcriptRecord.Email__c;
        
      // Add the name to the list of outputs
      prechatInfos.add(prechatData);
    }
    
    return prechatInfos;
  }
}