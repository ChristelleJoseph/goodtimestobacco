public with sharing class GT_WholesaleOrderForm {
    public class orderException extends Exception {}
    public Boolean ordersAllowed {get;set;}
    private final Order ordStandard;
    public List<OrderDTO> OrderDTOs {get; set;}
    public List<Order> orders {get; set;}
    public Account currentAccount {get;set;}
    public Order currentOrder {get;set;}
    public String countParamMonth {get; set;}
    public String lastOrder {get; set;}
    public String deleteItemId {get; set;}
    public Id pageId {get;set;}
    public Environment_Variable__mdt ordersOwner {get;set;}
    public List<OrderItem> olisDelete {get;set;}

    public String soql {get;set;}

    public List<wProduct> prodList {get;set;}

    public Set<wProduct> checklistObjects {get;set;}

    public String selectedList{get;set;}

    public GT_WholesaleOrderForm(){
        ordersAllowed = true;
        olisDelete = new List<OrderItem>();
        currentAccount = new Account();
        currentOrder = new Order();
        
        pageId = ApexPages.currentPage().getParameters().get('id');

        String objectStr = 'Account';
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectStr);
        
        if(pageId != null){
  
            if(pageId.getSobjectType() == objType){
                currentAccount = [SELECT Id, Name, RecordType.Name, AccountNumber, Email__c, Phone, Account__c, (SELECT Id, Name FROM Orders),
                                  		 Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode, Account.ShippingCountry FROM Account WHERE Id=:pageId];
                
                if(currentAccount.Account__c.substring(0,2)=='GT'){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'This account in not approved for orders. Please work with you sales manager to have the account loaded into Great Plains.')); 
                    ordersAllowed = false;
                }else{
                    ordersAllowed = true;
                    Map<Id, Order> orderMap = new  Map<Id, Order>();
                }

         
            }else{
                currentOrder = [SELECT Id, OwnerId, Owner.Name, Owner.Email, Owner.Phone, OrderNumber, Name, Type, Status, Total_Displays__c, TotalAmount, Submitted_Date__c, AccountId, 
                                	   Additional_Notes__c, Tracking_Number__c, Pallets__c, EffectiveDate, PoNumber FROM Order WHERE Id=:pageId];
                currentAccount = [SELECT Id, Name, RecordType.Name, AccountNumber, Email__c, Phone, Account__c, Account.ShippingStreet, Account.ShippingCity,
                                         Account.ShippingState, Account.ShippingPostalCode, Account.ShippingCountry FROM Account WHERE Id =: currentOrder.AccountId];

                if(currentAccount.Account__c.substring(0,2)=='GT'){
                    ordersAllowed = false;
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'This account in not approved for orders. Please work with you sales manager to have the account loaded into Great Plains.')); 
                }else{    
                    ordersAllowed = true;       
                    //debug
                    //System.debug('Retreived account: ' + currentAccount.Name);
                    refreshOrderDTOs();
                }
    
            }
        }else{

        }

        ordersOwner = [SELECT Email__c,OwnerName__c FROM Environment_Variable__mdt WHERE label='OrdersOwner'][0];

        soql = 'SELECT Name, Item_Num__c, Description, Family, ProductCode FROM Product2 WHERE (Item_Status__c = \'1\' OR Item_Status__c = \'2\')  ';
        runQuery();

    }

    public void onPageLoad(){
        if(!olisDelete.isEmpty())
            delete olisDelete;
    }

    public void refreshOrderDTOs () {
        OrderDTOs = new List<OrderDTO>();
        OrderDTOs = getOrderDTOs();
    }

    public void saveOrder(){
        List<OrderItem> rliForUpdate = new List<OrderItem>();
        //MTC NOT NEEDED
        //Decimal pouchesCount = 0;
        Decimal displaysCount = 0;
		
        for (OrderDTO item : OrderDTOs) {   
            for (OrderItem rli : item.ordLI.values()) {
                if(rli.Quantity == null) {
                    rli.Quantity = 0;
                }
                
                if(rli.Quantity_Type__c == 'Display') {
                    displaysCount += rli.Quantity;
                }
                
                rliForUpdate.add(rli);
            }

        }
        try{
            currentOrder.Total_Displays__c = displaysCount;
            update currentOrder;
            upsert rliForUpdate;
            currentOrder = [SELECT Id, OwnerId, Owner.Name, Owner.Email, Owner.Phone, OrderNumber, Name, Type, Status, Total_Displays__c, TotalAmount, Submitted_Date__c, AccountId, 
                            Account.Name, Account.Phone, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode,
                            Account.ShippingCountry, Additional_Notes__c, Tracking_Number__c, Pallets__c, EffectiveDate, PoNumber FROM Order WHERE Id=:currentOrder.Id];
        } catch (DmlException  ex) {
            System.debug('Error ::: ' + ex.getMessage());
            System.debug('Error ::: ' + ex.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
		}
        refreshOrderDTOs();
    }

    public void addLineItem(){
        List<String> itemsToAdd = selectedList.split(',');

        if(itemsToAdd.size()>=2){
            for(Integer i=0; i<itemsToAdd.size()-1;i+=2){
                //select the wProducts from the prod list
                updateCheckListObj(itemsToAdd[i], itemsToAdd[i+1]);
            }
        }
        
        //verify that a new order has been created or that one is being edited
        if(currentOrder.id != null){
            PriceBook2 priceBook = [SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].get(0);
            currentOrder.Pricebook2Id = priceBook.Id;
            List<Id> listProductIds = new List<Id>();
            Map<Id, PricebookEntry> mapPriceBookEntries = new Map<Id, PricebookEntry>();
            
            for(wProduct checkObj : checklistObjects) {
                listProductIds.add(checkObj.wrappedProd.Id);
            }
            
            for(PriceBookEntry pbEntry : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id =: priceBook.Id AND Product2Id IN : listProductIds]) {
                mapPriceBookEntries.put(pbEntry.Product2Id, pbEntry);
            }
            
            for(wProduct checkObj:checklistObjects){
                OrderDTO newOrderDTO;
                
                if(mapPriceBookEntries.containsKey(checkObj.wrappedProd.Id)) {
                    newOrderDTO = new OrderDTO(new OrderItem(Quantity = 0, OrderId = currentOrder.Id, PricebookEntryId = mapPriceBookEntries.get(checkObj.wrappedProd.Id).Id, Product2Id = checkObj.wrappedProd.Id, Quantity_Type__c = 'Display', UnitPrice = mapPriceBookEntries.get(checkObj.wrappedProd.Id).UnitPrice), currentOrder);
                }
                else {
                    newOrderDTO = new OrderDTO(new OrderItem(Quantity = 0, OrderId = currentOrder.Id, Product2Id = checkObj.wrappedProd.Id, Quantity_Type__c = 'Display'), currentOrder);
                }
                
                newOrderDTO.isNew = true;
                newOrderDTO.productNumber = checkObj.wrappedProd.Item_Num__c;
                newOrderDTO.productName = checkObj.wrappedProd.Name;

                OrderDTOs.add(newOrderDTO);
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Create a new order to begin adding line items.'));
        }

        //clear out the check boxes
        clearSelections();    
    }

    public void updateCheckListObj(String prodId, String selectedState ){
        //construct the list if it has not already been
        if(checklistObjects==null || checklistObjects.isEmpty()) {
            checklistObjects = new Set<wProduct>();
        }

        if(prodList.isEmpty()){
        }else{
        }

        //loop through each prod in the list to select the prod the user selected
        for(wProduct prod : prodList){
            //if the match is not already selected 
            if( prodId == String.valueOf(prod.wrappedProd.Id) && selectedState == 'true'){

                //add the checked match to the request set for processing (use set instead of list to remove duplicates when users check and uncheck the same match)
                checklistObjects.add(prod);
                prod.selected = true;

                //debug
                //System.debug(' Added: ' + prod.wrappedProd.Name + '  ' + ' prod.selected: ' + prod.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');

            //if the match is already selected
            }else if(prodId == String.valueOf(prod.wrappedProd.Id) && selectedState == 'false'){

                //remove the checked match from the set 
                checklistObjects.remove(prod);

                //debug
                //System.debug(' Removed: ' + prod.wrappedProd.Name + '  ' + ' prod.selected: ' + prod.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');
            }
        }
    }

    public PageReference newOrder() {
        User usr = [SELECT Id, Analyst__c, Supervisor__c, Supervisor_2__c, Supervisor_3__c, Supervisor_4__c FROM User WHERE Id = :Userinfo.getUserId()];
        PriceBook2 priceBook = [SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].get(0);

        Order ord = new Order(AccountId=currentAccount.Id, Status='Draft', Initiated_Date__c = Date.today(), EffectiveDate = Date.today(), Pricebook2Id = priceBook.Id, Total_Displays__c = 0.0, Type = currentAccount.RecordType.Name, PoNumber = '');

        try {
            insert ord;
        
        } catch (DmlException  ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
            return null;
        }

        currentOrder = ord;

        PageReference redirectedPage = new PageReference(Page.GT_WholesaleOrderForm.getUrl());
        redirectedPage.setRedirect(true);
        redirectedPage.getParameters().put('id', currentOrder.Id);

        return redirectedPage;
    }

    public PageReference submitOrder() {
        for(OrderDTO orderObj : OrderDTOs) {
            for(OrderItem orderItemObj : orderObj.ordLI.values()) {
                if(orderItemObj.Quantity == NULL || orderItemObj.Quantity == 0) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Cannot save return with 0 quantity on return item. Please add a quanitity or delete the return item.'));
                    return null;
                }
            }
        }
        
        Order ord = currentOrder;
        ord.Status = 'Activated';
        ord.EffectiveDate = Date.today();
        ord.Initiated_Date__c = Date.today();
        autosendOrder(ord);

        try {
            update ord;

            //debug
            //System.debug('Order succeeded: ' + ord.Id + '  ' + ord.Stage__c);
        
        } catch (DmlException  ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
            System.debug('Error ::: ' + ex.getStackTraceString());
            return null;
        }

        PageReference redirectedPage = new PageReference(Page.GT_WholesaleOrderForm.getUrl());
        redirectedPage.setRedirect(true);
        redirectedPage.getParameters().put('id', currentOrder.Id);

        return redirectedPage;
    }


    private List<OrderDTO> getOrderDTOs() {
		
        Order ord = [
            SELECT Id, Name, EffectiveDate, AccountId, Additional_Notes__c, Pallets__c,  Tracking_Number__c, Status, Total_Displays__c, PoNumber
            FROM Order
            WHERE AccountId = :currentAccount.Id AND Id=:currentOrder.Id
        ];

        //debug
        //System.debug('ord: ' + ord.Id + '  visit date: ' + ord.Submitted_Date__c);

        List<OrderItem> rlis = [
            SELECT Id, ServiceDate, Product2.Item_Desc__c, TotalPrice, UnitPrice, Quantity,
                Product2.Product_Brand__c, Product2.Item_Num__c, Order.EffectiveDate, Product2.Name, Product2.is_Loose_Product__c, CreatedDate, 
                Displays__c, Quantity_Type__c 
            FROM OrderItem
            WHERE OrderId =:currentOrder.Id
            ORDER BY Product2.Item_Desc__c ASC NULLS LAST, ServiceDate ASC NULLS LAST
        ];
        //debug
        //System.debug('Query rlis ::: ' + JSON.serialize(rlis));
      
        Map<String, OrderDTO> mapOrders = new  Map<String, OrderDTO>();

        if(rlis != null){
            for (OrderItem item : rlis) {
                if (mapOrders.containsKey(item.Product2.Item_Num__c) ) {
                    if (mapOrders.get(item.Product2.Item_Num__c).ordLI.get(item.OrderId).Id == null) {
                        mapOrders.get(item.Product2.Item_Num__c).ordLI.put(item.OrderId, item);
                    } else {
                        mapOrders.put(item.Product2.Item_Num__c + item.Id, new OrderDTO(item, currentOrder));
                    }

                } else {
                    mapOrders.put(item.Product2.Item_Num__c, new OrderDTO(item, currentOrder));
                }
            }
        }
        if(currentOrder != null){
            orders = new List<Order>();
            orders.add(currentOrder);
        }
            
        return mapOrders.values();
    }

    public class OrderDTO {
        public Boolean isNew {get; set;}
        public String brand {get; set;}
        public String productNumber {get; set;}
        public String productDescription {get; set;}
        public String productName {get; set;}
        public Map<Id, OrderItem> ordLI {get; set;}

        public OrderDTO (OrderItem rli, Order ord) {
            this.isNew = false;
            this.brand = rli.Product2.Product_Brand__c;
            this.productNumber = rli.Product2.Item_Num__c;
            this.productDescription = rli.Product2.Name;
            this.ordLI = new Map<Id, OrderItem>();

            this.ordLI.put(ord.Id, new OrderItem(Product2Id = null));
            this.ordLI.put(rli.OrderId, rli);
        }
    }


    public void createDeletionRequest() {
        if (!String.isBlank(deleteItemId)) {
            OrderItem deleteOrderLineItem = [SELECT Id FROM OrderItem WHERE Id = : deleteItemId];
            delete deleteOrderLineItem;
        }

        refreshOrderDTOs();
        saveOrder();
        deleteItemId = '';

    }
    
    //The current sort direction - defaults to asc
    public String sortDir {
        get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
        set;
    }

    // Variable that dictates the current field to sort the results by. defaults to Name if no sort order is selected
    public String sortField {
        get  { if (sortField == null) {sortField = 'Name'; } return sortField;  }
        set;
    }



    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';

        // run the query
        runQuery();
    }

    // build the final soql string and run the query 
    public void runQuery() {

        try {
            //query salesforce for prod matching the defined criteria
            //prodList = Database.query(soql + ' order by ' + sortField + ' ' + sortDir + ' limit 250');

            //reset the list of prod 
            prodList = new List<wProduct>();

            //reset the list of prod match requests to prevent users from creating multiple match requests after running an additional search
            checklistObjects = new Set<wProduct>();

            //for each product ordered by the search 
            for(Product2 prod1 :  Database.query(soql + ' order by ' + sortField + ' ' + sortDir + ' limit 100')) {
                // As each prod is processed we create a new wProduct object and add it to the prodList
                prodList.add(new wProduct(prod1));
            }

        } catch (Exception e) {
            //display an error message at the top of the page
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'runquery Error ' + e.getCause() + ' ' + e.getMessage()));
        }

    }

    // adds the search parameters passed via Javascript
    public PageReference runSearch() {

        //parameter variables that a user can search by
        String searchVal = Apexpages.currentPage().getParameters().get('searchVal');

        if(searchVal!=null){
            //remove special characters 
            searchVal = searchVal.replaceAll('[^a-zA-Z0-9\\s+/]', '');
            
            //allow for multiple words in the search input
            List<String> listSearchVal = searchVal.split(' ');
			PriceBook2 priceBook = [SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1].get(0);

            Boolean first = true;
            soql = 'SELECT Name, Item_Num__c, Description, Family, ProductCode, Item_Status__c FROM Product2';
            for(String str1 : listSearchVal){
                if(str1 != '' && str1.length()>1){
                    if(first){
                        soql = soql + ' WHERE Id IN (SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = \''+ priceBook.Id +'\') AND (Item_Status__c = \'1\' OR Item_Status__c = \'2\') AND (';
                    } else {
                        soql = soql + ' AND';
                    }
                    soql = soql + ' (Product2.Name LIKE \'%'+String.escapeSingleQuotes(str1)+'%\' OR Product2.Item_Num__c LIKE \'%'+String.escapeSingleQuotes(str1)+'%\')';
                    first = false;
                } 
            }
            soql = soql + ')';

            //ensures that the soql was built
            if(!first){
                //debug
                //System.debug('SOQL String: ' + soql);

                // run the soql 
                runQuery();
            }


            
        }

        return null;
    }



    public void clearSelections(){ 

        if(prodList==null || prodList.isEmpty()) {
            prodList = new List<wProduct>();
            //debug
            //System.debug('clearSelections - prodList instantiated');
        }


        for(wProduct prod : prodList){
            prod.selected = false;

            //debug
            //System.debug('clearSelections - product removed from prod list: ' + prod.wrappedProd.Name + ' prod.selected: ' + prod.selected + ' ');
        }

        checklistObjects = new Set<wProduct>();

        //debug
        //System.debug('clearSelections - checklistObjects instantiated');
    }


    //wrapper class to allow control of check box selected list items 
    public class wProduct {
        //holds the prod record
        public Product2 wrappedProd {get; set;}

        //holds the selected state of the checkbox in a given list
        public Boolean selected {get; set;}

        public wProduct(Product2 prod) {
            wrappedProd = prod;
            selected = false;
        }
    }

    // Method to Send Mail to Order Form(Order)
    public pagereference autosendOrder(Order ord1) {

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        //debug
        //System.debug('recordId: ' + recordid);
        
        ord1 = [Select id, SendEmail__c, AccountId, PoNumber, CreatedById, status, Custom_notes_for_this_order__c from Order where id =: ord1.Id limit 1];
            
        if(ord1.Status != 'Activated'){

            Account acc1 = [Select id, Name from Account where id =: ord1.AccountId limit 1];
            
            //debug
            //System.debug('Order CreatedById: ' + ord1.CreatedById);

            User ordCreator = [SELECT Id, Email_Notification_Repository__c, National_Sales_Manager__c, Regional_Sales_Manager__c, Name, Email FROM User WHERE Id = : ord1.CreatedById];
            

            String [] toEmailUsers = new List<String>();
            String [] ccEmailUsers = new List<String>();


            if (ordCreator.Email != null) {
                ccEmailUsers.add(ordCreator.Email);
            }
            
            if (ordCreator.Email_Notification_Repository__c != null) {
                ccEmailUsers.add(ordCreator.Email_Notification_Repository__c);
            }
            
            if (ordCreator.National_Sales_Manager__c!= null) {
                User user1 = [SELECT Email FROM User WHERE Id = :ordCreator.National_Sales_Manager__c];
                ccEmailUsers.add(''+user1.Email);
            }
            
            if (ordCreator.Regional_Sales_Manager__c!= null) {
                User user1 = [SELECT Email FROM User WHERE Id = :ordCreator.Regional_Sales_Manager__c];
                ccEmailUsers.add(''+user1.Email);
            }
                
            if(ord1.Custom_notes_for_this_order__c == null){
                ord1.Custom_notes_for_this_order__c = '';
            }
            
            //toEmailUsers.add('Joseph@goodtimestobacco.com');
            toEmailUsers.add('mark_crawford@live.com');
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            Id templateId;  
            String templateApiName = 'Order_Form_Email_Template';
            try {templateId = [select id, name from EmailTemplate where developername = : templateApiName].id;}
            catch (Exception e) {
            System.debug('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + 
                            ' refer to Setup | Communications Templates ' + templateApiName);
            }

            mail.setToAddresses(toEmailUsers);
            mail.setCcAddresses(ccEmailUsers);
            mail.setTargetObjectId(ordCreator.Id);
            mail.setWhatId(ord1.Id);
            mail.setTemplateId(templateId);
            mail.setSaveAsActivity(false);
    
            emailMessages.add(mail);

            //debug
            //System.debug('mail'+mail.getSubject());
            
            //send email to those fields        
            Messaging.sendEmail(emailMessages);
            
            //flag for process to send out email
            ord1.SendEmail__c = TRUE;

            //change status to lock order
            ord1.Status = 'Activated';
            Update ord1;

            //debug
            //System.debug(LoggingLevel.INFO,'** entered sendTemplatedEmail, to:' + toUsers + ' cc:' + ccUsers +  ' templateId:' + templateId + ' tagetObjId:' + ord1.Id);
        
        }else{
            //do nothing
        }


        //ord1 = new Order();
        return new pagereference('/' + ord1.Id).setredirect(true);
    }
}