/*
Create By: RG_TEAM
CreatedDate : 21 July 2017
vf Page :RG_InventoryLineItemPage
*/
public class RG_InventoryLineItemCls {
Public List<Wrapper> wrapperList{get;set;}
public Id EditInventoryId{get;set;}
public Integer IndexNum{get;set;}
public Id InventorytId{get;set;}
public string productName{get;set;}
public String productCode{get;set;}
public String productCategory{get;set;}
public Boolean hasPermission {get;set;}

public Boolean errorProductFlag{get; set;}


public Boolean popupRendered{get;set;}
public List<productWrapper> productWrapperList{get;set;}

private Inventory__c inventory;

public Map<id, PricebookEntry> Product2IdPriceBookEntryMap{get;set;}
    //Constructor
    public RG_InventoryLineItemCls(ApexPages.StandardController stdController){
        wrapperList=new List<Wrapper>();
        InventorytId=stdController.getId();
        
        List<Inventory__c> inventories = [SELECT Id, Account__c FROM Inventory__c WHERE Id = : InventorytId];
        inventory = new Inventory__c ();
        if (inventories.size() > 0) {
            inventory = inventories[0];
        }
        //Inventory Line Item
        Integer IndexNumber=1;
        
        productWrapperList=new List<productWrapper>();
        productList();
        
        errorProductFlag=false;
        
        Product2IdPriceBookEntryMap=new Map<id, PricebookEntry>();
        for(PricebookEntry pricebookentryy:[SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2.Name='Standard Price Book'])
        {
            if(pricebookentryy.Product2id!=Null)
            Product2IdPriceBookEntryMap.put(pricebookentryy.Product2id, pricebookentryy);
        }
        
        for(Inventory_Line_Item__c iLineItem:[SELECT Id, Name, Account__c,PreviousQuantity__c, ProductDateCode__c, WholeSale__c, ResalePrice__c, WholeSaleMargin__c, Inventory__c, Inventory__r.Visit_Date__c   , Product__c, Product__r.Name, Product_description__c, Quantity__c 
                                                FROM Inventory_Line_Item__c 
                                                WHERE Inventory__c=:stdController.getId() Order By Lastmodifieddate DESC]){
              
              wrapperList.add(new Wrapper(IndexNumber,iLineItem, False));    
              IndexNumber++;
        }

        hasPermission = false;

        List<PermissionSetAssignment> lstcurrentUserPerSet =    [   SELECT Id, PermissionSet.Name,AssigneeId
                                                                FROM PermissionSetAssignment
                                                                WHERE AssigneeId = :Userinfo.getUserId() ];
        //system.debug('##lstcurrentUserPerSet: ' + lstcurrentUserPerSet);

        for (PermissionSetAssignment psa: lstcurrentUserPerSet)
        {
            //system.debug('##psa.PermissionSet.Name: ' + psa.PermissionSet.Name);
            if(psa.PermissionSet.Name.equals('Inventory_History_Admin'))
                hasPermission = true;
        }

        
    }
    
    public List<productWrapper> productList(){
        errorProductFlag=false;
        
        String productquery;
        
        productquery='SELECT Id, Name, Description, ProductCode,' +
            ' (SELECT Id, Name, PriceBook2.isStandard from priceBookEntries),'+
            ' Family FROM Product2 WHERE IsActive = true AND Item_Status__c IN (\'1\',\'2\')';
        
      
        if(String.isNotBlank(productCode) && String.isNotBlank(productName) && String.isNotBlank(productCategory))
        productquery+=' AND Name Like \''+productName+'%\' AND ProductCode Like \''+productCode+'%\' AND Family Like \''+productCategory+'%\''; 
        ELSE if(String.isNotBlank(productCode) && String.isNotBlank(productName))
        productquery+=' AND Name Like \''+productName+'%\' AND ProductCode Like \''+productCode+'%\'';
        ELSE IF(String.isNotBlank(productCode) && String.isNotBlank(productCategory) )
        productquery+=' AND ProductCode Like \''+productCode+'%\' AND Family Like \''+productCategory+'%\'';
        ELSE IF(String.isNotBlank(productName) && String.isNotBlank(productCategory) )
        productquery+=' AND Name Like \''+productCode+'%\' AND Family Like \''+productCategory+'%\'';
        ELSE if(String.isNotBlank(productName))
        productquery+=' AND Name Like \''+productName+'%\'';
        ELSE if(String.isNotBlank(productCode))
        productquery+=' AND ProductCode Like \''+productCode+'%\'';
         else if(String.isNotBlank(productCategory))
        productquery+=' AND Family Like \''+productCategory+'%\''; 

        for(Product2  product : Database.query(productquery)){
          for ( PriceBookEntry pbe : product.priceBookEntries ) {
                if ( pbe.PriceBook2.isStandard) 
                    productWrapperList.add(new productWrapper(false,product,'1'));
            }
        }
        
        System.debug('productWrapperList==>' + productWrapperList);
        
        return productWrapperList;
    }
    
    public PageReference prodListActionFunction(){
        System.debug('productNameactionfinctionmethod===>'+productName);
        productWrapperList.clear();
        productList();
        return null;
        
    }

    // Edit record  
    public PageReference EditInventoryLineItem(){
        wrapperList.clear();
        Integer IndexNumber=1;
            for(Inventory_Line_Item__c iLineItem:[SELECT Id, Name, Account__c,PreviousQuantity__c,ProductDateCode__c, WholeSale__c, ResalePrice__c, WholeSaleMargin__c, Inventory__c, Inventory__r.Visit_Date__c,Product__c, Product__r.Name, Product_description__c, Quantity__c 
                                                FROM Inventory_Line_Item__c 
                                                WHERE Inventory__c=:InventorytId Order By CreatedDate]){
              
              wrapperList.add(new Wrapper(IndexNumber,iLineItem, False));    
              IndexNumber++;
                }
                
        List<Wrapper> WrapperEditList=new List<Wrapper>();
        for(Wrapper w:wrapperList){
            if(w.inventoryLineItem.Id==EditInventoryId)
                WrapperEditList.add(new Wrapper(w.IndexNo ,w.inventoryLineItem , True));
            else
                WrapperEditList.add(new Wrapper(w.IndexNo ,w.inventoryLineItem , False));
            
        }
        WrapperList.clear();
        WrapperList.addall(WrapperEditList);
        return null;
    }
    
    //Add
    public PageReference AddInventoryLineItem(){ 
        
       productName=Null;
       productCode=Null;   
       productCategory=Null;
        popupRendered=true;
        errorProductFlag=false;
        
        prodListActionFunction();
        return null;
        
    }
    //cancel button
    public PageReference cancelbtn(){
        productName=Null;
        popupRendered=false;
        return null;
    }
    
    
     
    //save btn 
    
    public Boolean flagDisable {get;set;}
     
    public PageReference savebtn(){
      
        string errorMsg='';
        errorProductFlag=false;
        
         List<Inventory_Line_Item__c> inventoryLineItemInsert=new List<Inventory_Line_Item__c>();
        if(!productWrapperList.isEmpty()){
            for(productWrapper prodWrapper: productWrapperList){
                system.debug('prodWrapper-quantity===>'+prodWrapper.quantity);
                if(prodWrapper.selectproduct && !errorProductFlag){
                inventoryLineItemInsert.add(new Inventory_Line_Item__c( Inventory__c=InventorytId, Product__c=prodWrapper.product.Id, Quantity__c=Integer.valueof(prodWrapper.quantity), WholeSale__c=Product2IdPriceBookEntryMap.get(prodWrapper.product.Id).UnitPrice,ResalePrice__c=0, Account__c = inventory.Account__c));
              
                }
            }
             popupRendered=false;
            
        }
        
        if(!inventoryLineItemInsert.isEmpty()){
            try{
                System.debug('inventoryLineItemInsert===>'+inventoryLineItemInsert);
                
                if(!errorProductFlag){Insert inventoryLineItemInsert;
                                      popupRendered=false;        
}
                
                
            }Catch(Exception e){
                System.debug('######## Inventory Line Item Insert #######'+e);
            }
            
            if(!errorProductFlag){
                wrapperList.clear();
                Integer IndexNumber=1;
                for(Inventory_Line_Item__c iLineItem:[SELECT Id, Name, Account__c,PreviousQuantity__c ,ProductDateCode__c, WholeSale__c, ResalePrice__c, WholeSaleMargin__c, Inventory__c, Inventory__r.Visit_Date__c, Product__c, Product__r.Name, Product_description__c, Quantity__c FROM Inventory_Line_Item__c 
                                                    WHERE Inventory__c=:InventorytId Order By CreatedDate]){                  
                  wrapperList.add(new Wrapper(IndexNumber,iLineItem, False));IndexNumber++;                 
                    }
             
            }
           
        }
        return null;
    }
    
    //Delete Link On User Based
    public String userProfileName {
        get {
            return [select Profile.Name from User where Id = :Userinfo.getUserId()].Profile.Name;
        }
    }
        
    //Delete Link
    public PageReference deleteInventoryLineItem(){


        if(EditInventoryId!=null){
            Inventory_Line_Item__c iLineItem=new Inventory_Line_Item__c(Id=EditInventoryId);
            try{
                Delete iLineItem;
                WrapperList.remove(IndexNum-1);
            }Catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
        
        return null;
    }
    
    
    // Update 
    public PageReference updateLineItem(){
        List<Inventory_Line_Item__c> UpdateInventoryLineItem=new List<Inventory_Line_Item__c>();
        boolean errorMsg=false;
        for(Wrapper w:WrapperList){
            if(w.inventoryLineItem.Product__c==NULL){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Product can\'t be blank'));
                errorMsg=true;
            }  else if(w.inventoryLineItem.Id!=Null)
                UpdateInventoryLineItem.add(new Inventory_Line_Item__c(Id=w.inventoryLineItem.Id,Inventory__c=InventorytId,  Product__c=w.inventoryLineItem.Product__c, Quantity__c=w.inventoryLineItem.Quantity__c, ProductDateCode__c=w.inventoryLineItem.ProductDateCode__c ,WholeSale__c=Product2IdPriceBookEntryMap.get(w.inventoryLineItem.Product__c)!=Null?Product2IdPriceBookEntryMap.get(w.inventoryLineItem.Product__c).UnitPrice:w.inventoryLineItem.WholeSale__c,ResalePrice__c=w.inventoryLineItem.ResalePrice__c));
            else 
                UpdateInventoryLineItem.add(new Inventory_Line_Item__c( Inventory__c=InventorytId, Product__c=w.inventoryLineItem.Product__c, Quantity__c=w.inventoryLineItem.Quantity__c, ProductDateCode__c=w.inventoryLineItem.ProductDateCode__c ,WholeSale__c=Product2IdPriceBookEntryMap.get(w.inventoryLineItem.Product__c)!=Null?Product2IdPriceBookEntryMap.get(w.inventoryLineItem.Product__c).UnitPrice:w.inventoryLineItem.WholeSale__c,ResalePrice__c=w.inventoryLineItem.ResalePrice__c));
        }
        Try{
            if(!errorMsg){
            Upsert UpdateInventoryLineItem;
            
            wrapperList.clear();
            Integer IndexNumber=1;
            for(Inventory_Line_Item__c iLineItem:[SELECT Id, Name, Account__c,PreviousQuantity__c , ProductDateCode__c, WholeSale__c, ResalePrice__c, WholeSaleMargin__c, Inventory__c, Inventory__r.Visit_Date__c, Product__c, Product__r.Name, Product_description__c, Quantity__c 
                                                FROM Inventory_Line_Item__c 
                                                WHERE Inventory__c=:InventorytId Order By CreatedDate]){
              
              wrapperList.add(new Wrapper(IndexNumber,iLineItem, False));    
              IndexNumber++;
                }
            }
        }Catch(Exception e){

        }
        
        return null;
    }
    
    public class Wrapper{
    public integer IndexNo{get;set;}
    public Inventory_Line_Item__c inventoryLineItem{get;set;}
    public boolean editBoolean{get;set;}
    public boolean WholeSaleMargin{get;set;}
    
        public Wrapper(integer IndexNo,Inventory_Line_Item__c inventoryLineItem, boolean editBoolean){
            this.IndexNo = IndexNo;
            this.inventoryLineItem = inventoryLineItem;
            this.editBoolean = editBoolean;
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