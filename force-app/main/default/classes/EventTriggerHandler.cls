public class EventTriggerHandler extends TriggerHandler {

    public override void afterInsert(List<SObject> newList) {
        EACActivityService.processEventActivities((List<Event>) newList);
    }
}
