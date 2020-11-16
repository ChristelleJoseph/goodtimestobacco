/**
 * Created by christellejoseph on 11/5/20.
 */

trigger GT_LicenseUploadNotification on ContentDocumentLink (after insert){

	Messaging.reserveSingleEmailCapacity(2);
	Messaging.SingleEmailMessage emailApprover = new Messaging.SingleEmailMessage();
	Messaging.SingleEmailMessage emailASM = new Messaging.SingleEmailMessage();


	Environment_Variable__mdt approverEmail = [SELECT Email__c FROM Environment_Variable__mdt WHERE DeveloperName = 'TMAApprover' ];

	String [] toAddresses = new String[] {String.valueOf(approverEmail.Email__c)};
	System.debug('address' + toAddresses);

	List<ContentDocumentLink> conDocLinks = ( Trigger.new == null ? Trigger.old : Trigger.new );
	Set<Id> parentIds = new Set<Id>();

	for ( ContentDocumentLink cdl : conDocLinks ) {
		parentIds.add( cdl.LinkedEntityId );
	}
	List<Account> updateField = new List<Account>();
	for ( List<Account> accounts : [ SELECT Id,Name,Account__c,( SELECT Id,  ContentDocument.Title FROM ContentDocumentLinks LIMIT 1 ) FROM Account WHERE Id IN :parentIds] ) {
		for ( Account a : accounts ) {
			for( ContentDocumentLink c: a.ContentDocumentLinks){
				if(!a.Account__c.startsWithIgnoreCase('GT')){
					a.License_Updated__c = date.today();
					a.License_status__c = 'Pending Approval';
					emailApprover.setToAddresses(toAddresses);
					emailApprover.setSubject('License Upload on ' + a.Name);
					//emailApprover.setPlainTextBody('The Account: ' + a.Name +' has a new license upload .');
					emailApprover.setHtmlBody('The following licenses has been uploaded for your approval. '+
							'Please complete the approval in Great Plains. ' + '<br/>' +
							'File Name: ' + c.ContentDocument.Title +
							'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view');
					System.debug('validate true' + a.Id);
					updateField.add(a);
					Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailApprover });
				}else{
					emailASM.setToAddresses(toAddresses);
					emailASM.setSubject('Licenses Uploaded To A Non-Great Plains account ');
					//emailASM.setPlainTextBody('The Account: ' + a.Name +' has a new license upload .');
					emailASM.setHtmlBody('The following licenses has been uploaded to a non-Great '+
							'Plains account. License approvals must be loaded onto GP accounts only.'+
							'Please review and ensure this was uploaded to the correct account.' +
							'For additional questions, please contact the analytics team.' + '<br/>' +
							'\n'+
							'File Name: ' + c.ContentDocument.Title +
							'Account: https://goodtimestobacco12345--roidev1.lightning.force.com/lightning/r/Account/'+a.Id+'/view');
					Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailASM });
				}
			}
		}
	}
	update updateField;
}