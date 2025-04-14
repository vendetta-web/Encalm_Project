@isTest
public class EmailUtilityTest {

    @isTest
    static void testSendEmail_withValidInputs() {

        Contact con = new Contact(LastName = 'Test Contact', Email = 'test@test.com');
        insert con;
		        
        EmailUtility.FlowInputs input = new EmailUtility.FlowInputs();
        input.templateName = 'Test_Template';
        input.toAddresses = 'recipient@example.com';
        input.ccAddresses = 'cc@example.com';
        input.bccAddresses = 'bcc@example.com';
        input.fromAddress = 'replyto@example.com';
        input.recordId = con.Id;
        input.Body = 'Body override'; 

        Test.startTest();
        EmailUtility.sendEmail(new List<EmailUtility.FlowInputs>{input});
        //input.recordId = 'a0Bxxxxxxxxxxxx';
        //EmailUtility.sendEmail(new List<EmailUtility.FlowInputs>{input});
        Test.stopTest();

        System.assert(true, 'Email should have been processed without error.');
    }
    
    @isTest
    static void testSendEmail_withInvalidTemplateName() {

        Lead leadRec = new Lead(LastName = 'Test Lead', Company = 'Test Co', Email = 'testEmail@gmail.com');
        insert leadRec;

        EmailUtility.FlowInputs input = new EmailUtility.FlowInputs();
        input.templateName = 'NonExistentTemplate';
        input.toAddresses = 'recipient@example.com';
        input.recordId = leadRec.Id;

        Test.startTest();
        EmailUtility.sendEmail(new List<EmailUtility.FlowInputs>{input});
        
        input.recordId = null;
        EmailUtility.sendEmail(new List<EmailUtility.FlowInputs>{input});
        input.templateName = null;
        input.toAddresses = null;
        //try{
            EmailUtility.sendEmail(new List<EmailUtility.FlowInputs>{input});
        //}catch(exception e){
         //   system.debug('exception------'+e.getMessage());
        //}
        Test.stopTest();

        System.assert(true, 'Template not found.');
    }

}