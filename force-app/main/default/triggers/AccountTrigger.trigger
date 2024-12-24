trigger AccountTrigger on Account (before insert, before update) {
    // Collect all relevant field values from the trigger context
    Map<String, Set<String>> fieldValuesToCheck = new Map<String, Set<String>>();
    fieldValuesToCheck.put('Phone', new Set<String>());
    fieldValuesToCheck.put('PersonEmail', new Set<String>());
    fieldValuesToCheck.put('BusinessEmail__c', new Set<String>());

    // Prepare to store duplicates
    Map<Id, String> duplicateErrors = new Map<Id, String>();

    // Collect values for new and updated records
    for (Account acc : Trigger.new) {
        if (acc.Phone != null) fieldValuesToCheck.get('Phone').add(acc.Phone);
        if (acc.PersonEmail != null) fieldValuesToCheck.get('PersonEmail').add(acc.PersonEmail);
        if (acc.BusinessEmail__c != null) fieldValuesToCheck.get('BusinessEmail__c').add(acc.BusinessEmail__c);
    }

    // Query for possible duplicates
    List<Account> duplicates = [
        SELECT Id, Phone, PersonEmail, BusinessEmail__c
        FROM Account
        WHERE Phone IN :fieldValuesToCheck.get('Phone') OR
              PersonEmail IN :fieldValuesToCheck.get('PersonEmail') OR
              BusinessEmail__c IN :fieldValuesToCheck.get('BusinessEmail__c')
    ];

    // Cross-check duplicates and add errors
   for (Account duplicate : duplicates) {
    for (Account acc : Trigger.new) {
        if (Trigger.isInsert || Trigger.oldMap.get(acc.Id) != null) {
            // Initialize a list to hold error messages
            List<String> errorMessages = new List<String>();

            // Check for duplicate phone number
            if (duplicate.Phone != null && duplicate.Phone == acc.Phone) {
                errorMessages.add('An account with the same phone number already exists.');
            }
            // Check for duplicate personal email
            if (duplicate.PersonEmail != null && duplicate.PersonEmail == acc.PersonEmail) {
                errorMessages.add('An account with the same personal email already exists.');
            }
            // Check for duplicate business email
            if (duplicate.BusinessEmail__c != null && duplicate.BusinessEmail__c == acc.BusinessEmail__c) {
                errorMessages.add('An account with the same business email already exists.');
            }

            // Combine messages if there are any
            if (!errorMessages.isEmpty()) {
                String combinedMessage = String.join(errorMessages, ' ');
                duplicateErrors.put(acc.Id, combinedMessage);
            }
        }
    }
}

    // Add errors to accounts
    for (Account acc : Trigger.new) {
        if (duplicateErrors.containsKey(acc.Id)) {
            acc.addError(duplicateErrors.get(acc.Id));
        }
    }
}