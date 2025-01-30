public with sharing class MDEN_PdfAttachmentController {
    @AuraEnabled
    public static void createContentVersion(String recordId, String base64Data) {
        try {
            // Decode the Base64 PDF data
            Blob pdfBlob = EncodingUtil.base64Decode(base64Data);

            // Create ContentVersion to upload the file
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'Generated_PDF';
            contentVersion.PathOnClient = 'Generated_PDF.pdf';
            contentVersion.VersionData = pdfBlob;
            contentVersion.IsMajorVersion = true;

            // Insert ContentVersion
            insert contentVersion;

            // Get ContentDocumentId after insert
            ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

            // Create ContentDocumentLink to link the file to the record
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDocument.Id;
            contentDocumentLink.LinkedEntityId = recordId;  // Link to the record (Account, Opportunity, etc.)
            contentDocumentLink.ShareType = 'V';  // 'V' for Viewer access
            contentDocumentLink.Visibility = 'AllUsers';  // Can be 'AllUsers' or 'InternalUsers'

            // Insert the ContentDocumentLink to associate the file with the record
            insert contentDocumentLink;

            System.debug('File successfully attached to record');
        } catch (Exception e) {
            System.debug('Error while creating file: ' + e.getMessage());
            throw new AuraHandledException('Error while creating file: ' + e.getMessage());
        }
    }
}