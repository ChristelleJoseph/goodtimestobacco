public with sharing class InventoryTriggerHandler {

    public static void validateNewInventory(List<Inventory__c> listInventories){
        Set<Id>accountIds = new Set<Id>();
        Set<Date>inventoryDates = new Set<Date>();
        for (Inventory__c item : listInventories) {
            accountIds.add(item.Account__c);
            inventoryDates.add(item.Visit_Date__c);
        }

        Map<Id,Set<Date>> accountInventoryMap = new Map<Id,Set<Date>>();
        for (Account item : [
                SELECT Id,
                (SELECT Visit_Date__c FROM Inventory__r WHERE Visit_Date__c IN : inventoryDates)
                FROM Account
                WHERE Id IN : accountIds
                ]) {
            if (item.Inventory__r.size() > 0) {
                Set<Date> currentInventoryDates = new Set<Date>();
                for (Inventory__c inventoryItem : item.Inventory__r) {
                    currentInventoryDates.add(inventoryItem.Visit_Date__c);
                }
                accountInventoryMap.put(item.Id, currentInventoryDates);
            }
        }

        for (Inventory__c item : listInventories) {
            if (accountInventoryMap.containsKey(item.account__c)
                && accountInventoryMap.get(item.account__c).contains(item.Visit_Date__c)) {
                item.addError('Inventory for this date already exists');
            }
        }
    }
}