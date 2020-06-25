trigger RG_ProductTrigger on Product2 (after insert,after update) {
    /** Trigger to Insert and Remove Products on Pricebook**/
    if(trigger.Isafter)
    	RG_PricebookEntryOnProductHandler.priceBookEntry(trigger.new);  
 
}