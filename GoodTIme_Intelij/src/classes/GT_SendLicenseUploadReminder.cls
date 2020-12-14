global class GT_SendLicenseUploadReminder implements Database.Batchable<ContentDocumentLink>
{
	global class CustomIterable implements iterable<ContentDocumentLink>{
		global Iterator<ContentDocumentLink> Iterator(){
			return new CustomIterator();
		}
	}
	global Iterable<ContentDocumentLink> start(Database.BatchableContext bc)
	{
		return new CustomIterable();

	}

	public void execute(Database.BatchableContext bc, List<ContentDocumentLink> scope)
	{
		List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
		List<FeedItem> postFeed = new List<FeedItem>();

		Messaging.reserveSingleEmailCapacity(2);
		Messaging.SingleEmailMessage mail;

		Environment_Variable__mdt approverEmail = [SELECT Email__c FROM Environment_Variable__mdt WHERE DeveloperName = 'licenseApprover' ];

		System.debug('approverEmail' + approverEmail);

		List<User> users = [SELECT id, email From User where email =:String.valueOf(approverEmail.Email__c)];
		Id approverUserId;

		System.debug('users ' + users);

		if(users.size() == 1){
			System.debug('size' + users.size() );
			for(User u: users){
				approverUserId = u.Id;
			}

			System.debug('approverUserId ' + approverUserId);
		}

		String [] toAddresses = new String[] {String.valueOf(approverEmail.Email__c)};

		Map<Id, Id> accountByUser = new Map<Id, Id>();

		Set<Id> accountIds = new Set<Id>();

		for (ContentDocumentLink cdl: scope)
		{
			accountByUser.put(cdl.LinkedEntityId, cdl.ContentDocument.OwnerId);
			accountIds.add( cdl.LinkedEntityId );
		}

		List<Account> acc = [ SELECT Id, Name, Account__c, License_Updated__c ,(SELECT Id, ContentDocument.Title FROM ContentDocumentLinks WHERE  ContentDocument.Title LIKE 'License%') FROM Account WHERE Id IN :accountIds];//WHERE  ContentDocument.Title LIKE 'License%'
		System.debug('acc' + acc);

			Integer MultipleOfThreeCheck;
			for ( Account a : acc ) {
				for( ContentDocumentLink c: a.ContentDocumentLinks){
					if(!a.Account__c.startsWithIgnoreCase('GT') && a.License_Updated__c.day() != date.today().day()){
						MultipleOfThreeCheck =  Date.today().day() - a.License_Updated__c.day();
						if(math.mod(MultipleOfThreeCheck,3) == 0){
							System.debug('true');
							toAddresses.add(accountByUser.get(a.Id));
							mail = new Messaging.SingleEmailMessage();
							mail.setToAddresses(toAddresses);
							mail.setSubject('License Approval Reminder On ' + a.Name + ' Account');
							mail.setPlainTextBody('The following license has been uploaded for your approval.\n '+
									'Please complete the approval in Great Plains.\n' +
									'\n'+
									'File Name: ' + c.ContentDocument.Title + '\n'+
									'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view');


							if(approverUserId !=null)
							{
								System.debug('not null');
								FeedItem PostApprover = new FeedItem(
										ParentId = approverUserId,
										Body = 'The following license has been uploaded for your approval.\n ' +
												'Please complete the approval in Great Plains.\n' +
												'\n' +
												'File Name: ' + c.ContentDocument.Title + '\n' +
												'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/' + a.Id + '/view'
								);
								postFeed.add(PostApprover);
							}

							FeedItem PostASM = new FeedItem(
									ParentId = accountByUser.get(a.Id),
									Body = 'The following license has been uploaded for your approval.\n '+
											'Please complete the approval in Great Plains.\n' +
											'\n'+
											'File Name: ' + c.ContentDocument.Title + '\n'+
											'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view'
							);

							postFeed.add(PostASM);
							lstEmail.add(mail);

						}
					}
				}

			}

		Messaging.sendEmail(lstEmail);
		insert postFeed;

	}

	public void finish(Database.BatchableContext bc)
	{
	}
}
