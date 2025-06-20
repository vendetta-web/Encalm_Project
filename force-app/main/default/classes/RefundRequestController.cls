public class RefundRequestController {
    @AuraEnabled
    public static void createRefundRequest(String oppId){
        System.debug('createRefundRequest --oppId-->'+oppId);
        Decimal totalInvoiceAmt = 0;
        List<OpportunityLineItem> lineItemsToUpdateLst = new List<OpportunityLineItem>();
        List<OpportunityLineItem> cancelledList = [SELECT Id, OpportunityId, Status__c, Invoice_Amount__c, is_Refund_Initiated__c FROM OpportunityLineItem 
                                                   WHERE OpportunityId  =: oppId AND Status__c LIKE '%Cancelled%' AND is_Refund_Initiated__c = false];
        System.debug('cancelledList.size()-->'+cancelledList.size());
        for(OpportunityLineItem item : cancelledList){
            totalInvoiceAmt += item.Invoice_Amount__c;
        }
        if(totalInvoiceAmt > 0){
            Order_Request__c ordReq = new Order_Request__c();
            ordReq.Status__c = 'Refund Initiated';
            ordReq.Change_Type__c = 'Refund Request';
            ordReq.Booking__c = oppId;
            ordReq.Invoice_Amount__c = totalInvoiceAmt;
            insert ordReq;
            
            // Submit for Approval
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(ordReq.Id);
            req.setSkipEntryCriteria(false); // Let the system evaluate your entry criteria
            Approval.ProcessResult result = Approval.process(req);
            System.debug('Approval Submitted: ' + result.isSuccess());
            
            for(OpportunityLineItem item : cancelledList){
                item.is_Refund_Initiated__c = true;
                lineItemsToUpdateLst.add(item);
            }
        }
        
        if(lineItemsToUpdateLst.size() > 0)
            update lineItemsToUpdateLst;
        
    }

}