public class OracleInvoiceQueuableService implements Queueable, Database.AllowsCallouts {
    private String oppStr;
    private String oppLineItemStr;
    private String txInvStr;
    public OracleInvoiceQueuableService(String oppStr, String oppLineItemStr, String txInvStr) {
        this.oppStr = oppStr;
        this.oppLineItemStr = oppLineItemStr;
        this.txInvStr = txInvStr;
    }
	public void execute(QueueableContext context) {
        
        OracleInvoiceService.createInvoice(oppStr, oppLineItemStr, txInvStr); 
    }
    
 /*   private Tax_Invoice__c taxRec;
    private String oppId;
    private String isCancelled;
    
    public OracleInvoiceQueuableService(String oppId, String isCancelled, Tax_Invoice__c taxRec) {
        this.oppId = oppId;
        this.isCancelled = isCancelled;
        this.taxRec = taxRec;
    }
    public void execute(QueueableContext context) {
        
        TaxInvoiceController.generateTaxInvoice(oppId, 'No', taxRec); 
    }*/
}