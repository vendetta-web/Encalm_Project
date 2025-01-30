/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_sale_order_details_by_gso/*')	
global class MDEN_GetServiceOrderCompleteDetails {
    @HttpGet
    global static MDEN_GetResponseWrapper saveSaleOrderParent(){
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper();
        mainData mainDataDetails = new mainData('', '');
        itemData itemDataDetails = new itemData('', '');
        guestData guestDataDetails = new guestData('', '');
        custData custDataDetails = new custData('', '');
        gsoData gsoDataDetails = new gsoData('', '');
        porterData porterDataDetails = new porterData('', '');
        buggyData buggyDataDetails = new buggyData('', ''); 
        
        Map<String, String> flightTypeMap = new Map<String, String>{
                                                 'Arrival' => '1', 
                                                  'Departure' => '2',
                                                  'Transit' => '3'
                                            };
        
        try{
            //MDEN_RegisterCustomer.registerCustomer();
            
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            
			/* 
			//Use below id to test maindata, itemdata, guestdata and cust data
            String reqBody =' { ' +
                            ' "id": "006Su00000AQldRIAT" '+
                            ' } ';

            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            */
            
            System.debug('requestMap==>'+requestMap.id);
            if(requestMap <> null && requestMap.id <> null){
                List<Salutation__c> salutationList = new List<Salutation__c>();
                List<Country__c> countryList = new List<Country__c>();
                
                /********** Start : Fetching Main Data i.e. Opportunity Details **********/
                mainDataDetails = new mainData('true', 'data found.');
                List<mainDataList> listOfMainData = new List<mainDataList>();
                
                List<Opportunity> oppList = [Select  id, 
                                             		 name, 
                                             	   	 AccountId,
                                             		 Account.name,
                                             		 Account.firstname,
                                             		 Account.lastname,	
                                             		 Account.Country__c,
                                                     Account.Country__r.name,
                                             		 Account.Phone,
                                              		 Account.PersonMobilePhone,
                                             		 Account.PersonTitle,
                                             		 Amount,
                                             	   	 StageName,
                                                   	 Number_of_Adults__c, 
                                                     Number_of_Children__c, 
                                                     Number_of_Infants__c,
                                                     Date_of_Arrival__c,
                                                     Date_of_Departure__c,
                                                     Flight_Number_Arrival__c,
                                                     Flight_Number_Departure__c,
                                                     Arriving_Airport__c,
                                                     Departure_Airport__c,
                                                     Flight_Type__c,
                                                     STA_Time__c,
                                                     STD_Time__c,
                                                     Sector__c,
                                             		 CreatedDate,
                                                     Service_Airport__c,
                                             		 Service_Category__c,
                                             		 Service_Type__c,
                                                     //Service_Airport__r.Airport_Name__c,
                                             		 //Service_Airport__r.Location_Id__c,
                                             		 Arriving_Flight_Schedule__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.name,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Code__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, 
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Location_Id__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c,
                                             		 Departure_Flight_Schedule__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.name,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Code__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, 
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Location_Id__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.name,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_No_Arrival__c,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.name,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Flight_No_Departure__c,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c
                                             From Opportunity
                                             Where id = :requestMap.id];
                
                System.debug('oppList==>'+oppList);
                if(oppList <> null && !oppList.isEmpty()){
                    if(oppList[0].Account.PersonTitle <> null)
                		salutationList = [select id, name, Salutation_Name__c from Salutation__c Where Salutation_Name__c =:oppList[0].Account.PersonTitle limit 1];
                    
                    System.debug('salutationList==>'+salutationList);
                    if(oppList[0].Account.Country__c <> null)
                		countryList = [select id, name, Country_code__c, Country_Name__c, Phone_Code__c from Country__c Where id = :oppList[0].Account.Country__c limit 1];
                    
                    System.debug('countryList==>'+countryList);
                    for(Opportunity opp : oppList){
                        mainDataList mainDataListDetails  = new mainDataList();
						mainDataListDetails.id = opp.id;
                        mainDataListDetails.partner_id = new List<String>{opp.AccountId, opp.Account.name};
                        mainDataListDetails.name = opp.name;
                        mainDataListDetails.date_order = String.valueOf(opp.CreatedDate);
                        mainDataListDetails.dates = String.valueOf(opp.CreatedDate);
                        //mainDataListDetails.airport_location_id = new List<String>{opp.Service_Airport__r.Location_Id__c, opp.Service_Airport__r.Airport_Name__c};
                        //mainDataListDetails.commitment_date = String.valueOf(opp.CreatedDate);
                        //Need Service Terminal field on Opportunity
                        mainDataListDetails.airport_terminal_id = new List<String>{opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.name, opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Code__c};
                        mainDataListDetails.arrival_flight_id = new List<String>{opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_No_Arrival__c, opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c};
                        mainDataListDetails.departure_flight_id = new List<String>{opp.Departure_Flight_Schedule__r.Flight_Detail__r.Flight_No_Departure__c, opp.Departure_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c};
                        mainDataListDetails.arrival_airline_id = new List<String>{opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name, opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c};
                        mainDataListDetails.departure_airline_id = new List<String>{opp.Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name, opp.Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c};
                        mainDataListDetails.service_category = opp.Service_Category__c;
                        mainDataListDetails.service_type_id = new List<String>{flightTypeMap.get(opp.Service_Type__c), opp.Service_Type__c};
                        mainDataListDetails.arrival_time = opp.STA_Time__c;
                        mainDataListDetails.departure_time = opp.STD_Time__c;
                        //mainDataListDetails.booking_made_from = opp.name;
                        mainDataListDetails.from_airport_id = new List<String>{opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c};
                        mainDataListDetails.to_airport_id = new List<String>{opp.Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, opp.Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c};
                        mainDataListDetails.no_of_adult = String.valueOf(opp.Number_of_Adults__c);
                        mainDataListDetails.no_of_children = String.valueOf(opp.Number_of_Children__c);
                        mainDataListDetails.no_of_infants = String.valueOf(opp.Number_of_Infants__c);
                        //mainDataListDetails.itinerary_no = opp.name;
                        //mainDataListDetails.pricelist_id = new List<String>{};
                        //mainDataListDetails.placard_name = opp.name;
                        mainDataListDetails.contact_number = opp.Account.Phone;
                        //mainDataListDetails.placard_email = opp.name;
                        mainDataListDetails.title = new List<String>{salutationList[0].name, salutationList[0].Salutation_Name__c};
                        mainDataListDetails.first_name = opp.Account.firstname;
                        mainDataListDetails.last_name = opp.Account.lastname;
                        mainDataListDetails.country_code = opp.Account.Country__r.name;
                        //mainDataListDetails.country_code = countryList[0].name;
                        //mainDataListDetails.instruction_comments = opp.name;
                        //mainDataListDetails.gso_ids = new List<String>{};
                        //mainDataListDetails.porter_ids = new List<String>{};
                        //mainDataListDetails.buggy_driver_ids = new List<String>{};
                        mainDataListDetails.booking_stage = opp.StageName;
                        //mainDataListDetails.state = opp.name;
                        mainDataListDetails.amount_total = String.valueOf(opp.Amount);
                        //mainDataListDetails.milestone_status = opp.name;
                        //mainDataListDetails.guest_feedback = opp.name;
                        //mainDataListDetails.additional_info = opp.name;
                        //mainDataListDetails.payment_method = opp.name;
                        //mainDataListDetails.atime = opp.name;
                        //mainDataListDetails.dtime = opp.name;

                        listOfMainData.add(mainDataListDetails);
                    }
                                        
                    mainDataDetails.datalist = listOfMainData;
                	mden_responseWrapper.mainData = mainDataDetails;
            	}else{
                    mainDataDetails = new mainData('false', 'data not found.');
                	/*itemDataDetails = new itemData('false', 'data not found.');
                    guestDataDetails = new guestData('false', 'data not found.');
                    custDataDetails = new custData('false', 'data not found.');
                    gsoDataDetails = new gsoData('false', 'data not found.');
                    porterDataDetails = new porterData('false', 'data not found.');
                    buggyDataDetails = new buggyData('false', 'data not found.');*/
                }
                
                
                /********** End : Fetching Main Data i.e. Opportunity Details **********/ 
                
                /********** Start : Fetching Item Data i.e. Opportunity Product or OpportunityLineItem Details **********/
                if(oppList <> null && !oppList.isEmpty()){
                	itemDataDetails = new itemData('true', 'data found.');
                    
                    List<itemDataList> listOfItemData = new List<itemDataList>();
                    System.debug('oppList[0].id==>'+oppList[0].id);
                    List<OpportunityLineItem> oppLineItemList = [Select id, name, ProductCode, Quantity, UnitPrice, ListPrice, TotalPrice, product2Id, product2.name, product2.ProductCode
                                                 From OpportunityLineItem
                                                 Where opportunityId = :oppList[0].id];
                    
                    System.debug('oppLineItemList==>'+oppLineItemList);
                    if(oppLineItemList <> null && !oppLineItemList.isEmpty()){
                        for(OpportunityLineItem oppLineItem : oppLineItemList){
                            itemDataList itemDataListDetails  = new itemDataList();
                            itemDataListDetails.id = oppLineItem.id;
                            itemDataListDetails.product_id = new List<String>{oppLineItem.product2.ProductCode, oppLineItem.product2.name};
                            itemDataListDetails.name = oppLineItem.product2.name;
                            itemDataListDetails.product_uom_qty = String.valueOf(oppLineItem.Quantity);
                            itemDataListDetails.product_uom = new List<String>{String.valueOf(oppLineItem.Quantity) /*oppLineItem.name*/, 'Units'};
                            itemDataListDetails.price_unit = String.valueOf(oppLineItem.UnitPrice);
                            itemDataListDetails.price_subtotal = String.valueOf(oppLineItem.TotalPrice);
                            
                            /*
                            oli.OpportunityId = opportunityId;
                            oli.Product2Id = productId;
                            oli.Quantity = 1;
                            oli.UnitPrice = unitPrice;
                            oli.PricebookEntryId = pricebookEntry; // Link PricebookEntry to OLI
                            oli.Pickup_Terminal__c = pickupTerminal;
                            oli.Drop_Terminal__c = dropTerminal;
                            */
                            
                            listOfItemData.add(itemDataListDetails);
                        }
                                            
                        itemDataDetails.datalist = listOfItemData;
                    }
                    
                    
                    mden_responseWrapper.itemData = itemDataDetails;                                
                }else{
                    itemDataDetails = new itemData('false', 'data not found.');
                }
                
                /********** End : Fetching Item Data i.e. Opportunity Product or OpportunityLineItem Details **********/
                
                /********** Start : Fetching Guest Data i.e. Opportunity Details **********/
                if(oppList <> null && !oppList.isEmpty()){
                	guestDataDetails = new guestData('true', 'data found.');
                    
                    List<guestDataList> listOfGuestData = new List<guestDataList>();
                    
                    List<Passenger_Details__c> passengerList = [Select id, First_Name__c, Last_Name__c, dob__c, Passport_No__c, Travel_PNR_No__c, Age__c, Travel_Class__c
                                                 From Passenger_Details__c
                                                 Where Opportunity_ID__c = :oppList[0].id];
                    
                    if(passengerList <> null && !passengerList.isEmpty()){
                        for(Passenger_Details__c passengerDetail : passengerList){
                            guestDataList guestDataListDetails  = new guestDataList();
							guestDataListDetails.id = passengerDetail.id;
                            guestDataListDetails.first_name = passengerDetail.First_Name__c;
                            guestDataListDetails.last_name = passengerDetail.Last_Name__c;
                            //Date dob = Date.valueOf(passengerDetail.dob__c);
                            guestDataListDetails.dob = String.valueOf(passengerDetail.dob__c);
                            guestDataListDetails.passport = passengerDetail.Passport_No__c;
                            guestDataListDetails.pnr_no = passengerDetail.Travel_PNR_No__c;
                            guestDataListDetails.age = String.valueOf(passengerDetail.Age__c);
                            guestDataListDetails.class_type = passengerDetail.Travel_Class__c;
                            
                            /*
                            passenger.Opportunity_ID__c = requestMap.parent_id;
                            passenger.Title__c  = (salutation[0].Salutation_Name__c <> null) ? salutation[0].Salutation_Name__c : '';
                            passenger.First_Name__c  = requestMap.first_name;   
                            passenger.Last_Name__c  = requestMap.last_name;
                            passenger.Gender__c = requestMap.gender;
                            Date dob = Date.valueOf(requestMap.dob);
                            passenger.dob__c = (dob <> null) ? dob : null;
                            passenger.Age__c = (requestMap.age <> null) ? Decimal.valueOf(requestMap.age) : null;
                            passenger.Passport_No__c = requestMap.passport_no;
                            passenger.Travel_PNR_No__c = requestMap.pnr_no;
                            passenger.Travel_Class__c = requestMap.class_type;
                            passenger.Mobile__c = requestMap.mobile;
							passenger.Passenger_Type__c = (String) guest.get('type'); 
							passenger.Designation__c = (String) guest.get('designation');
                            //passenger.country = (country[0].Country_Name__c <> null) ? country[0].Country_Name__c : '';
                            */
                                                 
                            listOfGuestData.add(guestDataListDetails);
                        }
                                            
                        guestDataDetails.datalist = listOfGuestData;
                    }
                    
                    
                    mden_responseWrapper.guestData = guestDataDetails;                                
                }else{
                    guestDataDetails = new guestData('false', 'data not found.');
                }
                /********** End : Fetching Guest Data i.e. Opportunity Details **********/
                
                /********** Start : Fetching Cust Data i.e. Opportunity Details **********/
                if(oppList <> null && !oppList.isEmpty() && oppList[0].AccountId <> null){
                	custDataDetails = new custData('true', 'data found.');
                    
                    List<custDataList> listOfCustData = new List<custDataList>();
                    
                    List<Account> accountList = [Select Id,
                                                        Name,
                                                        firstname,
                                                        lastname,
                                                        PersonEmail,
                                                 		PersonMobilePhone,
                                                        Phone,
                                                        BusinessEmail__c,
                                                        PersonTitle,
                                                        Password__c,
                                                        PersonGenderIdentity,
                                                        PersonBirthdate,
                                                        /*ClickToDial__Country_Code__c,*/
                                                        State__r.name,
                                                        State__r.State_Name__c,
                                                        Country__r.name,
                                                        Country__r.Country_Name__c,
                                                        Pin_Code__c/*,
                                                        type,
                                                        BillingCity,
                                                        BillingStreet*/
                                                 From Account
                                                 Where id = :oppList[0].AccountId];
                    
                    if(accountList <> null && !accountList.isEmpty()){
                        for(Account acc : accountList){
                            custDataList custDataListDetails  = new custDataList();
							custDataListDetails.id = acc.id;
                            custDataListDetails.name = acc.name;
                            custDataListDetails.first_name = acc.FirstName;
                            custDataListDetails.last_name = acc.LastName;
                            custDataListDetails.email = acc.PersonEmail;
                            custDataListDetails.mobile = acc.Phone;
                            custDataListDetails.gender = acc.PersonGenderIdentity;
                            custDataListDetails.dob = String.valueOf(acc.PersonBirthdate);
                            custDataListDetails.country_id = new List<String>{acc.Country__r.name, acc.Country__r.Country_Name__c};
                            custDataListDetails.title = new List<String>{salutationList[0].name, salutationList[0].Salutation_Name__c};
                            //custDataListDetails.credit_limit = acc.gender;
                            //custDataListDetails.ledger_balance = acc.gender;
                            //custDataListDetails.booking_balance = acc.gender;

                            listOfCustData.add(custDataListDetails);
                        }
                                            
                        custDataDetails.datalist = listOfCustData;
                    }
                    
                    
                    mden_responseWrapper.custData = custDataDetails;                                
                }else{
                    custDataDetails = new custData('false', 'data not found.');
                }                
                
                /********** End : Fetching Cust Data i.e. Opportunity Details **********/                
                
                /********** Start : Fetching gso Data i.e. ----- Details **********/    
                if(oppList <> null && !oppList.isEmpty()){
                	gsoDataDetails = new gsoData('true', 'data found.');
                    
                    /*
                    List<Passenger_Details__c> passengerList = [Select id, First_Name__c, Last_Name__c, dob__c, Passport_No__c, Travel_PNR_No__c, Age__c, Travel_Class__c
                                                 From Passenger_Details__c
                                                 Where Opportunity_ID__c = :oppList[0].id];
                    
                    if(passengerList <> null && !passengerList.isEmpty()){
                        for(Passenger_Details__c passengerDetail : passengerList){
                            guestDataList guestDataListDetails  = new guestDataList();
					    }
                                            
                    }
                    */
                    
                    mden_responseWrapper.gsoData = gsoDataDetails;                                
                }else{
                    gsoDataDetails = new gsoData('false', 'data not found.');
                }
                
                /********** End : Fetching gso Data i.e. ----- Details **********/   
                
                
                /********** Start : Fetching porter Data i.e. ----- Details **********/    
                if(oppList <> null && !oppList.isEmpty()){
                	porterDataDetails = new porterData('true', 'data found.');
                    
                    /*
                    List<Passenger_Details__c> passengerList = [Select id, First_Name__c, Last_Name__c, dob__c, Passport_No__c, Travel_PNR_No__c, Age__c, Travel_Class__c
                                                 From Passenger_Details__c
                                                 Where Opportunity_ID__c = :oppList[0].id];
                    
                    if(passengerList <> null && !passengerList.isEmpty()){
                        for(Passenger_Details__c passengerDetail : passengerList){
                            guestDataList guestDataListDetails  = new guestDataList();
					    }
                                            
                    }
                    */
                    
                    mden_responseWrapper.porterData = porterDataDetails;                                
                }else{
                    porterDataDetails = new porterData('false', 'data not found.');
                }
                /********** End : Fetching porter Data i.e. ----- Details **********/ 
                
                /********** Start : Fetching buggy Data i.e. ----- Details **********/    
                if(oppList <> null && !oppList.isEmpty()){
                	buggyDataDetails = new buggyData('true', 'data found.');
                    
                    /*
                    List<Passenger_Details__c> passengerList = [Select id, First_Name__c, Last_Name__c, dob__c, Passport_No__c, Travel_PNR_No__c, Age__c, Travel_Class__c
                                                 From Passenger_Details__c
                                                 Where Opportunity_ID__c = :oppList[0].id];
                    
                    if(passengerList <> null && !passengerList.isEmpty()){
                        for(Passenger_Details__c passengerDetail : passengerList){
                            guestDataList guestDataListDetails  = new guestDataList();
					    }
                                            
                    }
                    */
                    
                    mden_responseWrapper.buggyData = buggyDataDetails;                                
                }else{
                    buggyDataDetails = new buggyData('false', 'data not found.');
                }
                
                
                /********** End : Fetching buggy	 Data i.e. ----- Details **********/                    
            }
        }catch(Exception e){
            mainDataDetails = new mainData('false', 'data not found.');
            itemDataDetails = new itemData('false', 'data not found.');
            guestDataDetails = new guestData('false', 'data not found.');
            custDataDetails = new custData('false', 'data not found.');
            gsoDataDetails = new gsoData('false', 'data not found.');
            porterDataDetails = new porterData('false', 'data not found.');
            buggyDataDetails = new buggyData('false', 'data not found.');
            //system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }
        
        /*String resBody = '{        '+
                            ' "mainData": {        '+
                            '  "status": "true",        '+
                            '  "message": "data found.",        '+
                            '  "datalist": [        '+
                            '   {        '+
                            '    "id": "006Su00000AOxScIAL",        '+
                            '    "partner_id": [        '+
                            '     "914",        '+
                            '     "SHRIDA TRAVELS"        '+
                            '    ],        '+
                            '    "name": "S09050",        '+
                            '    "date_order": "2022-06-24 14:12:29",        '+
                            '    "date": "2022-06-25 05:30:00",        '+
                            '    "airport_location_id": [        '+
                            '     "8008",        '+
                            '     "Indira Gandhi International Airport"        '+
                            '    ],        '+
                            '    "commitment_date": "2022-06-25 10:55:00",        '+
                            '    "airport_terminal_id": [        '+
                            '     "2",        '+
                            '     "International"        '+
                            '    ],        '+
                            '    "arrival_flight_id": [        '+
                            '     "47433",        '+
                            '     "UK-18"        '+
                            '    ],        '+
                            '    "departure_flight_id": {        '+
                            '     "1": "NA"        '+
                            '    },        '+
                            '    "arrival_airline_id": [        '+
                            '     "63",        '+
                            '     "VISTARA"        '+
                            '    ],        '+
                            '    "departure_airline_id": {        '+
                            '     "1": "NA"        '+
                            '    },        '+
                            '    "service_category": "Welcome and Assist",        '+
                            '    "service_type_id": [        '+
                            '     "1",        '+
                            '     "Arrival"        '+
                            '    ],        '+
                            '    "arrival_time": "1055",        '+
                            '    "departure_time": "",        '+
                            '    "booking_made_from": "b2b",        '+
                            '    "from_airport_id": [        '+
                            '     "8472",        '+
                            '     "London Heathrow International Airport"        '+
                            '    ],        '+
                            '    "to_airport_id": [        '+
                            '     "8008",        '+
                            '     "Indira Gandhi International Airport"        '+
                            '    ],        '+
                            '    "no_of_adult": "1",        '+
                            '    "no_of_children": "0",        '+
                            '    "no_of_infants": "0",        '+
                            '    "itinerary_no": "M49994677",        '+
                            '    "pricelist_id": [        '+
                            '     "3",        '+
                            '     "15% Discount (INR)"        '+
                            '    ],        '+
                            '    "placard_name": "MR. SUSHAIN MITTAL",        '+
                            '    "contact_number": "9910031518",        '+
                            '    "placard_email": "false",        '+
                            '    "title": [        '+
                            '     "42",        '+
                            '     "MS."        '+
                            '    ],        '+
                            '    "first_name": "SUSHAIN",        '+
                            '    "last_name": "MITTAL",        '+
                            '    "country_code": "91",        '+
                            '    "instruction_comments": "Porter/ Buggy",        '+
                            '    "gso_ids": [],        '+
                            '    "porter_ids": [],        '+
                            '    "buggy_driver_ids": [],        '+
                            '    "booking_stage": "confirmed",        '+
                            '    "state": "sale",        '+
                            '    "amount_total": "3400",        '+
                            '    "milestone_status": "false",        '+
                            '    "guest_feedback": "false",        '+
                            '    "additional_info": "false",        '+
                            '    "payment_method": "on_credit",        '+
                            '    "atime": "10:55",        '+
                            '    "dtime": ""        '+
                            '   }        '+
                            '  ]        '+
                            ' },        '+
                            ' "itemData": {        '+
                            '  "status": "true",        '+
                            '  "message": "data found.",        '+
                            '  "datalist": [        '+
                            '   {        '+
                            '    "id": "10635",        '+
                            '    "product_id": [        '+
                            '     "36",        '+
                            '     "SILVER (INT-ARR) (Adult)"        '+
                            '    ],        '+
                            '    "name": "SILVER (INT-ARR)",        '+
                            '    "product_uom_qty": "1",        '+
                            '    "product_uom": [        '+
                            '     "1",        '+
                            '     "Units"        '+
                            '    ],        '+
                            '    "price_unit": "2881.36",        '+
                            '    "price_subtotal": "2881.36"        '+
                            '   }        '+
                            '  ]        '+
                            ' },        '+
                            ' "guestData": {        '+
                            '  "status": "true",        '+
                            '  "message": "data found.",        '+
                            '  "datalist": [        '+
                            '   {        '+
                            '    "id": "13963",        '+
                            '    "first_name": "SUSHAIN",        '+
                            '    "last_name": "MITTAL",        '+
                            '    "dob": "2022-06-24",        '+
                            '    "passport": "",        '+
                            '    "pnr_no": "",        '+
                            '    "age": "0",        '+
                            '    "class_type": "business"        '+
                            '   }        '+
                            '  ]        '+
                            ' },        '+
                            ' "custData": {        '+
                            '  "status": "true",        '+
                            '  "message": "data found.",        '+
                            '  "datalist": [        '+
                            '   {        '+
                            '    "id": "914",        '+
                            '    "name": "SHRIDA TRAVELS",        '+
                            '    "first_name": "JYOTI",        '+
                            '    "last_name": "ARORA",        '+
                            '    "email": "shridatravels01@gmail.com",        '+
                            '    "mobile": "+91 99100 31518",        '+
                            '    "gender": "false",        '+
                            '    "dob": "1970-01-01",        '+
                            '    "country_id": [        '+
                            '     "104",        '+
                            '     "India"        '+
                            '    ],        '+
                            '    "title": [        '+
                            '     "42",        '+
                            '     "MS."        '+
                            '    ],        '+
                            '    "credit_limit": "2000",        '+
                            '    "ledger_balance": "10000",        '+
                            '    "booking_balance": "7500"        '+
                            '   }        '+
                            '  ]        '+
                            ' },        '+
                            ' "gsoData": {        '+
                            '  "status": "true",        '+
                            '  "message": "data not found."        '+
                            ' },        '+
                            ' "porterData": {        '+
                            '  "status": "true",        '+
                            '  "message": "data not found."        '+
                            ' },        '+
                            ' "buggyData": {        '+
                            '  "status": "true",        '+
                            '  "message": "data not found."        '+
                            ' }        '+
                            '}';
            */
        
        return mden_responseWrapper;
    }	 
    /*
    global static boolean checkCustomerDuplicacy(String email, String accId){
        Account acc = new Account();
        system.debug('email==>'+email);
        system.debug('accId==>'+accId);
        
        try{
            if(accId <> null){
                acc = [Select id from Account Where PersonEmail = :email AND id != :accId];
            }else{
                acc = [Select id from Account Where PersonEmail = :email];
            }
            system.debug('acc==>'+acc	);
            if(acc <> null){
                return true;
            }else{
                return false;
            }
        }catch(Exception e){
            System.debug('Error Message : '+e.getMessage());
            return false;
        }
    }
    */
    global class MDEN_GetResponseWrapper {
        global mainData mainData; 
        global itemData itemData;
        global guestData guestData;
        global custData custData;
        global gsoData gsoData;
        global porterData porterData;
        global buggyData buggyData;
        
        global MDEN_GetResponseWrapper(){}        
    }
    
    global class mainData{
        global String status;
        global String message; 
        global List<mainDataList> datalist;
        
        global mainData(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 
	
    global class mainDataList{
        global String id;
        global List<String> partner_id;
        global String name;
        global String date_order;
        global String dates;
        global List<String> airport_location_id;
        global String commitment_date;
        global List<String> airport_terminal_id;
        global List<String> arrival_flight_id;
        global List<String> departure_flight_id;
        global List<String> arrival_airline_id;
        global List<String> departure_airline_id;
        global String service_category;
        global List<String> service_type_id;
        global String arrival_time;
        global String departure_time;
        global String booking_made_from;
        global List<String> from_airport_id;
        global List<String> to_airport_id;
        global String no_of_adult;
        global String no_of_children;
        global String no_of_infants;
        global String itinerary_no;
        global List<String> pricelist_id;
        global String placard_name;
        global String contact_number;
        global String placard_email;
        global List<String> title;
        global String first_name;
        global String last_name;
        global String country_code;
        global String instruction_comments;
        global List<String> gso_ids;
        global List<String> porter_ids;
        global List<String> buggy_driver_ids;
        global String booking_stage;
        global String state;
        global String amount_total;
        global String milestone_status;
        global String guest_feedback;
        global String additional_info;
        global String payment_method;
        global String atime;
        global String dtime;
        
        global mainDataList(){}
    }
        
    global class itemData{
        global String status;
        global String message; 
        global List<itemDataList> datalist;
        
        global itemData(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 
	
    global class itemDataList{
        global String id;
        global List<String> product_id;
        global String name;
        global String product_uom_qty;
        global List<String> product_uom;
        global String price_unit;
        global String price_subtotal;
        
        global itemDataList(){}
    }

    global class guestData{
        global String status;
        global String message; 
        global List<guestDataList> datalist;
        
        global guestData(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 
	
    global class guestDataList{
        global String id;
        global String first_name;
        global String last_name;
        global String dob;
        global String passport;
        global String pnr_no;
        global String age;
        global String class_type;
        
        global guestDataList(){}
    }
    
    global class custData{
        global String status;
        global String message; 
        global List<custDataList> datalist;
        
        global custData(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 
	
    global class custDataList{
        global String id;
        global String name;
        global String first_name;
        global String last_name;
        global String email;
        global String mobile;
        global String gender;
        global String dob;
        global List<String> country_id;
        global List<String> title;
        global String credit_limit;
        global String ledger_balance;
        global String booking_balance;
            
        global custDataList(){}
    }
    
    global class gsoData{
        global String status;
        global String message; 
        
        global gsoData(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 
    
    global class porterData{
        global String status;
        global String message; 
        
        global porterData(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 

    
    global class buggyData{
        global String status;
        global String message; 
        
        global buggyData(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 
    
    global class MDEN_GetRequestWrapper {
        global String id;
        global MDEN_GetRequestWrapper(){}        
    }
}