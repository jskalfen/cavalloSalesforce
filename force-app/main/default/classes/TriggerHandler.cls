public virtual class TriggerHandler {


    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
        AFTER_UNDELETE
    }

    private static Set<String> bypassedHandlers = new Set<String>();

    @TestVisible
    private TriggerContext context;

    @TestVisible
    private Boolean isTriggerExecuting;

    public TriggerHandler() {
        this.setTriggerContext();
    }

    public void run() {
        if(!validateRun()) {
            return;
        }

        switch on this.context {
            when BEFORE_INSERT {
                this.beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                this.beforeUpdate(Trigger.new, Trigger.oldMap);
            }
            when BEFORE_DELETE {
                this.beforeDelete(Trigger.old);
            }
            when AFTER_INSERT {
                this.afterInsert(Trigger.new);
            }
            when AFTER_UPDATE {
                this.afterUpdate(Trigger.new, Trigger.oldMap);
            }
            when AFTER_DELETE {
                this.afterDelete(Trigger.old);
            }
            when AFTER_UNDELETE {
                this.afterUndelete(Trigger.new);
            }
        }
    }

    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if(!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
            (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
            (ctx != null && ctx == 'before update')){
            this.context = TriggerContext.BEFORE_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
            (ctx != null && ctx == 'before delete')) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
            (ctx != null && ctx == 'after insert')) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
            (ctx != null && ctx == 'after update')) {
            this.context = TriggerContext.AFTER_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
            (ctx != null && ctx == 'after delete')) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
            (ctx != null && ctx == 'after undelete')) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    @TestVisible
    private Boolean validateRun() {
        if(!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        return true;
    }

    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }

    @TestVisible
    protected virtual void beforeInsert(List<SObject> triggerNew) {}
    @TestVisible
    protected virtual void beforeUpdate(List<SObject> triggerNew, Map<Id, SObject> triggerOldMap) {}
    @TestVisible
    protected virtual void beforeDelete(List<SObject> triggerOld) {}
    @TestVisible
    protected virtual void afterInsert(List<SObject> triggerNew) {}
    @TestVisible
    protected virtual void afterUpdate(List<SObject> triggerNew, Map<Id, SObject> triggerOldMap) {}
    @TestVisible
    protected virtual void afterDelete(List<SObject> triggerOld) {}
    @TestVisible
    protected virtual void afterUndelete(List<SObject> triggerNew) {}

    public class TriggerHandlerException extends Exception {}
}