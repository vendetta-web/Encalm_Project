public class TaxInvoiceGeneratorQueuable implements Queueable, Database.AllowsCallouts {
    private Tax_Invoice__c taxRec;
    private String oppId;
   // private String isCancelled;
    
    public TaxInvoiceGeneratorQueuable(String oppId, Tax_Invoice__c taxRec) {
        this.oppId = oppId;
       // this.isCancelled = isCancelled;
        this.taxRec = taxRec;
    }
    public void execute(QueueableContext context) {
        TaxInvoiceController.generateTaxInvoice(oppId, taxRec); 
    }
}