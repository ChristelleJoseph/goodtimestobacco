/**
 * Created by christellejoseph on 6/13/20.
 */
@IsTest
public with sharing class GT_TMARecapTest
{
	@IsTest
	  public static void testShouldGetOrderFromAccountGivenAccountId()
	{
		Account TestAcc = createAccountWithOrders();

		Test.startTest();
		PageReference pageRef = page.GT_TMARecapForm;
		pageRef.getParameters().put('id',TestAcc.Id);
		Test.setCurrentPage(pageRef);
		GT_TMARecapClass controller = new GT_TMARecapClass(new ApexPages.StandardController(TestAcc));
		controller.getOrderItemsFromAccount();

		List<OrderItem> orderItemsList = [
				SELECT id, Brand__c, Item_Description__c, Quantity
				FROM OrderItem
		];

		system.assertEquals(2, orderItemsList.size());
		Test.stopTest();

	}

	public static Account createAccountWithOrders(){

		Pricebook2 openPB = new Pricebook2(
				Name = 'Open Stock Items',
				Description = 'Price Book 2009 Products',
				IsActive = true);

		insert openPB;

		Product_Brand__c prodBrandTest = new Product_Brand__c(
				Name = 'Flat Wrap 2/79');

		insert prodBrandTest;

		Product2 prod1 = new Product2(
				Name = 'Flat Wrap Product',
				ProductCode = '101',
				Item_Num__c = '444441',
				Item_Status__c = '1',
				Product_Brand__c = prodBrandTest.Id,
				IsActive = true);

		insert prod1;

		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry standardPrice = new PricebookEntry(
				Pricebook2Id = pricebookId,
				Product2Id = prod1.Id,
				UnitPrice = 10000,
				IsActive = true,
				UseStandardPrice = false);

		insert standardPrice;


		PricebookEntry pbEntry1 = new PricebookEntry(
				IsActive = true,
				Pricebook2Id = openPB.Id,
				Product2Id = prod1.Id,
				UnitPrice = 9999,
				UseStandardPrice=true);

		insert pbEntry1;

		Account acc = new Account();
		acc.name= 'test';
		acc.Account__c= '123456';
		acc.OwnerId = UserInfo.getUserId();

		insert acc;

		Order orderTest = new Order(
				AccountId = acc.Id,
				Name = 'Order',
				EffectiveDate = Date.today(),
				Status = 'Draft',
				Pricebook2Id = openPB.Id);

		insert orderTest;


		OrderItem orderItemTest = new OrderItem(
				OrderId = orderTest.Id,
				Quantity = 20,
				PricebookEntryId = pbEntry1.Id);

		insert orderItemTest;
		return acc;
	}

}