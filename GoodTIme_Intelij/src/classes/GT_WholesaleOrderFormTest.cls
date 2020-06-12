@isTest
public class GT_WholesaleOrderFormTest {
    @testSetup static void setupData() {
        RecordType accountRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Wholesaler or Distributor'];
        Account testAccount = new Account(Name = 'Test Account', Account__c = 'test1', RecordTypeId = accountRecordType.Id);
        insert testAccount;
        
        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;
        
        Pricebook2 customPB = new Pricebook2(id=Test.getStandardPricebookId(), Name='Standard Price Book', isActive=true);
        update customPB;
        
        Product_Brand__c pb1 = new Product_Brand__c(Name='Flat Wrap 2/79');
        Product_Brand__c pb2 = new Product_Brand__c(Name='4KS 60CT');
        Product_Brand__c pb3 = new Product_Brand__c(Name='CITY LIFE 5F99');
        insert new List<Product_Brand__c> { pb1, pb2, pb3 };
        
        Product2 prod1 = new Product2(Name='Test Flat Wrap Product', ProductCode='101', Item_Num__c='444441', Item_Status__c='1', Product_Brand__c=pb1.Id, IsActive=true);
        Product2 prod2 = new Product2(Name='Test 4K Lites', ProductCode='102', Item_Num__c='444442', Item_Status__c='3', Product_Brand__c=pb2.Id, IsActive=true);
        Product2 prod3 = new Product2(Name='Test City Life', ProductCode='103', Item_Num__c='444443', Item_Status__c='1', Product_Brand__c=pb3.Id, IsActive=true);
        insert new List<Product2> { prod1, prod2, prod3 };
    }
    
    public static testMethod void testOrderForm1() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1].get(0);
		Test.setCurrentPage(Page.GT_WholesaleOrderForm);
        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
        GT_WholesaleOrderForm controller = new GT_WholesaleOrderForm();
        System.assertEquals(testAccount.Id, controller.currentAccount.Id);
        
        // Clear Product Selections
        controller.prodList = NULL;
        controller.clearSelections();
        
        // Create new Order
        controller.newOrder();
        Order testOrder = [SELECT Id FROM Order LIMIT 1].get(0);
        ApexPages.currentPage().getParameters().put('id', testOrder.Id);
        controller = new GT_WholesaleOrderForm();
        System.assertEquals(testOrder.Id, controller.currentOrder.Id);
        
        // Search Products
        ApexPages.currentPage().getParameters().put('searchVal', 'Test');
        controller.runSearch();
        System.assertEquals(2, controller.prodList.size());
        
        // Toggle Run Queries
        controller.toggleSort();
        
        // Clear Product Selections
        controller.clearSelections();
        
        // Add Order Items
        controller.selectedList = '';
        Integer index = 1;
        
        for(GT_WholesaleOrderForm.wProduct prod : controller.prodList) {
            if(Math.mod(index, 2) == 0 ) {
                controller.selectedList = controller.selectedList + String.valueOf(prod.wrappedProd.Id) + ',false,';
            }
            else {
            	controller.selectedList = controller.selectedList + String.valueOf(prod.wrappedProd.Id) + ',true,';
            }
        }
        
        controller.addLineItem();
        
        // Save Order Items
        for(GT_WholesaleOrderForm.OrderDTO item : controller.OrderDTOs) {   
            for(OrderItem oli : item.ordLI.values()) {
                oli.Quantity = 5;
            }
        }
        
        controller.saveOrder();
        System.assertEquals(10, controller.currentOrder.Total_Displays__c);
        
        // Delete Order Item
        controller.deleteItemId = controller.OrderDTOs.get(0).ordLI.values().get(0).Id;
        controller.createDeletionRequest();
        
        // On Page Load
       	//controller.olisDelete.add(controller.OrderDTOs.get(0).ordLI.values().get(0));
        controller.onPageLoad();
        
        // Submit Order
        controller.submitOrder();   
        
        // Additional test coverage
        System.assertEquals(NULL, controller.countParamMonth);
        System.assertEquals(NULL, controller.lastOrder);
    } 
    
    public static testMethod void testOrderForm2() {
        Account testAccount = [SELECT Id, Account__c FROM Account LIMIT 1].get(0);
        testAccount.Account__c = 'GTtest0';
        update testAccount;
        
		Test.setCurrentPage(Page.GT_WholesaleOrderForm);
        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
        GT_WholesaleOrderForm controller = new GT_WholesaleOrderForm();
        System.assertEquals(testAccount.Id, controller.currentAccount.Id);
        
        // Create new Order
        controller.newOrder();
        Order testOrder = [SELECT Id FROM Order LIMIT 1].get(0);
        ApexPages.currentPage().getParameters().put('id', testOrder.Id);
        controller = new GT_WholesaleOrderForm();
        System.assertEquals(testOrder.Id, controller.currentOrder.Id);
    }
}