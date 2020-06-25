@isTest
public with sharing class GT_PriceTrackingTest {
    public GT_PriceTrackingTest() {

    }
    

    static testmethod void test_AddBrand () { 

        //Create account, inventory, inventory line items, pricebooks, products, and brands
        Account acc = createAccountWithInventories();

        GT_PriceTrackingClass controller1 = new GT_PriceTrackingClass(new ApexPages.StandardController(acc));
	

        //get the brand IDs to add them to the select list 
        List<Product_Brand__c> lst_PBs = [SELECT Id, Name FROM Product_Brand__c];

        Test.startTest();
        
        PageReference pg=Page.GT_PriceTrackingPage;
        pg.getParameters().put('id',acc.Id);
        

        Test.setCurrentPage(pg);
        controller1.getRetailPriceArchives();

        List<Retail_Price_Archive__c> lst_RPAs = [SELECT Id FROM Retail_Price_Archive__c];

        //after the page is loaded and the action is triggered there should be an Retail Price Archive Created 
        system.assertEquals(1, lst_RPAs.size());

        //set the conditions necessary to add a brand - update the list with a checked brand 
        controller1.selectedList = lst_PBs.get(0).Id + ',true,'+ lst_PBs.get(1).Id + ',false,' + lst_PBs.get(2).Id + ',true';

        controller1.addBrand();
        
        //set the wRetailPrice to an arbitraty value so you can save it 
        for(GT_PriceTrackingClass.wRetailPrice wRP : controller1.archivePrices){
            wRP.wrapRP.Price__c = 1;
        }

        //save the brand price 
        controller1.saveChanges();

        //after the brand is added there should be 2 retail prices
        List<Retail_Price__c> lst_RPs = [SELECT Id FROM Retail_Price__c];
        system.assertEquals(2, lst_RPs.size());

        //one brand was not checked as true on the selectedList so it remains on the inventory, but has not been added the RPA use the getInvtoryBrands method to bring it into the list.
        controller1.getInventoryBrands();

        //remove the brand that was added by the import
        controller1.removeBrandName = lst_PBs.get(1).Name;
        controller1.removeBrand();

        //save the brand prices 
        controller1.saveChanges();

        //verify that the brand was removed from the list and not commited to the database 
        lst_RPs = [SELECT Id FROM Retail_Price__c];
        system.assertEquals(2, lst_RPs.size());

        
        //run the import again to verify its functionality 
        controller1.getInventoryBrands();

        //set the wRetailPrice to an arbitraty value so you can save it 
        for(GT_PriceTrackingClass.wRetailPrice wRP : controller1.archivePrices){
            wRP.wrapRP.Price__c = 1;
        }

        //save the brand prices 
        controller1.saveChanges();

        //after the brand is added, the import is run there should be 3 retail prices
        lst_RPs = [SELECT Id FROM Retail_Price__c];
        system.assertEquals(3, lst_RPs.size());

        //delete RP from the list and database
        controller1.deleteItemId = lst_RPs.get(2).Id;
        controller1.createDeletionRequest();

        //verify that RP was deleted from the database
        lst_RPs = [SELECT Id FROM Retail_Price__c];
        system.assertEquals(2, lst_RPs.size());

        //arbitrary code coverage for delete link user profile
        String userName = controller1.userProfileName;

		Test.stopTest();

    }

    static testmethod void test_AddBrandNoRPA () { 

        //Create account, inventory, inventory line items, pricebooks, products, and brands
        Account acc = createAccountWithInventories();

        GT_PriceTrackingClass controller1 = new GT_PriceTrackingClass(new ApexPages.StandardController(acc));
	

        //get the brand IDs to add them to the select list 
        List<Product_Brand__c> lst_PBs = [SELECT Id, Name FROM Product_Brand__c];

        Test.startTest();
        
        PageReference pg=Page.GT_PriceTrackingPage;
        pg.getParameters().put('id',acc.Id);
        
        List<Retail_Price_Archive__c> lst_oldRPAs = [SELECT Id FROM Retail_Price_Archive__c];
        delete lst_oldRPAs;

        Test.setCurrentPage(pg);
        controller1.getRetailPriceArchives();
        
        
        List<Retail_Price_Archive__c> lst_RPAs = [SELECT Id FROM Retail_Price_Archive__c];

        //after the page is loaded and the action is triggered there should be an Retail Price Archive Created 
        system.assertEquals(1, lst_RPAs.size());

        //set the conditions necessary to add a brand - update the list with a checked brand 
        controller1.selectedList = lst_PBs.get(0).Id + ',true,'+ lst_PBs.get(1).Id + ',false,' + lst_PBs.get(2).Id + ',true';

        controller1.addBrand();
        
        //set the wRetailPrice to an arbitraty value so you can save it 
        for(GT_PriceTrackingClass.wRetailPrice wRP : controller1.archivePrices){
            wRP.wrapRP.Price__c = 1;
        }

        //save the brand price 
        controller1.saveChanges();

        //after the brand is added there should be 2 retail prices
        List<Retail_Price__c> lst_RPs = [SELECT Id FROM Retail_Price__c];
        system.assertEquals(2, lst_RPs.size());

		Test.stopTest();

    }

    public static Account createAccountWithInventories(){
        //create test account
        Account acc1 = new Account();
        acc1.name= 'test';
        acc1.Account__c= '123456';
        insert acc1;

        List<Inventory__c> inc_inventories = new List<Inventory__c>();

        //create test inventories on the account 
        //Inventory with todays date
        //Inventory__c inv1= new Inventory__c(Visit_Date__c = Date.Today(), account__c = acc1.Id);
        //insert inv1;
        
        //Inventory without todays date
        Inventory__c inv2= new Inventory__c(Visit_Date__c = Date.Today().addDays(-35), Account__c = acc1.Id);
        inc_inventories.add(inv2);
        insert inv2;

        //create brands and products products
        List<Product2> lst_products = createProducts(acc1);

        //Create inventory with ilis associated to products with assigned brands
        Inventory_Line_Item__c ili1 = new Inventory_Line_Item__c(Account__c=acc1.Id, Inventory__c=inv2.Id, Product__c=lst_products.get(0).Id);
        Inventory_Line_Item__c ili2 = new Inventory_Line_Item__c(Account__c=acc1.Id, Inventory__c=inv2.Id, Product__c=lst_products.get(1).Id);
        Inventory_Line_Item__c ili3 = new Inventory_Line_Item__c(Account__c=acc1.Id, Inventory__c=inv2.Id, Product__c=lst_products.get(2).Id);

        insert ili1;
        insert ili2;
        insert ili3;

        return acc1;
    }

    public static List<Product2> createProducts(Account acc){

        List<Product2> products = new List<Product2>();
        
        //create pricebooks

        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;

        Id pricebookId = Test.getStandardPricebookId(); 

        Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update customPB;

        //create product brands 
        Product_Brand__c pb1 = new Product_Brand__c(Name='Flat Wrap 2/79');
        Product_Brand__c pb2 = new Product_Brand__c(Name='4KS 60CT');
        Product_Brand__c pb3 = new Product_Brand__c(Name='CITY LIFE 5F99');

        insert pb1;
        insert pb2;
        insert pb3;

        //creat products with associated brands 
        Product2 prod1 = new Product2(Name='Flat Wrap Product', ProductCode='101', Item_Num__c='444441', Item_Status__c='1', Product_Brand__c=pb1.Id, IsActive=true);
        Product2 prod2 = new Product2(Name='4K Lites', ProductCode='102', Item_Num__c='444442', Item_Status__c='1', Product_Brand__c=pb2.Id, IsActive=true);
        Product2 prod3 = new Product2(Name='City Life', ProductCode='103', Item_Num__c='444443', Item_Status__c='1', Product_Brand__c=pb3.Id, IsActive=true);
        
        insert prod1;
        products.add(prod1);

        insert prod2;
        products.add(prod2);
    
        insert prod3;
        products.add(prod3);


        Retail_Price_Archive__c RPA2 = new Retail_Price_Archive__c(Account__c=acc.Id, Recorded_Date__c=date.today().addDays(-40));
        insert RPA2;

        return products;

    }

}