public with sharing class GT_PriceTrackingClass {
    public List<Retail_Price_Archive__c> archive {get; set;}
    public List<wRetailPrice> archivePrices {get; set;}
    public List<wBrand> productBrands {get; set;}
    public String accountId {get; set;}
    public String lastInventory {get; set;}
    public String deleteItemId {get; set;}
    public String removeBrandName {get; set;}
    public Set<wBrand> checklistObjects {get;set;}
    public String selectedList{get;set;}
    private final Account acct;


    public GT_PriceTrackingClass(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();

    }

    public void addBrand(){

        checklistObjects = new Set<wBrand>();

        //debug
        System.debug('addLineItem - selectedList array: ' + selectedList);

        //convert the string to a list 
        List<String> brandsToAdd = selectedList.split(',');
        
        //debug
        System.debug('brandsToAdd.size(): ' + brandsToAdd.size());
        
        
        if(brandsToAdd.size()>=2){

            for(Integer i=0; i<brandsToAdd.size()-1;i++){
                //debug
                System.debug('Map: brandsToAdd['+i+']: ' + brandsToAdd[i] + '   brandsToAdd['+i+'+1] ' + brandsToAdd[i+1]);
                
                //select the wProducts from the prod list
                updateCheckListObj(brandsToAdd[i], brandsToAdd[i+1]);

                //skip over the selected state
                i++;
            }
        }

        if(checklistObjects != null && !checklistObjects.isEmpty()){
            //debug
            System.debug('checklistObjects size : ' + checklistObjects.size());


            // create a map so that all Product_Brands__c is locatable by its Id (key)
            Map<id, Product_Brand__c> map_Brands = new Map<id, Product_Brand__c>(
                [SELECT Name FROM Product_Brand__c]);


            
            for(wBrand checkObj:checklistObjects){
                //debug
                //System.debug('Added to line item : ' + checkObj.wrapBrand.Name + '  ' + checkObj.selected + ' \n');
                
                boolean flag = true;

                for(wRetailPrice wRP1 : archivePrices){
                    
                    //debug
                    //System.debug('brandId: ' + brandId + '  ' + map_Brands.get(brandId).Name);
                    
                    if(wRP1.rpBrandName == checkObj.wrapBrand.Name){
                        flag = false;
                    }
                    
                }

                if(flag){
                    
                    Retail_Price__c rp1 = new Retail_Price__c(Retail_Price_Archive__c = archive[0].Id, Product_Brand__c = checkObj.wrapBrand.Id, Price__c=0);
                    archivePrices.add(new wRetailPrice(rp1, map_Brands.get(checkObj.wrapBrand.Id).Name));
                    
                    //debug
                    //System.debug('Added to list brand : ' + rp1.Product_Brand__r.Name  + ' \n');
                }
    
            }
        }else{
            //debug
            //System.debug('checklistObjects is empty');
        }
    }

    public void updateCheckListObj(String brandId, String selectedState ){ 
        //debug
        //System.debug('  updateCheckListObj - entered   ');

        //construct the list if it has not already been
        
        if(checklistObjects==null) {
            checklistObjects = new Set<wBrand>();

            //debug
            //System.debug('  updateCheckListObj - checklistObjects instantiated  ');
        }

        if(productBrands.isEmpty()){

            //debug
            //System.debug('Nothing in productBrands');
        }else{

            //debug
            //System.debug(' productBrands size: ' + productBrands.size() + ' ');
        }

        for(wBrand brand : productBrands){

            //System.debug(' Added: ' + brand.wrapBrand.Name + '  ' + ' brand.selected: ' + brand.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');

            //if the match is not already selected 
            if( brandId == String.valueOf(brand.wrapBrand.Id) && selectedState == 'true'){

                //add the checked match to the request set for processing (use set instead of list to remove duplicates when users check and uncheck the same match)
                checklistObjects.add(brand);
                brand.selected = true;

                //debug
                System.debug(' Added: ' + brand.wrapBrand.Name + '  ' + ' brand.selected: ' + brand.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');

            //if the match is already selected
            }else if(brandId == String.valueOf(brand.wrapBrand.Id) && selectedState == 'false'){

                //remove the checked match from the set 
                checklistObjects.remove(brand);

                //debug
                //System.debug(' Removed: ' + brand.wrapBrand.Name + '  ' + ' brand.selected: ' + brand.selected + '  ' + ' checklistObjects size : ' + checklistObjects.size() + '  ');
            }
        }
    }


    
   public void getInventoryBrands() {
     
		accountId = ApexPages.currentPage().getParameters().get('id');
        
        //debug
        //System.debug('accountId: ' + accountId);

        //get a list of inventories and their visit date 
        List<Inventory__c> inventoriesDESC = [
            SELECT Id, Visit_Date__c
            FROM Inventory__c
            WHERE Account__c = : accountId AND Visit_Date__c <= TODAY
            ORDER BY Visit_Date__c DESC LIMIT 3
        ];

        for(Inventory__c inv : inventoriesDESC){
            //System.debug('Inventories : ' + inv.Id + ' Visit Date: ' +  inv.Visit_Date__c);
        }


        String lastInventory;
        
        if(!inventoriesDESC.isEmpty()){
            lastInventory = inventoriesDESC[0].Id;
        }
        
		
        //debug
        //System.debug('lastInventory: ' + lastInventory);

		//select all the inventory line items for all of the previously gathered inventories 
        List<Inventory_Line_Item__c> lst_ilis = [
            SELECT Id, ProductDateCode__c, Quantity__c, Product_description__c, Age__c,
                Brand__c, Product_Number__c, Inventory__r.Visit_Date__c, Inventory__c,
                Product__r.Product_Brand__c
            FROM Inventory_Line_Item__c
            WHERE Inventory__c = :lastInventory AND Product__r.Item_Status__c != '3'
            ORDER BY Brand__c ASC NULLS LAST, Product_Number__c  ASC NULLS LAST
            
        ];
        
        //debug
        //System.debug('lst_ilis size: ' + lst_ilis.size());

        Set<Id> brands = new Set<Id>();
        for(Inventory_Line_Item__c ili : lst_ilis){
            brands.add(ili.Product__r.Product_Brand__c);
        }



        // create a map so that all Product_Brands__c is locatable by its Id (key)
        Map<id, Product_Brand__c> map_Brands = new Map<id, Product_Brand__c>(
                [SELECT Name FROM Product_Brand__c]);
        
        for(Id brandId : brands){
            
            boolean flag = true;
            
            //debug
            //System.debug('brandId: ' + brandId + 'map_Brands.get(brandId): ' + map_Brands.get(brandId));

            if(archivePrices == null){
                archivePrices= new List<wRetailPrice>();
            }

            //checks to see if the product2 has a brand properly assigned
            if(map_Brands.get(brandId)!=null){

                for(wRetailPrice wRP1 : archivePrices){
                    
                    //debug
                    //System.debug('brandId: ' + brandId + '  ' + map_Brands.get(brandId).Name);
                    
                    
                    if(wRP1.rpBrandName == map_Brands.get(brandId).Name){
                        flag = false;
                    }
                    
                }
                
                if(flag){
                    
                    //debug
                    //System.debug('flag: ' + flag);

                    //debug
                    //System.debug('archive[0].Id: ' + archive[0].Id + 'brandId: ' + brandId);

                    Retail_Price__c rp1 = new Retail_Price__c(Retail_Price_Archive__c = archive[0].Id, Product_Brand__c = brandId, Price__c=0);
                    archivePrices.add(new wRetailPrice(rp1, map_Brands.get(brandId).Name));
                }
            }
        }

    }


    
    public void getRetailPriceArchives () {
        
        accountId = Apexpages.currentPage().getParameters().get('Id');

        //debug
        //System.debug('accountId: ' + accountId);

        archive = [
            SELECT Id, Recorded_Date__c, Account__c,
                (SELECT Id, Product_Brand__c, Product_Brand__r.Name, Sale_Price__c, Price__c, Retail_Price_Archive__c FROM Retail_Prices__r)
            FROM Retail_Price_Archive__c
            WHERE Account__c = :accountId
            ORDER BY Recorded_Date__c DESC LIMIT 1
        ];


        //If no retail price archive currently exists create and save a new one
        if(archive.size()<1){
            Retail_Price_Archive__c RPA1 = new Retail_Price_Archive__c(
                Recorded_Date__c=Date.Today(),
                Account__c=accountId
            );
            insert RPA1;

            archive.add(RPA1);
        }

        //archivePrices holds the pricing information from the last RPA
        archivePrices = new List<wRetailPrice>();

        for(Retail_Price_Archive__c rpa: archive)
        {   
            for(Retail_Price__c rp1 : rpa.Retail_Prices__r)
                archivePrices.add(new wRetailPrice(rp1, rp1.Product_Brand__r.Name));
        }

        getBrands();
    }

    public void getBrands(){
        productBrands = new List<wBrand>();

        for(Product_Brand__c pb : [SELECT Id, Name, Description__c FROM Product_Brand__c]){
            productBrands.add(new wBrand(pb));
        }

    }


    public void saveChanges(){
  
        //get the last RPA for date comparison
        Retail_Price_Archive__c rpa;
        if(archive.size()>0){
            rpa = archive.get(0);
        }

        //do not save if there are no Retail Prices recorded
        if(archivePrices.size()>=1){

            List<Retail_Price__c> lst_RP1 = new List<Retail_Price__c>();

            //debug
            //System.debug('RPA recorded date: ' + rpa.Recorded_Date__c + ' date.today(): ' + date.today() + ' between dates: ' + rpa.Recorded_Date__c.daysBetween(Date.today()));
            
            if(rpa.Recorded_Date__c.daysBetween(Date.today()) > 30){
                accountId = ApexPages.currentPage().getParameters().get('id');
                
                //create a new retail price archive record 
                Retail_Price_Archive__c rpaReplace = new Retail_Price_Archive__c(Account__c=accountId, Recorded_Date__c=date.today());
                insert rpaReplace;

                //debug
                //System.debug('Inserted RPA');

                //create a map of the brand names to ID for access when creating new Retail Prices
                Map<String, Product_Brand__c> map_NameBrands = new Map<String, Product_Brand__c>();
                for (Product_Brand__c p : [SELECT name,id FROM Product_Brand__c]) {
                    map_NameBrands.put(p.name, p);
                }
        

                //have an RPA, looping through it to check if the values of the prices are greater than zero, 
                for(wRetailPrice rp1 : archivePrices){
                    //adding the Retail Prices to a list to be submitted to the database
                    if(rp1.wrapRP.Price__c != 0){
                        //adding the whole price record here, need to create a new price record (with a relationship to the new retail price and add it )

                        //debug
                        //System.debug('map_NameBrands.get(rp1.rpBrandName): ' + map_NameBrands.get(rp1.rpBrandName));

                        //new price record
                        Retail_Price__c rpReplace = new Retail_Price__c(Price__c=rp1.wrapRP.Price__c, Retail_Price_Archive__c=rpaReplace.Id, Product_Brand__c=map_NameBrands.get(rp1.rpBrandName).Id);
                        //set relationship

                        lst_RP1.add(rpReplace);
                    }
                }

                //this may insert new records on the current RPA, this is where I need to generate a new RPA?
                insert lst_RP1;

                //debug
                //System.debug('Inserted List!');

            //if the recorded date is under 30 days old, update the current Retail Price Archives Retail Prices
            }else{

                for(wRetailPrice rp1 : archivePrices){
                    if(rp1.wrapRP.Price__c != 0){
                        
                        lst_RP1.add(rp1.wrapRP);
                        //System.debug(rp1.wrapRP);

                    }
                }


                upsert lst_RP1;

                

                //debug
                //System.debug('Updated List!');
            }
        }else{
            System.debug('No retail prices recorded, Retail Price Archive not saved');
        }
    }

    public void createDeletionRequest() {
        
        //debug
        //System.debug('deleteItemId: '+ deleteItemId);

        if (!String.isBlank(deleteItemId)) {
            Retail_Price__c deleteRP1 = [SELECT Id FROM Retail_Price__c WHERE Id = : deleteItemId];
            delete deleteRP1;
        }

        getRetailPriceArchives();
        deleteItemId = '';

    }

    public void removeBrand() {
        
        //debug
        //System.debug('removeBrandName: '+ removeBrandName);

        List<wRetailPrice> archivePricesToKeep = new List<wRetailPrice>();

        if (!String.isBlank(removeBrandName)) {
            
            Product_Brand__c removeBR = [SELECT Name FROM Product_Brand__c WHERE Name = : removeBrandName];
            
            for(wRetailPrice rp1 : archivePrices){
                
                if(rp1.rpBrandName != removeBR.Name){
                    archivePricesToKeep.add(rp1);
                }
            }
            archivePrices = archivePricesToKeep;
        }

        getRetailPriceArchives();
        removeBrandName = '';
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

    public class wBrand {
    
        public Product_Brand__c wrapBrand {get; set;}

        public Boolean selected {get; set;}

        public wBrand(Product_Brand__c b1) {
            wrapBrand = b1;
            selected = false;
        }
    }

    public class wRetailPrice {
  
        public Retail_Price__c wrapRP {get; set;}

        public String rpBrandName {get; set;}

        public boolean isNew {get; set;}

        public wRetailPrice(Retail_Price__c rp, String bName) {
            wrapRP = rp;
            rpBrandName = bName;
            //isNew = createdState;

        }
    }


    
}