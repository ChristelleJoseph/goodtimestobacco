({
	doInit : function(component, event, helper) {

        let userId = $A.get("$SObjectType.CurrentUser.Id");
        let recordId = component.get("v.pageReference").state.c__id;

        const recordId2 = component.get("v.recordId");

        console.log('check here original',recordId );
        console.log('check here',recordId2 );


        let action = component.get("c.isValidUser");
        action.setParams({
            userId: userId,
            recordId: recordId
        });
        action.setCallback(this, function(data) {
            let result = data.getReturnValue();
            console.log('result 123', result);
            console.log('check here',recordId2 );

            if (result == false){

                let btn1 = component.find('btn1');
                btn1.set('v.disabled', true);

                let btn2 = component.find('btn2');
                btn2.set('v.disabled', true);

                let btn3 = component.find('btn3');
                btn3.set('v.disabled', true);

                let btn4 = component.find('btn4');
                btn4.set('v.disabled', true);

                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Warning',
                    message: 'Please Check The Following Items: \n Account Should Have Associated Email Address.\n ' +
                        'User Should Have Assigned Supervisor.',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'warning',
                    mode: 'sticky'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);


        component.set("v.recordId", component.get("v.pageReference").state.c__id);
        helper.getBaseData(component, event, helper);
	},

    showApprovalPanel : function(component, event, helper) {
        component.set("v.showApprovalPanel", true);
    },

    hideApprovalPanel : function(component, event, helper) {
        component.set("v.showApprovalPanel", false);
    },

    recordApprove : function(component, event, helper) {
        helper.approveRecord(component, event, helper, 'Approve');
    },

    recordReject : function(component, event, helper) {
        helper.approveRecord(component, event, helper, 'Reject');
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
    
    sendForApproval : function(component, event, helper) {
        helper.submitForApproval(component, event, helper);
    },

    launchRecap : function(component, event, helper) {
        const record = component.get("v.tmaRecord");
        // window.open('/apex/GT_TMARecapForm?id=' + record.Id, '_blank');
        $A.get("e.force:navigateToURL").setParams({
            "url":"/apex/GT_TMARecapForm?id=" + record.Id
        }).fire();
    }
})