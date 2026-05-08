trigger TaskTrigger on Task (after insert) {
    new TaskTriggerHandler().run();
}
