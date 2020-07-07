/**
 * Created by christellejoseph on 6/28/20.
 */
@IsTest
public with sharing class GT_TMARecapClass_TwoTest
{

	@IsTest
	public static void testBuildDataTableWithTMAInfo()
	{
		Trade_Marketing_Agreement_Promotion__c tmaPromo = new Trade_Marketing_Agreement_Promotion__c(
				Name = 'Promo',
				Maximum_Allowance_Rate__c = 5
		);

		insert tmaPromo;

		Product_Brand__c brand = new Product_Brand__c(
				Name = 'Cool Brand',
				Description__c = 'some description',
				Trade_Marketing_Agreement_Promotion__c = tmaPromo.Id
		);

		insert brand;

		Account acc = New Account(
				name = 'Account ',
				Account__c  = '1234560'

		);

		insert acc;

		Trade_Marketing_Agreement__c tmAgreement = new Trade_Marketing_Agreement__c(
				Name = 'tmAgreement',
				Account__c = acc.Id,
				Trade_Marketing_Agreement_Promotion__c = tmaPromo.Id,
				Start_Date__c = date.today(),
				End_Date__c = date.today() + 10
		);

		insert tmAgreement;

		List<Trade_Marketing_Agreement_Line_Item__c> tmaList = new List<Trade_Marketing_Agreement_Line_Item__c>();

		Trade_Marketing_Agreement_Line_Item__c tmaLineItem1 = new Trade_Marketing_Agreement_Line_Item__c(
				Trade_Marketing_Agreement__c = tmAgreement.Id,
				Product_Brand__c = brand.Id,
				Allowance_Rate__c = 3,
				Quantity__c = 40,
				Discount__c = 10

				//120
		);

		tmaList.add(tmaLineItem1);

		Trade_Marketing_Agreement_Line_Item__c tmaLineItem2 = new Trade_Marketing_Agreement_Line_Item__c(
				Trade_Marketing_Agreement__c = tmAgreement.Id,
				Product_Brand__c = brand.Id,
				Allowance_Rate__c = 2,
				Quantity__c = 20,
				Discount__c = 5
				//40
		);

		tmaList.add(tmaLineItem2);

		Trade_Marketing_Agreement_Line_Item__c tmaLineItem3 = new Trade_Marketing_Agreement_Line_Item__c(
				Trade_Marketing_Agreement__c = tmAgreement.Id,
				Product_Brand__c = brand.Id,
				Allowance_Rate__c = 3,
				Quantity__c = 0,
				Discount__c = 0
				//270
		);

		tmaList.add(tmaLineItem3);

		insert tmaList;

		Test.startTest();
		PageReference pageRef = page.GT_TMARecapForm_Two;
		pageRef.getParameters().put('id',tmAgreement.Id);
		Test.setCurrentPage(pageRef);
		GT_TMARecapClass_Two controller = new GT_TMARecapClass_Two(new ApexPages.StandardController(tmAgreement));
		controller.displayTMARecapFormDataTable();

		List<Trade_Marketing_Agreement_Line_Item__c> data = [
				SELECT Id, Product_Brand__r.Name, Product_Brand__r.Description__c, Allowance_Rate__c, Quantity__c,
						Discount__c, Trade_Marketing_Agreement__r.Start_Date__c,
						Trade_Marketing_Agreement__r.End_Date__c
				From Trade_Marketing_Agreement_Line_Item__c
		];



		system.assertEquals(3, data.size());
		System.assertEquals(15.00, controller.totalDiscount);

		controller.tmaWrapList.get(2).quantity = 90;

		controller.save();


		List<Trade_Marketing_Agreement_Line_Item__c> data2 = [
				SELECT Id, Product_Brand__r.Name, Product_Brand__r.Description__c, Allowance_Rate__c, Quantity__c,
						Discount__c, Trade_Marketing_Agreement__r.Start_Date__c,
						Trade_Marketing_Agreement__r.End_Date__c
				From Trade_Marketing_Agreement_Line_Item__c
		];


		System.assertEquals(430, controller.totalDiscount);





		Test.stopTest();

	}

}