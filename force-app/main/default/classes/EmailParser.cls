public class EmailParser {
    
    public static void parseAndSetPicklistFromEmail(Case caseRecord, String emailBody) {
        // Query custom metadata for both Priority and Service
        List<Keyword__mdt> customerMetadataList = [
            SELECT DeveloperName, MasterLabel, KeywordList__c, Type__c 
            FROM Keyword__mdt 
            WHERE Type__c IN ('Priority', 'Service')
        ];
        
        // Normalize the email body to lowercase
        String emailBodyLower = emailBody != null ? emailBody.toLowerCase() : '';
        System.debug('emailBody ==> ' + emailBodyLower);
        
        // Initialize maps for Priority and Service
        Map<String, List<String>> priorityKeywordsMap = new Map<String, List<String>>();
        Map<String, List<String>> serviceKeywordsMap = new Map<String, List<String>>();
        
        // Populate the maps based on Type__c
        for (Keyword__mdt metadata : customerMetadataList) {
            if (metadata.KeywordList__c != null) {
                // Split the keywords and trim whitespace
                List<String> keywords = metadata.KeywordList__c.split(',');
                // Add keywords to the appropriate map
                if (metadata.Type__c == 'Priority') {
                    priorityKeywordsMap.put(metadata.MasterLabel.toLowerCase(), keywords);
                    System.debug('Added to Priority Map: ' + metadata.DeveloperName + ' => ' + keywords);
                } else if (metadata.Type__c == 'Service') {
                    serviceKeywordsMap.put(metadata.MasterLabel.toLowerCase(), keywords);
                    System.debug('Added to Service Map: ' + metadata.DeveloperName + ' => ' + keywords);
                }
            }
        }
        
        // Initialize variables to store matched values
        String priorityValue = '';
        String serviceValue = '';
        
        // Check for Priority matches
        for (String key : priorityKeywordsMap.keySet()) {
            List<String> keywords = priorityKeywordsMap.get(key);
            System.debug('Checking Priority Key: ' + key + ' with keywords: ' + keywords);
            for (String keyword : keywords) {
                System.debug('Priority Keyword: ' + keyword);
                if (emailBodyLower.contains(keyword.toLowerCase().trim())) {
                    priorityValue = key;
                    System.debug('Matched Priority Value: ' + priorityValue);
                    break;
                }
            }        }
        
        // Check for Service matches
        for (String key : serviceKeywordsMap.keySet()) {
            List<String> keywords = serviceKeywordsMap.get(key);
            System.debug('Checking Service Key: ' + key + ' with keywords: ' + keywords);
            for (String keyword : keywords) {
                System.debug('Service Keyword: ' + keyword);
                if (emailBodyLower.contains(keyword.toLowerCase().trim())) {
                    serviceValue = key;
                    System.debug('Matched Service Value: ' + serviceValue);
                    break;
                }
            }
        }
        
        // Set values in the Case record
        System.debug('Final Priority Value: ' + priorityValue);
        if (String.isNotBlank(priorityValue)) {
            caseRecord.Priority = priorityValue;
        } else {
            // Set default priority to 'Regular' if no keywords matched
            caseRecord.Priority = 'Regular';
            System.debug('No matching keywords found, setting priority to Regular' );
        }
        
        System.debug('Final Service Value: ' + serviceValue);
        if (String.isNotBlank(serviceValue)) {
            caseRecord.Service__c = serviceValue;
        }else {
            // Set default service to 'General Inquiry' if no keywords matched
            caseRecord.Service__c = 'General Inquiry';
            System.debug('No matching keywords found, setting service to General Inquiry' );
        }
        
    }
}