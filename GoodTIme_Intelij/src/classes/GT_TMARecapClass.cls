public without sharing class GT_TMARecapClass {
	//001Z000001VAERbIAP
	private final Account acct;
	public  Date startDate{get;set;}
	public  Date endDate{get;set;}
	public String accountId {get; set;}
	public Decimal totalDiscount {get; set;}
	public boolean showResults {get; set;}
	public boolean noResultsFoundMessage {get; set;}

	public List<OrderItem> orderItems {get; set;}
	public List<Trade_Marketing_Agreement_Line_Item__c> tmaLineItems {get; set;}
	public List<TMAWrapperClassObject> tmaWrapList{get; set;}


	public GT_TMARecapClass(ApexPages.StandardController stdController) {
		this.acct = (Account)stdController.getRecord();
	}

	public void DisplayTMARecapFormDataTable(){
		showResults = false;
		noResultsFoundMessage = false;
		getOrderItemsFromAccount();
		getTMADiscountAndAllowanceRate();
		BuildTMARecapFormWithRequiredInformation();
		calculateTotalDiscount();
	}

	private void getOrderItemsFromAccount(){
		accountId = ApexPages.currentPage().getParameters().get('id');
		orderItems = [
				SELECT id, Brand__c, Item_Description__c, Quantity
				FROM OrderItem
				WHERE Order.AccountId = :accountId
		];
	}

	private void getTMADiscountAndAllowanceRate(){
		accountId = ApexPages.currentPage().getParameters().get('id');
		if(startDate != null && endDate != null && startDate <= endDate){
			System.debug('startDate' + startDate);
			System.debug('endDate' + endDate);
			tmaLineItems = [
					SELECT Allowance_Rate__c, Trade_Marketing_Agreement__r.Total_Discount__c
					FROM Trade_Marketing_Agreement_Line_Item__c
					WHERE Trade_Marketing_Agreement__r.Account__c =:accountId
					AND Trade_Marketing_Agreement__r.Start_Date__c =:startDate
					AND Trade_Marketing_Agreement__r.End_Date__c =:endDate
			];
		}
		if(tmaLineItems.size()> 0){
			showResults = true;
			noResultsFoundMessage = false;
		}else{
			showResults = false;
			noResultsFoundMessage = true;
		}
	}


	private void BuildTMARecapFormWithRequiredInformation(){

			tmaWrapList = new List<TMAWrapperClassObject>();
			for(OrderItem order: orderItems)
			{
				for (Trade_Marketing_Agreement_Line_Item__c tmaLineItem : tmaLineItems)
				{
					tmaWrapList.add(new TMAWrapperClassObject
							(
									order.Brand__c,
									order.Item_Description__c,
									order.Quantity,
									tmaLineItem.Trade_Marketing_Agreement__r.Total_Discount__c,
									tmaLineItem.Allowance_Rate__c)
					);
				}

				System.debug('tmaWrapList' + tmaWrapList);
				System.debug('tmaWrapList' + tmaWrapList.size());
			}

	}

	private void calculateTotalDiscount(){
		totalDiscount = 0;
		for(TMAWrapperClassObject TMAWrapperObject: tmaWrapList){
			totalDiscount += TMAWrapperObject.discount;
		}
	}

	public class TMAWrapperClassObject{
		public String brand {get; set;}
		public String brandDescription {get; set;}
		public Decimal quantity {get; set;}
		public Decimal discount {get; set;}
		public Decimal allowanceRate {get; set;}

		public TMAWrapperClassObject(String brand,String brandDescription, Decimal quantity, Decimal discount, Decimal allowanceRate ){
			this.brand = brand;
			this.brandDescription = brandDescription;
			this.quantity = quantity;
			this.discount = discount;
			this.allowanceRate = allowanceRate;
		}
	}
}

/*
todo
throw error message if start date is greater than end date
if two TMA will List update to reflect?
 */