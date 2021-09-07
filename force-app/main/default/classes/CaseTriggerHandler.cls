public class CaseTriggerHandler {
	public void run() {
            if(trigger.isAfter && trigger.isInsert) {
            }
            if(trigger.isAfter && trigger.isUpdate) {
                  afterUpdateHandler((List<Case>)trigger.new, (Map<Id,case>)trigger.oldMap);
            }

            if(trigger.isBefore && trigger.isInsert) {
            }
            if(trigger.isBefore && trigger.isUpdate) {
               
            }
    }
    /** 
    @author: Ashapriya Gadi
    @description: This method is used to populate the userWhoClosed__c field on case with lastmodifiedby user,
	*				immediately after it is closed to make sure that the right value is passed in SendClosedCasesBatch class to the API.
    */
     private void afterUpdateHandler(List<case> caseList, Map<Id,case> oldCaseMap) {
        try{
			List<Case> casesUpdate = new List<Case>();
			for(Case caseObj: caseList){
   			if(caseObj.Status != oldCaseMap.get(caseObj.id).Status && caseObj.Status == 'Closed' && caseObj.userWhoClosed__c ==null){
       			case c = new case(id=caseObj.id);
                c.userWhoClosed__c = caseObj.LastModifiedById;
                casesUpdate.add(c);
   			}
			}
            update casesUpdate;
           
        }
        catch(Exception ex){
            system.debug('ex '+ ex.getMessage()+' '+ex.getLineNumber());
        }
    }
    
}