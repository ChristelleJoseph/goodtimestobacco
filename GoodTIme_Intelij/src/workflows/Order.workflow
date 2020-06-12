<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>New_Order_Created</fullName>
        <description>New Order Created</description>
        <protected>false</protected>
        <recipients>
            <recipient>joseph@goodtimestobacco.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Order_Form_Email_Template</template>
    </alerts>
    <rules>
        <fullName>NEW ORDER CREATED</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Order.CreatedById</field>
            <operation>equals</operation>
            <value>Sam Saleh</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
