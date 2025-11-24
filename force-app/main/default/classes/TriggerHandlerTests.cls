@isTest(isParallel=true)
private class TriggerHandlerTests {

    private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';

    private static String lastMethodCalled;

    private static TriggerHandlerTests.TestHandler handler = new TriggerHandlerTests.TestHandler();

    static {
        handler.isTriggerExecuting = true;
    }

    @isTest
    static void testBeforeInsert() {
        beforeInsertMode();
        handler.run();
        System.assertEquals('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
    }

    @isTest
    static void testBeforeUpdate() {
        beforeUpdateMode();
        handler.run();
        System.assertEquals('beforeUpdate', lastMethodCalled, 'last method should be beforeUpdate');
    }

    @isTest
    static void testBeforeDelete() {
        beforeDeleteMode();
        handler.run();
        System.assertEquals('beforeDelete', lastMethodCalled, 'last method should be beforeDelete');
    }

    @isTest
    static void testAfterInsert() {
        afterInsertMode();
        handler.run();
        System.assertEquals('afterInsert', lastMethodCalled, 'last method should be afterInsert');
    }

    @isTest
    static void testAfterUpdate() {
        afterUpdateMode();
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method should be afterUpdate');
    }

    @isTest
    static void testAfterDelete() {
        afterDeleteMode();
        handler.run();
        System.assertEquals('afterDelete', lastMethodCalled, 'last method should be afterDelete');
    }

    @isTest
    static void testAfterUndelete() {
        afterUndeleteMode();
        handler.run();
        System.assertEquals('afterUndelete', lastMethodCalled, 'last method should be afterUndelete');
    }

    @isTest
    static void testNonTriggerContext() {
        try{
            handler.run();
            System.assert(false, 'the handler ran but should have thrown');
        } catch(TriggerHandler.TriggerHandlerException te) {
            System.assertEquals(TRIGGER_CONTEXT_ERROR, te.getMessage(), 'the exception message should match');
        } catch(Exception e) {
            System.assert(false, 'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
    }

    @isTest
    static void testGetHandlerName() {
        System.assertEquals('TestHandler', handler.getHandlerName(), 'handler name should match class name');
    }

    @isTest
    static void testVirtualMethods() {
        TriggerHandler h = new TriggerHandler();
        h.beforeInsert(new List<sObject>());
        h.beforeUpdate(new List<sObject>(), new Map<Id, sObject>());
        h.beforeDelete(new List<sObject>());
        h.afterInsert(new List<sObject>());
        h.afterUpdate(new List<sObject>(), new Map<Id, sObject>());
        h.afterDelete(new List<sObject>());
        h.afterUndelete(new List<sObject>());
    }

    private static void resetTest() {
        lastMethodCalled = null;
    }

    private static void beforeInsertMode() {
        handler.setTriggerContext('before insert', true);
    }

    private static void beforeUpdateMode() {
        handler.setTriggerContext('before update', true);
    }

    private static void beforeDeleteMode() {
        handler.setTriggerContext('before delete', true);
    }

    private static void afterInsertMode() {
        handler.setTriggerContext('after insert', true);
    }

    private static void afterUpdateMode() {
        handler.setTriggerContext('after update', true);
    }

    private static void afterDeleteMode() {
        handler.setTriggerContext('after delete', true);
    }

    private static void afterUndeleteMode() {
        handler.setTriggerContext('after undelete', true);
    }

    private class TestHandler extends TriggerHandler {

        public override void beforeInsert(List<sObject> newTrigger) {
            TriggerHandlerTests.lastMethodCalled = 'beforeInsert';
        }

        public override void beforeUpdate(List<sObject> newTrigger, Map<Id, sObject> oldMap) {
            TriggerHandlerTests.lastMethodCalled = 'beforeUpdate';
        }

        public override void beforeDelete(List<sObject> oldTrigger) {
            TriggerHandlerTests.lastMethodCalled = 'beforeDelete';
        }

        public override void afterInsert(List<sObject> newTrigger) {
            TriggerHandlerTests.lastMethodCalled = 'afterInsert';
        }

        public override void afterUpdate(List<sObject> newTrigger, Map<Id, sObject> oldMap) {
            TriggerHandlerTests.lastMethodCalled = 'afterUpdate';
        }

        public override void afterDelete(List<sObject> oldTrigger) {
            TriggerHandlerTests.lastMethodCalled = 'afterDelete';
        }

        public override void afterUndelete(List<sObject> newTrigger) {
            TriggerHandlerTests.lastMethodCalled = 'afterUndelete';
        }
    }
}