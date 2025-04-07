@IsTest
public class DemoEmailUtilityTest {
    
    @isTest
    static void testSendEmailWithoutRecordId() {
        DemoEmailUtility.FlowInputs dEmailRcd = new DemoEmailUtility.FlowInputs();
        dEmailRcd.templateName='test email template';
        dEmailRcd.toAddresses='test123@yopmail.com';
        dEmailRcd.ccAddresses='test124@yopmail.com';
        dEmailRcd.bccAddresses='test125@yopmail.com';
        dEmailRcd.fromAddress='test.salesforce23@yopmail.com';
        dEmailRcd.recordId=null;
        dEmailRcd.Body='test body';
        dEmailRcd.Subject='test subject';
        
        Test.startTest();
        DemoEmailUtility.sendEmail(new List<DemoEmailUtility.FlowInputs>{dEmailRcd});
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailWithCase() {
        Case case1 = new Case(Status = 'New', TAT_Start__c = System.now().addDays(-1));
        insert case1;
        DemoEmailUtility.FlowInputs dEmailRcd = new DemoEmailUtility.FlowInputs();
        dEmailRcd.templateName='test email template';
        dEmailRcd.toAddresses='test123@yopmail.com';
        dEmailRcd.ccAddresses='test124@yopmail.com';
        dEmailRcd.bccAddresses='test125@yopmail.com';
        dEmailRcd.fromAddress='test.salesforce23@yopmail.com';
        dEmailRcd.recordId=case1.Id;
        dEmailRcd.Body='test body';
        dEmailRcd.Subject='test subject';
        
        Test.startTest();
        DemoEmailUtility.sendEmail(new List<DemoEmailUtility.FlowInputs>{dEmailRcd});
        Test.stopTest();
    }      
    @isTest
    static void testSendEmailWithLead() {
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Open'
            ,Email='testlead23@yopmail.com'
        );
        insert testLead;
        DemoEmailUtility.FlowInputs dEmailRcd = new DemoEmailUtility.FlowInputs();
        dEmailRcd.templateName='test email template';
        dEmailRcd.toAddresses='test123@yopmail.com';
        dEmailRcd.ccAddresses='test124@yopmail.com';
        dEmailRcd.bccAddresses='test125@yopmail.com';
        dEmailRcd.fromAddress='test.salesforce23@yopmail.com';
        dEmailRcd.recordId=testLead.Id;
        dEmailRcd.Body='test body';
        dEmailRcd.Subject='test subject';
        
        Test.startTest();
        DemoEmailUtility.sendEmail(new List<DemoEmailUtility.FlowInputs>{dEmailRcd});
        Test.stopTest();
    }      
    
}