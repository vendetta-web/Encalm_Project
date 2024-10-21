@RestResource(urlMapping='/Create_Lead/*')
global Class LeadConversion{
@HttpPost
  global static Lead leadConversion() {
    RestRequest requ = RestContext.request;
    String req = requ.requestBody.tostring();
      Lead newLead = new Lead();
      System.debug('-----body------------------------>'+req);
   // = new LeadConversionWrapper(); 
      LeadConversionWrapper reqBean  = (LeadConversionWrapper)JSON.deserialize(req,LeadConversionWrapper.class);
      System.debug('---------->'+reqBean);
      system.debug('---------------reqBean------------->');
     if(reqBean!= null  && reqBean.LastName!= null && reqBean.company != null && reqBean.numberofAdult != null){
          Lead newLeadRec = new Lead();
          newLeadRec.Company = reqBean.company;
          newLeadRec.Travel_Date__c = Date.valueOf(reqBean.travelDate);
          newLeadRec.LastName  = reqBean.lastName;
          newLeadRec.FirstName = reqBean.firstName;
         newLeadRec.Number_of_Adult__c = reqBean.numberofAdult;
          System.debug('reqBean.leadWrapper============>'+reqBean);
        Insert newLeadRec;
          System.debug('Lead==========>'+newLeadRec);
         if(newLeadRec != null &&  !reqBean.addOnServices.IsEmpty()){
             List<Add_On__c> addOnList = new List<Add_On__c>();
             for(LeadConversionWrapper.AddOnServices rec : reqBean.addOnServices ){
                 Add_On__c addonRec = new Add_On__c();
                 addonRec.Name = rec.name;
                 addonRec.Lead_ID__c = newLeadRec.Id;
                 System.debug('---rec.addOnServiceQty-----------'+rec.addOnServiceQty);
                 if(rec.addOnServiceQty != null){
                       addonRec.AddOnServiceQty__c = Decimal.valueOf(rec.addOnServiceQty); 
                 }
             
               addonRec.AddOnService__c =  rec.addOnService;
                 addOnList.add(addonRec);
                 System.debug('-------------rec---------------->'+rec);
             }
             if(!addOnList.isEmpty()){
                 insert addOnList;
                     System.debug('----addOnList------------------'+addOnList);
             }
             List<Passenger_Details__c> passengerDetailsList = new List<Passenger_Details__c>();
             if(newLeadRec != null &&  !reqBean.passengerDetails.IsEmpty()){
                 for(LeadConversionWrapper.PassengerDetails rec: reqBean.passengerDetails){
                     Passenger_Details__c passengerDetailsRec = new Passenger_Details__c();
                     passengerDetailsRec.name  = rec.name;
                     passengerDetailsRec.Lead_ID__c = newLeadRec.Id;
                     passengerDetailsRec.Airline_PNR__c = rec.airlinePNR;
                     passengerDetailsList.add(passengerDetailsRec);
                     }
                 if(!passengerDetailsList.isEmpty()){
                    insert passengerDetailsList ;
                     System.debug('----------passengerDetailsList----'+passengerDetailsList);
                 }
             }
         }
           System.debug('newLeadRec==========>'+newLeadRec);
          
      }
      return newLead ;
          
  }
}