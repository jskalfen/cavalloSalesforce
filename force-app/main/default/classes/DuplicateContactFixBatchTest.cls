@isTest
class DuplicateContactFixBatchTest {
    @isTest
    static void testDuplicateContactFixBatch() {
        Contact con = new Contact();
        con.LastName = 'test';
        insert con;

        Contact con1 = new Contact();
        con1.LastName = 'test';
        insert con1;

        DuplicateContactFixBatch myBatchObject = new DuplicateContactFixBatch();
        Id batchId = Database.executeBatch(myBatchObject);
    }
}