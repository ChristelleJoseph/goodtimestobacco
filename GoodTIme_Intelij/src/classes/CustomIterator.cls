

global class CustomIterator implements Iterator<ContentDocumentLink>{


	List<ContentDocumentLink> cdls {get; set;}
	Integer i {get; set;}

	public CustomIterator(){
		cdls =  [SELECT id,ContentDocumentId, ContentDocument.Title, ContentDocument.OwnerId, LinkedEntityId
		FROM ContentDocumentLink where LinkedEntityId
				IN (SELECT Id FROM Account Where License_Status__c = 'Pending Approval' AND (NOT Account__c LIKE 'GT%')) AND ContentDocument.Title LIKE 'License%'];
		i = 0;
	}

	global boolean hasNext(){
		if(i >= cdls.size()) {
		return false;
		} else {
		return true;
		}
	}

	global ContentDocumentLink next(){
		if(i == 8){return null;}
		i++;
		return cdls[i-1];
		}

}