global class GT_SendLicenseUploadReminder implements Database.Batchable<ContentDocumentLink>
{
	global class CustomIterable implements iterable<ContentDocumentLink>{
		global Iterator<ContentDocumentLink> Iterator(){
			return new CustomIterator();
		}
	}
	global Iterable<ContentDocumentLink> start(Database.BatchableContext bc)
	{
		System.debug('start');
		return new CustomIterable();

	}

	public void execute(Database.BatchableContext bc, List<ContentDocumentLink> scope)
	{
		System.debug('in execute');
		Messaging.reserveSingleEmailCapacity(2);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		Environment_Variable__mdt approverEmail = [SELECT Email__c FROM Environment_Variable__mdt WHERE DeveloperName = 'TMAApprover' ];

		String [] toAddresses = new String[] {String.valueOf(approverEmail.Email__c)};

		Map<Id, Id> accountByUser = new Map<Id, Id>();

		for (ContentDocumentLink cdl: scope)
		{
			accountByUser.put(cdl.LinkedEntityId, cdl.ContentDocument.OwnerId);
		}

		Integer MultipleOfThreeCheck;
		for ( List<Account> accounts : [ SELECT Id, Name, Account__c, License_Updated__c ,(SELECT Id, ContentDocument.Title FROM ContentDocumentLinks LIMIT 1 ) FROM Account WHERE Id IN :accountByUser.keyset()]) {
			for ( Account a : accounts ) {
				for( ContentDocumentLink c: a.ContentDocumentLinks){
					if(!a.Account__c.startsWithIgnoreCase('GT')){
						MultipleOfThreeCheck =  Date.today().day() - a.License_Updated__c.day();
						System.debug('MultipleOfThreeCheck ' + MultipleOfThreeCheck);
						if(math.mod(MultipleOfThreeCheck,3) == 0){
							System.debug('in if statement');
							toAddresses.add(accountByUser.get(a.Id));
							mail.setToAddresses(toAddresses);
							mail.setSubject('License Approval Reminder');
							mail.setPlainTextBody('The following license has been uploaded for your approval.\n '+
									'Please complete the approval in Great Plains.\n' +
									'\n'+
									'File Name: ' + c.ContentDocument.Title + '\n'+
									'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view');
							Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
						}
					}
				}

			}
		}

	}

	public void finish(Database.BatchableContext bc)
	{
	}
}
