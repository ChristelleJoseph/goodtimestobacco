/**
 * Created by christellejoseph on 11/5/20.
 */

trigger GT_LicenseUploadNotification on ContentDocumentLink (after insert){

	Messaging.reserveSingleEmailCapacity(2);
	Messaging.SingleEmailMessage emailApprover = new Messaging.SingleEmailMessage();
	Messaging.SingleEmailMessage emailASM = new Messaging.SingleEmailMessage();


	Environment_Variable__mdt approverEmail = [SELECT Email__c FROM Environment_Variable__mdt WHERE DeveloperName = 'licenseApprover' ];


	List<User> users = [SELECT id, email From User where email =:String.valueOf(approverEmail.Email__c)];
	Id approverUserId;

	System.debug('users ' + users);

		if(users.size() == 1){
			System.debug('size' + users.size() );
			for(User u: users){
				approverUserId = u.Id;
			}
		}


	String [] toAddresses = new String[] {};
	String [] ccAddresses = new String[] {};

	List<ContentDocumentLink> conDocLinks = ( Trigger.new == null ? Trigger.old : Trigger.new );
	Set<Id> accountIds = new Set<Id>();
	Set<Id> docIds = new Set<Id>();

	for ( ContentDocumentLink cdl : conDocLinks ) {
		accountIds.add( cdl.LinkedEntityId );
		docIds.add( cdl.ContentDocumentId);
		}

	Map<Id,ContentDocumentLink> DocByAccount = new Map<Id,ContentDocumentLink>();
	for (ContentDocumentLink cdlIterator : [SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.Title, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId IN :accountIds AND ContentDocumentId IN :docIds]) {
		 if(cdlIterator.ContentDocument.Title.startsWithIgnoreCase('License')){
			 DocByAccount.put(cdlIterator.LinkedEntityId, cdlIterator);
		 }
	}

	List<Account> updateField = new List<Account>();
	List<FeedItem> postFeed = new List<FeedItem>();

	for (List<Account> accounts : [ SELECT Id, Name, Account__c,( SELECT Id,  ContentDocument.Title, ContentDocument.OwnerId FROM ContentDocumentLinks WHERE  ContentDocument.Title LIKE 'License%' LIMIT 1) FROM Account WHERE Id IN :DocByAccount.keySet()]){ //WHERE  ContentDocument.Title LIKE 'License%'
		for ( Account a : accounts ) {
			for( ContentDocumentLink c: a.ContentDocumentLinks){
				if(!a.Account__c.startsWithIgnoreCase('GT') && c.ContentDocument.Title.startsWithIgnoreCase('License')){
					a.License_Updated__c = date.today();
					a.License_status__c = 'Pending Approval';
					toAddresses.add(String.valueOf(approverEmail.Email__c));
					ccAddresses.add(c.ContentDocument.OwnerId);
					emailApprover.setToAddresses(toAddresses);
					emailApprover.setCcAddresses(ccAddresses);
					emailApprover.setSubject('License Upload on ' + a.Name);
					emailApprover.setHtmlBody('The following licenses has been uploaded for your approval. '+
							'Please complete the approval in Great Plains. ' + '<br/>' +
							+ '<br/>' +
							'File Name: ' + c.ContentDocument.Title  + '<br/>' +
							'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view');
					updateField.add(a);
					Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailApprover });

					FeedItem AsmPost = new FeedItem(
							ParentId = c.ContentDocument.OwnerId,
							Body = 'The following licenses has been uploaded for your approval. '+
							'Please complete the approval in Great Plains. ' + '\n' +
							+ '\n' +
							'File Name: ' + c.ContentDocument.Title  + '\n' +
							'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view'
					);

					postFeed.add(AsmPost);

					if(approverUserId !=null){
						FeedItem ApproverPost = new FeedItem(
								ParentId = approverUserId,
								Body = 'The following licenses has been uploaded for your approval. '+
										'Please complete the approval in Great Plains. ' + '\n' +
										+ '\n' +
										'File Name: ' + c.ContentDocument.Title  + '\n' +
										'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view'
						);
						postFeed.add(ApproverPost);
					}

				}
				else if(a.Account__c.startsWithIgnoreCase('GT') && c.ContentDocument.Title.startsWithIgnoreCase('License')){
					toAddresses.add(c.ContentDocument.OwnerId);
					emailASM.setToAddresses(toAddresses);
					emailASM.setSubject('Licenses Uploaded To A Non-Great Plains account ');
					emailASM.setHtmlBody('The following licenses has been uploaded to a non-Great '+
							'Plains account. License approvals must be loaded onto GP accounts only. '+
							'Please review and ensure this was uploaded to the correct account.' + '<br/>' +
							'For additional questions, please contact the analytics team.' + '<br/>' +
							+ '<br/>' +
							'File Name: ' + c.ContentDocument.Title  + '<br/>' +
							'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view');
					Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailASM });

					FeedItem AsmPostGT = new FeedItem(
							ParentId = c.ContentDocument.OwnerId,
							Body = 'The following licenses has been uploaded for your approval. '+
									'Please complete the approval in Great Plains. ' + '\n' +
									+ '\n' +
									'File Name: ' + c.ContentDocument.Title  + '\n' +
									'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view'
					);

					postFeed.add(AsmPostGT);
				}
			}
		}
	}
	update updateField;
	insert postFeed;
}