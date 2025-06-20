public with sharing class PaymentTransactionHandler {
    public static void handlePaymentTransaction(List<Payment_Transaction__c> paymentTransactions) {
        Set<Id> opportunityIds = new Set<Id>();

        // Collect all Opportunity Ids linked via Payment_Transaction__c
        for (Payment_Transaction__c payment : paymentTransactions) {
            if (payment.Booking__c != null && payment.order_status__c == 'Success') {
                opportunityIds.add(payment.Booking__c);
            }
        }

        if (opportunityIds.isEmpty()) {
            return;
        } else {
            OrderRequestController.updateDataFromOrderRequest(opportunityIds);
        }
		
        
    }
}