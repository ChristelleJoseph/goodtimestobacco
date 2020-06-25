<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Request_Form_Email_Alert</fullName>
        <description>Request Form Email Alert</description>
        <protected>false</protected>
        <recipients>
            <field>Send_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Request_Form_Email_Template</template>
    </alerts>
</Workflow>
