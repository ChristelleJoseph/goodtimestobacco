public without sharing class GT_ReturnForm {
    public class returnException extends Exception {}
    public Boolean returnsAllowed {get;set;}

    private final Return__c retStandard;
    public List<ReturnDTO> ReturnDTOs {get; set;}
    public List<Return__c> returns {get; set;}
    public Account currentAccount {get;set;}
    public Return__c currentReturn {get;set;}
    public String countParamMonth {get; set;}
    public String lastReturn {get; set;}
    public String deleteItemId {get; set;}
    public Id pageId {get;set;}
    public Environment_Variable__mdt returnsOwner {get;set;}
    public List<Return_Line_Item__c> rlisDelete {get;set;}
    public Boolean zeroInQuantity = false;

    public Boolean quantityDisplay {get;set;}

    // Holds the string that builds a soql query. This variable holds the initial query without the order and limit
    public String soql {get;set;}

    //The list of prod to render to the visual force page
    public List<wProduct> prodList {get;set;}

    //The list of prod
    public Set<wProduct> checklistObjects {get;set;}

    public String selectedList{get;set;}

    public GT_ReturnForm(){
        quantityDisplay = true;
        returnsAllowed = true;
        rlisDelete = new List<Return_Line_Item__c>();
        currentAccount = new Account();
        currentReturn = new Return__c();
        
        pageId = ApexPages.currentPage().getParameters().get('id');

        String objectStr = 'Account';
        // Convert to schema.sObjectType
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectStr);
        if(pageId != null){
            //launched from account record - create new return
            if(pageId.getSobjectType() == objType){
            
                currentAccount = [SELECT Id, Name, AccountNumber, Email__c, Account__c, (SELECT Id, Name, Submitted_Date__c FROM Returns__r) FROM Account WHERE Id=:pageId];
                
                if(currentAccount.Account__c.substring(0,2)=='GT'){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'This account in not approved for returns. Please work with you sales manager to have the account loaded into Great Plains.')); 
                    returnsAllowed = false;
                }else{
                    returnsAllowed = true;
                    convertQuantity();

                    Map<Id, Return__c> returnMap = new  Map<Id, Return__c>();

                    //check if the current account has and returns from the past month
                    for(Return__c ret : currentAccount.Returns__r){
                        if(ret.Submitted_Date__c < Date.today().addDays(-30)){
                            //debug
                            //system.debug('Added return to map: ' + ret.Name);
                            
                            returnMap.put(ret.Id,ret);
                        }
                    }
                }

            //launched from edit button on return - edit current return
            }else{
                currentReturn = [SELECT Id, Name, Submitted_Date__c, Initiated_Date__c, Account__c, Initiator__c, Additional_Notes__c, Pallets__c,  Tracking_Number__c, Stage__c, Total_Pouches__c, Total_Displays__c FROM Return__c WHERE Id=:pageId];
                currentAccount = [SELECT Id, Name, AccountNumber, Email__c, Account__c FROM Account WHERE Id IN (SELECT Account__c FROM Return__c WHERE Id=:currentReturn.Id)];

                if(currentAccount.Account__c.substring(0,2)=='GT'){
                    returnsAllowed = false;
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'This account in not approved for returns. Please work with you sales manager to have the account loaded into Great Plains.')); 
                }else{    
                    returnsAllowed = true;       
                    //System.debug('Retreived account: ' + currentAccount.Name);
                    refreshReturnDTOs();
                }
    
            }
        }else{
            //launched from new button on returns page
            System.debug('Hit proper section');
        }

        /*Load environment variables*/
        returnsOwner = [SELECT Email__c,OwnerName__c FROM Environment_Variable__mdt WHERE label='ReturnsOwner'][0];

        soql = 'SELECT Name, Item_Num__c, Description, Family, ProductCode FROM Product2 WHERE (Item_Status__c = \'1\' OR Item_Status__c = \'2\')  ';
        runQuery();

    }

    public void onPageLoad(){

        if(!rlisDelete.isEmpty())
            delete rlisDelete;
    }

    public Return__c createReturn(Map<Id, Return__c> returnMap){
        return null;
    }



    public void refreshReturnDTOs () {
        ReturnDTOs = new List<ReturnDTO>();
        ReturnDTOs = getReturnDTOs();
    }
    public void holdPage(){
        //do nothing
    }


    public void convertQuantity(){

        if(currentReturn.Stage__c == 'Draft' ){
            quantityDisplay = true;
        }else if(currentReturn.Stage__c != 'Draft'){
            quantityDisplay = false;
        }
    }

    public void convertLooseProducts(){
        //removes the previously created allloosereturns so that a new one is created
        removeAllLooseReturnLineItem();

        List<Return_Line_Item__c> rliForUpdate = new List<Return_Line_Item__c>();
        List<Return_Line_Item__c> rliForLooseItems = new List<Return_Line_Item__c>();

        //map of products with their respective loose associations
        Map<Id, Id> looseProducts = new Map<Id,Id>();
        for(Product2 prod : [SELECT Id, Loose_Product__c FROM Product2]){
            looseProducts.put(prod.Id, prod.Loose_Product__c);
        }

        for (ReturnDTO item : ReturnDTOs) {           
            if (!item.isNew) {
                for (Return_Line_Item__c rli : item.retLI.values()) {
                    //verify there is a line item and it has a product date input
                    if(rli.id != null && rli.Product_Date__c != null){
                        //count displays
                        if (rli.Displays__c != null && rli.Quantity_Type__c == 'Display') {
                            rli.Integration_Record__C = TRUE;
                            rli.Display_Record__C = TRUE;  
                        //count pouches
                        }else if(rli.Pouches__c != null && rli.Quantity_Type__c == 'Pouch'){

                            if(!rli.Product__r.is_Loose_Product__c){

                                //create a clone of the rli that is about to be converted to all loose products
                                Return_Line_Item__c looseProduct = rli.clone(false, false, false, false);
                                
                                //indicate that it is not for the integration to pickup
                                looseProduct.Integration_Record__C = FALSE;
                                looseProduct.Display_Record__C = TRUE;
                                
                                //add it to list to be inserted
                                rliForLooseItems.add(looseProduct);

                                //convert the current one to all loose products 
                                rli.Product__c = looseProducts.get(rli.Product__c);

                                //indicate that this is not a record to display to the user 
                                rli.Display_Record__C = FALSE;
                                rli.Integration_Record__C = TRUE;                          

                            }

                            rliForUpdate.add(rli);
                            
                        //add new line items that have no quanitity
                        }else{
                            
                        }
                    }
                }
            } else {
                Return_Line_Item__c rli = item.retLI.get(String.valueOf(currentReturn.Id));
                if(rli.Product__c != null && rli.Product_Date__c != null){
                    if (rli.Displays__c != null && rli.Quantity_Type__c == 'Display') {
                            rli.Integration_Record__C = TRUE;
                            rli.Display_Record__C = TRUE;   
                    }else if(rli.Pouches__c != null && rli.Quantity_Type__c == 'Pouch'){
                        if(!rli.Product__r.is_Loose_Product__c){
 
                                //create a clone of the rli that is about to be converted to all loose products
                                Return_Line_Item__c looseProduct = rli.clone(false, false, false, false);
                                
                                //indicate that it is not for the integration to pickup
                                looseProduct.Integration_Record__C = FALSE;
                                looseProduct.Display_Record__C = TRUE;
                                
                                //add it to list to be inserted
                                rliForLooseItems.add(looseProduct);

                                //convert the current one to all loose products 
                                rli.Product__c = looseProducts.get(rli.Product__c);

                                //indicate that this is not a record to display to the user 
                                rli.Display_Record__C = FALSE;
                                rli.Integration_Record__C = TRUE;                         

                        }
                        rliForUpdate.add(rli);
                    }else{

                    }
                }
            }
        }

        try{
            upsert rliForUpdate;
            insert rliForLooseItems;
        } catch (DmlException  ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
        }
        //don't need this because you want the list to stay after after they have clicked the submit button
        //refreshReturnDTOs();
    }

    public void removeAllLooseReturnLineItem(){
        List <Return_Line_Item__c> rlis = [SELECT Id FROM Return_Line_Item__c WHERE Return__c=:currentReturn.Id AND Product_Number__c ='100110'];
        
        try{
            delete rlis;
        } catch (DmlException  ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
        }

        //refreshReturnDTOs();
        //saveReturn();

    }

    public void saveReturn(){
        //update , Pouches__c, Displays__c count and change logic here
        convertLooseProducts();
        List<Return_Line_Item__c> rliForUpdate = new List<Return_Line_Item__c>();
        Decimal pouchesCount = 0;
        Decimal displaysCount = 0;

        //map of products with their respective loose associations
        Map<Id, Id> looseProducts = new Map<Id,Id>();
        for(Product2 prod : [SELECT Id, Loose_Product__c FROM Product2]){
            looseProducts.put(prod.Id, prod.Loose_Product__c);
        }

        for (ReturnDTO item : ReturnDTOs) {           
            if (!item.isNew) {
                for (Return_Line_Item__c rli : item.retLI.values()) {
                    //verify there is a line item and it has a product date input
                    if(rli.id != null && rli.Product_Date__c != null){
                        //count displays
                        if (rli.Displays__c != null && rli.Quantity_Type__c == 'Display' ) {
                            //debug
                            //System.debug('rli.Id: ' + rli.Id );
                            
                            displaysCount += rli.Displays__c;

                            //zero out numbers that were input at pouches
                            rli.Pouches__c = 0;

                            rliForUpdate.add(rli);

                        //count pouches
                        }else if(rli.Pouches__c != null && rli.Quantity_Type__c == 'Pouch'){
                            //debug
                            //System.debug('rli.Id: ' + rli.Id );
                            
                            pouchesCount += rli.Pouches__c;

                            //zero out numbers that were input at displays
                            rli.Displays__c = 0;

                            /*
                            if(!rli.Product__r.is_Loose_Product__c){
                                //change product to loose product 
                                rli.Product__c = looseProducts.get(rli.Product__c);
                            }
                            */

                            rliForUpdate.add(rli);
                            
                        //add new line items that have no quanitity
                        }else{
                            //zero out numbers that were input at pouches
                            rli.Pouches__c = 0;

                             //zero out numbers that were input at displays
                            rli.Displays__c = 0;

                            rliForUpdate.add(rli);
                        }
                    }

                }
            } else {
                Return_Line_Item__c rli = item.retLI.get(String.valueOf(currentReturn.Id));
                if(rli.Product__c != null && rli.Product_Date__c != null){
                    if (rli.Displays__c != null && rli.Quantity_Type__c == 'Display') {
                        //debug
                        //System.debug('rli: hit error?');
                        //System.debug('rli: ' + rli );
                        displaysCount += rli.Displays__c;

                        //zero out numbers that were input at pouches
                        rli.Pouches__c = 0;

                        rliForUpdate.add(rli);
                    }else if(rli.Pouches__c != null && rli.Quantity_Type__c == 'Pouch'){
                        //debug
                        //System.debug('rli: hit error?');
                        //System.debug('rli: ' + rli );
                        pouchesCount += rli.Pouches__c;

                        //zero out numbers that were input at displays
                        rli.Displays__c = 0;

                        /*
                        if(!rli.Product__r.is_Loose_Product__c){
                            //change product to loose product 
                            rli.Product__c = looseProducts.get(rli.Product__c);
                        }
                        */


                        rliForUpdate.add(rli);
                    }else{
                        rliForUpdate.add(rli);

                        //zero out numbers that were input at pouches
                        rli.Pouches__c = 0;

                        //zero out numbers that were input at displays
                        rli.Displays__c = 0;
                    }
                }

            }
        }

        //check for zero quanitity in rliUpdates
        for(Return_Line_Item__c rliCheck : rliForUpdate){
            if((rliCheck.displays__c == 0 && rliCheck.pouches__c == 0) || (rliCheck.displays__c == null && rliCheck.pouches__c == null)){
                zeroInQuantity = true;
                break;
            }else{
                zeroInQuantity = false;
            }
        }

        try{
            currentReturn.Total_Displays__c = displaysCount;
            currentReturn.Total_Pouches__c = pouchesCount;
            update currentReturn;
            upsert rliForUpdate;
        } catch (DmlException  ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
        }
        refreshReturnDTOs();
    }



    public void addLineItem(){

        //debug
        //System.debug('addLineItem - selectedList array: ' + selectedList);

        //convert the string to a list 
        List<String> itemsToAdd = selectedList.split(',');
        
        //debug
        //System.debug('itemsToAdd.size(): ' + itemsToAdd.size());
        
        if(itemsToAdd.size()>=2){

            for(Integer i=0; i<itemsToAdd.size()-1;i+=2){
                //debug
                //System.debug('Map: itemsToAdd[i]: ' + itemsToAdd[i] + '   itemsToAdd[i+1] ' + itemsToAdd[i+1]);
                
                //select the wProducts from the prod list
                updateCheckListObj(itemsToAdd[i], itemsToAdd[i+1]);
            }
        }

        /*
        Boolean hasTodayReturn = false;
        
        if(returns.isEmpty() && returns == null){
            //debug
            //System.debug('No returns found');
        }
        
        for (Return__c item : returns) {
            if (item.Id == lastReturn && item.Submitted_Date__c == Date.Today()) {
                hasTodayReturn = true;
            }
        }
        */

        //debug
        //System.debug('addLineItem - hasTodayInentory: ' + hasTodayReturn);
        
        //verify that a new return has been created or that one is being edited
        if(currentReturn.id != null){
            if(checklistObjects != null && !checklistObjects.isEmpty()){
                //debug
                //System.debug('checklistObjects size : ' + checklistObjects.size());
            }else{
                //debug
                //System.debug('checklistObjects is empty');
            }
            

            for(wProduct checkObj:checklistObjects){
                //debug
                //System.debug('Added to line item : ' + checkObj.wrappedProd.Name + '  ' + checkObj.selected + ' checkObj.wrappedProd.Item_Num__c: ' +  checkObj.wrappedProd.Item_Num__c + ' \n');

                ReturnDTO newReturnDTO = new ReturnDTO(new Return_Line_Item__c(Return__c = currentReturn.Id, Product__c = checkObj.wrappedProd.Id), currentReturn);
                newReturnDTO.isNew = true;
                newReturnDTO.productNumber = checkObj.wrappedProd.Item_Num__c;
                newReturnDTO.productName = checkObj.wrappedProd.Name;


                //List<Return_Line_Item__c> rliForUpdate = new List<Return_Line_Item__c>();
                ReturnDTOs.add(newReturnDTO);
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Create a new return to begin adding line items.'));
        }

        //clear out the check boxes
        clearSelections();    
    }

  

    public void updateCheckListObj(String prodId, String selectedState ){ 
        //debug
        //System.debug('  updateCheckListObj - entered   ');

        //construct the list if it has not already been
        if(checklistObjects==null || checklistObjects.isEmpty()) {
            checklistObjects = new Set<wProduct>();

            //debug
            //System.debug('  updateCheckListObj - checklistObjects instantiated  ');
        }

        if(prodList.isEmpty()){

            //debug
            //System.debug('Nothing in prodList');
        }else{

            //debug
            //System.debug(' prodList size: ' + prodList.size() + ' ');
        }

        //loop through each prod in the list to select the prod the user selected
        for(wProduct prod : prodList){
            //if the match is not already selected 
            System.debug(' Comparing: prod.Id' + prodId + ' ' + 'String.valueOf(prod.wrappedProd.Id): '+ String.valueOf(prod.wrappedProd.Id) + ' selectedState: ' + prod.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');
            if( prodId == String.valueOf(prod.wrappedProd.Id) && selectedState == 'true'){

                //add the checked match to the request set for processing (use set instead of list to remove duplicates when users check and uncheck the same match)
                checklistObjects.add(prod);
                prod.selected = true;

                //debug
                System.debug(' Added: ' + prod.wrappedProd.Name + '  ' + ' prod.selected: ' + prod.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');

            //if the match is already selected
            }else if(prodId == String.valueOf(prod.wrappedProd.Id) && selectedState == 'false'){

                //remove the checked match from the set 
                checklistObjects.remove(prod);

                //debug
                System.debug(' Removed: ' + prod.wrappedProd.Name + '  ' + ' prod.selected: ' + prod.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');
            }
        }
        
          
    }

    public PageReference newReturn() {
        User usr = [SELECT Id, Analyst__c, Supervisor__c, Supervisor_2__c, Supervisor_3__c, Supervisor_4__c FROM User WHERE Id = :Userinfo.getUserId()];

        Return__c ret = new Return__c(Account__c=currentAccount.Id, Initiator__c=usr.Id, Initiator_Analyst__c=usr.Analyst__c, Initiator_Supervisor_1__c=usr.Supervisor__c, 
        Initiator_Supervisor_2__c=usr.Supervisor_2__c, Initiator_Supervisor_3__c=usr.Supervisor_3__c, Initiator_Supervisor_4__c=usr.Supervisor_4__c, External_Inventory_User__c='kevin.zuraik@goodtimestobacco.com',
        Stage__c='Draft', Initiated_Date__c = Date.today());

        try {
            insert ret;
        
        } catch (DmlException  ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
            return null;
        }

        currentReturn = ret;

        PageReference redirectedPage = new PageReference(Page.GT_ReturnForm.getUrl());
        redirectedPage.setRedirect(true);
        redirectedPage.getParameters().put('id', currentReturn.Id);

        return redirectedPage;
    }

    public PageReference submitReturn() {
        saveReturn();
        
        //check that none of the quanitities are zero 
        if(zeroInQuantity){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Cannot save return with 0 quantity on return item. Please add a quanitity or delete the return item.' ));
            return null;
        }else{


            //don't allow submission if they are zero 

            Return__c ret = currentReturn;
            ret.Stage__c = 'Submitted';
            ret.Submitted_Date__c = Date.today();
            ret.Initiated_Date__c = Date.today();
            
            //convert loose products 
            convertLooseProducts();

            try {
                update ret;
                //System.debug('Return succeeded: ' + ret.Id + '  ' + ret.Stage__c);
            
            } catch (DmlException  ex) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
                return null;
            }

            currentReturn = ret;

            PageReference redirectedPage = new PageReference(Page.GT_ReturnForm.getUrl());
            redirectedPage.setRedirect(true);
            redirectedPage.getParameters().put('id', currentReturn.Id);

            return redirectedPage;
        }
    }


    private List<ReturnDTO> getReturnDTOs() {
		
        Return__c ret = [
            SELECT Id, Name, Submitted_Date__c, Account__c, Initiator__c, Additional_Notes__c, Pallets__c,  Tracking_Number__c, Stage__c, Total_Displays__c, Total_Pouches__c
            FROM Return__c
            WHERE Account__c = :currentAccount.Id AND Id=:currentReturn.Id
        ];

        //debug
        //System.debug('ret: ' + ret.Id + '  visit date: ' + ret.Submitted_Date__c);

		//select all the return line items for the editing return
        List<Return_Line_Item__c> rlis = [
            SELECT Id, Product_Date__c, Product__r.Item_Desc__c, Age__c, Return_Percentage__c,
                Product__r.Product_Brand__c, Product__r.Item_Num__c, Return__r.Submitted_Date__c, Product__r.Name, Product__r.is_Loose_Product__c, CreatedDate, 
                Return_Code__c, Pouches__c, Displays__c, Quantity_Type__c 
            FROM Return_Line_Item__c
            WHERE Return__c =:currentReturn.Id AND Display_Record__c = TRUE
            ORDER BY Product__r.Item_Desc__c ASC NULLS LAST, Product_Date__c ASC NULLS LAST
        ];

        //List<Return_Line_Item__c> rlisUpdateAgeAtReplishment = new List<Return_Line_Item__c>();
        
        //debug
        //System.debug('rlis list size: ' + rlis.size());

        //Remove rli's with null date
        Map<String, ReturnDTO> mapReturns = new  Map<String, ReturnDTO>();

        if(rlis != null){
            //START HERE
            for(Integer i=1; i<rlis.size(); i++){
                //remove null product dates from rli
                if(rlis.get(i).Product_Date__c== null){
                   rlis.remove(i);
                }
            }

            Set<String> prodNumbers = new Set<String>();
            for (Integer i = 0; i < rlis.size(); i++) {
                prodNumbers.add(rlis.get(i).Product__r.Item_Num__c);
                
                //debug
                System.debug('rlis.get(i).Product__r.Item_Num__c: ' + rlis.get(i).Product__r.Item_Num__c);
            }

            //gets a list of all the products with a valid item status
            List<Product2> products = [
                SELECT Id, ProductCode, Item_Num__c, Item_Status__c, Name
                FROM Product2
                WHERE Item_Num__c in :prodNumbers    
            ];

            //debug
            System.debug('products list size: ' + products.size());

          
            Map<String, Product2> mapProductsWithInvalidStatus = new  Map<String, Product2>();
            for (Integer i = 0; i < products.size(); i++) {

                if(products.get(i).Item_Status__c == '3'){ 
                    //debug
                    //System.debug('ReturnDTO - products.get('+i+').Item_Status__c = ' + products.get(i).Item_Status__c);
                    
                    mapProductsWithInvalidStatus.put(products.get(i).Item_Num__c, products.get(i));
                }
                
            }

            for (Return_Line_Item__c item : rlis) {
                
                //debug
                //System.debug('containsKey: ' + mapProductsWithInvalidStatus.containsKey(item.Product__r.Item_Num__c) + 'For item: ' + item.Product__r.Item_Num__c);
                
                //remove line items with invalid product status 
                if(mapProductsWithInvalidStatus.containsKey(item.Product__r.Item_Num__c)){
                    rlisDelete.add(item);
                    continue;
                }
                    
                //if the returns contain a product number
                if (mapReturns.containsKey(item.Product__r.Item_Num__c) ) {
                    //if the Return_Line_Item__c does not contain an ID, then add the current item
                    if (mapReturns.get(item.Product__r.Item_Num__c).retLI.get(item.Return__c).Id == null) {
                        mapReturns.get(item.Product__r.Item_Num__c).retLI.put(item.Return__c, item);
                    } else {
                        mapReturns.put(item.Product__r.Item_Num__c + item.Id, new ReturnDTO(item, currentReturn));
                    }

                } else {
                    mapReturns.put(item.Product__r.Item_Num__c, new ReturnDTO(item, currentReturn));
                }
                
            }
        }
        if(currentReturn != null){
            returns = new List<Return__c>();
            returns.add(currentReturn);
        }
        
        

        return mapReturns.values();
    }

    public class ReturnDTO {
        public Boolean isNew {get; set;}
        public String brand {get; set;}
        public String productNumber {get; set;}
        public String productDescription {get; set;}
        public String productName {get; set;}
        public Map<Id, Return_Line_Item__c> retLI {get; set;}

        public ReturnDTO (Return_Line_Item__c rli, Return__c ret) {
            this.isNew = false;
            this.brand = rli.Product__r.Product_Brand__c;
            this.productNumber = rli.Product__r.Item_Num__c;
            this.productDescription = rli.Product__r.Name;
            this.retLI = new Map<Id, Return_Line_Item__c>();

            this.retLI.put(ret.Id, new Return_Line_Item__c(Product__c = null));
            this.retLI.put(rli.Return__c, rli);
        }
    }


    public void createDeletionRequest() {
        if (!String.isBlank(deleteItemId)) {
            Return_Line_Item__c deleteReturnLineItem = [SELECT Id FROM Return_Line_Item__c WHERE Id = : deleteItemId];
            delete deleteReturnLineItem;
        }

        refreshReturnDTOs();
        saveReturn();
        deleteItemId = '';

    }
    
    //Delete Link On User Based
    public String userProfileName {
        get {
            return [
                    select Profile.Name
                    from User
                    where Id = :Userinfo.getUserId()
                    ].Profile.Name;
        }
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

            //for each product returned by the search 
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

            /*
            //add any search values that have been filled in by the user to the soql query - search by region of currently logged in users (hard coded for demonstrative purposes)
            soql = 'SELECT Name, Item_Num__c, Description, Family, ProductCode, Item_Status__c FROM Product2 WHERE (Item_Status__c = \'1\' OR Item_Status__c = \'2\') ';
            
            for(String str1:listSearchVal){
                soql += ' AND Name LIKE \'%'+String.escapeSingleQuotes(str1)+'%\'';
            }

            for(String str1:listSearchVal){
                soql += ' OR Account__c LIKE \'%'+String.escapeSingleQuotes(str1)+'%\'';
            }
            */

            Boolean first = true;
            soql = 'SELECT Name, Item_Num__c, Description, Family, ProductCode, Item_Status__c FROM Product2';
            for(String str1 : listSearchVal){
                if(str1 != '' && str1.length()>1){
                    if(first){
                        soql = soql + ' WHERE (Item_Status__c = \'1\' OR Item_Status__c = \'2\') AND (';
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
    
}