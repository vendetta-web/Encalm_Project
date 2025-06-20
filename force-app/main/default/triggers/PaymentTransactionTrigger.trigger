trigger PaymentTransactionTrigger on Payment_Transaction__c (after update) {
    PaymentTransactionHandler.handlePaymentTransaction(Trigger.new);
}