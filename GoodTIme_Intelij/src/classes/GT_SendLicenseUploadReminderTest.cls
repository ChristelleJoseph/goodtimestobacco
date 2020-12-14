/**
 * Created by christellejoseph on 11/15/20.
 */

@isTest
public with sharing class GT_SendLicenseUploadReminderTest
{
	static testMethod void testBatchNotificationProcess()
	{

		Account acct = new Account(
				Name='TEST_ACCT',
				Account__c ='LU1234',
				License_Updated__c = Date.today() - 3,
				License_Status__c = 'Pending Approval'
		);
		insert acct;
		Account acct2 = new Account(
				Name='TEST_ACCT',
				Account__c ='LUP1234',
				License_Updated__c = Date.today() - 3,
				License_Status__c = 'Approved'
		);
		insert acct2;

		ContentVersion contentVersion = new ContentVersion(
				Title = 'PDF',
				PathOnClient = 'PDF.pdf',
				VersionData = Blob.valueOf('Test Content'),
				IsMajorVersion = true
		);
		insert contentVersion;

		ContentVersion contentVersion2 = new ContentVersion(
				Title = 'PDF',
				PathOnClient = 'PDF.pdf',
				VersionData = Blob.valueOf('Test Content'),
				IsMajorVersion = true
		);
		insert contentVersion2;

		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = acct.id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		insert cdl;

		List<ContentDocument> documents2 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		ContentDocumentLink cdl2 = New ContentDocumentLink();
		cdl2.LinkedEntityId = acct2.id;
		cdl2.ContentDocumentId = documents2[0].Id;
		cdl2.shareType = 'V';
		insert cdl2;

		Test.startTest();
		GT_SendLicenseUploadReminder obj = new GT_SendLicenseUploadReminder();
		DataBase.executeBatch(obj);
		Test.stopTest();
	}
}