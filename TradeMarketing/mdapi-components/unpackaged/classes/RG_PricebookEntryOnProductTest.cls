@Istest
public class RG_PricebookEntryOnProductTest {
@Istest(SeeAllData=true)
    public static void PricebookEntryOnProductTest(){
		Product2 prod = new Product2(Name ='Product X',Item_Num__c='7845693',Item_Status__c='1',ProductCode='Pro-X',isActive = true);
		insert prod;
        Id lststdPricebookid = [select id from Pricebook2 where name='Standard Price Book'  limit 1].Id;
        Id custPricebookid = [select id from Pricebook2 where name='Open Stock Items'  limit 1].Id;
        Product2 prod1 = new Product2(Name ='Product X1',Item_Num__c='9874584',Item_Status__c='2',ProductCode='Pro-X1',isActive = true);
		insert prod1;  
        prod.Item_Status__c='2';
        update prod;
    }
}