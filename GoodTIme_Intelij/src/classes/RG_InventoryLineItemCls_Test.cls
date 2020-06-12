@isTest
public class RG_InventoryLineItemCls_Test {
    static testmethod void lineItemGeneration_Test () {
        //Inventory
        Inventory__c inv= new Inventory__c(Visit_Date__c=Date.Today());
        Insert inv;
        

        /*
        Id pricebookId = Test.getStandardPricebookId(); 
        
                // Create a custom price book
        Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update customPB;
`       */

        
        Pricebook2 openPB = new Pricebook2(Name = 'Open Stock Items', Description = 'Price Book 2009 Products', IsActive = true); 
        insert openPB;

        Id pricebookId = Test.getStandardPricebookId(); 

        Pricebook2 customPB = new Pricebook2(id=pricebookId, Name='Standard Price Book', isActive=true);
        update customPB;



        //Product2
        Product2 prod = new Product2(Name = 'Laptop X200',ProductCode='104', Family = 'none', Item_Num__c = '1234', Item_Status__c = '1');                      
        
        insert prod;
        

        //PriceBookEntry
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = openPB.id,
            Product2Id = prod.Id,
            IsActive = true);
        
        
        //insert pbEntry ;
        
        //Inventory_Line_Item__c
        List<Inventory_Line_Item__c> inlinelist = new  List<Inventory_Line_Item__c>();
        inlinelist.add(new Inventory_Line_Item__c( Inventory__c=inv.id, Quantity__c=42));
        insert inlinelist;
        //WorkOrder
        WorkOrder wrrkodr= new WorkOrder(Pricebook2id=openPB.id);
        
        insert wrrkodr;
        //WorkOrderLineItemList
        List<WorkOrderLineItem> workordline= new List<WorkOrderLineItem>();
        
        workordline.add(new WorkOrderLineItem(WorkOrderid=wrrkodr.id, PricebookEntryid=pbEntry.id));
        insert workordline;
        
        
        //RG_InventoryLineItemPage
        PageReference pg=Page.RG_InventoryLineItemPage;
        pg.getParameters().put('id',inv.id);
        
        ApexPages.StandardController std= new ApexPages.StandardController(inv);
        
        RG_InventoryLineItemCls rginvline= new RG_InventoryLineItemCls(std);
        rginvline.AddInventoryLineItem();
        rginvline.EditInventoryId=inlinelist[0].id;
        rginvline.savebtn();
        rginvline.cancelbtn();
        rginvline.EditInventoryLineItem();
        rginvline.updateLineItem();
        rginvline.deleteInventoryLineItem();
        rginvline.flagDisable = false;
        RG_InventoryLineItemCls.productWrapper newClass231 = new RG_InventoryLineItemCls.productWrapper(true, prod, '5');

        rginvline.productName = 'Laptop X200';
        rginvline.productCode = '104';
        rginvline.productCategory = 'test';
        rginvline.productList();



        //RG_WorkOrderLineItemPage
        PageReference pgwrk=Page.RG_WorkOrderLineItemPage;
        pgwrk.getParameters().put('id',wrrkodr.id);
        
        ApexPages.StandardController stdwrk= new ApexPages.StandardController(wrrkodr);
        
        RG_WorkOrderLineItemCls rgwork= new RG_WorkOrderLineItemCls(stdwrk);
        rgwork.AddOrderLineItem();
        rgwork.EditOrderId=workordline[0].id;
        rgwork.savebtn();
        rgwork.AddOrderLineItem();
        rgwork.cancelbtn();
        rgwork.EditOrderLineItem();
        rgwork.updateLineItem();
        rgwork.deleteOrderLineItem();
        rgwork.prodListActionFunction();
        
        
         PageReference page1=Page.RG_InventoryLineItemClonePage;
        page1.getParameters().put('id',inv.id);
         RG_InventoryCloneCls  inclone= new RG_InventoryCloneCls();
        system.debug('inlinelist==>'+inlinelist);
inclone.InventoryClone();
        
        
        
        
    }
}