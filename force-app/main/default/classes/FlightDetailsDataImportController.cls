public class FlightDetailsDataImportController {
    @AuraEnabled
    public static void importCSVFile(String csvString, String airportCodeFromFileName) {
        List<String> rows = csvString.split('\\n');
        Map<String, String> daysOfWeekMap = new Map<String, String>{'Monday' => '1', 'Tuesday' => '2', 'Wednesday' => '3', 'Thursday' => '4', 'Friday' => '5', 'Saturday' => '6', 'Sunday' => '7'};
        
        //Map<String, Map<String, Map<String, Flight_Detail__c>>> flightDetailsMap = new Map<String, Map<String, Map<String, Flight_Detail__c>>>();
        Map<String, Flight_Detail__c> flightDetailsMap = new Map<String, Flight_Detail__c>();
        Map<String, Flight_Schedule__c> flightScheduleMap = new Map<String, Flight_Schedule__c>();
        Map<String, Transit_Flight_Detail__c> transitFlightDetailMap = new Map<String, Transit_Flight_Detail__c>();

        Map<String, Airline__c> airlineMap = new Map<String, Airline__c>();
        Map<String, Airport__c> airportMap = new Map<String, Airport__c>();
        Map<String, Map<String, Terminal__c>> terminalMap = new Map<String, Map<String, Terminal__c>>();
      //  Map<Integer, List<Id>> rowVsDepartureArrivalFlightIds = new Map<Integer, List<Id>>();

        List<Flight_Detail__c> flightDetailsToInsert = new List<Flight_Detail__c>();
        List<Flight_Schedule__c> flightSchedulesToInsert = new List<Flight_Schedule__c>();
        List<Transit_Flight_Detail__c> transitFlightDetailsToInsert = new List<Transit_Flight_Detail__c>();


        Flight_Detail__c flightDetail;
        String airline;
        String flightNumberArrival;
        String flightNumberDeparture;
        String origin;
        String destination;
        String arrivalTerminal;
        String departureTerminal;
        String arrivalTime;
        String departureTime;
        String frequency;
        Date fromDate;
        Date toDate;
        Date today = Date.today();

        //try{
            for(Flight_Detail__c fdetail : [SELECT id, Flight_Number__c, Arrival_Airport__c, Departure_Airport__c FROM Flight_Detail__c LIMIT 49999]){
                String fdetailKey = fdetail.Flight_Number__c +'_'+ fdetail.Arrival_Airport__c +'_'+ fdetail.Departure_Airport__c;
                flightDetailsMap.put(fdetailKey, fdetail);
            /*if (!flightDetailsMap.containsKey(fdetail.Flight_Number__c)) {
                    flightDetailsMap.put(fdetail.Flight_Number__c, new Map<String, Map<String, Flight_Detail__c>>());
                }
                if (!flightDetailsMap.get(fdetail.Flight_Number__c).containsKey(fdetail.Arrival_Airport__c)) {
                    flightDetailsMap.get(fdetail.Flight_Number__c).put(fdetail.Arrival_Airport__c, new Map<String, Flight_Detail__c>());
                }
                if (!flightDetailsMap.get(fdetail.Flight_Number__c).get(fdetail.Arrival_Airport__c).containsKey(fdetail.Departure_Airport__c)) {
                    flightDetailsMap.get(fdetail.Flight_Number__c).get(fdetail.Arrival_Airport__c).put(fdetail.Departure_Airport__c, fdetail);
                }*/
            }

            for(Flight_Schedule__c fsch : [SELECT id, Flight_Detail__c, Flight_Date__c, Departure_Terminal__c, Arrival_Terminal__c, STD__c, STA__c FROM Flight_Schedule__c where Flight_Date__c >= :today LIMIT 49999]){
                String depTerminal = fsch.Departure_Terminal__c;
                String arrTerminal = fsch.Arrival_Terminal__c;
                String fschKey;
                if(depTerminal != '')
                    fschKey = fsch.Flight_Detail__c +'_'+ fsch.Flight_Date__c +'_'+ fsch.Departure_Terminal__c +'_'+ fsch.STD__c;
                else if(arrTerminal != '')
                    fschKey = fsch.Flight_Detail__c +'_'+ fsch.Flight_Date__c +'_'+ fsch.Arrival_Terminal__c +'_'+ fsch.STA__c;
                if(fschKey != null)
                    flightScheduleMap.put(fschKey, fsch);   
            }

            for(Transit_Flight_Detail__c transit : [SELECT Id, Transit_Airport__c, Main_Flight__c, Connecting_Flight__c FROM Transit_Flight_Detail__c WHERE Main_Flight__c != null AND Connecting_Flight__c != null LIMIT 49999]){
                String transitKey = transit.Transit_Airport__c +'_'+ transit.Main_Flight__c +'_'+ transit.Connecting_Flight__c; 
                transitFlightDetailMap.put(transitKey, transit);
            }

            for(Airline__c aline : [SELECT id, Airline_Code__c, Airline_Name__c  FROM Airline__c LIMIT 49999]){
                airlineMap.put(aline.Airline_Code__c, aline);
            }

            for (Airport__c airport : [SELECT Id, Airport_Code__c FROM Airport__c LIMIT 49999]) 
            {
                airportMap.put(airport.Airport_Code__c, airport);
            }

            for (Terminal__c tr : [SELECT id, Name, Airport__c  FROM Terminal__c LIMIT 49999]) 
            {
                if (!terminalMap.containsKey(tr.Airport__c)) {
                    terminalMap.put(tr.Airport__c, new Map<String, Terminal__c>());
                }
                if (!terminalMap.get(tr.Airport__c).containsKey(tr.Name)) {
                    terminalMap.get(tr.Airport__c).put(tr.Name, tr);
                }
            }

            for (Integer i = 1; i < rows.size(); i++) { // Skipping header row
                List<String> columns = rows[i].split(',');
                if (columns.size() < 11) continue;

                airline = columns[0];
                flightNumberArrival = columns[1];
                flightNumberDeparture = columns[2];
                origin = columns[4];
                destination = columns[7];

                // Insert the Flight_Detail__c record if it is not present in the system (chekcing flight Number, Arrival & Destination Airport values to find the existing record)
                if(flightNumberDeparture != null && flightNumberDeparture != ''){
                    
                  //  if(!flightDetailsMap.containsKey(flightNumberDeparture) || !flightDetailsMap.get(flightNumberDeparture).containsKey(airportMap.get(destination).Id)
                  //  || !flightDetailsMap.get(flightNumberDeparture).get(airportMap.get(destination).Id).containsKey(airportMap.get(airportCodeFromFileName).Id))
                    if(!flightDetailsMap.containsKey(flightNumberDeparture +'_'+ airportMap.get(destination).Id +'_'+ airportMap.get(airportCodeFromFileName).Id))
                    {
                        System.debug('--flightNumberDepartue does not exist---');
                        flightDetail = new Flight_Detail__c(
                            Airline_Id__c = airlineMap.get(airline).Id,
                            Flight_Number__c = flightNumberDeparture,
                            Name = airline + '-' + flightNumberDeparture,
                            Arrival_Airport__c = airportMap.get(destination).Id,
                            Departure_Airport__c = airportMap.get(airportCodeFromFileName).Id
                        );
                        flightDetailsToInsert.add(flightDetail);
                    }
                }

                if(flightNumberArrival != null && flightNumberArrival != ''){
                    
                    //if(!flightDetailsMap.containsKey(flightNumberArrival) || !flightDetailsMap.get(flightNumberArrival).containsKey(airportMap.get(airportCodeFromFileName).Id)
                    // || !flightDetailsMap.get(flightNumberArrival).get(airportMap.get(airportCodeFromFileName).Id).containsKey(airportMap.get(origin).Id))
                    if(!flightDetailsMap.containsKey(flightNumberArrival +'_'+ airportMap.get(airportCodeFromFileName).Id +'_'+ airportMap.get(origin).Id))
                    {
                        System.debug('--flightNumberArrival does not exist---');
                        flightDetail = new Flight_Detail__c(
                            Airline_Id__c = airlineMap.get(airline).Id,
                            Flight_Number__c = flightNumberArrival,
                            Name = airline + '-' + flightNumberArrival,
                            Arrival_Airport__c = airportMap.get(airportCodeFromFileName).Id, //'DEL',
                            Departure_Airport__c = airportMap.get(origin).Id
                        );
                        flightDetailsToInsert.add(flightDetail);
                    }
                }
                
                System.debug('flightDetailsToInsert.size()-->'+flightDetailsToInsert.size());
            }

            // Insert Flight_Detail__c records and map their IDs
            if (!flightDetailsToInsert.isEmpty()) {
                insert flightDetailsToInsert;

                for (Flight_Detail__c fd : flightDetailsToInsert) {

                    String key = fd.Flight_Number__c +'_'+ fd.Arrival_Airport__c +'_'+ fd.Departure_Airport__c;
                    flightDetailsMap.put(key, fd);

                    /*if (!flightDetailsMap.containsKey(fd.Flight_Number__c)) {
                        flightDetailsMap.put(fd.Flight_Number__c, new Map<String, Map<String, Flight_Detail__c>>());
                    }
                    if (!flightDetailsMap.get(fd.Flight_Number__c).containsKey(fd.Arrival_Airport__c)) {
                        flightDetailsMap.get(fd.Flight_Number__c).put(fd.Arrival_Airport__c, new Map<String, Flight_Detail__c>());
                    }
                    if (!flightDetailsMap.get(fd.Flight_Number__c).get(fd.Arrival_Airport__c).containsKey(fd.Departure_Airport__c)) {
                        flightDetailsMap.get(fd.Flight_Number__c).get(fd.Arrival_Airport__c).put(fd.Departure_Airport__c, fd);
                    }*/
                }
                System.debug('flightDetailsMap.values()-->'+flightDetailsMap.values());
            }

            // Process Flight_Schedule__c and Transit_Flight_Detail__c records
            for (Integer i = 1; i < rows.size(); i++) {
                List<String> columns = rows[i].split(',');
                if (columns.size() < 11) continue;

                flightNumberArrival = columns[1];
                flightNumberDeparture = columns[2];
                origin = columns[4];
                destination = columns[7];
                arrivalTerminal = columns[10];
                departureTerminal = columns[11].replace('\r', '');
                arrivalTime = columns[5];
                departureTime = columns[6];
                frequency = columns[3];
                fromDate = Date.parse(columns[8]);
                toDate = Date.parse(columns[9]);
            
                //Process Flight_Schedule__c records for Departing flights    
                if (flightNumberDeparture != null && flightNumberDeparture != '' )
                {
                    // Ensure flightDetail is retrieved correctly
                    String flightDetailKey = flightNumberDeparture +'_'+ airportMap.get(destination).Id +'_'+ airportMap.get(airportCodeFromFileName).Id;
                   // if(flightDetailsMap.containsKey(flightNumberDeparture) && flightDetailsMap.get(flightNumberDeparture).containsKey(airportMap.get(destination).Id)
                    //&& flightDetailsMap.get(flightNumberDeparture).get(airportMap.get(destination).Id).containsKey(airportMap.get(airportCodeFromFileName).Id))
                    if(flightDetailsMap.containsKey(flightDetailKey))
                    {
                        Id flightDetailId = flightDetailsMap.get(flightDetailKey).Id;
                        Id terminalId = terminalMap.get(airportMap.get(airportCodeFromFileName).Id).get(departureTerminal).Id;
                        Date currentDate = fromDate;

                        while (currentDate <= toDate) {
                            DateTime fromDateTime = (DateTime)currentDate;
                            String dayOfWeek = daysOfWeekMap.get(fromDateTime.format('EEEE'));
                        
                            if(frequency.contains(dayOfWeek)){
                                Integer minutes = Integer.valueOf(departureTime.substring(departureTime.length() - 2));
                                Integer hours = (departureTime.length() > 2) ? Integer.valueOf(departureTime.substring(0, departureTime.length() - 2)) : 0;
                                Time t = Time.newInstance(hours, minutes, 0, 0);
                                String k = flightDetailId +'_'+ currentDate +'_'+ terminalId +'_'+ t;
                                System.debug('key--k-->'+k);

                                // Insert the Flight_Schedule__c record if it is not present in the system (with same flightDetailId, date, termial and time)
                                if(!flightScheduleMap.containsKey(k)){
                                    flightSchedulesToInsert.add(new Flight_Schedule__c(
                                        Flight_Detail__c = flightDetailId,
                                        Flight_Date__c = currentDate,
                                        Departure_Terminal__c = terminalId,
                                        STD__c = t
                                    ));
                                }
                                
                            }   
                            currentDate = currentDate.addDays(1);
                        } 
                       /* if(!rowVsDepartureArrivalFlightIds.containsKey(i))
                        {
                            rowVsDepartureArrivalFlightIds.put(i, new List<Id>{flightDetailId});
                        }
                        else{
                            rowVsDepartureArrivalFlightIds.get(i).add(flightDetailId);
                        }
                        System.debug('departure--rowVsDepartureArrivalFlightIds.get(i)-->'+rowVsDepartureArrivalFlightIds.get(i));  */ 
                    }
                }

                //Process Flight_Schedule__c records for arriving flights  
                if (flightNumberArrival != null && flightNumberArrival != '' )
                {
                    String flightDetailKey = flightNumberArrival +'_'+ airportMap.get(airportCodeFromFileName).Id +'_'+ airportMap.get(origin).Id;
                
                   // if(flightDetailsMap.containsKey(flightNumberArrival) && flightDetailsMap.get(flightNumberArrival).containsKey(airportMap.get(airportCodeFromFileName).Id)
                   // && flightDetailsMap.get(flightNumberArrival).get(airportMap.get(airportCodeFromFileName).Id).containsKey(airportMap.get(origin).Id))
                    if(flightDetailsMap.containsKey(flightDetailKey))
                    {
                        Id flightDetailId = flightDetailsMap.get(flightDetailKey).Id;
                        Id terminalId = terminalMap.get(airportMap.get(airportCodeFromFileName).Id).get(arrivalTerminal).Id;
                        Date currentDate = fromDate;
                        while (currentDate <= toDate) {
                            System.debug('currentDate-->'+currentDate);
                            DateTime fromDateTime = (DateTime)currentDate;
                            String dayOfWeek = daysOfWeekMap.get(fromDateTime.format('EEEE'));
                            System.debug('dayOfWeek-->'+dayOfWeek);
                        
                            if(frequency.contains(dayOfWeek)){
                                Integer minutes = Integer.valueOf(arrivalTime.substring(arrivalTime.length() - 2));
                                Integer hours = (arrivalTime.length() > 2) ? Integer.valueOf(arrivalTime.substring(0, arrivalTime.length() - 2)) : 0;
                                Time t = Time.newInstance(hours, minutes, 0, 0);

                                String k = flightDetailId +'_'+ currentDate +'_'+ terminalId +'_'+ t;

                                if(!flightScheduleMap.containsKey(k)){
                                    flightSchedulesToInsert.add(new Flight_Schedule__c(
                                            Flight_Detail__c = flightDetailId,
                                            Flight_Date__c = currentDate,
                                            Arrival_Terminal__c = terminalId,
                                            STA__c = t
                                        ));
                                }
                            }
                            currentDate = currentDate.addDays(1);
                        }
                        /*if(!rowVsDepartureArrivalFlightIds.containsKey(i))
                            {
                                rowVsDepartureArrivalFlightIds.put(i, new List<Id>{flightDetailId});
                            }
                            else{
                                rowVsDepartureArrivalFlightIds.get(i).add(flightDetailId);
                            }
                            System.debug('arrival--rowVsDepartureArrivalFlightIds.get(i)-->'+rowVsDepartureArrivalFlightIds.get(i));*/
                    }
                }

                //Process Transit_Flight_Detail__c records (only when a row has both Arrival and Departure details AND if it is not present in the system)
                if(flightNumberDeparture != null && flightNumberDeparture != ''  && flightNumberArrival != null && flightNumberArrival != ''){
                    
                    Id departureFlightId = flightDetailsMap.get(flightNumberDeparture +'_'+ airportMap.get(destination).Id +'_'+ airportMap.get(airportCodeFromFileName).Id).Id;
                    Id arrivalFlightId = flightDetailsMap.get(flightNumberArrival +'_'+ airportMap.get(airportCodeFromFileName).Id +'_'+ airportMap.get(origin).Id).Id;
                    String transitFlightKey = airportMap.get(airportCodeFromFileName).Id +'_'+ arrivalFlightId +'_'+ departureFlightId;

                    if(!transitFlightDetailMap.containsKey(transitFlightKey))
                    {
                        transitFlightDetailsToInsert.add(new Transit_Flight_Detail__c(
                                Main_Flight__c = arrivalFlightId,
                                Connecting_Flight__c = departureFlightId,
                                Transit_Airport__c = airportMap.get(airportCodeFromFileName).Id
                            ));
                    }
                }
                
            }

            // Insert Flight_Schedule__c records
            if (!flightSchedulesToInsert.isEmpty()) {
                insert flightSchedulesToInsert;
            }

            //Insert Transit_Flight_Detail__c records (only when a row has both Arrival and Departure details)
           /* if(!rowVsDepartureArrivalFlightIds.isEmpty()){
                for(Integer i : rowVsDepartureArrivalFlightIds.keySet()){
                    System.debug('rowVsDepartureArrivalFlightIds.get(i).size()-->'+rowVsDepartureArrivalFlightIds.get(i).size());
                    if(rowVsDepartureArrivalFlightIds.get(i).size() == 2){
                        transitFlightDetailsToInsert.add(new Transit_Flight_Detail__c(
                                Main_Flight__c = rowVsDepartureArrivalFlightIds.get(i)[0],
                                Connecting_Flight__c = rowVsDepartureArrivalFlightIds.get(i)[1],
                                Transit_Airport__c = airportMap.get(airportCodeFromFileName).Id
                            ));
                    }

                }
            }*/

            //Insert Transit_Flight_Detail__c records
            if(!transitFlightDetailsToInsert.isEmpty()){
                insert transitFlightDetailsToInsert;
            }

       /* }
        catch(Exception e){
            System.debug('exception-->'+e.getMessage());
            if(e.getMessage().contains('Invalid date'))
                throw new AuraHandledException('Please make sure to have the From (Date) & To (Date) in dd/mm/yyyy format');
            else
                throw new AuraHandledException(e.getMessage());
        }  */   
    }
}