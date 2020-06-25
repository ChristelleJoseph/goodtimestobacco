@isTest
public class RG_InventoriesHystoryClsTest {
    static testmethod void InventoriesHystoryTest () {
        Account newAccount = new Account();
        newAccount.name= 'test';
        newAccount.account__c= '123456';
        insert newAccount;

        //Inventory
        Inventory__c inv= new Inventory__c(Visit_Date__c = Date.Today(), account__c = newAccount.Id);
        insert inv;

        
        Inventory__c inv3= new Inventory__c(Visit_Date__c = Date.Today()-30, account__c = newAccount.Id);
        insert inv3;

        Inventory__c inv4= new Inventory__c(Visit_Date__c = Date.Today()-60, account__c = newAccount.Id);
        insert inv4;


		

        List<Product2> products = new List<Product2>();
        
        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;

        Id pricebookId = Test.getStandardPricebookId(); 

        Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update customPB;

        Product2 prod1 = new Product2(Name='4K Lites', ProductCode='101', Family = 'none', Item_Num__c='444441', Item_Status__c='1', IsActive=true);

        insert prod1;
        products.add(prod1);

        Product2 prod2 = new Product2(Name='4K Lites other', ProductCode='102', Family = 'none', Item_Num__c='444442', Item_Status__c='1', IsActive=true);

        insert prod2;
        products.add(prod2);


        
        //Inventory_Line_Item__c
        List<Inventory_Line_Item__c> inlinelist = new  List<Inventory_Line_Item__c>();
        
        inlinelist.add(new Inventory_Line_Item__c( Inventory__c=inv.id, Quantity__c=42, account__c = newAccount.Id, Product__c = products.get(0).Id, ProductDateCode__c = Date.Today()));
        inlinelist.add(new Inventory_Line_Item__c( Inventory__c=inv.id, Quantity__c=42, account__c = newAccount.Id, Product__c = products.get(0).Id, ProductDateCode__c = Date.Today()-45));
        inlinelist.add(new Inventory_Line_Item__c( Inventory__c=inv3.id, Quantity__c=100, account__c = newAccount.Id, Product__c = products.get(0).Id, ProductDateCode__c = Date.Today()-30));
        inlinelist.add(new Inventory_Line_Item__c( Inventory__c=inv4.id, Quantity__c=200, account__c = newAccount.Id, Product__c = products.get(0).Id, ProductDateCode__c = Date.Today()-60));
        inlinelist.add(new Inventory_Line_Item__c( Inventory__c=inv4.id, Quantity__c=200, account__c = newAccount.Id, Product__c = products.get(0).Id, ProductDateCode__c = null));
 
        insert inlinelist;


        //RG_InventoryLineItemPage
        PageReference pg=Page.RG_InventoriesHistoryPage;
        pg.getParameters().put('id',newAccount.id);
        Test.setCurrentPage(pg);


        RG_InventoriesHistoryCls controller = new RG_InventoriesHistoryCls();
        controller.countOfMonth  = 3;
        system.assertEquals(1, controller.inventories.size());
        system.assertEquals(2, controller.inventoryDTOs.size());
        controller.saveChanges();
        String userName = controller.userProfileName;
        String iliId = [SELECT Id FROM Inventory_Line_Item__c LIMIT 1].Id;
        controller.deleteItemId = iliId;
        controller.createDeletionRequest();
        system.assertEquals(0, [SELECT Id FROM Inventory_Line_Item__c WHERE Id = : iliId].size());
        try {
            //Inventory2
            Inventory__c inv2 = new Inventory__c(Visit_Date__c = Date.Today(), account__c = newAccount.Id);
            insert inv2;
        } catch (exception e) {

        }
    }

   
    static testmethod void InventoriesHystoryTestRemoval () {

        Account newAccount = new Account();
        newAccount.name= 'test1';
        newAccount.account__c= '1234567';
        insert newAccount;

        //Inventory
        Inventory__c inv1= new Inventory__c(Visit_Date__c = Date.Today(), account__c = newAccount.Id);
        insert inv1;

        Inventory__c inv2= new Inventory__c(Visit_Date__c = Date.Today().addDays(-31), account__c = newAccount.Id);
        insert inv2;

        Inventory__c inv3= new Inventory__c(Visit_Date__c = Date.Today().addDays(-62), account__c = newAccount.Id);
        insert inv3;

        Inventory__c inv4= new Inventory__c(Visit_Date__c = Date.Today().addDays(-93), account__c = newAccount.Id);
        insert inv4;

        Inventory__c inv5= new Inventory__c(Visit_Date__c = Date.Today().addDays(-123), account__c = newAccount.Id);
        insert inv5;
        

        List<Product2> products = new List<Product2>();
        
        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;

        Id pricebookId = Test.getStandardPricebookId(); 

        Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update customPB;

        Product2 prod1 = new Product2(Name='test prod1', Description='test prod1', ProductCode='101', Family = 'none', Item_Num__c='444441', Item_Status__c='1', IsActive=true);
        insert prod1;
        products.add(prod1);

        Product2 prod2 = new Product2(Name='test prod2', Description='test prod2', ProductCode='102', Family = 'none', Item_Num__c='444442', Item_Status__c='1', IsActive=true);
        insert prod2;
        products.add(prod2);

        Product2 prod3 = new Product2(Name='test prod3', Description='test prod3', ProductCode='102', Family = 'none', Item_Num__c='444443', Item_Status__c='1', IsActive=true);
        insert prod3;
        products.add(prod3);
        
        /*
        Product2 prod1 = new Product2(Name='test with status 1', ProductCode='11', Family = 'none', Item_Num__c='44441', Item_Status__c='1');
        Product2 prod2 = new Product2(Name='test with status 2', ProductCode='12', Family = 'none', Item_Num__c='44442', Item_Status__c='2');
        Product2 prod3 = new Product2(Name='test with status 3', ProductCode='13', Family = 'none', Item_Num__c='44443', Item_Status__c='2');
        
        insert prod1;
        products.add(prod1);

        insert prod2;
        products.add(prod2);
    
        insert prod3;
        products.add(prod3);
        */

        System.debug('prod.Id: ' + prod1.Id);

        //Inventory_Line_Item__c
        
        List<Inventory_Line_Item__c> inlinelist1 = new  List<Inventory_Line_Item__c>();
        inlinelist1.add(new Inventory_Line_Item__c( Inventory__c=inv1.id, Quantity__c=0, account__c = newAccount.Id, Product__c = prod1.Id, ProductDateCode__c = Date.Today()));
        inlinelist1.add(new Inventory_Line_Item__c( Inventory__c=inv1.id, Quantity__c=0, account__c = newAccount.Id, Product__c = prod2.Id, ProductDateCode__c = Date.Today()));
        inlinelist1.add(new Inventory_Line_Item__c( Inventory__c=inv1.id, Quantity__c=0, account__c = newAccount.Id, Product__c = prod3.Id, ProductDateCode__c = Date.Today()));
        insert inlinelist1;

        
        List<Inventory_Line_Item__c> inlinelist2 = new  List<Inventory_Line_Item__c>();
        inlinelist2.add(new Inventory_Line_Item__c( Inventory__c=inv2.id, Quantity__c=0, account__c = newAccount.Id, Product__c=prod1.Id, ProductDateCode__c = Date.Today().addDays(-31)));
        inlinelist2.add(new Inventory_Line_Item__c( Inventory__c=inv2.id, Quantity__c=0, account__c = newAccount.Id, Product__c=prod2.Id, ProductDateCode__c = Date.Today().addDays(-31)));
        inlinelist2.add(new Inventory_Line_Item__c( Inventory__c=inv2.id, Quantity__c=0, account__c = newAccount.Id, Product__c=prod3.Id, ProductDateCode__c = Date.Today().addDays(-31)));
        insert inlinelist2;

        List<Inventory_Line_Item__c> inlinelist3 = new  List<Inventory_Line_Item__c>();
        inlinelist3.add(new Inventory_Line_Item__c( Inventory__c=inv3.id, Quantity__c=0, account__c = newAccount.Id, Product__c=prod1.Id, ProductDateCode__c = Date.Today().addDays(-62)));
        inlinelist3.add(new Inventory_Line_Item__c( Inventory__c=inv3.id, Quantity__c=0, account__c = newAccount.Id, Product__c=prod2.Id, ProductDateCode__c = Date.Today().addDays(-62)));
        inlinelist3.add(new Inventory_Line_Item__c( Inventory__c=inv3.id, Quantity__c=10, account__c = newAccount.Id, Product__c=prod3.Id, ProductDateCode__c = Date.Today().addDays(-62)));
        insert inlinelist3;


        List<Inventory_Line_Item__c> inlinelist4 = new  List<Inventory_Line_Item__c>();
        inlinelist4.add(new Inventory_Line_Item__c( Inventory__c=inv4.id, Quantity__c=0, account__c = newAccount.Id, Product__c=prod1.Id, ProductDateCode__c = Date.Today().addDays(-93)));
        inlinelist4.add(new Inventory_Line_Item__c( Inventory__c=inv4.id, Quantity__c=10, account__c = newAccount.Id, Product__c=prod2.Id, ProductDateCode__c = Date.Today().addDays(-93)));
        inlinelist4.add(new Inventory_Line_Item__c( Inventory__c=inv4.id, Quantity__c=0, account__c = newAccount.Id, Product__c=prod3.Id, ProductDateCode__c = Date.Today().addDays(-93)));
        insert inlinelist4;

        List<Inventory_Line_Item__c> inlinelist5 = new  List<Inventory_Line_Item__c>();
        inlinelist5.add(new Inventory_Line_Item__c( Inventory__c=inv5.id, Quantity__c=10, account__c = newAccount.Id, Product__c=prod1.Id, ProductDateCode__c = Date.Today().addDays(-123)));
        inlinelist5.add(new Inventory_Line_Item__c( Inventory__c=inv5.id, Quantity__c=10, account__c = newAccount.Id, Product__c=prod2.Id, ProductDateCode__c = Date.Today().addDays(-123)));
        inlinelist5.add(new Inventory_Line_Item__c( Inventory__c=inv5.id, Quantity__c=10, account__c = newAccount.Id, Product__c=prod3.Id, ProductDateCode__c = Date.Today().addDays(-123)));
        insert inlinelist5;
        


        //RG_InventoryLineItemPage
        PageReference pg=Page.RG_InventoriesHistoryPage;
        pg.getParameters().put('id',newAccount.id);
        Test.setCurrentPage(pg);

    
        RG_InventoriesHistoryCls controller = new RG_InventoriesHistoryCls();


        //system.assertEquals(1, controller.inventories.size());
        system.assertEquals(2, controller.inventoryDTOs.size());
      
        controller.deleteInvalidLineItems();

        List<Inventory_Line_Item__c> ilisAssert = [
            SELECT Id
            FROM Inventory_Line_Item__c
        ];

        //system.assertEquals(2, ilisAssert.size());
        controller.saveChanges();
  

    }
    
    static testmethod void CloneButtonTest () {
        Account newAccount = new Account();
        newAccount.name= 'test';
        newAccount.account__c= '123456';
        insert newAccount;

        //Inventory
        Inventory__c inv= new Inventory__c(Visit_Date__c = Date.Today().addDays(-2), account__c = newAccount.Id);
        insert inv;

        //Inventory_Line_Item__c
        List<Inventory_Line_Item__c> inlinelist = new  List<Inventory_Line_Item__c>();
        inlinelist.add(new Inventory_Line_Item__c(Inventory__c = inv.id, Quantity__c = 42, account__c = newAccount.Id));
        insert inlinelist;

	
        //RG_InventoryLineItemPage
        PageReference pg=Page.RG_InventoriesHistoryPage;
        pg.getParameters().put('id',newAccount.id);
        //pg.getParameters().put('count','1');
        Test.setCurrentPage(pg);

        RG_InventoriesHistoryCls controller = new RG_InventoriesHistoryCls();

        PageReference newPR = controller.newInventory();
        system.assertEquals(2, [SELECT Id FROM Inventory__c].size());
     


        PageReference pg2=Page.RG_InventoriesHistoryPage;
        pg2.getParameters().put('count','1');
        Test.setCurrentPage(pg2);
       	
        RG_InventoriesHistoryCls controller2 = new RG_InventoriesHistoryCls();
	
        PageReference newPR2 = controller2.newInventory();
        system.assertEquals(3, [SELECT Id FROM Inventory__c].size());
    }

    static testmethod void logaCallTest () {

        Account newAccount = new Account();
        newAccount.name= 'test';
        newAccount.account__c= '123456';
        insert newAccount;

        Task newTask = new Task();
        newTask.Subject = Label.Task_subject_for_log_a_call;
        newTask.WhatId = newAccount.Id;
        insert newTask;
        system.assertEquals(1, [SELECT Id FROM Task].size());
    }
    

	@isTest
    public static void productsFunctionality () { 
		RG_InventoriesHistoryCls controller1 = new RG_InventoriesHistoryCls();
		List<Inventory__c> inc_inventories = new List<Inventory__c>();

        Account newAccount = new Account();
        newAccount.name= 'test';
        newAccount.account__c= '123456';
        insert newAccount;

        //Inventory with todays date
        Inventory__c inv1= new Inventory__c(Visit_Date__c = Date.Today(), account__c = newAccount.Id);
        insert inv1;
        
        //Inventory without todays date
        Inventory__c inv2= new Inventory__c(Visit_Date__c = Date.Today().addDays(-2), account__c = newAccount.Id);
        inc_inventories.add(inv2);
        insert inv2;
        
        List<Product2> products = createProductsPriceBooksHelper();

        RG_InventoriesHistoryCls.wProduct wProd1 = new RG_InventoriesHistoryCls.wProduct(products.get(0));
        RG_InventoriesHistoryCls.wProduct wProd2 = new RG_InventoriesHistoryCls.wProduct(products.get(1));
        RG_InventoriesHistoryCls.wProduct wProd3 = new RG_InventoriesHistoryCls.wProduct(products.get(2));
        
        controller1.prodList.add(wProd1);
        controller1.prodList.add(wProd2);
        controller1.prodList.add(wProd3);

        controller1.selectedList = wProd1.wrappedProd.Id + ',true,'+ wProd2.wrappedProd.Id+ ',false,' + wProd3.wrappedProd.Id + ',true';

        Test.startTest();
        
        PageReference pg=Page.RG_InventoriesHistoryPage;
        pg.getParameters().put('searchVal','4k');
        Test.setCurrentPage(pg);
        
        controller1.runSearch();
        controller1.toggleSort();
        
        

        inc_inventories.add(inv1);
		controller1.lastInventory = inv1.Id;
      	controller1.inventories = inc_inventories;
        controller1.addLineItem();

        System.assertEquals(2, controller1.prodList.size());

       	inc_inventories = new List<Inventory__c>();
        inc_inventories.add(inv2);
		controller1.lastInventory = inv2.Id;
      	controller1.inventories = inc_inventories;
        controller1.addLineItem();

        //create error exception condition for wrong sort to throw dml error
        controller1.soql = '';
        controller1.sortField = '$%$#';
        controller1.runSearch();

        //cause instantiation of prod list
        controller1.prodList=null;
        controller1.clearSelections();
        
		Test.stopTest();

    }

    public static List<Product2> createProductsPriceBooksHelper(){

        List<Product2> products = new List<Product2>();
        
        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;

        Id pricebookId = Test.getStandardPricebookId(); 

        Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update customPB;

        Product2 prod1 = new Product2(Name='4K Lites', ProductCode='101', Family = 'none', Item_Num__c='444441', Item_Status__c='1');
        Product2 prod2 = new Product2(Name='4K apple', ProductCode='102', Family = 'none', Item_Num__c='444442', Item_Status__c='1');
        Product2 prod3 = new Product2(Name='1% cigars', ProductCode='103', Family = 'none', Item_Num__c='444443', Item_Status__c='1');

        insert prod1;
        products.add(prod1);

        insert prod2;
        products.add(prod2);
    
        insert prod3;
        products.add(prod3);

        return products;

    }

}