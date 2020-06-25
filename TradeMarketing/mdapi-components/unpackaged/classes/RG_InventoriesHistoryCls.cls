public with sharing class RG_InventoriesHistoryCls {

    public List<InventoryDTO> inventoryDTOs {get; set;}
    public List<Inventory__c> inventories {get; set;}
    public String accountId {get; set;}
    public String countParamMonth {get; set;}
    public Integer countOfMonth {get; set;}
    public String lastInventory {get; set;}
    public String deleteItemId {get; set;}
    public Inventory_Line_Item__c inventoryLineTemplate {get; set;}
    public List<Inventory_Line_Item__c> ilisDelete {get;set;}


    // Holds the string that builds a soql query. This variable holds the initial query without the order and limit
    public String soql {get;set;}

    //The list of prod to render to the visual force page
    public List<wProduct> prodList {get;set;}

    //The list of prod to request a match for
    public Set<wProduct> checklistObjects {get;set;}

    public String selectedList{get;set;}


    public RG_InventoriesHistoryCls(){

        ilisDelete = new List<Inventory_Line_Item__c>();
        inventoryLineTemplate = new Inventory_Line_Item__c();
        accountId = ApexPages.currentPage().getParameters().get('id');
        countParamMonth = ApexPages.currentPage().getParameters().get('count');
        if(countParamMonth == null ){
            countOfMonth = 1;
        } else {
            countOfMonth = Integer.valueOf(countParamMonth);
        }

        refreshInventoryDTOs();

        soql = 'SELECT Name, Item_Num__c, Description, Family, ProductCode FROM Product2 WHERE (Item_Status__c = \'1\' OR Item_Status__c = \'2\')  ';
        runQuery();

    }

    public void refreshInventoryDTOs () {
        inventoryDTOs = new List<InventoryDTO>();
        inventoryDTOs = getInventoryDTOs();
    }

    public void saveChanges(){
        List<Inventory_Line_Item__c> iliForUpdate = new List<Inventory_Line_Item__c>();
        for (InventoryDTO item : inventoryDTOs) {
            
            
            
            if (!item.isNew) {
                for (Inventory_Line_Item__c ili : item.invLI.values()) {
                    if (ili.id != null) {
                        iliForUpdate.add(ili);
                    }
                }
            } else {
                if (item.invLI.get(lastInventory).Product__c != null) {
                    iliForUpdate.add(item.invLI.get(lastInventory));
                }
            }
        }
        try{
            upsert iliForUpdate;
        } catch (DmlException  ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
        }
        refreshInventoryDTOs();

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

        Boolean hasTodayInventory = false;
        
        if(inventories.isEmpty() && inventories == null){
            //debug
            //System.debug('No inventories found');
        }
        
        for (Inventory__c item : inventories) {
            if (item.Id == lastInventory && item.Visit_Date__c == Date.Today()) {
                hasTodayInventory = true;
            }
        }

        //debug
        //System.debug('addLineItem - hasTodayInentory: ' + hasTodayInventory);
        
        if (hasTodayInventory) {
            if(checklistObjects != null && !checklistObjects.isEmpty()){
                //debug
                //System.debug('checklistObjects size : ' + checklistObjects.size());
            }else{
                //debug
                //System.debug('checklistObjects is empty');
            }
            

            for(wProduct checkObj:checklistObjects){
                //debug
                //System.debug('Added to line item : ' + checkObj.wrappedProd.Name + '  ' + checkObj.selected + ' \n');

                InventoryDTO newInventoryDTO = new InventoryDTO(new Inventory_Line_Item__c(Account__c = accountId, Inventory__c = lastInventory, Product__c = checkObj.wrappedProd.Id), inventories);
                newInventoryDTO.isNew = true;
                newInventoryDTO.productNumber = checkObj.wrappedProd.Item_Num__c;
                
                
                List<Inventory_Line_Item__c> iliForUpdate = new List<Inventory_Line_Item__c>();
                inventoryDTOs.add(newInventoryDTO);
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'You can add line items only for today\'s Inventory'));
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

    public pageReference newInventory() {
        String newInventoryId = '';
        List<Inventory__c> currentInventory = [
            SELECT Id, Visit_Date__c, Account__c, Description__c,  (
                SELECT Id, Product_description__c, ProductDateCode__c, Inventory__c, Account__c, Product__c,ResalePrice__c, WholeSale__c
                FROM Inventory_Line_Items__r
            )
            FROM Inventory__c
            WHERE Id = :lastInventory
        ];

        if (currentInventory.size() > 0) {
            currentInventory[0].Visit_Date__c = Date.today();
            Inventory__c newInventory = currentInventory[0].clone(false, true, false, false);

            try {
                insert newInventory;
                newInventoryId = newInventory.Id;

                List<Inventory_Line_Item__c> newILIs = new List<Inventory_Line_Item__c>();
                for (Inventory_Line_Item__c item : currentInventory[0].Inventory_Line_Items__r) {
                    Inventory_Line_Item__c newILI = item.clone(false, true, false, false);
                    newILI.Inventory__c = newInventory.Id;
                    newILIs.add(newILI);
                }
                insert newILIs;
            } catch (DmlException  ex) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getDmlMessage(0)));
                return null;
            }
        } else {
            insert new List<Inventory__c>{new Inventory__c(Visit_Date__c = Date.today(), Account__c = accountId)};
        }

        PageReference redirectedPage = new PageReference(Page.RG_InventoriesHistoryPage.getUrl());
        redirectedPage.setRedirect(true);
        redirectedPage.getParameters().put('id', accountId);
        redirectedPage.getParameters().put('count', String.valueOf(countOfMonth));

        return redirectedPage;
    }

    
    public List<Inventory__c> getInventoryList(Integer monthsAgo){
        //get a list of inventories and their visit date 
        List<Inventory__c> inventories = [
            SELECT Id, Visit_Date__c
            FROM Inventory__c
            WHERE Account__c = : accountId AND Visit_Date__c <= TODAY
            ORDER BY Visit_Date__c DESC LIMIT : monthsAgo
        ];

        /*
        for(Inventory__c inv : inventories){
            //debug
            System.debug('inv: ' + inv.Id + '  visit date: ' + inv.Visit_Date__c);
        }
        */

        return inventories;
    }

    public List<Inventory_Line_Item__c> getInventoryLineItemList(List<Inventory__c> inventories){
        //select all the inventory line items for all of the previously gathered inventories 
        List<Inventory_Line_Item__c> ilis = [
            SELECT Id, ProductDateCode__c, Quantity__c, Product_description__c, Age__c, Age_at_replenishment__c,
                Brand__c, Product_Number__c, Inventory__r.Visit_Date__c, Inventory__c, CreatedDate
            FROM Inventory_Line_Item__c
            WHERE Inventory__c in : inventories
            ORDER BY Product_description__c ASC NULLS LAST, ProductDateCode__c  ASC NULLS LAST
        ];

        return ilis;
    }

    public Set<String> findInvalidItems(List<Inventory_Line_Item__c> ilis){
        Map<String,Integer> matchesCount = new Map<String,Integer>();
        //Map<String,Integer> duplicatesWithQuantityCount = new Map<String,Integer>();
        Set<String> setSafeItems = new Set<String>();
        Set<String> setRemovalItems = new Set<String>();
        
        for(Integer i=1; i<ilis.size(); i++){
            //debug
            //System.debug('Checking for match: ' + ilis.get(i-1).Product_description__c + ' = ' + ilis.get(i).Product_description__c + ' Date code: ' + ilis.get(i-1).ProductDateCode__c);

            //check for null date match and remove ili if it has 3 consecutive null or zero quanitities 
            //need to check if the ili is new, that way it is not being removed when there is no date 
            if(ilis.get(i-1).Product_description__c == ilis.get(i).Product_description__c && (ilis.get(i-1).Quantity__c == null || ilis.get(i-1).Quantity__c == 0) && ilis.get(i-1).Inventory__c != ilis.get(i).Inventory__c){
                
                Integer currentCount = matchesCount.get(ilis.get(i-1).Product_description__c);

                //debug
                //System.debug('Match found: ' + ilis.get(i-1).Product_description__c + ' = ' + ilis.get(i).Product_description__c + ' Date code: ' + ilis.get(i-1).ProductDateCode__c + ' Current count: ' + currentCount);

                if(currentCount == null){
                    matchesCount.put(ilis.get(i-1).Product_description__c, 1);

                    //debug
                    //System.debug('Match found, value of 1 assigned to: ' +  ilis.get(i-1).Product_description__c);
                }else{
                    Integer loggedValue = matchesCount.get(ilis.get(i-1).Product_description__c);
                    loggedValue = loggedValue +1;
                    matchesCount.put(ilis.get(i-1).Product_description__c, loggedValue);
                    
                    //debug
                    System.debug('Match found, value of ' + loggedValue + ' assigned to: ' +  ilis.get(i-1).Product_description__c);
                }
            }
            
            if(ilis.get(i-1).Product_description__c == ilis.get(i).Product_description__c && (ilis.get(i-1).Quantity__c != null && ilis.get(i-1).Quantity__c != 0)){
                //add the item to the safe set, then remove these items from the removal set
                setSafeItems.add(ilis.get(i).Product_description__c);
            }       
        }

        
        for (Integer count=0; count<ilis.size(); count++){
            //debug
            //System.debug('ilis.size(): ' + ilis.size() + 'ilis.get(count).Product_description__c: ' + ilis.get(count).Product_description__c + 'matchesCount.get(ilis.get(count).Product_description__c): ' + matchesCount.get(ilis.get(count).Product_description__c));
            
            if(matchesCount.get(ilis.get(count).Product_description__c) > 2){
                //debug
                System.debug('adding to removal list: ' + ilis.get(count).Product_description__c + ' count: ' + count);
                
                setRemovalItems.add(ilis.get(count).Product_description__c);
                
            }
        }
        //remove any items that have duplicate non null values
        setRemovalItems.removeAll(setSafeItems);

        return setRemovalItems;
    }


    private List<InventoryDTO> getInventoryDTOs() {
        
        List<Inventory_Line_Item__c> ilisUpdateAgeAtReplishment = new List<Inventory_Line_Item__c>();

        //generate list of invalid inventory line items to remove from the DTO 
        List<Inventory__c> pastInventories = getInventoryList(4);
        
        List<Inventory_Line_Item__c> pastIlis = getInventoryLineItemList(pastInventories);
        
        Set<String> itemsToRemoveFromDTO = findInvalidItems(pastIlis);
        

        //build final list based on view last selection in VF page 
        inventories = new List<Inventory__c>();
        
        List<Inventory__c> inventoriesDESC = getInventoryList(countOfMonth);
		
        //get the most recent inventory and copy the inventories into a new list in reverse order 
        for (Integer i = inventoriesDESC.size() - 1; i >= 0; i--) {
           if (inventoriesDESC[i].Visit_Date__c <= Date.today()) {
                lastInventory = inventoriesDESC[i].Id;
           }
            inventories.add(inventoriesDESC[i]);
        }

		//select all the inventory line items for all of the previously gathered inventories 
        List<Inventory_Line_Item__c> ilis = getInventoryLineItemList(inventories);

        //debug
        //System.debug('ilis list size (before removal set): ' + ilis.size());

        //Remove Ili's if they are in the removal set
        Integer count=0;
        while (count<ilis.size()){
            //debug
            //System.debug('comparing: ' + ilis.get(count).Product_description__c + ' itemsToRemoveFromDTO.contains(ilis.get(count).Product_description__c): ' + itemsToRemoveFromDTO.contains(ilis.get(count).Product_description__c) + ' count: ' + count);

            if( itemsToRemoveFromDTO.contains(ilis.get(count).Product_description__c)){
                //debug
                //System.debug('removing: ' + ilis.get(count).Product_description__c + ' count: ' + count);

                ilis.remove(count);
            }else{
                count++;
            }
        }

        //debug
        System.debug('ilis list size: (after removal set)' + ilis.size());



        Set<String> prodNumbers = new Set<String>();
        for (Integer i = 0; i < ilis.size(); i++) {
            prodNumbers.add(ilis.get(i).Product_Number__c);
            
            //debug
            //System.debug('ilis.get(i).Product_Number__c: ' + ilis.get(i).Product_Number__c + 'ilis.get(i).Product_description__c: ' + ilis.get(i).Product_description__c);
            //System.debug();
        }

        //gets a list of all the products with a valid item status
        List<Product2> products = [
            SELECT Id, ProductCode, Item_Num__c, Item_Status__c
            FROM Product2
            WHERE Item_Num__c in :prodNumbers    
        ];

        //debug
        //System.debug('products list size: ' + products.size());

        //adds the valid products to a map for the following comparison
        Map<String, Product2> mapProductsWithInvalidStatus = new  Map<String, Product2>();
        for (Integer i = 0; i < products.size(); i++) {

            if(products.get(i).Item_Status__c == '3'){ 
                //debug
                //System.debug('InventoryDTO - products.get('+i+').Item_Status__c = ' + products.get(i).Item_Status__c);
                
                mapProductsWithInvalidStatus.put(products.get(i).Item_Num__c, products.get(i));
            }
            
        }

        
        Map<String, InventoryDTO> mapInventuries = new  Map<String, InventoryDTO>();
        
        for (Inventory_Line_Item__c item : ilis) {
            
            //debug
            //System.debug('containsKey: ' + mapProductsWithInvalidStatus.containsKey(item.Product_Number__c) + ' For item: ' + item.Product_Number__c);
            
            //remove line items with invalid product status 
            if(mapProductsWithInvalidStatus.containsKey(item.Product_Number__c)){

                //debug
                //System.debug('  ^^ removed from list');
                ilisDelete.add(item);
                continue;
            }
 
            //debug
            //System.debug('mapInventuries.containsKey(item.Product_Number__c): ' + mapProductsWithInvalidStatus.containsKey(item.Product_Number__c) + ' For item: ' + item.Product_Number__c);    
        
            //if the inventories contain a product number
            if (mapInventuries.containsKey(item.Product_Number__c) ) {

                //if the Inventory_Line_Item__c does not contain an ID, then add the current item
                if (mapInventuries.get(item.Product_Number__c).invLI.get(item.Inventory__c).Id == null) {
                    mapInventuries.get(item.Product_Number__c).invLI.put(item.Inventory__c, item);
                } else {
                    mapInventuries.put(item.Product_Number__c + item.Id, new InventoryDTO (item, inventories));
                }

            } else {

                mapInventuries.put(item.Product_Number__c, new InventoryDTO (item, inventories));
            }
        }
        
        //loop through inventory values and make a list of those being displayed
        
        //compare look for matches in the list of ili, if no match exists remove from DTO

        //currently looping through ilis, generating DTOs 

        for (InventoryDTO dto : mapInventuries.values()) {
            
            //debug
            System.debug('dto.productNumber: ' + dto.productNumber + 'dto.productDescription: ' + dto.productDescription);
            //System.debug('ilis.get(i).Product_Number__c: ' + ilis.get(i).Product_Number__c);
        }


        return mapInventuries.values();
    }

    public class InventoryDTO {
        public Boolean isNew {get; set;}
        public Boolean vfAvailable {get; set;}
        public String brand {get; set;}
        public String productNumber {get; set;}
        public String productDescription {get; set;}
        public Map<Id, Inventory_Line_Item__c> invLI {get; set;}

        public InventoryDTO (Inventory_Line_Item__c ili, List<Inventory__c> inventories) {
            this.isNew = false;
            this.brand = ili.Brand__c;
            this.productNumber = ili.Product_Number__c;
            this.productDescription = ili.Product_description__c;
            this.invLI = new Map<Id, Inventory_Line_Item__c>();
            for (Inventory__c item : inventories) {
                this.invLI.put(item.Id, new Inventory_Line_Item__c(Product__c = null));
            }
            this.invLI.put(ili.Inventory__c, ili);
        }
    }

    public void deleteInvalidLineItems(){
        if(!ilisDelete.isEmpty())
            delete ilisDelete;
    }

    public void createDeletionRequest() {
        if (!String.isBlank(deleteItemId)) {
            Inventory_Line_Item__c deleteInventoryLineItem = [SELECT Id FROM Inventory_Line_Item__c WHERE Id = : deleteItemId];
            delete deleteInventoryLineItem;
        }

        refreshInventoryDTOs();
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

            //for each contract returned by the search 
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
                System.debug('SOQL String: ' + soql);

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