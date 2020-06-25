//********* Send Mail On Button Click *********//
//Created On 09/24/2018
public class RG_RequestFormEmailAlertCls {

    String recordid;

    public Order ord1 {get;set;}

    // Constructor
    public RG_RequestFormEmailAlertCls(ApexPages.StandardController controller) {
		recordid = apexpages.currentPage().getparameters().get('id');
        
        try{
            ord1 = [Select id, SendEmail__c, AccountId, PoNumber, CreatedById, status, Custom_notes_for_this_order__c from Order where id =: recordid limit 1];
        }catch(Exception e){
            ord1 = null;
        }

    }

    // Method to Send Mail to Return Form(Case)
    public pagereference autosendCase() {
        Case EmailId = [Select id, Customer_Email__c, Send_Email__c from
            case where id =:
            recordid limit 1
        ];
        if(EmailId.Customer_Email__c != NULL)
        	EmailId.Send_Email__c = EmailId.Customer_Email__c;

        Update EmailId;
        return new pagereference('/' + recordid).setredirect(true);
    }
   
   /*
    // Method to Send Mail to Return Form(Case)
    public pagereference sendMailToKevinOnCase() {
       Case EmailId = [Select id, Send_Email__c from
            case where id =:
            recordid limit 1
        ];
        EmailId.Send_Email__c = 'kevin.zuraik@goodtimestobacco.com';

        Update EmailId;
        return new pagereference('/' + recordid).setredirect(true);
    }
	*/

    // Method to Send Mail to Order Form(Order)
    public pagereference autosendOrder() {

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        //debug
        //System.debug('recordId: ' + recordid);
        
        ord1 = [Select id, SendEmail__c, AccountId, PoNumber, CreatedById, status, Custom_notes_for_this_order__c from Order where id =: recordid limit 1];
            
        if(ord1.Status != 'Activated'){

            Account acc1 = [Select id, Name from Account where id =: ord1.AccountId limit 1];
            
            //debug
            //System.debug('Order CreatedById: ' + ord1.CreatedById);

            User ordCreator = [SELECT Id, Email_Notification_Repository__c, National_Sales_Manager__c, Regional_Sales_Manager__c, Name, Email FROM User WHERE Id = : ord1.CreatedById];
            

            String [] toEmailUsers = new List<String>();
            String [] ccEmailUsers = new List<String>();


            if (ordCreator.Email != null) {
                ccEmailUsers.add(ordCreator.Email);
            }
            
            if (ordCreator.Email_Notification_Repository__c != null) {
                ccEmailUsers.add(ordCreator.Email_Notification_Repository__c);
            }
            
            if (ordCreator.National_Sales_Manager__c!= null) {
                User user1 = [SELECT Email FROM User WHERE Id = :ordCreator.National_Sales_Manager__c];
                ccEmailUsers.add(''+user1.Email);
            }
            
            if (ordCreator.Regional_Sales_Manager__c!= null) {
                User user1 = [SELECT Email FROM User WHERE Id = :ordCreator.Regional_Sales_Manager__c];
                ccEmailUsers.add(''+user1.Email);
            }
                
            if(ord1.Custom_notes_for_this_order__c == null){
                ord1.Custom_notes_for_this_order__c = '';
            }
            
            toEmailUsers.add('Joseph@goodtimestobacco.com');

            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            Id templateId;  
            String templateApiName = 'Order_Form_Email_Template';
            try {templateId = [select id, name from EmailTemplate where developername = : templateApiName].id;}
            catch (Exception e) {
            System.debug('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + 
                            ' refer to Setup | Communications Templates ' + templateApiName);
            }

            mail.setToAddresses(toEmailUsers);
            mail.setCcAddresses(ccEmailUsers);
            mail.setTargetObjectId(ordCreator.Id);
            mail.setWhatId(ord1.Id);
            mail.setTemplateId(templateId);
            mail.setSaveAsActivity(false);
    
            emailMessages.add(mail);

            //debug
            //System.debug('mail'+mail.getSubject());
            
            //send email to those fields        
            Messaging.sendEmail(emailMessages);
            
            //flag for process to send out email
            ord1.SendEmail__c = TRUE;

            //change status to lock order
            ord1.Status = 'Activated';
            Update ord1;

            //debug
            //System.debug(LoggingLevel.INFO,'** entered sendTemplatedEmail, to:' + toUsers + ' cc:' + ccUsers +  ' templateId:' + templateId + ' tagetObjId:' + ord1.Id);
        
        }else{
            //do nothing
        }


        //ord1 = new Order();
        return new pagereference('/' + ord1.Id).setredirect(true);
    }
    
    /* This code is to be used if the email send out is ever limited solely to a process within process builder - EMBER 01182019
    public pagereference autosendOrder() {
        
        Order EmailId = [Select id, SendEmail__c from Order where id =: recordid limit 1];
        EmailId.SendEmail__c = TRUE;
        Update EmailId;

        return new pagereference('/' + recordid).setredirect(true);
    }
	*/
    
    // Method to Send Mail to Other Record Type(Order)
    public pagereference autoSendOtherRequestTicket() {
        
        list < Case > listOfCase = [Select id, Notes__c, Account.Name, CreatedDate, RecordType.Name, Email_To__c, CreatedBy.email, Owner.Email from
            case where id =:
            recordid limit 1
        ];

        List < User > ManagerEmailid = [Select id, Manager.Email from User where id =: listOfCase[0].createdbyid];
        System.debug(ManagerEmailid[0].Manager.Email);

        List < Attachment > listOfattachments = [SELECT Id, Name, Body, ContentType FROM Attachment WHERE ParentId =: recordid];
        List < Messaging.EmailFileAttachment > email_attachments = new List < Messaging.EmailFileAttachment > ();

        // Attach a file to mail body
        for (Attachment att: listOfattachments) {
            Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
            email_att.setBody(att.Body);
            email_att.setContentType(att.ContentType);
            email_att.setFileName(att.Name);
            email_att.setinline(false);
            email_attachments.add(email_att);
        }

        // Generate email here 
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        List < String > ListofmailTo = new List < String > ();
        
        if(listOfCase[0].Email_To__c == NUll)
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'/"Email To"/ Is Empty'));        
        
        else if (listOfCase[0].Email_To__c != NUll)
            ListofmailTo.add(listOfCase[0].Email_To__c);
       
        List < String > Listofccto = new List < String > ();
        if (listOfCase[0].CreatedBy.email != NULL)
            Listofccto.add(listOfCase[0].CreatedBy.email);

        if (ManagerEmailid[0].Manager.Email != NULL)
            Listofccto.add(ManagerEmailid[0].Manager.Email);

        Date createDate = Date.newInstance(listOfCase[0].CreatedDate.year(), listOfCase[0].CreatedDate.month(), listOfCase[0].CreatedDate.day());
        String dateInString = createDate.format();
        if (listOfCase[0].Account.Name != NULL && listOfCase[0].RecordType.Name != NULL)
            email.setSubject(listOfCase[0].Account.Name + ' ' + listOfCase[0].RecordType.Name + ' ' + dateInString);
        email.setToAddresses(ListofmailTo);
        email.setCcAddresses(Listofccto);
        email.setPlainTextBody(listOfCase[0].Notes__c != NULL ? listOfCase[0].Notes__c : ' ');

        if (!email_attachments.IsEmpty() && email_attachments != NULL)
            email.setFileAttachments(email_attachments);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
            email
        });

        return new pagereference('/' + recordid).setredirect(true);

    }
	
    // Method to Send Mail to POS Request Type Record Type(Case)
    public pagereference autosendPOSRequestType() {
        
        list < Case > listOfCase = [Select id, CreatedDate, CreatedBy.Name FROM Case WHERE id =: recordid limit 1];

        List < Attachment > listOfattachments = [SELECT Id, Name, Body, ContentType FROM Attachment WHERE ParentId =: recordid];
        List < Messaging.EmailFileAttachment > email_attachments = new List < Messaging.EmailFileAttachment > ();

        // Attach a file to mail body
        for (Attachment att: listOfattachments) {
            Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
            email_att.setBody(att.Body);
            email_att.setContentType(att.ContentType);
            email_att.setFileName(att.Name);
            email_att.setinline(false);
            email_attachments.add(email_att);
        }

        // Generate email here 
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        Date createDate = Date.newInstance(listOfCase[0].CreatedDate.year(), listOfCase[0].CreatedDate.month(), listOfCase[0].CreatedDate.day());
        String dateInString = createDate.format();

        List < String > ListofmailTo = new List < String > {'desiree.murphy@goodtimestobacco.com'};
			email.setSubject(listOfCase[0].CreatedBy.Name + ' ' + dateInString + ' POS REQUEST');
        	email.setToAddresses(ListofmailTo);
        	email.setPlainTextBody(' ');
        
        if(!email_attachments.IsEmpty() && email_attachments != NULL)
           		email.setFileAttachments(email_attachments);
        		
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        
        return new pagereference('/' + recordid).setredirect(true);  

    } 

}