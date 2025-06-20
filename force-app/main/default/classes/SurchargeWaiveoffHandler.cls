public class SurchargeWaiveoffHandler {
    
    public static Boolean isTriggerRunning = false;
    
    public static void createOpportunityLineItemSurchargeWaiveOff(List<Opportunity> oppList) {
        
        Set<Id> oppIds = new Set<Id>();
        List<Approval_Process_Event__e> events = new List<Approval_Process_Event__e>();
        
        List<Transaction_History__c> transactionList = new List<Transaction_History__c>();
        for (Opportunity opp : oppList) {
            oppIds.add(opp.Id);
           /* Approval_Process_Event__e eventPayload = new Approval_Process_Event__e(
                Status__c = opp.Surcharge_WaiveOff_Request__c
            );
            events.add(eventPayload);*/
        }
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
             Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c,
             Saved_State_Addons__c, Saved_State_OrderSummary__c,Pricebook2Id, Surcharge_WaiveOff_Request__c
             FROM Opportunity WHERE Id IN :oppIds]
        );
        
        List<Product2> surchargeProduct = [SELECT Id FROM Product2 WHERE Name = 'Surcharge Waive Off' LIMIT 1];
        
        List<PricebookEntry> pbe = [SELECT Id,UnitPrice, Pricebook2Id FROM PricebookEntry WHERE Product2Id = :surchargeProduct[0].Id  AND IsActive = true LIMIT 1]; 
        
        // Check if the surcharge line already exists
        Map<Id,Id> oppsWithLineItem = new Map<Id,Id>();
        for (OpportunityLineItem oli : [SELECT Id, OpportunityId, PricebookEntry.Product2Id FROM OpportunityLineItem 
                                        WHERE OpportunityId IN :oppIds AND PricebookEntry.Product2.Name = 'Surcharge'])//:surchargeProduct[0].Id ]) 
        {
            oppsWithLineItem.put(oli.OpportunityId,oli.id);
        }
        
        // Create new line items
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for (Opportunity opp : oppMap.values()) {
            if (opp.Surcharge_WaiveOff_Request__c == 'Approved' && !pbe.IsEmpty() && !surchargeProduct.IsEmpty() && oppsWithLineItem.get(opp.Id) != null) {   
                
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = opp.Id;
                oli.PricebookEntryId = pbe[0].Id;
                oli.Quantity = 1;
                oli.UnitPrice = pbe[0].UnitPrice;
                oli.Status__c = 'Active';
                oli.Product2Id = surchargeProduct[0].Id;
                oli.Opportunity_Product__c = oppsWithLineItem.get(opp.Id);
                system.debug('oli>>>>+' + oli);
                PackageSelectionController.calculateGstApplicable(opp, oli);
                
                oliList.add(oli);
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
       /* if (!events.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(events);
        }*/
        
    }
    public static void approvalPlatformEvent(List<Opportunity> oppList) {
        system.debug('oppList>>>>+' + oppList);
        List<Approval_Process_Event__e> events = new List<Approval_Process_Event__e>();
        
        for (Opportunity opp : oppList) {
            system.debug('opp>>>>+' + opp);
            Approval_Process_Event__e eventPayload = new Approval_Process_Event__e(
                Status__c = opp.Surcharge_WaiveOff_Request__c
            );
            events.add(eventPayload);
        }
        if (!events.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(events);
        }
    }
    
}