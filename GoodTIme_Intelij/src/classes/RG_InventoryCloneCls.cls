public class RG_InventoryCloneCls {
        
        public PageReference InventoryClone(){
            id inventoryId=ApexPages.currentPage().getParameters().get('Id');
            
            List<Inventory__c> inventoryList=new List<Inventory__c>();
            Inventory__c inventory;
            try{
                inventory=[SELECT Id, Account__c, Visit_Date__c, Description__c FROM Inventory__c WHERE Id=: inventoryId];
            }Catch(Exception e){
                System.debug('####### No ILI in list ########'+e);
            }
            
            if(inventory!=Null){
            //clone Inventory record
            //
            
            Inventory__c createInventory=inventory.clone(false, true);
            system.debug('createInventory==>'+createInventory);
            
            //Create Inventory record
            try{
                createInventory.Visit_Date__c = Date.today();
                Insert createInventory;
            }Catch(Exception e){
                System.debug('####### createInventory Exception ######## '+e);
            }
            
            List<Inventory_Line_Item__c> inventoryLineItemList=new List<Inventory_Line_Item__c>();
            Map<id, PricebookEntry> Product2IdPriceBookEntryMap=new Map<id, PricebookEntry>();
            for(PricebookEntry pricebookentryy:[SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.Name='Standard Price Book'])
            {
                if(pricebookentryy.Product2id!=Null)
                Product2IdPriceBookEntryMap.put(pricebookentryy.Product2id, pricebookentryy);
            }
        
            
            for(Inventory_Line_Item__c inventoryLineItem : [SELECT Id, Account__c,PreviousQuantity__c, ProductDateCode__c, WholeSale__c, ResalePrice__c, WholeSaleMargin__c, Inventory__r.Visit_Date__c,  Inventory__c, Product__c, Product_description__c, Quantity__c 
                                                            FROM Inventory_Line_Item__c 
                                                            WHERE Inventory__c=:inventory.Id])
            {
                //clone InventoryLineItem record
                Inventory_Line_Item__c inventLineItem=inventoryLineItem.clone(false, true);
                inventLineItem.Inventory__c=createInventory.Id;
                inventLineItem.Quantity__c=0;
                inventLineItem.PreviousQuantity__c= inventoryLineItem.Quantity__c;
                inventLineItem.ProductDateCode__c=inventoryLineItem.Inventory__r.Visit_Date__c;
                
                if(Product2IdPriceBookEntryMap.get(inventoryLineItem.Product__c)!=NULL)
                    inventLineItem.WholeSale__c=Product2IdPriceBookEntryMap.get(inventoryLineItem.Product__c).UnitPrice;

                inventLineItem.ResalePrice__c=inventoryLineItem.ResalePrice__c;
                
                
                System.debug('inventLineItem===>'+inventLineItem);
                inventoryLineItemList.add(inventLineItem);
            }
            
            
            if(!inventoryLineItemList.isEmpty())
            {
                try{
                    Insert inventoryLineItemList;
                }Catch(Exception e){
                    System.debug('####### inventoryLineItemList Insert Exception ########'+e);
                }
            }
                    
            
            //(SELECT Id, Account__c, Inventory__c, Product__c, Product_description__c, Quantity__c FROM Inventory_Line_Items__r)
            
            return new PageReference('/'+createInventory.Id);
            }
            return new PageReference('/'+inventoryId);
        }
        
}