public class RG_PricebookEntryOnProductHandler {
    /** Called From RG_ProductTrigger On after insert **/
     public static void priceBookEntry(List<Product2> triggerNew){
        list<PricebookEntry> insertlstPbe = new list<PricebookEntry>();
        list<PricebookEntry> insertCustlstPbe = new list<PricebookEntry>();
        list<PricebookEntry> dellstPbe = new list<PricebookEntry>();
        list<PricebookEntry> delStdlstPbe = new list<PricebookEntry>();
        map<Id,pricebookentry> mapOfProductPricebook = new map<id,pricebookentry>();
        map<Id,pricebookentry> mapOfProductStndPricebook = new map<id,pricebookentry>(); 
         
        Id lststdPricebookid;
        Id custPricebookid;
         lststdPricebookid = [select id from Pricebook2 where name='Standard Price Book'  limit 1].Id;
         custPricebookid = [select id from Pricebook2 where name='Open Stock Items'  limit 1].Id;        
       
         for(pricebookentry pb : [select id,product2Id,pricebook2Id from pricebookentry Where product2id IN: triggernew AND pricebook2Id =: custPricebookid]){
           if(pb.Id != NULL)  
           	mapOfProductPricebook.put(pb.product2Id,pb);
         }  
         
         for(pricebookentry pbe : [select id,product2Id,pricebook2Id from pricebookentry Where product2id IN: triggernew AND pricebook2Id =: lststdPricebookid]){
           if(pbe.Id != NULL)  
           	mapOfProductStndPricebook.put(pbe.product2Id,pbe);
         }  
         
        for(Product2 objProduct: triggernew) {
            if(objProduct.Item_Status__c != '1' ){
                 if(mapOfProductPricebook.containsKey(objProduct.Id)){                 
                     	dellstPbe.add(mapOfProductPricebook.get(objProduct.Id));
                     }
                
            	if(mapOfProductStndPricebook.containsKey(objProduct.Id)){             	
                 		delStdlstPbe.add(mapOfProductStndPricebook.get(objProduct.id));
            		}
                }
            else if(objProduct.Item_Status__c == '1' && !mapOfProductStndPricebook.containsKey(objProduct.Id) && !mapOfProductPricebook.containsKey(objProduct.Id)){
                  	PricebookEntry PB = new PricebookEntry();
            		PB.IsActive = true;
                  	PB.UnitPrice = 0.00;
            		//PB.UseStandardPrice = False;
            		if(objProduct.Id != NULL)
                		PB.Product2Id = objProduct.id;
              		if(lststdPricebookid != NULL)
                		PB.Pricebook2Id = lststdPricebookid;
                	insertlstPbe.add(PB);
                
            }
        }
         	if(!insertlstPbe.isEmpty())
                insert insertlstPbe;
         for(pricebookentry pbe : [select id,product2Id,pricebook2Id from pricebookentry Where product2id IN: triggernew AND pricebook2Id =: lststdPricebookid]){
           if(pbe.Id != NULL)  
           	mapOfProductStndPricebook.put(pbe.product2Id,pbe);
         }  
         for(Product2 objProduct: triggernew) {
         	if(objProduct.Item_Status__c == '1' && mapOfProductStndPricebook.containsKey(objProduct.Id) && !mapOfProductPricebook.containsKey(objProduct.Id)){
                	PricebookEntry PB = new PricebookEntry();
            		PB.IsActive = true;
                  	PB.UnitPrice = 0.00;
            		//PB.UseStandardPrice = False;
            		if(objProduct.Id != NULL)
                		PB.Product2Id = objProduct.id;
              		if(custPricebookid != NULL)
                		PB.Pricebook2Id = custPricebookid;
                	insertCustlstPbe.add(PB);               
            	}
         }
         	if(!insertCustlstPbe.isEmpty())
                insert insertCustlstPbe;
           	
              /* Ember removing so that the integration will operate again. Not sure as to why Rithom originally coded to delete products of status 3, records should remain in the system.
              if(!dellstPbe.isEmpty())
                delete dellstPbe;
                
         	if(!delStdlstPbe.isEmpty())
                delete delStdlstPbe;
          		*/
     }
             
}