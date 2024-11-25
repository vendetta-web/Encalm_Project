@IsTest
public class EmailParserTest {
    
    @IsTest
    static void testParseAndSetPicklistFromEmail() {
        // Create a test Case record
        Case testCase = new Case(
            Subject = 'Test Case Subject',
            Description = 'Test Case Description'
        );
        insert testCase;
        
        // Create a test email body
        String testEmailBody = 'This is a test email with a High priority and Sales Service.';
        
        // Call the method to be tested
        EmailParser.parseAndSetPicklistFromEmail(testCase, testEmailBody);
        
        // Retrieve the updated Case record
        Case updatedCase = [SELECT Id, Priority, Service__c FROM Case WHERE Id = :testCase.Id];
        
        // Assert the expected results
        System.assertEquals('High', updatedCase.Priority, 'Priority should be set to High');
        System.assertEquals('Sales', updatedCase.Service__c, 'Service should be set to Sales');
    }
}