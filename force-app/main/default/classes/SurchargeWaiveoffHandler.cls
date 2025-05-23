public class SurchargeWaiveoffHandler {
    public static Boolean isTriggerRunning = false;
    public static void createOpportunityLineItem(List<Opportunity> oppList) {
        Set<Id> oppIds = new Set<Id>();
        Set<Id> oppsMissingPricebook = new Set<Id>();
        List<Transaction_History__c> transactionList = new List<Transaction_History__c>();
        for (Opportunity opp : oppList) {
            oppIds.add(opp.Id);
            if (opp.Surcharge_WaiveOff_Request__c == 'Approved' && opp.Pricebook2Id == null) {
                oppsMissingPricebook.add(opp.Id);
            }
        }
        if (!oppsMissingPricebook.isEmpty()) {
            Id standardPBId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Opportunity opp : [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id IN :oppsMissingPricebook]) {
                opp.Pricebook2Id = standardPBId;
                oppsToUpdate.add(opp);
            }
            update oppsToUpdate;
        }
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c,
            Saved_State_Addons__c, Saved_State_OrderSummary__c,Pricebook2Id, Surcharge_WaiveOff_Request__c
            FROM Opportunity WHERE Id IN :oppIds]
        );
        
        Product2 surchargeProduct = [SELECT Id FROM Product2 WHERE Name = 'Surcharge' LIMIT 1];
        
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();
        Set<Id> pricebookIds = new Set<Id>();
        for (Opportunity opp : oppMap.values()) {
            if (opp.Surcharge_WaiveOff_Request__c == 'Approved' && opp.Pricebook2Id != null) {
                pricebookIds.add(opp.Pricebook2Id);
            }
        }
        
        for (PricebookEntry pbe : [SELECT Id,UnitPrice, Pricebook2Id FROM PricebookEntry WHERE Product2Id = :surchargeProduct.Id AND Pricebook2Id IN :pricebookIds AND IsActive = true]) 
        {
            pbeMap.put(pbe.Pricebook2Id, pbe);
        }
        
        // Check if the surcharge line already exists to avoid duplicates
        Set<Id> oppsWithLineItem = new Set<Id>();
        for (OpportunityLineItem oli : [SELECT Id, OpportunityId, PricebookEntry.Product2Id FROM OpportunityLineItem 
                                        WHERE OpportunityId IN :oppIds AND PricebookEntry.Product2Id = :surchargeProduct.Id ]) 
        {
            oppsWithLineItem.add(oli.OpportunityId);
        }
        
        // Create new line items
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for (Opportunity opp : oppMap.values()) {
            if (opp.Surcharge_WaiveOff_Request__c == 'Approved' && pbeMap.get(opp.Pricebook2Id) != null && surchargeProduct != null) {
                
                PricebookEntry pbe = pbeMap.get(opp.Pricebook2Id);
                if (pbe != null) {
                    decimal invoiceAmount = pbe.UnitPrice - (pbe.UnitPrice * 0.18);
                    OpportunityLineItem oli = new OpportunityLineItem();
                        oli.OpportunityId = opp.Id;
                        oli.PricebookEntryId = pbe.Id;
                        oli.Quantity = 1;
                        oli.UnitPrice = -pbe.UnitPrice;
                        oli.Status__c = 'Active';
                        oli.Product2Id = surchargeProduct.Id;
                    	PackageSelectionController.calculateGstApplicable(opp, oli);
                        //Invoice_Amount__c = -invoiceAmount;
                    oliList.add(oli);
                }
            }
        }
        
        if (!oliList.isEmpty()) {
            insert oliList;
        }
        for (OpportunityLineItem oli : oliList) {
            if (oli.UnitPrice != 0) {
                Transaction_History__c transactionRec = new Transaction_History__c();
                transactionRec.Booking_Id__c = oli.OpportunityId;
                transactionRec.List_Price__c = oli.UnitPrice;
                transactionRec.Name = oli.Opportunity.Name;
                transactionRec.Transaction_Type__c = 'Debit';
                transactionRec.Order_Id__c = oli.Id; 
                transactionList.add(transactionRec);
            }
        }
        if(!transactionList.isEmpty()){
            insert transactionList;
        }
        
    }
}