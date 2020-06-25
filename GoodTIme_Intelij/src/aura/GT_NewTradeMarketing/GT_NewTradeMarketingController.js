({
	doInit : function(component, event, helper) {
        location.href = '/lightning/n/Trade_Marketing_Form?c__id=' + component.get("v.recordId");
        /* let navService = component.find("navService");
        let pageReference = {
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Trade_Marketing_Form'
            },
            state: {
                "c__id": component.get("v.recordId")
            }
        };
        
        navService.navigate(pageReference); */
	}
})