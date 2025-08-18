@isTest(Seealldata=true)
class RecordUpdateBatchTest {
    @isTest
    static void LeadNameUpdateBatchTest() {

       
        Test.startTest();
            Database.executeBatch(new RecordUpdateBatch(), 200);
        Test.stopTest();
    }
}