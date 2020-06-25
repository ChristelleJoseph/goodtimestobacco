({
	doInit : function(component, event, helper) {
        component.set("v.recordId", component.get("v.pageReference").state.c__id);
		helper.getBaseData(component, event, helper);
	},
    
    saveRecord : function(component, event, helper) {
        const promotion = component.get("v.promotion");
        
        if(promotion.Id) {
        	helper.saveTradeMarketingAgreement(component, event, helper);
        }
        else {
            helper.showToast('Error', 'Please select promotion record.', 'error');
        }
    },
    
    getPromotions : function(component, event, helper) {
        helper.searchPromotions(component, event, helper);
    },
    
    addLineItems : function(component, event, helper) {
        let productBrands = component.get("v.productBrands");
        const record = component.get("v.tmaRecord");
        let selectedBrands = new Array();
        
        productBrands.forEach(function(productBrand) {
            if(productBrand.isSelected == true) {
                selectedBrands.push({Product_Brand__c : productBrand.productBrand.Id, Trade_Marketing_Agreement__c : record.Id});
            }
        });
        
        if(selectedBrands.length > 0) {
            component.set("v.newLineItems", selectedBrands);
            helper.saveAgreementsListItems(component, event, helper);
        }
        else {
            helper.showToast('Info', 'No Products selected.', 'info');
        }
    },
    
    selectPromotion : function(component, event, helper) {
        const index = event.currentTarget.dataset.index;
        const promotions = component.get("v.promotions");
        let record = component.get("v.tmaRecord");
        
        component.set("v.promotion", promotions[index]);
        component.set("v.displayPill", true);
        record.Trade_Marketing_Agreement_Promotion__c = promotions[index].Id;
        component.set("v.tmaRecord", record);
        helper.saveTradeMarketingAgreement(component, event, helper);
        
        helper.hideLookupResult(component, 'lookupResult');
        helper.getProductBrands(component, event, helper);
    },
    
    clearLookup : function(component, event, helper) {
        component.set("v.promotion", {});
        component.set("v.displayPill", false);
    },
    
    lookupFocus : function(component, event, helper) {
        helper.searchPromotions(component, event, helper);
        helper.showLookupResult(component, 'lookupResult');
    },
    
    deleteLineItem : function(component, event, helper) {
        const index = event.currentTarget.dataset.index;
        const lineItems = component.get("v.lineItems");
        helper.deleteAgreementsListItem(component, event, helper, lineItems[index].Id);
    },
    
    launchRecap : function(component, event, helper) {
        const record = component.get("v.tmaRecord");
        location.href = '/apex/GT_TMARecapForm_Two?id=' + record.Id;
    }
})