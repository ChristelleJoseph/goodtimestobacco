({
	getBaseData : function(component, event, helper) {
		let action = component.get("c.getBaseData");
        const recordId = component.get("v.recordId");
        
        action.setParams({
            strRecordId : recordId
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === "SUCCESS") {
                let data = response.getReturnValue();
                
                if(data.isSuccess == true) {
                    if(recordId.startsWith("001")) {
                        let navService = component.find("navService");
                        let pageReference = {
                            type: 'standard__navItemPage',
                            attributes: {
                                apiName: 'Trade_Marketing_Form'
                            },
                            state: {
                                "c__id": data.tradeMarketingAgreement.Id
                            }
                        };
                        
                        navService.navigate(pageReference);
                    }
                    
                    let lineItems = [];
                    
                    if(data.tradeMarketingAgreement.Trade_Marketing_Agreement_Line_Items__r) {
                        lineItems = data.tradeMarketingAgreement.Trade_Marketing_Agreement_Line_Items__r;
                    }
                    
                    if(data.tradeMarketingAgreement.Trade_Marketing_Agreement_Promotion__c) {
                        component.set("v.promotion", {Id: data.tradeMarketingAgreement.Trade_Marketing_Agreement_Promotion__c, Name: data.tradeMarketingAgreement.Trade_Marketing_Agreement_Promotion__r.Name});
                        component.set("v.displayPill", true);
                        delete data.tradeMarketingAgreement.Trade_Marketing_Agreement_Promotion__r.Name;
                        helper.getProductBrands(component, event, helper);
                    }
                    
                    delete data.tradeMarketingAgreement.Trade_Marketing_Agreement_Line_Items__r;
                    component.set("v.lineItems", lineItems);
                    component.set("v.tmaRecord", data.tradeMarketingAgreement);
                    component.set("v.recordId", data.tradeMarketingAgreement.Id);
                }
                else {
                    helper.showToast('Error', data.strMessage, 'error');
                }
            }
            else if(state === "INCOMPLETE") {
                // do something
            }
            else if(state === "ERROR") {
                let errors = response.getError();
                
                if(errors) {
                    if(errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                }
                else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    
	saveTradeMarketingAgreement : function(component, event, helper) {
		let action = component.get("c.saveTradeMarketingAgreement");
        
        action.setParams({
            tradeMarketingAgreement : component.get("v.tmaRecord"),
            listLineItems : component.get("v.lineItems")
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === "SUCCESS") {
                let data = response.getReturnValue();
                
                if(data.isSuccess == true) {
                    helper.getBaseData(component, event, helper);
                }
                else {
                    helper.showToast('Error', data.strMessage, 'error');
                }
            }
            else if(state === "INCOMPLETE") {
                // do something
            }
            else if(state === "ERROR") {
                let errors = response.getError();
                
                if(errors) {
                    if(errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                }
                else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    
	searchPromotions : function(component, event, helper) {
		let action = component.get("c.searchPromotions");
        
        action.setParams({
            strName : component.get("v.searchName")
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === "SUCCESS") {
                let data = response.getReturnValue();
                
                if(data.isSuccess == true) {
                    component.set("v.promotions", data.listLookupRecord);
                }
                else {
                    helper.showToast('Error', data.strMessage, 'error');
                }
            }
            else if(state === "INCOMPLETE") {
                // do something
            }
            else if(state === "ERROR") {
                let errors = response.getError();
                
                if(errors) {
                    if(errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                }
                else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    
	getProductBrands : function(component, event, helper) {
		let action = component.get("c.getProductBrands");
        const promotion = component.get("v.promotion");
        
        action.setParams({
            strPromotionId : promotion.Id
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === "SUCCESS") {
                let data = response.getReturnValue();
                
                if(data.isSuccess == true) {
                    let productBrands = [];
                    
                    data.listProductBrands.forEach(function(productBrand) {
                        productBrands.push({isSelected : false, productBrand : productBrand});
                    });
                    
                    component.set("v.productBrands", productBrands);
                    
                    if(productBrands.length <= 0) {
                        helper.showToast('Info', 'No Products found for selected promotion.', 'info');
                    }
                }
                else {
                    helper.showToast('Error', data.strMessage, 'error');
                }
            }
            else if(state === "INCOMPLETE") {
                // do something
            }
            else if(state === "ERROR") {
                let errors = response.getError();
                
                if(errors) {
                    if(errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                }
                else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    
	saveAgreementsListItems : function(component, event, helper) {
		let action = component.get("c.saveAgreementsListItems");
        
        action.setParams({
            listLineItems : component.get("v.newLineItems")
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === "SUCCESS") {
                let data = response.getReturnValue();
                
                if(data.isSuccess == true) {
                    component.set("v.newLineItems", []);
                    helper.getBaseData(component, event, helper);
                }
                else {
                    helper.showToast('Error', data.strMessage, 'error');
                }
            }
            else if(state === "INCOMPLETE") {
                // do something
            }
            else if(state === "ERROR") {
                let errors = response.getError();
                
                if(errors) {
                    if(errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                }
                else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    
	deleteAgreementsListItem : function(component, event, helper, strLineItemId) {
		let action = component.get("c.deleteAgreementsListItem");
        
        action.setParams({
            strLineItemId : strLineItemId
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            
            if(state === "SUCCESS") {
                let data = response.getReturnValue();
                
                if(data.isSuccess == true) {
                    helper.getBaseData(component, event, helper);
                }
                else {
                    helper.showToast('Error', data.strMessage, 'error');
                }
            }
            else if(state === "INCOMPLETE") {
                // do something
            }
            else if(state === "ERROR") {
                let errors = response.getError();
                
                if(errors) {
                    if(errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                }
                else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
	},
    
    showLookupResult : function(component, componentName) {
        const foropen = component.find(componentName);
        $A.util.addClass(foropen, 'lookupResult');
    },
    
    hideLookupResult : function(component, componentName) {
        const forclose = component.find(componentName);
        $A.util.removeClass(forclose, 'lookupResult');
    },
    
    showToast : function(strTitle, strMessage, strType) {
        $A.get("e.force:showToast").setParams({
            "type": strType,
            "title": strTitle,
            "message": strMessage
        }).fire();
    }
})