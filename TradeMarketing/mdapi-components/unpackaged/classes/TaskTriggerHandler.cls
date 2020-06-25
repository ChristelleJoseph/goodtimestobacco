public with sharing class TaskTriggerHandler {

    public static void sendEmailOwnerAndCC(List<Task> listTasks){
    	

        User currentUser = [SELECT Id, Analyst__c, Supervisor__c, Supervisor_2__c, Supervisor_3__c, Supervisor_4__c, External_Supervisor_1__c, External_Supervisor_2__c, External_Supervisor_3__c, External_Supervisor_4__c, Name FROM User WHERE Id = : UserInfo.getUserId()];
        List<Messaging.SingleEmailMessage> emailsList = new List<Messaging.SingleEmailMessage>();
    	
        Set<Id> accountIds = new Set<Id>();
        for (Task task : listTasks){
            accountIds.add(task.WhatId);
        }
    	
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Name, ShippingCity, ShippingState, RecordType.Name FROM Account WHERE Id IN : accountIds]);
        if(!accounts.IsEmpty() && accounts != NULL){
            for (Task task : listTasks){
                String [] ccEmailUsers = new List<String>();

                if (currentUser.Analyst__c != null) {
                    User user1 = [SELECT Email FROM User WHERE Id = :currentUser.Analyst__c];
                    ccEmailUsers.add(''+user1.Email);
                }

                if (currentUser.Supervisor__c!= null) {
                    User user1 = [SELECT Email FROM User WHERE Id = :currentUser.Supervisor__c];
                    ccEmailUsers.add(''+user1.Email);
                }

                if (currentUser.Supervisor_2__c!= null) {
                    User user1 = [SELECT Email FROM User WHERE Id = :currentUser.Supervisor_2__c];
                    ccEmailUsers.add(''+user1.Email);
                }
                
                if (currentUser.Supervisor_3__c != null) {
                    User user1 = [SELECT Email FROM User WHERE Id = :currentUser.Supervisor_3__c];
                    ccEmailUsers.add(''+user1.Email);
                }
                         
                if (currentUser.Supervisor_4__c != null) {
                    User user1 = [SELECT Email FROM User WHERE Id = :currentUser.Supervisor_4__c];
                    ccEmailUsers.add(''+user1.Email);
                }
                
               
                if (currentUser.External_Supervisor_1__c != null) {
                    ccEmailUsers.add(''+currentUser.External_Supervisor_1__c);
                }
                if (currentUser.External_Supervisor_2__c != null) {
                    ccEmailUsers.add(''+currentUser.External_Supervisor_2__c);
                }
                if (currentUser.External_Supervisor_3__c != null) {
                    ccEmailUsers.add(''+currentUser.External_Supervisor_3__c);
                }
                if (currentUser.External_Supervisor_4__c != null) {
                    ccEmailUsers.add(''+currentUser.External_Supervisor_4__c);
                }

                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();


                mail.setTargetObjectId(currentUser.Id);
                mail.setCcAddresses(ccEmailUsers);
                mail.setSubject(currentUser.Name+ ' - ' +accounts.get(task.WhatId).Name+ ' - '+task.Subject+' - '+Date.today().format());
                //note that styling was added to remove images due to an error in outlook
                mail.setHtmlBody(
                    '<head><style>img{display:none;}</style></head>'+
                    '<b>New task logged by:  </b>' + currentUser.Name + '<br><br>'  +
                    + '<b>Task Type: </b>' + task.Subject + '<br><br>' +
                    + '<b>Account Type: </b>' + accounts.get(task.WhatId).RecordType.Name + '<br><br>' +
                    + '<b>Customer name: </b>' + accounts.get(task.WhatId).Name + '<br><br>' +
                    + '<b>Customer city: </b>' + accounts.get(task.WhatId).ShippingCity + '<br><br>' +
                    + '<b>Customer state: </b>' + accounts.get(task.WhatId).ShippingState + '<br><br>' +
                    + '<b>Purpose of call: </b>' + task.description + '<br><br>' +
                    + '<b>Result: </b>' + task.What_were_your_results__c + '<br><br>' +
                    + '<b>Comments: </b>'+ task.Notes_and_Comments__c + '<br><br>' +
                    + '<b>Comments Continued: </b>'+ task.Notes_and_Comments_Continued__c + '<br><br>'
                    
                );
                mail.saveAsActivity = false;
                emailsList.add(mail);

                //debug
                //System.debug('mail'+mail.getSubject());
            }
            if (emailsList.size() > 0) {
                Messaging.sendEmail(emailsList);
            }
        }
    }
}