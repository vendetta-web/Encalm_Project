/**
* @File Name : OracleInvoiceService.cls
* @Description : Provides functionality for creating invoices (B2B/B2C), credit memos, and uploading QR code attachments.
* @Author : Supriya Bassi
* @Last Modified By :
* @Last Modified On : June 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 18, 2025 |   | Initial Version
**/

public with sharing class OracleInvoiceService {
    
    private static final String NAMED_CREDENTIAL = 'Oracle_AR_Service';
    
    
    @future(callout=true)
    //public static HttpResponse createB2CInvoice(Opportunity opp, List<OpportunityLineItem> lineItems) {
    public static void createInvoice(String oppStr, String lineItemsStr, String txInvRecStr) {
        Tax_Invoice__c txInvRec = (Tax_Invoice__c)JSON.deserialize(txInvRecStr, Tax_Invoice__c.class);
        Opportunity opp = (Opportunity)JSON.deserialize(oppStr, Opportunity.class);
        List<OpportunityLineItem> lineItems = (List<OpportunityLineItem>)JSON.deserialize(lineItemsStr, List<OpportunityLineItem>.class);
        
        OracleInvoiceRequest request = buildInvoiceRequest(opp, lineItems,'B2C', txInvRec);
        System.debug('JSON.serialize(request)-->'+JSON.serialize(request));
        sendRequest(JSON.serialize(request), txInvRec);
    }  
      
   /* @future(callout=true)
    public static void createB2BInvoice(String oppStr, String lineItemsStr, String txInvRecStr) {
        Tax_Invoice__c txInvRec = (Tax_Invoice__c)JSON.deserialize(txInvRecStr, Tax_Invoice__c.class);
        Opportunity opp = (Opportunity)JSON.deserialize(oppStr, Opportunity.class);
        List<OpportunityLineItem> lineItems = (List<OpportunityLineItem>)JSON.deserialize(lineItemsStr, List<OpportunityLineItem>.class);
        OracleInvoiceRequest request = buildInvoiceRequest(opp, lineItems,'B2B', txInvRec);
        sendRequest(JSON.serialize(request), txInvRec);
    }  */ 
    
    
    //Creates and sends a credit memo to Oracle Receivables.
    public static void createCreditMemo(Opportunity opp, List<OpportunityLineItem> lineItems, String txInvRecStr) {
        Tax_Invoice__c txInvRec = (Tax_Invoice__c)JSON.deserialize(txInvRecStr, Tax_Invoice__c.class);
        OracleCreditMemoRequest request = buildCreditMemoRequest(opp, lineItems);
        sendRequest(JSON.serialize(request), txInvRec);
    }
    
    //Uploads a QR code URL as an attachment to the Oracle invoice record.
    public static HttpResponse uploadQRCodeAttachment(Opportunity opp, String qrCodeUrl) {
        String body = buildSoapRequest(opp, qrCodeUrl);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/fscmService/ErpIntegrationService');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json'); //req.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        req.setBody(body);
        
        Http http = new Http();
        return http.send(req);
    }
    
    //Sends a JSON-based POST request to Oracle API.
    private static void sendRequest(String requestObj, Tax_Invoice__c txInvRec ) {
        Integer maxRetries = 3;
        Integer attempts = 0;
        Boolean success = false;
        String resBody;
        Http http = new Http();
        HttpRequest req;
        HttpResponse res;
        
        while (attempts < maxRetries && !success) 
        {
            try {
                attempts++;
                
                req = new HttpRequest();
                req.setEndpoint('callout:Oracle_AR_Invoice/fscmRestApi/resources/11.13.18.05/receivablesInvoices'); 
                req.setMethod('POST');
                req.setTimeout(60000); // 60 seconds
                req.setHeader('Content-Type', 'application/json');
                req.setBody(requestObj);
                
                res = http.send(req);
                resBody = res.getBody();
                System.debug('Oracle ---res.getStatusCode()-->'+res.getStatusCode());
                if (res.getStatusCode() == 201) {
                    System.debug('resBody-->'+resBody);
                    TaxInvoiceRecordHandler.updateOracleResponse(txInvRec, requestObj, resBody, 'Success');
                }
                else {
                    TaxInvoiceRecordHandler.updateOracleResponse(txInvRec, requestObj, resBody, 'Failed');
                    System.debug('Erro in Oracle. Response: ' + res.getBody());
                }
            } 
            catch (System.CalloutException e) 
            {
                System.debug('Attempt ' + attempts + ' failed: ' + e.getMessage());
                
                if (attempts >= maxRetries) {
                    // Log failure or update record with error message
                  //  TaxInvoiceRecordHandler.logOracleError(txInvRec, e.getMessage());
                } else {
                    // Optional: short pause between retries (not real delay, just logging here)
                    System.debug('Retrying in 1 second... (simulated)');
                    // Note: Apex doesn't support Thread.sleep() in normal context
                }
            }
        }
    }
        
    //Builds the Oracle invoice request object based on the opportunity and line items.
    
    private static OracleInvoiceRequest buildInvoiceRequest(Opportunity opp, List<OpportunityLineItem> lineItems, String accountType, Tax_Invoice__c txInvRecord) {
        Tax_Invoice__c txInvRec = [SELECT Id, Name, IRN__c, Acknowledgement_Number__c, Acknowledgement_Date__c FROM Tax_Invoice__c WHERE Id =: txInvRecord.Id ];
        System.debug('Oracle --buildInvoiceRequest--txInvRec-->'+txInvRec);
        Encalm_Details__mdt encalmDtls = [SELECT Id, GSTIN__c, Legal_Name__c, Address__c, State__c, Pin_Code__c 
                                          FROM Encalm_Details__mdt WHERE DeveloperName =: opp.Service_Airport__c];
        
        List<TaxInvoiceRecordHandler.OppLineItemWrapper> lineItemWrapLst = TaxInvoiceRecordHandler.prepareLineItemWrapper(opp, lineItems);
        Date todayDate = System.today();
        
        String formattedMonth = todayDate.month() < 10 ? '0' + todayDate.month() : String.valueOf(todayDate.month());
        String formattedDay = todayDate.day() < 10 ? '0' + todayDate.day() : String.valueOf(todayDate.day());
        
        String formattedDate = todayDate.year() + '-' + formattedMonth + '-' + formattedDay;
        
        OracleInvoiceRequest request = new OracleInvoiceRequest();
        request.InvoiceCurrencyCode = 'INR';
        request.TransactionNumber = txInvRec.Name; //'24253601_Test18'; //
        request.TransactionDate = formattedDate; //Date.today().format();
        request.TransactionType = 'POS INV '+ encalmDtls.State__c;
        request.TransactionSource = 'Encalm Manual Source'; //'Salesforce Manual Source';
        request.BillToCustomerNumber = '120001138'; //opp.Account.AccountNumber;
        request.BillToSite = '889'; //opp.Account.Customer_Site_Number__c;
        request.PaymentTerms = '30 Days'; //opp.Account.Payment_Terms__c;
        request.BusinessUnit = 'Encalm Airport Business Unit';
        request.AccountingDate = formattedDate;
        request.FirstPartyRegistrationNumber = '36AAGCE6783M1ZY'; //encalmDtls.GSTIN__c; //
        request.ThirdPartyRegistrationNumber = '01AAECK3675L2ZF'; //opp.Account.GST__c;
                
        OracleInvoiceDFF dff = new OracleInvoiceDFF();
        dff.irnNumber = txInvRec.IRN__c;
        dff.acknowledgementNumber = String.valueOf(txInvRec.Acknowledgement_Number__c);
        dff.acknowledgementDate = formattedDate;
        // dff.eInvErrorMessage = opp.E_Invoice_Error__c;
        request.receivablesInvoiceDFF = new List<OracleInvoiceDFF>{ dff };
        
        OracleInvoiceDistributions dist = new OracleInvoiceDistributions();
        dist.InvoiceLineNumber = 1;
        dist.AccountClass = 'Revenue';
        dist.AccountCombination = '10.101.9999.4601001001.401.1031.99.999.999';
        dist.Percent = 100;
        request.receivablesInvoiceDistributions = new List<OracleInvoiceDistributions>{ dist };
            
        request.receivablesInvoiceLines = new List<OracleInvoiceLine>();
        //for (OpportunityLineItem line : lineItems) {
        for(TaxInvoiceRecordHandler.OppLineItemWrapper wrap : lineItemWrapLst){ 
            OracleInvoiceLine invoiceLine = new OracleInvoiceLine();
            invoiceLine.LineNumber = String.valueOf(wrap.SrNo); //String.valueOf(line.SortOrder);
            invoiceLine.Description = wrap.description; //line.Description;
            invoiceLine.Quantity = String.valueOf(wrap.quantity); //String.valueOf(line.Quantity);
            invoiceLine.UnitSellingPrice = String.valueOf(wrap.unitPrice); //String.valueOf(line.UnitPrice);
            
            invoiceLine.receivablesInvoiceLineTaxLines = new List<OracleTaxLine>();
            if (wrap.cgst > 0) {
                OracleTaxLine cgst = new OracleTaxLine();
                cgst.TaxRateCode = 'CGST 9% REC 0';
                cgst.TaxRegimeCode = 'IND TAX';
                cgst.TaxAmount = String.valueOf(wrap.cgst);
                invoiceLine.receivablesInvoiceLineTaxLines.add(cgst);
                
                OracleTaxLine sgst = new OracleTaxLine();
                sgst.TaxRateCode = 'SGST 9% REC 0';
                sgst.TaxRegimeCode = 'IND TAX';
                sgst.TaxAmount = String.valueOf(wrap.cgst);
                invoiceLine.receivablesInvoiceLineTaxLines.add(sgst);
            } else {
                OracleTaxLine igst = new OracleTaxLine();
                igst.TaxRateCode = 'IGST 18% REC 0';
                igst.TaxRegimeCode = 'IND TAX';
                igst.TaxAmount = String.valueOf(wrap.igst);
                invoiceLine.receivablesInvoiceLineTaxLines.add(igst);
            }
            
            request.receivablesInvoiceLines.add(invoiceLine);
        }
        System.debug('oracle - request-->'+request);
        return request;
    }
    
    /**
* Builds the Oracle credit memo request object based on the opportunity and line items.
* @param opp Opportunity record
* @param lineItems Opportunity line items
* @return OracleCreditMemoRequest object
*/
    private static OracleCreditMemoRequest buildCreditMemoRequest(Opportunity opp, List<OpportunityLineItem> lineItems) {
        OracleCreditMemoRequest request = new OracleCreditMemoRequest();
        request.CreditMemoCurrency = 'INR';
        // request.TransactionNumber = opp.Credit_Memo_Number__c;
        // request.TransactionDate = Date.today().format();
        // request.TransactionType = 'POS CM Telangana';
        // request.TransactionSource = 'Salesforce Manual Source';
        // request.BillToCustomerNumber = opp.Account.Oracle_Customer_Number__c;
        // request.BillToSite = opp.Account.Oracle_Site_Number__c;
        // request.CreditMemoComments = opp.Credit_Memo_Reason__c;
        // request.BusinessUnit = 'Encalm Airport Business Unit';
        // request.AccountingDate = Date.today().format();
        // request.FirstPartyRegistrationNumber = '36AAGCE6783M1ZY';
        
        // if (opp.Account.GST_Registered__c) {
        //     request.ThirdPartyRegistrationNumber = opp.Account.GST_Number__c;
        // }
        
        // OracleCreditMemoDFF dff = new OracleCreditMemoDFF();
        // dff.irnNumber = opp.IRN_Number__c;
        // dff.acknowledgementNumber = opp.Acknowledgement_Number__c;
        // dff.acknowledgementDate = opp.Acknowledgement_Date__c != null ? opp.Acknowledgement_Date__c.format() : Date.today().format();
        // dff.eInvErrorMessage = opp.E_Invoice_Error__c;
        // request.receivablesCreditMemoDFF = new List<OracleCreditMemoDFF>{ dff };
        
        // request.receivablesCreditMemoLines = new List<OracleCreditMemoLine>();
        // for (OpportunityLineItem line : lineItems) {
        //     OracleCreditMemoLine creditLine = new OracleCreditMemoLine();
        //     creditLine.LineNumber = String.valueOf(line.SortOrder);
        //     creditLine.LineDescription = line.Description;
        //     creditLine.LineQuantityCredit = String.valueOf(line.Quantity * -1);
        //     creditLine.UnitSellingPrice = String.valueOf(line.UnitPrice);
        
        //     creditLine.receivablesCreditMemoLineTaxLines = new List<OracleTaxLine>();
        //     OracleTaxLine taxLine = new OracleTaxLine();
        //     if (opp.Account.GST_Registered__c) {
        //         taxLine.TaxRateCode = 'CGST 9% REC 0';
        //     } else {
        //         taxLine.TaxRateCode = 'IGST 18% REC 0';
        //     }
        //     taxLine.TaxRegimeCode = 'IND TAX';
        //     taxLine.TaxAmount = String.valueOf(line.TotalPrice * -0.18);
        //     creditLine.receivablesCreditMemoLineTaxLines.add(taxLine);
        
        //     request.receivablesCreditMemoLines.add(creditLine);
        // }
        return request;
    }
    
    /**
* Constructs the SOAP envelope required for uploading an attachment to Oracle.
* @param opp Opportunity record
* @param qrCodeUrl URL of the QR code attachment
* @return XML-formatted SOAP envelope string
*/
    private static String buildSoapRequest(Opportunity opp, String qrCodeUrl) {
        return '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/" ' +
            'xmlns:erp="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/">' +
            '<soapenv:Header/>' +
            '<soapenv:Body>' +
            '<typ:uploadAttachment>' +
            '<typ:entityName>RA_CUSTOMER_TRX_ALL</typ:entityName>' +
            '<typ:categoryName>CUSTOMER_TRX</typ:categoryName>' +
            '<typ:allowDuplicate>Yes</typ:allowDuplicate>' +
            '<typ:attachmentRows>' +
            '<erp:UserKeyA>Encalm Airport Business Unit</erp:UserKeyA>' +
            //    '<erp:UserKeyB>' + opp.Invoice_Number__c + '</erp:UserKeyB>' +
            '<erp:UserKeyC>Salesforce Manual Source</erp:UserKeyC>' +
            //    '<erp:UserKeyD>' + opp.Oracle_Transaction_Id__c + '</erp:UserKeyD>' +
            '<erp:UserKeyE>#NULL</erp:UserKeyE>' +
            '<erp:AttachmentType>URL</erp:AttachmentType>' +
            //    '<erp:Title>' + opp.Invoice_Number__c + '.txt</erp:Title>' +
            '<erp:Content>' + qrCodeUrl + '</erp:Content>' +
            '</typ:attachmentRows>' +
            '</typ:uploadAttachment>' +
            '</soapenv:Body>' +
            '</soapenv:Envelope>';
    }
    
    // --- Wrapper Classes ---
    
    /** Wrapper for Oracle Invoice API request */
    public class OracleInvoiceRequest {
        public String InvoiceCurrencyCode;
        public String TransactionNumber;
        public String TransactionDate;
        public String TransactionType;
        public String TransactionSource;
        public String BillToCustomerNumber;
        public String BillToSite;
        public String PaymentTerms;
        public String BusinessUnit;
        public String AccountingDate;
        public String FirstPartyRegistrationNumber;
        public String ThirdPartyRegistrationNumber;
        public List<OracleInvoiceLine> receivablesInvoiceLines;
        public List<OracleInvoiceDFF> receivablesInvoiceDFF;
        public List<OracleInvoiceDistributions> receivablesInvoiceDistributions;
    }
    
    /** Wrapper for Oracle Invoice line details */
    public class OracleInvoiceLine {
        public String LineNumber;
        public String Description;
        public String Quantity;
        public String UnitSellingPrice;
        public List<OracleTaxLine> receivablesInvoiceLineTaxLines;
    }
    
    /** Wrapper for Oracle tax line details */
    public class OracleTaxLine {
        public String TaxRateCode;
        public String TaxRegimeCode;
        public String TaxAmount;
    }
    
    /** Wrapper for Oracle Invoice DFF (Descriptive Flexfields) */
    public class OracleInvoiceDFF {
        public String irnNumber;
        public String acknowledgementNumber;
        public String acknowledgementDate;
        public String eInvErrorMessage;
    }
    
    public class OracleInvoiceDistributions {
        public Integer InvoiceLineNumber;
        public String AccountClass;
        public String AccountCombination;
        public Integer Percent;
    }
    
    
    /** Wrapper for Oracle Credit Memo API request */
    public class OracleCreditMemoRequest {
        public String CreditMemoCurrency;
        public String TransactionNumber;
        public String TransactionDate;
        public String TransactionType;
        public String TransactionSource;
        public String BillToCustomerNumber;
        public String BillToSite;
        public String CreditMemoComments;
        public String BusinessUnit;
        public String AccountingDate;
        public String FirstPartyRegistrationNumber;
        public String ThirdPartyRegistrationNumber;
        public List<OracleCreditMemoLine> receivablesCreditMemoLines;
        public List<OracleCreditMemoDFF> receivablesCreditMemoDFF;
    }
    
    /** Wrapper for Oracle Credit Memo line details */
    public class OracleCreditMemoLine {
        public String LineNumber;
        public String LineDescription;
        public String LineQuantityCredit;
        public String UnitSellingPrice;
        public List<OracleTaxLine> receivablesCreditMemoLineTaxLines;
    }
    
    /** Wrapper for Oracle Credit Memo DFF (Descriptive Flexfields) */
    public class OracleCreditMemoDFF {
        public String irnNumber;
        public String acknowledgementNumber;
        public String acknowledgementDate;
        public String eInvErrorMessage;
    }
}