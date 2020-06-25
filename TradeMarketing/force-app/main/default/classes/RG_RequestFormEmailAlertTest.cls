@isTest
public class RG_RequestFormEmailAlertTest {
/*
    @isTest
    public static void RG_RequestFormEmailAlert_TEST()
    {
    
       User u3 = createUsersHelper();
        
        System.RunAs(u3){            
         Test.StartTest();  
            Case cas=new Case();
            cas.Status='New';
            cas.Origin='Phone';
            cas.Notes__c = 'test';
            cas.Email_To__c = 'test@gmail.com';
            insert cas;
            
            Attachment attach=new Attachment(); 
            attach.Name='Test Attachment'; 
            Blob bodyBlob=Blob.valueOf('Test Attachment Body'); 
            attach.body=bodyBlob; 
            attach.parentId=cas.Id; 
            attach.ContentType = 'application/msword'; 
            attach.IsPrivate = false; 
            attach.Description = 'Test'; 
            insert attach; 

                
            PageReference page=page.RG_RequestFormEmailAlert;
            page.getparameters().put('id',cas.id); 
            test.setCurrentpage(page);        
            ApexPages.StandardController sc = new ApexPages.standardController(cas);
            RG_RequestFormEmailAlertCls Request = new RG_RequestFormEmailAlertCls(sc);
            Request.autosendCase(); 
            //Request.autoSendOtherRequestTicket();
            Request.autosendPOSRequestType();
                
            Integer invocations = Limits.getEmailInvocations();
            
          Test.stopTest();
          
          system.assertEquals(1, invocations, 'An email should be sent');
        
      }
    }
*/


    @isTest
    public static void autoSendOtherRequestTicket_TEST()
    {
    
		User u3 = createUsersHelper();
        
        System.RunAs(u3){            
         Test.StartTest();  
			Case cas = createCaseHelper();
            
			createAttachmentHelper(cas);
                
            PageReference page=page.RG_RequestFormEmailAlert;
            page.getparameters().put('id',cas.id); 
            test.setCurrentpage(page);        
            ApexPages.StandardController sc = new ApexPages.standardController(cas);
            RG_RequestFormEmailAlertCls Request = new RG_RequestFormEmailAlertCls(sc);
    
            Request.autoSendOtherRequestTicket();
      
                
            Integer invocations = Limits.getEmailInvocations();
            
          Test.stopTest();
          
          system.assertEquals(1, invocations, 'An email should be sent');
	
      }
    }
    
    @isTest
    public static void autoSendOrder_TEST()
    {
       	User u3 = createUsersHelper();
        
        System.RunAs(u3){  
            Test.StartTest(); 
            Account acc = new Account(Name='Test',Account__c='121');
            insert acc;
            
            Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
            insert openPB;

            Id pricebookId = Test.getStandardPricebookId(); 

            Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
            update customPB;

            Product2 prod1 = new Product2(Name='4K Lites', ProductCode='101', Item_Num__c='444441', Item_Status__c='1', isActive=true);
            Product2 prod2 = new Product2(Name='4K apple', ProductCode='102', Item_Num__c='444442', Item_Status__c='1', isActive=true);
            Product2 prod3 = new Product2(Name='1% cigars', ProductCode='103', Item_Num__c='444443', Item_Status__c='1', isActive=true);

            insert prod1;
            insert prod2;
            insert prod3;
        
            PricebookEntry pe1 = [SELECT Pricebook2Id, Product2Id, UnitPrice, IsActive FROM PricebookEntry WHERE Pricebook2Id =:pricebookId AND Product2Id=:prod1.Id];

            //debug
            //System.debug('PE1: '+ pe1.Id);

            PricebookEntry pe2 = [SELECT Pricebook2Id, Product2Id, UnitPrice, IsActive FROM PricebookEntry WHERE Pricebook2Id =:pricebookId AND Product2Id=:prod1.Id];
            PricebookEntry pe3 = [SELECT Pricebook2Id, Product2Id, UnitPrice, IsActive FROM PricebookEntry WHERE Pricebook2Id =:pricebookId AND Product2Id=:prod1.Id];

            Order ord = new Order(AccountId=acc.Id, EffectiveDate=System.today(), Status='Draft', PriceBook2Id=pricebookId);
            insert ord;

            OrderItem ordItm1 = new OrderItem(OrderId=ord.Id, Product2Id=prod1.Id, UnitPrice=10.99, Quantity=10, PricebookEntryId=pe1.id);
            insert ordItm1;

            OrderItem ordItm2 = new OrderItem(OrderId=ord.Id, Product2Id=prod2.Id, UnitPrice=11.99, Quantity=11, PricebookEntryId=pe2.id);
            insert ordItm2;

            OrderItem ordItm3 = new OrderItem(OrderId=ord.Id, Product2Id=prod2.Id, UnitPrice=12.99, Quantity=12, PricebookEntryId=pe3.id);
            insert ordItm3;

            PageReference page=page.RG_OrderFormEmailAlert;
            page.getparameters().put('Id',ord.id); 
            test.setCurrentpage(page);
            ApexPages.StandardController sc = new ApexPages.standardController(ord);
            
            RG_RequestFormEmailAlertCls Order = new RG_RequestFormEmailAlertCls(sc);
            order.autosendOrder();

            
            Integer invocations = Limits.getEmailInvocations();
            
            Test.stopTest();

            Order ord2 = [SELECT status FROM Order WHERE Id=:ord.Id];
            system.assertEquals('Activated',ord2.Status, 'The order status should be updated to activated');
            system.assertEquals(1, invocations, 'An email should be sent');
        }
    }    
    
  
    
    @isTest
    public static void autosendCase_TEST(){
        
		Case cas = createCaseHelper();
        
        PageReference page=page.RG_RequestFormEmailAlert;
        page.getparameters().put('id',cas.id); 
        test.setCurrentpage(page);        
        ApexPages.StandardController sc = new ApexPages.standardController(cas);
        RG_RequestFormEmailAlertCls Request = new RG_RequestFormEmailAlertCls(sc);
        Request.autosendCase(); 
    }
    
    @isTest
    public static void autosendPOSRequestType_TEST(){
        User u3 = createUsersHelper();
        
        System.RunAs(u3){            
         Test.StartTest();  
			Case cas = createCaseHelper();
            
			createAttachmentHelper(cas);
                
            PageReference page=page.RG_RequestFormEmailAlert;
            page.getparameters().put('id',cas.id); 
            test.setCurrentpage(page);        
            ApexPages.StandardController sc = new ApexPages.standardController(cas);
            RG_RequestFormEmailAlertCls Request = new RG_RequestFormEmailAlertCls(sc);
    
            Request.autosendPOSRequestType();
      
                
            Integer invocations = Limits.getEmailInvocations();
            
          Test.stopTest();
          
          system.assertEquals(1, invocations, 'An email should be sent');
    	}
    }
    
    
    public static User createUsersHelper()
    {
        User u1 = new User(   
         ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
         LastName = 'National',
         Email = 'Nationaluser000@amamama.com',
         Username = 'Nationaluser000@amamama.com' + System.currentTimeMillis(),
         CompanyName = 'NationalCompName',
         Title = 'National Sales Manager',
         Alias = 'Nation',
         TimeZoneSidKey = 'America/Los_Angeles',
         EmailEncodingKey = 'UTF-8',
         LanguageLocaleKey = 'en_US',
         LocaleSidKey = 'en_US'
        );             
        insert u1;
            
        User u2 = new User(   
         ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
         LastName = 'Regional',
         Email = 'Regionaluser000@amamama.com',
         Username = 'Regionaluser000@amamama.com' + System.currentTimeMillis(),
         CompanyName = 'RegionalCompName',
         Title = 'Regional Sales Manager',
         Alias = 'Region',
         TimeZoneSidKey = 'America/Los_Angeles',
         EmailEncodingKey = 'UTF-8',
         LanguageLocaleKey = 'en_US',
         LocaleSidKey = 'en_US'
        );             
        insert u2;
                    
        User u3 = new User(   
         ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
         LastName = 'last',
         Email = 'puser000@amamama.com',
         Username = 'puser000@amamama.com' + System.currentTimeMillis(),
         CompanyName = 'TEST',
         Title = 'title',
         Alias = 'alias',
         ManagerId = u2.Id,
         National_Sales_Manager__c = u1.Id,
         Regional_Sales_Manager__c = u2.Id,
         Email_Notification_Repository__c = 'none@none.com',
         TimeZoneSidKey = 'America/Los_Angeles',
         EmailEncodingKey = 'UTF-8',
         LanguageLocaleKey = 'en_US',
         LocaleSidKey = 'en_US'
        );  
            
        insert u3; 
        
        return u3;
        
    }
    
    public static Case createCaseHelper()
    {
        Case cas=new Case();
        cas.Status='New';
        cas.Origin='Phone';
        cas.Notes__c = 'test';
        cas.Email_To__c = 'test@gmail.com';
        insert cas;
        
        return cas;
    }
    
    public static Attachment createAttachmentHelper(Case cas)
    {
        Attachment attach=new Attachment(); 
        attach.Name='Test Attachment'; 
        Blob bodyBlob=Blob.valueOf('Test Attachment Body'); 
        attach.body=bodyBlob; 
        attach.parentId=cas.Id; 
        attach.ContentType = 'application/msword'; 
        attach.IsPrivate = false; 
        attach.Description = 'Test'; 
        insert attach; 
        
        return attach;
    }

    public static List<Product2> createProductsPriceBooksHelper(){

        List<Product2> products = new List<Product2>();
        
        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;

        Id pricebookId = Test.getStandardPricebookId(); 

        Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update customPB;

        Product2 prod1 = new Product2(Name='4K Lites', ProductCode='101', Item_Num__c='444441', Item_Status__c='1');
        Product2 prod2 = new Product2(Name='4K apple', ProductCode='102', Item_Num__c='444442', Item_Status__c='1');
        Product2 prod3 = new Product2(Name='1% cigars', ProductCode='103', Item_Num__c='444443', Item_Status__c='1');

        insert prod1;
        products.add(prod1);

        insert prod2;
        products.add(prod2);
    
        insert prod3;
        products.add(prod3);





        return products;

    }
    

}