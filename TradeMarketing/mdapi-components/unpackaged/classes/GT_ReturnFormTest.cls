@isTest
public without sharing class GT_ReturnFormTest {
    public GT_ReturnFormTest() {

    }

    static testmethod void test_newReturn () { 
        Account acc1 = createGPAccount();
        
        Id currentUser = UserInfo.getUserId();
        Test.startTest();
        
        PageReference pg=Page.GT_ReturnForm;
        pg.getParameters().put('id',acc1.Id);
        Test.setCurrentPage(pg);
        GT_ReturnForm controller1 = new GT_ReturnForm();
        controller1.newReturn();
        List<Return__c> lst_Rets = [SELECT Id FROM Return__c];
        

        Test.stopTest();
    }


    static testmethod void test_editReturn () { 
        Account acc1 = createGPAccount();
        Id currentUser = UserInfo.getUserId();
        Return__c ret1 = createReturn(acc1, currentUser, 'Draft', Date.today().addDays(-15));

        Test.startTest();
        

        //create new return with no previous returns
        PageReference pg=Page.GT_ReturnForm;
        pg.getParameters().put('id',ret1.Id);

        Test.setCurrentPage(pg);

        GT_ReturnForm controller1 = new GT_ReturnForm();
        //controller1.newReturn();


        List<Return__c> lst_Rets = [SELECT Id FROM Return__c];

        //after the page is loaded and new button is clicked, there should be a new return 
        system.assertEquals(1, lst_Rets.size());
        delete lst_Rets;

        Test.stopTest();
    }


    static testmethod void test_saveReturn () { 
        Account acc1 = createGPAccount();
        Id currentUser = UserInfo.getUserId();
        Return__c ret1 = createReturn(acc1, currentUser, 'Draft', Date.today().addDays(-15));

        Test.startTest();
        

        //create new return with no previous returns
        PageReference pg=Page.GT_ReturnForm;
        pg.getParameters().put('id',ret1.Id);

        Test.setCurrentPage(pg);

        GT_ReturnForm controller1 = new GT_ReturnForm();

        controller1.saveReturn();


        Return__c ret2 = [SELECT Id, Total_Pouches__c, Total_Displays__c FROM Return__c][0];

        //after the page is loaded and new button is clicked, there should be a new return 
        System.assertEquals(20, ret2.Total_Pouches__c);
        System.assertEquals(20, ret2.Total_Displays__c);



        Test.stopTest();
    }

    static testmethod void test_SubmitReturn () { 

        Account acc1 = createGPAccount();
        Id currentUser = UserInfo.getUserId();
        Return__c ret1 = createReturn(acc1, currentUser, 'Draft', Date.today().addDays(-15));

        Test.startTest();
        

        //create new return with no previous returns
        PageReference pg=Page.GT_ReturnForm;
        pg.getParameters().put('id',ret1.Id);

        Test.setCurrentPage(pg);

        GT_ReturnForm controller1 = new GT_ReturnForm();
        
        List<Return_Line_Item__c> lst_rli = [SELECT Id, Displays__c, Pouches__C FROM Return_Line_Item__c WHERE Return_Code__c='Regular' AND Quantity_Type__c='Display' AND Product_Date__c = :Date.today().addDays(-400)];

        System.debug('lst_rli: ' + lst_rli.size());

        //delete lst_rli;
        controller1.deleteItemId = lst_rli.get(0).Id;

        controller1.createDeletionRequest();

        controller1.deleteItemId = lst_rli.get(1).Id;

        controller1.createDeletionRequest();

        controller1.saveReturn();

        controller1.submitReturn();

        List<Return__c> lst_ret = [SELECT Id, Stage__c FROM Return__c WHERE Stage__c = 'Submitted'];
        System.debug('Account Owner: ' + acc1.OwnerId);

        System.debug('pg.getParameters(): ' + pg.getParameters() + 'lst_ret: ' + lst_ret.get(0).Stage__c);

        System.assertEquals(1, lst_ret.size());

        Test.stopTest();
    }

    static testmethod void test_AddLineItems () { 
        
        Id currentUser = UserInfo.getUserId();
        
        Test.startTest();
        Account acc1 = createGPAccount();
        //createProducts(acc1);
        Return__c ret1 = createReturn(acc1, currentUser, 'Draft', Date.today().addDays(-15));

        PageReference pg=Page.GT_ReturnForm;
        pg.getParameters().put('id',ret1.Id);
        pg.getParameters().put('searchVal','4k');
        
        Test.setCurrentPage(pg);

        GT_ReturnForm controller1 = new GT_ReturnForm();

        
        
        controller1.runSearch();
        controller1.toggleSort();

        Product2 prod = [SELECT Id FROM Product2 WHERE Name='4K Lites'][0];
        controller1.selectedList = prod.Id + ',true';

        Product2 prod2 = [SELECT Id FROM Product2 WHERE Name='Flat Wrap Product'][0];
        controller1.selectedList = prod2.Id + ',true';

        controller1.addLineItem();

        for (GT_ReturnForm.ReturnDTO item : controller1.ReturnDTOs) { 
            item.isNew=true;
        }

        controller1.saveReturn();
        

        system.assertEquals(7, [SELECT Id FROM Return_Line_Item__c WHERE Return__c=:ret1.Id].size());    
        
        
        controller1.deleteItemId = [SELECT Id FROM Return_Line_Item__c WHERE Return__c=:ret1.Id AND Quantity_Type__c='Pouch'][0].Id;
        
        
        controller1.createDeletionRequest();
        
     
        //system.assertEquals(5, [SELECT Id FROM Return_Line_Item__c WHERE Return__c=:ret1.Id].size());
        

        Test.stopTest();
    }

    static testmethod void test_Search () {
        Id currentUser = UserInfo.getUserId();
        
        Test.startTest();
        Account acc1 = createGPAccount();
        Return__c ret1 = createReturn(acc1, currentUser, 'Draft', Date.today().addDays(-15));

        PageReference pg=Page.GT_ReturnForm;
        pg.getParameters().put('id',ret1.Id);
        pg.getParameters().put('searchVal','4k');
        
        Test.setCurrentPage(pg);

        GT_ReturnForm controller1 = new GT_ReturnForm();

        controller1.runSearch();
        controller1.toggleSort();

        system.assertEquals(1, controller1.prodList.size());

    }

/*
    static testmethod void test_DeleteReturnLineItem () { 

        Id currentUser = UserInfo.getUserId();
        
        Test.startTest();
        Account acc1 = createGPAccount();
        //createProducts(acc1);
        Return__c ret1 = createReturn(acc1, currentUser, 'Draft', Date.today().addDays(-15));

        PageReference pg=Page.GT_ReturnForm;
        pg.getParameters().put('id',ret1.Id);
        pg.getParameters().put('searchVal','4k');
        
        Test.setCurrentPage(pg);

        GT_ReturnForm controller1 = new GT_ReturnForm();

        controller1.saveReturn();
       
        controller1.deleteItemId = [SELECT Id FROM Return_Line_Item__c WHERE Return__c=:ret1.Id AND Quantity_Type__c='Display'][0].Id;

        controller1.createDeletionRequest();

        system.assertEquals(5, [SELECT Id FROM Return_Line_Item__c WHERE Return__c=:ret1.Id].size());

        Test.stopTest();


    }
    */
    
    

    public static Account createGPAccount(){
        //create test account
        Account acc1 = new Account();
        acc1.name= 'test';
        acc1.Account__c= '123456';
        acc1.OwnerId = UserInfo.getUserId();
        insert acc1;

        return acc1;
    }
/*
    public static Account createSFAccount(){
        //create test account
        Account acc1 = new Account();
        acc1.name= 'testGT';
        acc1.Account__c= 'GT123456';
        insert acc1;

        return acc1;
    }
*/
    public static Return__c createReturn(Account acc1, Id user1, String stageVal, Date date1){
        //create test return
        Return__c ret1 = new Return__c();
        
        ret1.Account__c= acc1.Id;

        ret1.Additional_Notes__c = 'Test';
        ret1.Initiator__c = user1;
        ret1.Initiator_Supervisor_1__c = '005f4000001zgBTAAY';
        ret1.OwnerId = user1;
        ret1.Pallets__c = 2;

        ret1.Submitted_Date__c = date1;

        ret1.Stage__c = stageVal;
        ret1.Tracking_Number__c = '12342323323432';

        insert ret1;
        
        List<Product2> products = createProducts(acc1);


        
        Return_Line_Item__c retLI1 = new Return_Line_Item__c(Return__c=ret1.Id, Product__c=products.get(0).Id, Return_Code__c='Retail', Quantity_Type__c='Pouch', Product_Date__c = Date.today().addDays(-90), Pouches__c=10);
        Return_Line_Item__c retLI2 = new Return_Line_Item__c(Return__c=ret1.Id, Product__c=products.get(1).Id, Return_Code__c='Regular', Quantity_Type__c='Pouch', Product_Date__c = Date.today().addDays(-400), Pouches__c=10);
        Return_Line_Item__c retLI3 = new Return_Line_Item__c(Return__c=ret1.Id, Product__c=products.get(0).Id, Return_Code__c='Retail', Quantity_Type__c='Display', Product_Date__c = Date.today().addDays(-90), Displays__c=10);
        Return_Line_Item__c retLI4 = new Return_Line_Item__c(Return__c=ret1.Id, Product__c=products.get(1).Id, Return_Code__c='Regular', Quantity_Type__c='Display', Product_Date__c = Date.today().addDays(-400), Displays__c=10);
        Return_Line_Item__c retLI5 = new Return_Line_Item__c(Return__c=ret1.Id, Product__c=products.get(2).Id, Return_Code__c='Regular', Quantity_Type__c='Display', Product_Date__c = Date.today().addDays(-400));

        insert retLI1;
        insert retLI2;
        insert retLI3;
        insert retLI4;
        insert retLI5;

        return ret1;
    }

/*

    public static Account createAccountWithInventories(){
        //create test account
        Account acc1 = new Account();
        acc1.name= 'GTtest';
        acc1.Account__c= 'GT123456';
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
    */

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