/**
 * Created by christellejoseph on 6/21/20.
 */

public with sharing class GT_TMARecapClass_Two {
	private final Trade_Marketing_Agreement__c tmAgreement;
	public  Date startDate{get;set;}
	public  Date endDate{get;set;}
	public String tmaId {get; set;}
	public Decimal totalDiscount {get; set;}
	public boolean showResults {get; set;}
	public boolean noResultsFoundMessage {get; set;}
	public boolean timer {get; set;}


	public List<Trade_Marketing_Agreement__c> tmaDates {get; set;}
	public List<Trade_Marketing_Agreement_Line_Item__c> tmaLineItems {get; set;}
	public List<TMAWrapperClassObject> tmaWrapList{get; set;}


	public GT_TMARecapClass_Two(ApexPages.StandardController stdController) {
		this.tmAgreement = (Trade_Marketing_Agreement__c)stdController.getRecord();
	}

	public void DisplayTMARecapFormDataTable(){
		showResults = false;
		noResultsFoundMessage = false;
		getTMADiscountAndAllowanceRate();
		BuildTMARecapFormWithRequiredInformation();
		calculateTotalDiscount();
	}

	private void getTMADiscountAndAllowanceRate(){
		tmaId = ApexPages.currentPage().getParameters().get('id');

			tmaLineItems = [
					SELECT Id, Product_Brand__r.Name, Product_Brand__r.Description__c, Allowance_Rate__c, Quantity__c,
							Discount__c, Trade_Marketing_Agreement__r.Start_Date__c,
							Trade_Marketing_Agreement__r.End_Date__c
					From Trade_Marketing_Agreement_Line_Item__c
					WHERE Trade_Marketing_Agreement__c =:tmaId

			];
		if (tmaLineItems.size()> 0){
			showResults = true;
		}else{
			showResults = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No record found.'));

		}
	}

	private void BuildTMARecapFormWithRequiredInformation(){

		tmaDates = [Select Start_Date__c, End_Date__c FROM Trade_Marketing_Agreement__c Where Id = :tmaId ];
		startDate = tmaDates[0].Start_Date__c;
		endDate = tmaDates[0].End_Date__c;

		tmaWrapList = new List<TMAWrapperClassObject>();

		for(Trade_Marketing_Agreement_Line_Item__c tmaLineItem: tmaLineItems){
			if ( tmaLineItem.Discount__c == null){
				tmaLineItem.Discount__c = 0;
			}
			if ( tmaLineItem.Quantity__c == null){
				tmaLineItem.Quantity__c = 0;
			}
				tmaWrapList.add(new TMAWrapperClassObject
						(
								tmaLineItem.Id,
								tmaLineItem.Product_Brand__r.Name,
								tmaLineItem.Product_Brand__r.Description__c,
								tmaLineItem.Quantity__c,
								tmaLineItem.Discount__c,
								tmaLineItem.Allowance_Rate__c
						)
				);

			}
		}

	private void calculateTotalDiscount(){
		totalDiscount = 0;
		for(TMAWrapperClassObject TMAWrapperObject: tmaWrapList){
			totalDiscount += TMAWrapperObject.discount;
		}
	}

	public void save(){
		List<Trade_Marketing_Agreement_Line_Item__c> updateTmaLineItemList = new List<Trade_Marketing_Agreement_Line_Item__c>();
		for( TMAWrapperClassObject tm: tmaWrapList ){
			if (tm.quantity != null){
				tm.discount = (tm.quantity * tm.allowanceRate).setScale(2);
			}
			calculateTotalDiscount();


			if (tm.quantity != null){
				Trade_Marketing_Agreement_Line_Item__c updateTmaLineItem =
						new Trade_Marketing_Agreement_Line_Item__c(
							Id = tm.Id,
								Quantity__c	 = tm.quantity,
								Discount__c = tm.discount
						);
				updateTmaLineItemList.add(updateTmaLineItem);
			}
		}

		try{
			update updateTmaLineItemList;
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Records Saved successfully!'));


		}catch(DmlException e)
		{
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please enter Valid Data'));
		}

		timerOn();
	}


	public void clearMessage(){
		ApexPages.getMessages().clear();

	}

	public void timerOn(){
		timer = true;
	}

	public void timerOff(){
		timer = false;
	}


	public class TMAWrapperClassObject{
		public String Id {get; set;}
		public String brand {get; set;}
		public String brandDescription {get; set;}
		public Decimal quantity {get; set;}
		public Decimal discount {get; set;}
		public Decimal allowanceRate {get; set;}

		public TMAWrapperClassObject(String Id, String brand,String brandDescription, Decimal quantity, Decimal discount, Decimal allowanceRate ){
			this.Id = Id;
			this.brand = brand;
			this.brandDescription = brandDescription;
			this.quantity = quantity;
			this.discount = discount;
			this.allowanceRate = allowanceRate;
		}
	}

	//todo - fix capitalization in methods. Start with lowerCase
}