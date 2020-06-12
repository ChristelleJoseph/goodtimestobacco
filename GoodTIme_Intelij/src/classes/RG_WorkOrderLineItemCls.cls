public class RG_WorkOrderLineItemCls {
public List<WorkOrderLineItem> workOrderLineItemList{get;set;}
public Id EditOrderId{get;set;}
public Boolean renderEdit{get;set;}
public List<Wrapper> WrapperList{get;set;}
public Integer IndexNum{get;set;}
public Id WordOrderId{get;set;}

public string productName{get;set;}
public Boolean popupRendered{get;set;}
public List<productWrapper> productWrapperList{get;set;}
Map<Id, Id> Product2IdPriceBookEntryId;

    public RG_WorkOrderLineItemCls(ApexPages.StandardController stdController){
        workOrderLineItemList=new List<WorkOrderLineItem>();
        renderEdit=false;
        WrapperList=new List<Wrapper>();
        WordOrderId=stdController.getId();
        
        productWrapperList=new List<productWrapper>();
        productList();
        productName=Null;
        
        Integer IndexNumber=1;
        for(WorkOrderLineItem w: [Select Id, LineItemNumber, Expiration_Date__c,Discount,AdvertisingExpense__c,BoothFee__c, PricebookEntry.Name, PricebookEntryId, Product_Description__c, Quantity, Product2Id  
                                FROM WorkOrderLineItem 
                                WHERE WorkOrderId=:stdController.getId() Order By CreatedDate]){
        
            WrapperList.add(new Wrapper(IndexNumber ,w ,False));
            IndexNumber++;
        }
        
        
       
    }
    
    public List<productWrapper> productList(){
        String productquery;
        
        System.debug('productName===>'+productName);
        if(String.isNotBlank(productName))
        productquery='SELECT Id, Name, Description FROM Product2 WHERE Name Like \''+productName+'%\'';
        else
        productquery='SELECT Id, Name, Description FROM Product2';
        
        system.debug('productquery==>'+productquery);
        for(Product2  product : Database.query(productquery)){
            productWrapperList.add(new productWrapper(false,product,'1'));
        }
        
        return productWrapperList;
    }
    
    public PageReference prodListActionFunction(){
        System.debug('productNameactionfinctionmethod===>'+productName);
        productWrapperList.clear();
        productList();
        return null;
        
    }
    
    public PageReference EditOrderLineItem(){
        WrapperList.clear();
        Integer IndexNumber=1;
        for(WorkOrderLineItem w: [Select Id, LineItemNumber,Discount,AdvertisingExpense__c,BoothFee__c,  Expiration_Date__c, PricebookEntry.Name, PricebookEntryId, Product_Description__c, Quantity, Product2Id  
                                    FROM WorkOrderLineItem 
                                    WHERE WorkOrderId=:WordOrderId Order By CreatedDate]){
                
                WrapperList.add(new Wrapper(IndexNumber ,w ,False));
                IndexNumber++;
        }
        List<Wrapper> WrapperEditList=new List<Wrapper>();
        for(Wrapper w:WrapperList){
            if(w.WorkLItem.Id==EditOrderId)
                WrapperEditList.add(new Wrapper(w.IndexNo, w.WorkLItem, True));
            else
                WrapperEditList.add(new Wrapper(w.IndexNo, w.WorkLItem, False));
            
        }
        WrapperList.clear();
        WrapperList.addall(WrapperEditList);
        return null;
    }
    
    //Delete Link
    public PageReference deleteOrderLineItem(){
        if(EditOrderId!=Null){
            WorkOrderLineItem wOrderLineItem=new WorkOrderLineItem(Id=EditOrderId);
            
            try{
                delete wOrderLineItem;
                WrapperList.Remove(IndexNum-1);
            }Catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
            }
        }
        return null;
    }
    
    public PageReference AddOrderLineItem(){
      productWrapperList=new List<productWrapper>();
     productList();
     
        popupRendered=true;      
        
        return null;
       /*
        WorkOrderLineItem newWorkLItem=New WorkOrderLineItem(WorkOrderId=ApexPages.currentPage().getParameters().get('id') );
        Try{
            //Insert newWorkLItem;
            WrapperList.add(new Wrapper(WrapperList.Size()+1, newWorkLItem,True));
        }Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }
        
        */
       // return null;
    }
    
    //cancel button
    public PageReference cancelbtn(){
       
        productName=Null;
        popupRendered=false;
        return null;
        
     //  PageReference pageRef = new PageReference('/apex/RedirectPage').redirect(true);
        //    return  new PageReference('/apex/RedirectPage').setRedirect(true);
         
    }
    
        //save btn 
    public PageReference savebtn(){
        productName='';
          Set<Id> prodIdList=new Set<Id>();
        FOR(productWrapper w: productWrapperList)
            prodIdList.add(w.Product.Id);
        
          Product2IdPriceBookEntryId=new Map<Id, Id>();
        for(PricebookEntry priceBEntry:[SELECT id, Product2Id FROM PricebookEntry WHERE Product2Id In:prodIdList and Pricebook2.Name='Standard Price Book'])
        Product2IdPriceBookEntryId.put(priceBEntry.Product2Id, priceBEntry.Id);
        
        
        List<WorkOrderLineItem> WorkOrderLineItemInsert=new List<WorkOrderLineItem>();
        //UpdateWorkOrderLineItem.add(new WorkOrderLineItem( WorkOrderId=ApexPages.currentPage().getParameters().get('id'), PricebookEntryId=Product2IdPriceBookEntryId.get(w.WorkLItem.Product2Id), Quantity=w.WorkLItem.Quantity));
        if(!productWrapperList.isEmpty()){
            for(productWrapper prodWrapper: productWrapperList){
                if(prodWrapper.selectproduct)
                WorkOrderLineItemInsert.add(new WorkOrderLineItem( WorkOrderId=ApexPages.currentPage().getParameters().get('id'), PricebookEntryId=Product2IdPriceBookEntryId.get(prodWrapper.Product.Id), Quantity=integer.valueof(prodWrapper.Quantity)));
            }
            
            
        }
        
        if(!WorkOrderLineItemInsert.isEmpty()){
            try{
                System.debug('WorkOrderLineItemInsert===>'+WorkOrderLineItemInsert);
                Insert WorkOrderLineItemInsert;
            }Catch(Exception e){
                System.debug('######## WorkOrderLineItemInsert Insert #######'+e);
            }
        }   
          WrapperList.clear();
                    Integer IndexNumber=1;
                    for(WorkOrderLineItem w: [Select Id, Discount,AdvertisingExpense__c,BoothFee__c, LineItemNumber, Expiration_Date__c, PricebookEntry.Name, PricebookEntryId, Product_Description__c, Quantity, Product2Id  
                                        FROM WorkOrderLineItem 
                                        WHERE WorkOrderId=:WordOrderId Order By CreatedDate]){
                
                    WrapperList.add(new Wrapper(IndexNumber ,w ,False));
                    IndexNumber++;
            
            
        }
        popupRendered=false;
      return null;
    }
    
    
    public PageReference updateLineItem(){
          Set<Id> prodIdList=new Set<Id>();
        FOR(Wrapper w:WrapperList)
            prodIdList.add(w.WorkLItem.Product2Id);
        
          Product2IdPriceBookEntryId=new Map<Id, Id>();
        for(PricebookEntry priceBEntry:[SELECT id, Product2Id FROM PricebookEntry WHERE Product2Id In:prodIdList and Pricebook2.Name='Standard Price Book'])
        Product2IdPriceBookEntryId.put(priceBEntry.Product2Id, priceBEntry.Id);
        
        List<WorkOrderLineItem> UpdateWorkOrderLineItem=new List<WorkOrderLineItem>();
        boolean errorMsg=false;
        for(Wrapper w:WrapperList){
            if(w.WorkLItem.Product2Id==Null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Product can\'t be blank'));
                errorMsg=true;
            }else if(w.WorkLItem.Quantity<1){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Quantity can\'t be zero'));
                errorMsg=true;
            }
            else if(w.WorkLItem.Id != Null)
                UpdateWorkOrderLineItem.add(new WorkOrderLineItem(Id=w.WorkLItem.Id, WorkOrderId=ApexPages.currentPage().getParameters().get('id'), PricebookEntryId=Product2IdPriceBookEntryId.get(w.WorkLItem.Product2Id), Quantity=w.WorkLItem.Quantity,Expiration_Date__c=w.WorkLItem.Expiration_Date__c,Discount=w.WorkLItem.Discount,AdvertisingExpense__c=w.WorkLItem.AdvertisingExpense__c,BoothFee__c=w.WorkLItem.BoothFee__c));
            else 
                UpdateWorkOrderLineItem.add(new WorkOrderLineItem( WorkOrderId=ApexPages.currentPage().getParameters().get('id'), PricebookEntryId=Product2IdPriceBookEntryId.get(w.WorkLItem.Product2Id), Quantity=w.WorkLItem.Quantity, Expiration_Date__c=w.WorkLItem.Expiration_Date__c,Discount=w.WorkLItem.Discount, AdvertisingExpense__c=w.WorkLItem.AdvertisingExpense__c,BoothFee__c=w.WorkLItem.BoothFee__c));
        }
        Try{
             if(!errorMsg){
                    upsert UpdateWorkOrderLineItem;
                    WrapperList.clear();
                    Integer IndexNumber=1;
                    for(WorkOrderLineItem w: [Select Id, Discount,AdvertisingExpense__c,BoothFee__c,LineItemNumber, Expiration_Date__c, PricebookEntry.Name, PricebookEntryId, Product_Description__c, Quantity, Product2Id  
                                        FROM WorkOrderLineItem 
                                        WHERE WorkOrderId=:WordOrderId Order By CreatedDate]){
                
                    WrapperList.add(new Wrapper(IndexNumber ,w ,False));
                    IndexNumber++;
                    }
             }
        }Catch(Exception e){
            
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }
        return null;
    }
    
    public class Wrapper{
        public Integer IndexNo{get;set;}
        public WorkOrderLineItem WorkLItem{get;set;}
        public boolean EditBoolean{get;set;}
        
        public Wrapper(Integer IndexNo, WorkOrderLineItem WorkLItem, boolean EditBoolean){
            this.IndexNo = IndexNo;
            this.WorkLItem = WorkLItem;
            this.EditBoolean = EditBoolean;
        }
    }
    
    public class productWrapper{
        public boolean selectproduct{get;set;}
        public Product2 product{get;set;}
        public string quantity{get;set;}
        
        public productWrapper(boolean selectproduct, Product2 product, string quantity){
            this.selectproduct=selectproduct;
            this.product=product;
            this.quantity=quantity;
        }
        
    }
    
}