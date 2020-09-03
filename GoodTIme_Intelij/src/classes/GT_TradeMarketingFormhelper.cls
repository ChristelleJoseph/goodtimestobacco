/**
 *  @author Apical
 *  @date 14 June 2020
 *  @description helper class for Trade Marketing Form Controller
 */
public class GT_TradeMarketingFormhelper {

    public static BaseResponse getBaseData(String strRecordId) {
        BaseResponse response = new BaseResponse();

        try {
            Id recordId = Id.valueOf(strRecordId);
            String strObjectType = recordId.getSObjectType().getDescribe().getName().toUpperCase();

            switch on strObjectType {
                when 'ACCOUNT' {
                    response.tradeMarketingAgreement = new Trade_Marketing_Agreement__c(Account__c = recordId, Status__c = 'New');
                    insert response.tradeMarketingAgreement;
                }
                when 'TRADE_MARKETING_AGREEMENT__C' {
                    response.tradeMarketingAgreement = [SELECT Id, Name, Account__c, Account__r.Name, Account__r.Email__c, Approver_Notes__c,  Start_Date__c, End_Date__c, Status__c, Total_Discount__c, Trade_Marketing_Agreement_Promotion__c,
                                                       		   Trade_Marketing_Agreement_Promotion__r.Name, CreatedBy.Name, (SELECT Id, Allowance_Rate__c, Maximum_Allowance_Rate__c, Product_Brand__c,
                                                               Product_Brand__r.Name, Product_Brand__r.Description__c FROM Trade_Marketing_Agreement_Line_Items__r ORDER BY CreatedDate)
                                                        FROM Trade_Marketing_Agreement__c
                                                        WHERE Id =: recordId].get(0);

                    List<ProcessInstanceWorkitem> approvalInstanceList = [SELECT Id, OriginalActorId, Actor.Name FROM ProcessInstanceWorkitem
                                                                      WHERE ProcessInstance.Status = 'Pending' AND ProcessInstance.TargetObjectId =: strRecordId LIMIT 1];

                    if(!approvalInstanceList.isEmpty()) {
                        response.displayApprovals = approvalInstanceList.get(0).OriginalActorId == UserInfo.getUserId();
                    }
                }
            }
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }

    public static ResponseBase approveRecord(String strRecordId, String strApprovalType, String strApproverComment) {
        ResponseBase response = new ResponseBase();

        try {
            List<ProcessInstanceWorkItem> listWorkItems = [SELECT Id FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId =: strRecordId];
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments(strApproverComment);
            req.setAction(strApprovalType);
            req.setWorkitemId(listWorkItems.get(0).Id);
            Approval.ProcessResult result =  Approval.process(req);

            update new Trade_Marketing_Agreement__c(Id = strRecordId, Approver_Notes__c = strApproverComment);

            if(strApprovalType.equalsIgnoreCase('Approve')) {
                User currUser = [SELECT Id, Name,  Supervisor__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
                Trade_Marketing_Agreement__c agreement = [SELECT Id, CreatedBy.Id, Account__c, Account__r.Email__c, Approver_Notes__c FROM Trade_Marketing_Agreement__c WHERE Id =: strRecordId LIMIT 1];
                List<EmailTemplate> templates = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Trade_Marketing_Promotion_Approved'];
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templates.get(0).Id, agreement.CreatedBy.Id, strRecordId);
                mail.setSaveAsActivity(false);

                List<Messaging.RenderEmailTemplateBodyResult> listRenderedEmails = Messaging.renderEmailTemplate(agreement.CreatedBy.Id, strRecordId, new List<String> { templates.get(0).Body });
                Messaging.SingleEmailMessage mail1 = new Messaging.SingleEmailMessage();
                mail1.setToAddresses(new List<String> { agreement.Account__r.Email__c });
                mail1.setSubject(templates.get(0).Subject);
                mail1.setSenderDisplayName(currUser.Name);
                mail1.setPlainTextBody(listRenderedEmails.get(0).getMergedBody());

                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                PageReference pref = page.GT_TradeMarketingForm;
                pref.getParameters().put('id', strRecordId);
                pref.setRedirect(true);
                attachment.setFileName('Trade Marketing Agreement');
                attachment.setContentType('application/pdf');
                attachment.setBody(Test.isRunningTest() ? Blob.valueOf('Test String') : pref.getContent());

                mail1.setFileAttachments(new List<Messaging.EmailFileAttachment> { attachment });
                mail.setFileAttachments(new List<Messaging.EmailFileAttachment> { attachment });
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail, mail1 });

                mentionTextPost(agreement.Account__c, agreement.CreatedBy.Id, 'Your request for Trade Marketing Promotion has been approved.');
            }
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }

    public static void mentionTextPost(Id subjectId, Id userToMentionId, String postText) {
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = postText;
        messageInput.messageSegments.add(textSegment);

        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = userToMentionId;
        messageInput.messageSegments.add(mentionSegment);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.SubjectId = subjectId;

        ConnectApi.ChatterFeeds.postFeedElement(NULL, input);
    }

    public static ResponseBase saveTradeMarketingAgreement(Trade_Marketing_Agreement__c tradeMarketingAgreement, List<Trade_Marketing_Agreement_Line_Item__c> listLineItems) {
        ResponseBase response = new ResponseBase();

        try {
            update tradeMarketingAgreement;

            if(!listLineItems.isEmpty()) {
            	update listLineItems;
            }
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }

    public static LookupData searchPromotions(String strName) {
        LookupData response = new LookupData();

        try {
            strName = '%' + strName + '%';
            response.listLookupRecord = [SELECT Id, Name, Maximum_Allowance_Rate__c, Maximum_Brand_Selections__c
                                         FROM Trade_Marketing_Agreement_Promotion__c
                                         WHERE Name LIKE : strName
                                         LIMIT 5];
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }

    public static ProductBrandList getProductBrands(String strPromotionId) {
        ProductBrandList response = new ProductBrandList();

        try {
            response.listProductBrands = [SELECT Id, Name, Description__c
                                          FROM Product_Brand__c
                                          WHERE Trade_Marketing_Agreement_Promotion__c =: strPromotionId];
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }

    public static ResponseBase saveAgreementsListItems(List<Trade_Marketing_Agreement_Line_Item__c> listLineItems) {
        ResponseBase response = new ResponseBase();

        try {
            insert listLineItems;
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }

    public static ResponseBase deleteAgreementsListItem(String strLineItemId) {
        ResponseBase response = new ResponseBase();

        try {
            delete [SELECT Id FROM Trade_Marketing_Agreement_Line_Item__c WHERE Id =: strLineItemId];
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }

    public static ResponseBase submitForApproval(String strRecordId) {
        ResponseBase response = new ResponseBase();

        try {
            User currUser = [SELECT Id, Name, Supervisor__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting TMA for Approval.');
            req.setObjectId(strRecordId);
            req.setNextApproverIds(new List<Id> { currUser.Id });
            Approval.ProcessResult result = Approval.process(req);

            List<EmailTemplate> templates = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Trade_Marketing_Agreement_Submit'];
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templates.get(0).Id, currUser.Supervisor__c, strRecordId);
            mail.setSaveAsActivity(false);
            /* Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(currUser.Id);
            mail.setTemplateId(templates.get(0).Id);
            mail.setWhatId(strRecordId);
            mail.setSenderDisplayName(currUser.Name);
            mail.setSaveAsActivity(false); */
            /* mail.setPlainTextBody(EmailLogic.renderTemplate(strRecordId, templates.get(0).Body));
            mail.setToAddresses(new List<String> { currUser.Manager.Email }); */

            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            PageReference pref = page.GT_TradeMarketingForm;
            pref.getParameters().put('id', strRecordId);
            pref.setRedirect(true);
            attachment.setFileName('Trade Marketing Agreement');
            attachment.setContentType('application/pdf');
            attachment.setBody(Test.isRunningTest() ? Blob.valueOf('Test String') : pref.getContent());

            mail.setFileAttachments(new List<Messaging.EmailFileAttachment> { attachment });
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception ex) {
            response.isSuccess = false;
            response.strMessage = ex.getMessage();
        }

        return response;
    }


    public virtual class ResponseBase {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String strMessage;

        public ResponseBase() {
            this.isSuccess = true;
            this.strMessage = '';
        }
    }

    public class BaseResponse extends ResponseBase {
        @AuraEnabled public Trade_Marketing_Agreement__c tradeMarketingAgreement;
        @AuraEnabled public Boolean displayApprovals;

        public BaseResponse() {
            this.displayApprovals = false;
        }
    }

    public class ProductBrandList extends ResponseBase {
        @AuraEnabled public List<Product_Brand__c> listProductBrands;

        public ProductBrandList() {
            this.listProductBrands = new List<Product_Brand__c>();
        }
    }

    public class LookupData extends ResponseBase {
        @AuraEnabled public List<Trade_Marketing_Agreement_Promotion__c> listLookupRecord;

        public LookupData() {
            this.listLookupRecord = new List<Trade_Marketing_Agreement_Promotion__c>();
        }
    }
}