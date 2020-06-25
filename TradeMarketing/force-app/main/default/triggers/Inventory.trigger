trigger Inventory on Inventory__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        InventoryTriggerHandler.validateNewInventory (Trigger.new);
    }
}