Trigger TaskTrigger on Task (before insert) {
    if (Trigger.isBefore && Trigger.isInsert){
        TaskTriggerHandler.sendEmailOwnerAndCC (Trigger.new);
    }
}