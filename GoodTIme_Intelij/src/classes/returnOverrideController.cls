public with sharing class returnOverrideController {
    
    private final Account acct;
        

    
    public returnOverrideController(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();

        redirectToReturnForm(acct.Id);
    }

    public PageReference redirectToReturnForm(Id accountID){
        PageReference pageRef = new PageReference('/apex/GT_ReturnForm?id=' + accountID);
        return pageRef.setRedirect(true);
    }
}