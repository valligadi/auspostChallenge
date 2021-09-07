/** 
    @author: Ashapriya Gadi
    @description: The batch is used to send the closed cases along with the agent who closed the case, to the API and get the secret key back 
					from the API to populate Secret_Key__c on each case. 
*/
public with sharing class SendClosedCasesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        //query for cases that are closed and are not updated with secret key, to pass to API
        String query = 'SELECT Id, status, Secret_Key__c,userWhoClosed__c ';
        query += 'From case ';
        query += 'Where status = \'Closed\' AND Secret_Key__c = null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Case> scope)
    {
        List<Case> updateList = new List<Case>();
        try{
            //for each case, we need to call the API because API is not bulkified to accept a list of cases.
            for(Case caseRec : scope)
            {
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://nfapihub.herokuapp.com');
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                req.setTimeout(2000);//set the timeout according to api timeout. can be upto 120s
                String sJSON = '{"id":"'+caseRec.id+'","agentid":"'+caseRec.userWhoClosed__c+'"}';
                req.setBody(sJSON);
                HttpResponse res = h.send(req);
                if (res.getStatusCode() == 200) {
                    caseResponse myResponse = (caseResponse) JSON.deserialize(res.getBody(), caseResponse.class);
                    String key = (String) myResponse.secretKey;
                    System.debug('resp key>'+key);
                    case c = new case(id=caseRec.id);
                    c.Secret_Key__c = key;
                    updateList.add(c);
                } 
            }
            
            if(!updateList.isEmpty()){
                update updateList;
            }
        		
            
            }catch(System.CalloutException e) {
                    System.debug('Callout error: '+ e.getmessage());
             }

    }
    public class caseResponse {
        public string succ ;
        public string secretKey ;
    } 
	/** 
    @description: Use the finish method to finally send an email to the job creator with the batch job details
					
	*/
    public void finish(Database.BatchableContext BC)
    {	
      	AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email
                          FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Batch to pass closed cases to API ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed: ' + a.TotalJobItems +
                              ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        if(!Test.isRunningTest()){//schedule the batch by the end of first batch run after 30 minutes(can change this) and bypass this in test class. The scope is 100 as we are allowed only 100 callouts
            system.scheduleBatch(new SendClosedCasesBatch(), 'Closed cases', 30, 100);
        }
    }

}