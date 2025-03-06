public with sharing class OpportunityMetadataUpdater {

    @InvocableMethod(label='Update Opportunity Counter' description='Updates the Last Used Number in Custom Metadata')

    public static void updateCounter(List<Integer> newNumberList) {

        if (newNumberList.isEmpty()) {

            return;

        }

        Integer newNumber = newNumberList[0]; // Extract the number from Flow input

        // Create a Custom Metadata record

        Metadata.CustomMetadata customMetadataRecord = new Metadata.CustomMetadata();

        customMetadataRecord.fullName = 'Opportunity_Counter__mdt.Default_Counter';

        // Set the new value for Last Used Number

        Metadata.CustomMetadataValue newValue = new Metadata.CustomMetadataValue();

        newValue.field = 'Last_Used_Number__c';

        newValue.value = newNumber;

        customMetadataRecord.values.add(newValue);

        // Create a container for metadata deployment

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

        mdContainer.addMetadata(customMetadataRecord);

        try {

            // Deploy the metadata update asynchronously

            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);

            System.debug('Metadata update job enqueued. Job ID: ' + jobId);

        } catch (Exception e) {

            System.debug('Error updating Custom Metadata: ' + e.getMessage());

        }

    }

}