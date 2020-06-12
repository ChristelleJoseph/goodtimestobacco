@isTest
private class TaskTriggerHandler_Test {
    @isTest
    public static void TaskTriggerHandler() {
        User analyst = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
     		LastName = 'ANlast',
     		Email = 'ANpuser000@amamama.com',
     		Username = 'ANpuser000@amamama.com' + System.currentTimeMillis(),
     		CompanyName = 'ANTEST',
     		Title = 'ANtitle',
     		Alias = 'AN',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US'
        ); 
		insert analyst;
        
        User supervisor = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
     		LastName = 'SUPlast',
     		Email = 'SUPpuser000@amamama.com',
     		Username = 'SUPpuser000@amamama.com' + System.currentTimeMillis(),
     		CompanyName = 'SUPTEST',
     		Title = 'SUPtitle',
     		Alias = 'SUP',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US'
        );
        insert supervisor;
        
        User supervisor2 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
     		LastName = 'SUP2last',
     		Email = 'SUP2puser000@amamama.com',
     		Username = 'SUP2puser000@amamama.com' + System.currentTimeMillis(),
     		CompanyName = 'SUP2TEST',
     		Title = 'SUP2title',
     		Alias = 'SUP2',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US'
        );
        insert supervisor2;
        
        User supervisor3 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
     		LastName = 'SUP3last',
     		Email = 'SUP3puser000@amamama.com',
     		Username = 'SUP3puser000@amamama.com' + System.currentTimeMillis(),
     		CompanyName = 'SUP3TEST',
     		Title = 'SUP3title',
     		Alias = 'SUP3',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US'
        );
        insert supervisor3;
        
        User supervisor4 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
     		LastName = 'SUP4last',
     		Email = 'SUP4puser000@amamama.com',
     		Username = 'SUP4puser000@amamama.com' + System.currentTimeMillis(),
     		CompanyName = 'SUP4TEST',
     		Title = 'SUP4title',
     		Alias = 'SUP4',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US'
        );
        insert supervisor4;

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Custom'].Id,
     		LastName = 'last',
     		Email = 'puser000@amamama.com',
     		Username = 'puser000@amamama.com' + System.currentTimeMillis(),
     		CompanyName = 'TEST',
     		Title = 'title',
     		Alias = 'alias',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US',
            Supervisor__c = supervisor.Id,
            Supervisor_2__c = supervisor2.Id,
            Supervisor_3__c = supervisor3.Id,
            Supervisor_4__c = supervisor4.Id,
            analyst__c = analyst.Id
        ); 
        insert u;
    
         System.RunAs(u){            
         	Test.StartTest();  
           	
            Account acc = new Account(name='testAcc', account__c= '123456');
            insert acc;
            
            Contact con = new Contact(FirstName='John', LastName='Doe', email='none@none.com');
            insert con;
             
            Task tas= new Task(Subject='On-site Visit', WhatId=acc.Id, WhoId=con.id, Description='purpose of call test information', CallDisposition='Went well (results)');
            insert tas;
            system.assertEquals(1, [SELECT Id FROM Task].size());
             
			Integer invocations = Limits.getEmailInvocations();

        	Test.stopTest();
             
            system.assertEquals(1, invocations, 'An email should be sent');
        }
	}
}