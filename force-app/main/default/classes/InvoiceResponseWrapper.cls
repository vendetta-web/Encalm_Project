public class InvoiceResponseWrapper {
    
    public GenerateInvoiceResult Generate_Invoice_Result;

    public class GenerateInvoiceResult {
        public String error_desc;
        public String invoice_id;
        public String tiny_url;
        public String qr_code;
        public Integer invoice_status;
        public String error_code;
        public String merchant_reference_no;
    }

    // Optional: method to parse from JSON string
    public static InvoiceResponseWrapper parse(String jsonString) {
        return (InvoiceResponseWrapper) JSON.deserialize(jsonString, InvoiceResponseWrapper.class);
    }
}