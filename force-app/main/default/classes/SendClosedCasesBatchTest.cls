/** 
    @author: Ashapriya Gadi
    @description: This is used to test SendClosedCasesBatch batch class
					
*/
@isTest
public class SendClosedCasesBatchTest {

    /** 
        @description: set the mock data in the testsetup method. Create 100 cases because that will be the scope of the batch class
                        
    */
    @testSetUp
    private static void setUp(){
        List<Case> lst = new List<Case>();
        for(Integer i=0 ;i <100;i++){
        	Case c = new case(status='Open');
          	lst.add(c);  
        }
        insert lst ;
    }
    
    /** 
    @description: Update all the cases to closed and test the success outcome of the mock API 
					
	*/
    @isTest
    public static void testCaseUpdate() {
        Test.setMock(HttpCalloutMock.class, new CaseClosedMockResponse(true)); 
        List<Case> lst = new List<Case>();
        for(case c: [Select id, status from case limit 100]) {
            c.status = 'Closed';
            lst.add(c);  
        }
        update lst;
        Test.startTest();
       	SendClosedCasesBatch bt = new SendClosedCasesBatch();
		Database.executeBatch(bt,100);
        Test.stopTest();
        case cs = [Select Secret_Key__c from case limit 1];
        system.assertEquals('secret key', cs.Secret_Key__c);
    }
    
    /** 
    @description: Update all the cases to closed and test the failure outcome of the mock API 
					
	*/
    @isTest
    public static void testCaseUpdateError() {
        Test.setMock(HttpCalloutMock.class, new CaseClosedMockResponse(false)); 
        List<Case> lst = new List<Case>();
        for(case c: [Select id, status from case limit 100]) {
            c.status = 'Closed';
            lst.add(c);  
        }
        update lst;
        Test.startTest();
       	SendClosedCasesBatch bt = new SendClosedCasesBatch();
		Database.executeBatch(bt,100);
        Test.stopTest();
        case cs = [Select Secret_Key__c from case limit 1];
        system.assertEquals(null, cs.Secret_Key__c);
    }

}