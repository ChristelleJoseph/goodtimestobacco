/**
 *  @author Apical
 *  @date 14 June 2020
 *  @description controller class for Trade Marketing Form component
 */
public class GT_TradeMarketingFormController {
    @AuraEnabled
    public static GT_TradeMarketingFormhelper.BaseResponse getBaseData(String strRecordId) {
        return GT_TradeMarketingFormhelper.getBaseData(strRecordId);
    }

    @AuraEnabled
    public static GT_TradeMarketingFormhelper.ResponseBase saveTradeMarketingAgreement(Trade_Marketing_Agreement__c tradeMarketingAgreement, List<Trade_Marketing_Agreement_Line_Item__c> listLineItems) {
        return GT_TradeMarketingFormhelper.saveTradeMarketingAgreement(tradeMarketingAgreement, listLineItems);
    }

	@AuraEnabled
    public static GT_TradeMarketingFormhelper.ResponseBase approveRecord(String strRecordId, String strApprovalType, String strApproverComment) {
        return GT_TradeMarketingFormhelper.approveRecord(strRecordId, strApprovalType, strApproverComment);
    }

    @AuraEnabled
    public static GT_TradeMarketingFormhelper.LookupData searchPromotions(String strName) {
        return GT_TradeMarketingFormhelper.searchPromotions(strName);
    }

    @AuraEnabled
    public static GT_TradeMarketingFormhelper.ProductBrandList getProductBrands(String strPromotionId) {
        return GT_TradeMarketingFormhelper.getProductBrands(strPromotionId);
    }

    @AuraEnabled
    public static GT_TradeMarketingFormhelper.ResponseBase saveAgreementsListItems(List<Trade_Marketing_Agreement_Line_Item__c> listLineItems) {
        return GT_TradeMarketingFormhelper.saveAgreementsListItems(listLineItems);
    }

    @AuraEnabled
    public static GT_TradeMarketingFormhelper.ResponseBase deleteAgreementsListItem(String strLineItemId) {
        return GT_TradeMarketingFormhelper.deleteAgreementsListItem(strLineItemId);
    }

    @AuraEnabled
    public static GT_TradeMarketingFormhelper.ResponseBase submitForApproval(String strRecordId) {
        return GT_TradeMarketingFormhelper.submitForApproval(strRecordId);
    }


    @AuraEnabled
    public static boolean isValidUser (String userId, String recordId){
        User validUser = [SELECT Id, Email, Supervisor__c, Name  FROM User WHERE Id =:userId];
        Trade_Marketing_Agreement__c TMAccount = [SELECT Id, name, Status__c, Account__c, Account__r.Email__c, Account__r.Name FROM Trade_Marketing_Agreement__c WHERE Id =: recordId LIMIT 1];

        if(validUser.Supervisor__c != null && TMAccount.Account__r.Email__c != null){ return true;}
        else{ return false;}
    }
}