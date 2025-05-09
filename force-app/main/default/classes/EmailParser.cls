public class EmailParser {
    
    public static void parseAndSetPicklistFromEmail(Case caseRecord, String emailBody, String emailSubject) {
        try{
            System.debug('Starting parseAndSetPicklistFromEmail method.');
            // Query custom metadata for Priority, Service, and Location
            List<Keyword__mdt> customerMetadataList = [
                SELECT DeveloperName, MasterLabel, KeywordList__c, Type__c 
                FROM Keyword__mdt 
                WHERE Type__c IN ('Priority', 'Service', 'Location')
            ];
            
            // Normalize the email body and subject to lowercase
            String emailContentLower = ((emailBody != null ? emailBody : '') + 
                                        (emailSubject != null ? ' ' + emailSubject : '')).toLowerCase(); 
            
            System.debug('Normalized Email Content: ' + emailContentLower);
            
            // Initialize maps for Priority, Service, and Location
            Map<String, List<String>> priorityKeywordsMap = new Map<String, List<String>>();
            Map<String, List<String>> serviceKeywordsMap = new Map<String, List<String>>();
            Map<String, List<String>> locationKeywordsMap = new Map<String, List<String>>();
            
            // Populate the maps based on Type__c
            for (Keyword__mdt metadata : customerMetadataList) {
                if (metadata.KeywordList__c != null) {
                    List<String> keywords = metadata.KeywordList__c.split(',');
                    if (metadata.Type__c == 'Priority') {
                        priorityKeywordsMap.put(metadata.MasterLabel.toLowerCase(), keywords);
                        //System.debug('Priority Keywords: ' + metadata.MasterLabel + ' => ' + keywords);
                    } else if (metadata.Type__c == 'Service') {
                        serviceKeywordsMap.put(metadata.MasterLabel.toLowerCase(), keywords);
                        //System.debug('Service Keywords: ' + metadata.MasterLabel + ' => ' + keywords);
                    } else if (metadata.Type__c == 'Location') {
                        locationKeywordsMap.put(metadata.MasterLabel.toLowerCase(), keywords);
                        //System.debug('Location Keywords: ' + metadata.MasterLabel + ' => ' + keywords);
                    }
                }
            }
            
            // Initialize variables to store matched values
            String priorityValue = '';
            List<String> serviceValues = new List<String>();
            List<String> locationValues = new List<String>();
            
                    // Check for Priority matches
                        /*String emailcontentPrioKeywordVal = ((emailBody != null ? emailBody : '') + 
                            (emailSubject != null ? ' ' + emailSubject : ''))
                            .split('and')[0].trim(); */
            
            for (String key : priorityKeywordsMap.keySet()) {            
                List<String> keywords = priorityKeywordsMap.get(key);
                System.debug('Checking Priority Key: ' + key + ' with keywords: ' + keywords);
                for (String keyword : keywords) {
                    System.debug('Priority Keyword: ' + keyword);
                            // Saurabh
                            /* if(keyword.equalsIgnoreCase(emailcontentPrioKeywordVal)){
                                priorityValue = key;
                                System.debug('Matched Priority Value: ' + priorityValue);
                                break;
                                }*/
                            // Saurabh                
                    
                    if (emailContentLower.contains(keyword.toLowerCase().trim())) {
                        priorityValue = key;
                        System.debug('Matched Priority Value: ' + priorityValue);
                        break;
                    }
                }
                if(!String.isBlank(priorityValue))
                    break;
            }
            
            
            
            // Check for Service matches
            for (String key : serviceKeywordsMap.keySet()) {
                System.debug('Checking Service Key: ' + key);
                for (String keyword : serviceKeywordsMap.get(key)) {
                    // Match whole word with boundaries
                    String normalizedKeyword = keyword.toLowerCase().trim();
                    String regex = '\\b' + Pattern.quote(normalizedKeyword) + '\\b'; 
                    if (Pattern.compile(regex).matcher(emailContentLower).find()) {
                        serviceValues.add(key);
                        //System.debug('Matched Service Keyword: ' + keyword + ' => Service Value: ' + key);
                        break;
                    }
                }
            }
            
            // Check for Location matches
            for (String key : locationKeywordsMap.keySet()) {
                System.debug('Checking Location Key: ' + key);
                for (String keyword : locationKeywordsMap.get(key)) {
                    // Match whole word with boundaries
                    String normalizedKeyword = keyword.toLowerCase().trim();
                    String regex = '\\b' + Pattern.quote(normalizedKeyword) + '\\b'; 
                    if (Pattern.compile(regex).matcher(emailContentLower).find()) {
                        locationValues.add(key);
                        // System.debug('Matched Location Keyword: ' + keyword + ' => Location Value: ' + key);
                        break;
                    }
                }
            }
            
            // Set values in the Case record
            System.debug('Final Priority Value: ' + priorityValue);
            if (String.isNotBlank(priorityValue)) {
                caseRecord.Priority = priorityValue;
            } else {
                caseRecord.Priority = 'Low';
                System.debug('No matching Priority keywords found, setting default Priority: Low');
            }
            
            System.debug('Final Service Values: ' + serviceValues);
            if (!serviceValues.isEmpty()) {
                caseRecord.Services__c = String.join(serviceValues, ';');
            } 
            System.debug('Final Location Values: ' + locationValues);
            if (!locationValues.isEmpty()) {
                caseRecord.Location__c = String.join(locationValues, ';');
            }
            
            // Extract phone number from email content
            String phoneNumber = extractPhoneNumber(emailContentLower);
            if (phoneNumber != null) {
                caseRecord.SuppliedPhone = phoneNumber;
                System.debug('Extracted Phone Number: ' + phoneNumber);
            }
        } catch (Exception e) {
            System.debug('Error occurred in parseAndSetPicklistFromEmail method: ' + e.getMessage());
        }
    }
    
    private static String extractPhoneNumber(String text) {
        System.debug('Extracting phone number from text: ' + text);
        //Pattern phonePattern = Pattern.compile('(?:\\+\\d{1,3}[-.\\s]?)?\\(?\\d{1,4}\\)?[-.\\s]?\\d{1,4}[-.\\s]?\\d{1,9}');
        //Pattern phonePattern = Pattern.compile('(?=(?:\\D*\\d){10,})(?:\\+\\d{1,3}[-.\\s]?)?\\(?\\d{1,4}\\)?[-.\\s]?\\d{1,4}[-.\\s]?\\d{1,9}');
        Pattern phonePattern = Pattern.compile('\\b\\d{10,}\\b');
        Matcher matcher = phonePattern.matcher(text);
        if (matcher.find()) {
            System.debug('Phone number found (10 digits): ' + matcher.group());
            return matcher.group();
        }
        
        // If no continuous digits are found, check for more complex formats
        phonePattern = Pattern.compile('(?:\\+?\\d{1,3}[-.\\s]?)?(?:\\(?\\d{1,4}\\)?[-.\\s]?\\d{1,4}[-.\\s]?\\d{1,9})|\\b\\d{10,}\\b');
        matcher = phonePattern.matcher(text);
        if (matcher.find()) {
            System.debug('Phone number found (with separators): ' + matcher.group());
            return matcher.group();
        }
        System.debug('No phone number found.');
        return null;
    }
}