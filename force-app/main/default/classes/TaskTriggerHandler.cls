public class TaskTriggerHandler extends TriggerHandler {

    public override void afterInsert(List<SObject> newList) {
        EACActivityService.processTaskActivities((List<Task>) newList);
    }
}
