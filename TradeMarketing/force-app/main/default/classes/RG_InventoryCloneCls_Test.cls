@isTest
public class RG_InventoryCloneCls_Test {
    static testmethod void clone_test () {
        //Create Account
        Account acc1 = new Account(Name = 'Acc1', account__c= '123456');
        insert acc1;
    

        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;

        Id pricebookId = Test.getStandardPricebookId(); 

        Pricebook2 standardPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update standardPB;

        //Create Product
        Product2 pro = new Product2(Name='Product_Test', IsActive = true, Item_Num__c = '1234', Item_Status__c = '1');
        insert pro;
        
        //Create Price Book Entry
        //PriceBookEntry pbe = new PriceBookEntry(Product2Id = pro.id, PriceBook2Id = [select id from Pricebook2 where name='Standard Price Book'  limit 1].Id, UnitPrice = 100, IsActive = true, UseStandardPrice=true);
        //insert pbe;


		//Create Inventory
		Inventory__c inv = new Inventory__c(Account__c = acc1.id, Visit_Date__c = Date.today());
        insert inv;
        
        //Create Inventory line item
        Inventory_Line_Item__c invLineItem = new Inventory_Line_Item__c(Inventory__c = inv.id, Account__c = acc1.id, Product__c = pro.id, Quantity__c = 2);
        insert invLineItem;
        
		PageReference pageRef = Page.RG_InventoryLineItemClonePage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', inv.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(inv);
        RG_InventoryCloneCls obj = new RG_InventoryCloneCls();
		obj.InventoryClone();
        
    }
}