trigger EventTrigger on Event (after insert) {
    new EventTriggerHandler().run();
}
