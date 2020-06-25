({
	redirectToReturnForm : function(component, event, helper) {
		var rid = component.get("v.recordId")
        var eUrl= $A.get("e.force:navigateToURL");
        eUrl.setParams({
          "url": '/apex/GT_ReturnForm?id=' + rid
        });
        eUrl.fire();
	}
})