/**
 * Created by christellejoseph on 11/15/20.
 */
@isTest
public with sharing class GT_LicenseUploadNotificationTest
{

	static testmethod void testNonGTLicenseUpload(){
		Test.startTest();
		Account acct = new Account(
				Name='License_345',
				Account__c ='LU1234'
		);
		insert acct;

		ContentVersion contentVersion = new ContentVersion(
				Title = 'PDF_NonGT',
				PathOnClient = 'PDF.pdf',
				VersionData = Blob.valueOf('Test Content'),
				IsMajorVersion = true
		);
		insert contentVersion;
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = acct.id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		insert cdl;

		Test.stopTest();

	}

	static testmethod void testGTLicenceUpload(){
		Test.startTest();
		Account acct = new Account(
				Name='License_123',
				Account__c ='GT1234'
		);
		insert acct;

		ContentVersion contentVersion = new ContentVersion(
				Title = 'PDF_GT',
				PathOnClient = 'PDF.pdf',
				VersionData = Blob.valueOf('Test Content'),
				IsMajorVersion = true
		);
		insert contentVersion;

		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = acct.id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		insert cdl;

		Test.stopTest();

	}

}