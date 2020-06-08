# This is a project commisioned by Mark Crawford on behald of Good Time Tabacco Company - 06/05/2020

#setup SFDX

#create Project Stucture
sfdx force:project:create -n TradeMarketing

#create scratch org
sfdx force:org:create -s -f config/project-scratch-def.json -a TradeMarketingForm -d 30

#mdapi-componet
sfdx force:mdapi:retrieve -r mdapi-components/ -k mdapi-components/package.xml -u goodtimestobacco

unzip mdapi-components/unpackaged.zip -d mdapi-components/

sfdx force:mdapi:convert -r mdapi-components/unpackaged/ -d force-app/

#export Data
sfdx force:data:tree:export -q "select Name, StockKeepingUnit, QuantityUnitOfMeasure, Sticks_Per_Display__c, IsActive, Discontinued__c, DisplayUrl, Displays_In_Case__c, Is_Loose_Product__c, Item_Class__c, Item_Class_Desc__c, Item_Desc__c, Item_Num__c, Item_Status__c, Product_Brand__c, ProductCode, Description, Family From Product2 -d ./data

sfdx force:data:tree:import --sobjecttreefiles data/Product2.json


#Relevant APEX Classes & VF Code
GT_PriceTrackingClass
GT_PriceTrackingTest

#Files to use
GT_TMARecapClass.apxc
GT_TMARecapForm.vf

#Relavant Objects
Account
Order
Order Product
User
Trade_Marketing_Agreement__c
Trade_Marketing_Agreement_Line_Item__c
Trade_Marketing_Agreement_Promotion__c


