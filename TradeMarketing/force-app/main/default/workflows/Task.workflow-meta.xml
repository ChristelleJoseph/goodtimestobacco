<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Change_Subject</fullName>
        <field>Subject</field>
        <formula>TEXT(Subject__c)</formula>
        <name>Change Subject</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Change Subject For Log a Call</fullName>
        <actions>
            <name>Change_Subject</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Text(Subject__c)&lt;&gt;null</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WORKFLOW_TEST_SAM</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Task.OwnerId</field>
            <operation>equals</operation>
            <value>ABRAM JACOBSON</value>
        </criteriaItems>
        <description>WORKFLOW_TEST_SAM</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WORKFLOW_TEST_SAM1</fullName>
        <actions>
            <name>NEW_TASK</name>
            <type>Task</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Task.OwnerId</field>
            <operation>equals</operation>
            <value>Sam Saleh</value>
        </criteriaItems>
        <description>WORKFLOW_TEST_SAM</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <tasks>
        <fullName>NEW_TASK</fullName>
        <assignedTo>abram.jacobson@goodtimestobacco.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>TEST</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Task.CreatedDate</offsetFromField>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>NEW TASK</subject>
    </tasks>
</Workflow>
