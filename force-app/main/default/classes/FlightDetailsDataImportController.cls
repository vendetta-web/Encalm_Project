public class FlightDetailsDataImportController {
    @AuraEnabled
    public static void importCSVFile(String csvString) {
        List<String> rows = csvString.split('\\n');
        Map<String, String> daysOfWeekMap = new Map<String, String>{'Monday' => '1', 'Tuesday' => '2', 'Wednesday' => '3', 'Thursday' => '4', 'Friday' => '5', 'Saturday' => '6', 'Sunday' => '7'};
            
            Map<String, Flight_Detail__c> flightDetailsMap = new Map<String, Flight_Detail__c>();
        Map<String, Flight_Schedule__c> flightScheduleMap = new Map<String, Flight_Schedule__c>();
        // Map<String, Transit_Flight_Detail__c> transitFlightDetailMap = new Map<String, Transit_Flight_Detail__c>();
        
        Map<String, Airline__c> airlineMap = new Map<String, Airline__c>();
        Map<String, Airport__c> airportMap = new Map<String, Airport__c>();
        Map<String, Map<String, Terminal__c>> terminalMap = new Map<String, Map<String, Terminal__c>>();
        
        List<Airline__c> airlinesToInsert = new List<Airline__c>();
        List<Flight_Detail__c> flightDetailsToInsert = new List<Flight_Detail__c>();
        List<Flight_Schedule__c> flightSchedulesToInsert = new List<Flight_Schedule__c>();
        // List<Transit_Flight_Detail__c> transitFlightDetailsToInsert = new List<Transit_Flight_Detail__c>();
        
        
        Flight_Detail__c flightDetail;
        Flight_Schedule__c flightSchedule;
        String fdetailKey;
        String fschKey;
        String airlineName;
        String airlineCode;
        String airportCode;
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
            fdetailKey = fdetail.Flight_Number__c +'_'+ fdetail.Arrival_Airport__c +'_'+ fdetail.Departure_Airport__c;
            flightDetailsMap.put(fdetailKey, fdetail);
        }
        
        for(Flight_Schedule__c fsch : [SELECT id, Flight_Detail__c, Flight_Date__c, Departure_Terminal__c, Arrival_Terminal__c, STD__c, STA__c FROM Flight_Schedule__c where Flight_Date__c >= :today LIMIT 49999]){
            String depTerminal = fsch.Departure_Terminal__c;
            String arrTerminal = fsch.Arrival_Terminal__c;
            
            if(depTerminal != '')
                fschKey = fsch.Flight_Detail__c +'_'+ fsch.Flight_Date__c +'_'+ fsch.Departure_Terminal__c +'_'+ fsch.STD__c;
            else if(arrTerminal != '')
                fschKey = fsch.Flight_Detail__c +'_'+ fsch.Flight_Date__c +'_'+ fsch.Arrival_Terminal__c +'_'+ fsch.STA__c;
            flightScheduleMap.put(fschKey, fsch);   
        }
        
        /* for(Transit_Flight_Detail__c transit : [SELECT Id, Transit_Airport__c, Main_Flight__c, Connecting_Flight__c FROM Transit_Flight_Detail__c WHERE Main_Flight__c != null AND Connecting_Flight__c != null LIMIT 49999]){
String transitKey = transit.Transit_Airport__c +'_'+ transit.Main_Flight__c +'_'+ transit.Connecting_Flight__c; 
transitFlightDetailMap.put(transitKey, transit);
}*/
        
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
        
        // Loop all rows and insert airlines
        for (Integer i = 1; i < rows.size(); i++) {
            List<String> columns = rows[i].split(',');
            airlineName = columns[1];
            airlineCode = columns[3];
            //Insert Airlines
            if(airlineCode != '' && airlineCode != null && !airlineMap.containsKey(airlineCode)){
                Airline__c airl = new Airline__c(
                    Airline_Code__c = airlineCode,
                    Airline_Name__c = airlineName 
                );
                airlineMap.put(airl.Airline_Code__c, airl);
                airlinesToInsert.add(airl);
            }
            System.debug('airlinesToInsert--->'+airlinesToInsert);
        }
        if (!airlinesToInsert.isEmpty()) 
        {
            insert airlinesToInsert;
            for (Airline__c al : airlinesToInsert) 
            {
                airlineMap.put(al.Airline_Code__c, al);
            }
            System.debug('airlineMap.values()-->'+airlineMap.values());
        }
        
        
        // Process Flight Detail Records
        for (Integer i = 1; i < rows.size(); i++) { // Skipping header row
            List<String> columns = rows[i].split(',');
            if (columns.size() < 11) continue;
            
            airlineName = columns[1];
            airportCode = columns[2];
            airlineCode = columns[3];
            flightNumberArrival = columns[4];
            flightNumberDeparture = columns[5];
            origin = columns[9];
            destination = columns[15];
            
            // Insert the Flight_Detail__c record if it is not present in the system (chekcing flight Number, Arrival & Destination Airport values to find the existing record)
            if(flightNumberDeparture != null && flightNumberDeparture != '')
            {
                if(!flightDetailsMap.containsKey(flightNumberDeparture +'_'+ airportMap.get(destination).Id +'_'+ airportMap.get(airportCode).Id))
                {
                    System.debug('--flightNumberDepartue does not exist---');
                    flightDetail = new Flight_Detail__c(
                        Airline_Id__c = airlineMap.get(airlineCode).Id,
                        Flight_Number__c = flightNumberDeparture,
                        Name = airlineCode + '-' + flightNumberDeparture,
                        Arrival_Airport__c = airportMap.get(destination).Id,
                        Departure_Airport__c = airportMap.get(airportCode).Id
                    );
                    fdetailKey = flightDetail.Flight_Number__c +'_'+ flightDetail.Arrival_Airport__c +'_'+ flightDetail.Departure_Airport__c;
                    flightDetailsMap.put(fdetailKey, flightDetail);
                    flightDetailsToInsert.add(flightDetail);
                }
            }
            
            if(flightNumberArrival != null && flightNumberArrival != '')
            {
                if(!flightDetailsMap.containsKey(flightNumberArrival +'_'+ airportMap.get(airportCode).Id +'_'+ airportMap.get(origin).Id))
                {
                    System.debug('--flightNumberArrival does not exist---');
                    flightDetail = new Flight_Detail__c(
                        Airline_Id__c = airlineMap.get(airlineCode).Id,
                        Flight_Number__c = flightNumberArrival,
                        Name = airlineCode + '-' + flightNumberArrival,
                        Arrival_Airport__c = airportMap.get(airportCode).Id, //'DEL',
                        Departure_Airport__c = airportMap.get(origin).Id
                    );
                    fdetailKey = flightDetail.Flight_Number__c +'_'+ flightDetail.Arrival_Airport__c +'_'+ flightDetail.Departure_Airport__c;
                    flightDetailsMap.put(fdetailKey, flightDetail);
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
            }
            System.debug('flightDetailsMap.values()-->'+flightDetailsMap.values());
        }
        
        // Process Flight_Schedule__c records
        for (Integer i = 1; i < rows.size(); i++) {
            List<String> columns = rows[i].split(',');
            if (columns.size() < 11) continue;
            
            flightNumberArrival = columns[4];
            flightNumberDeparture = columns[5];
            frequency = columns[8];
            origin = columns[9];
            arrivalTime = columns[11];
            departureTime = columns[12];
            destination = columns[15];
            fromDate = parseCustomDate(columns[16]); //Date.parse(columns[16]);
            toDate = parseCustomDate(columns[17]); //Date.parse(columns[17]);
            arrivalTerminal = columns[18];
            departureTerminal = columns[19]; //.replace('\r', '');
            
            //Process Flight_Schedule__c records for Departing flights    
            if (flightNumberDeparture != null && flightNumberDeparture != '' )
            {
                // Ensure flightDetail is retrieved correctly
                String flightDetailKey = flightNumberDeparture +'_'+ airportMap.get(destination).Id +'_'+ airportMap.get(airportCode).Id;
                if(flightDetailsMap.containsKey(flightDetailKey))
                {
                    Id flightDetailId = flightDetailsMap.get(flightDetailKey).Id;
                    Id terminalId = terminalMap.get(airportMap.get(airportCode).Id).get(departureTerminal).Id;
                    Date currentDate = fromDate;
                    
                    while (currentDate <= toDate) {
                        DateTime fromDateTime = (DateTime)currentDate;
                        String dayOfWeek = daysOfWeekMap.get(fromDateTime.format('EEEE'));
                        
                        if(frequency.contains(dayOfWeek)){
                            Integer minutes = Integer.valueOf(departureTime.split(':')[1]); //Integer.valueOf(departureTime.substring(departureTime.length() - 2));
                            Integer hours = Integer.valueOf(departureTime.split(':')[0]); //(departureTime.length() > 2) ? Integer.valueOf(departureTime.substring(0, departureTime.length() - 2)) : 0;
                            Time t = Time.newInstance(hours, minutes, 0, 0);
                            String k = flightDetailId +'_'+ currentDate +'_'+ terminalId +'_'+ t;
                            System.debug('key--k-->'+k);
                            
                            // Insert the Flight_Schedule__c record if it is not present in the system (with same flightDetailId, date, termial and time)
                            if(!flightScheduleMap.containsKey(k))
                            {
                                flightSchedule = new Flight_Schedule__c(
                                    Flight_Detail__c = flightDetailId,
                                    Flight_Date__c = currentDate,
                                    Departure_Terminal__c = terminalId,
                                    STD__c = t
                                );
                                fschKey = flightSchedule.Flight_Detail__c +'_'+ flightSchedule.Flight_Date__c +'_'+ flightSchedule.Departure_Terminal__c +'_'+ flightSchedule.STD__c;
                                flightScheduleMap.put(fschKey, flightSchedule); 
                                flightSchedulesToInsert.add(flightSchedule); 
                            }
                            
                        }   
                        currentDate = currentDate.addDays(1);
                    }
                }
            }
            
            //Process Flight_Schedule__c records for arriving flights  
            if (flightNumberArrival != null && flightNumberArrival != '' )
            {
                String flightDetailKey = flightNumberArrival +'_'+ airportMap.get(airportCode).Id +'_'+ airportMap.get(origin).Id;
                if(flightDetailsMap.containsKey(flightDetailKey))
                {
                    Id flightDetailId = flightDetailsMap.get(flightDetailKey).Id;
                    Id terminalId = terminalMap.get(airportMap.get(airportCode).Id).get(arrivalTerminal).Id;
                    Date currentDate = fromDate;
                    while (currentDate <= toDate) {
                        System.debug('currentDate-->'+currentDate);
                        DateTime fromDateTime = (DateTime)currentDate;
                        String dayOfWeek = daysOfWeekMap.get(fromDateTime.format('EEEE'));
                        System.debug('dayOfWeek-->'+dayOfWeek);
                        
                        if(frequency.contains(dayOfWeek)){
                            Integer minutes = Integer.valueOf(arrivalTime.split(':')[1]); //Integer.valueOf(arrivalTime.substring(arrivalTime.length() - 2));
                            Integer hours = Integer.valueOf(arrivalTime.split(':')[0]); //(arrivalTime.length() > 2) ? Integer.valueOf(arrivalTime.substring(0, arrivalTime.length() - 2)) : 0;
                            Time t = Time.newInstance(hours, minutes, 0, 0);
                            
                            String k = flightDetailId +'_'+ currentDate +'_'+ terminalId +'_'+ t;
                            
                            if(!flightScheduleMap.containsKey(k)){
                                flightSchedule = new Flight_Schedule__c(
                                    Flight_Detail__c = flightDetailId,
                                    Flight_Date__c = currentDate,
                                    Arrival_Terminal__c = terminalId,
                                    STA__c = t
                                );
                                fschKey = flightSchedule.Flight_Detail__c +'_'+ flightSchedule.Flight_Date__c +'_'+ flightSchedule.Arrival_Terminal__c +'_'+ flightSchedule.STA__c;
                                flightScheduleMap.put(fschKey, flightSchedule); 
                                flightSchedulesToInsert.add(flightSchedule);
                            }
                        }
                        currentDate = currentDate.addDays(1);
                    }
                }
            }
            
            //Process Transit_Flight_Detail__c records (only when a row has both Arrival and Departure details AND if it is not present in the system)
            /* if(flightNumberDeparture != null && flightNumberDeparture != ''  && flightNumberArrival != null && flightNumberArrival != ''){

                Id departureFlightId = flightDetailsMap.get(flightNumberDeparture +'_'+ airportMap.get(destination).Id +'_'+ airportMap.get(airportCode).Id).Id;
                Id arrivalFlightId = flightDetailsMap.get(flightNumberArrival +'_'+ airportMap.get(airportCode).Id +'_'+ airportMap.get(origin).Id).Id;
                String transitFlightKey = airportMap.get(airportCode).Id +'_'+ arrivalFlightId +'_'+ departureFlightId;
                
                if(!transitFlightDetailMap.containsKey(transitFlightKey))
                {
                transitFlightDetailsToInsert.add(new Transit_Flight_Detail__c(
                Main_Flight__c = arrivalFlightId,
                Connecting_Flight__c = departureFlightId,
                Transit_Airport__c = airportMap.get(airportCode).Id
                ));
                }
			}*/
            
        }
        
        // Insert Flight_Schedule__c records
        if (!flightSchedulesToInsert.isEmpty()) {
            insert flightSchedulesToInsert;
        }
        
        //Insert Transit_Flight_Detail__c records
        /*if(!transitFlightDetailsToInsert.isEmpty()){
insert transitFlightDetailsToInsert;
}*/
        
        /* }
catch(Exception e){
System.debug('exception-->'+e.getMessage());
if(e.getMessage().contains('Invalid date'))
throw new AuraHandledException('Please make sure to have the From (Date) & To (Date) in dd/mm/yyyy format');
else
throw new AuraHandledException(e.getMessage());
}  */   
    }
    
    public static Date parseCustomDate(String dateStr) {
        if (String.isBlank(dateStr)) 
            return null;
        try 
        {
            List<String> parts = dateStr.trim().split('-');
            if (parts.size() != 3) return null;
            
            Integer day = Integer.valueOf(parts[0]);
            
            Map<String, Integer> monthMap = new Map<String, Integer>{
                'JAN' => 1, 'FEB' => 2, 'MAR' => 3, 'APR' => 4, 'MAY' => 5, 'JUN' => 6,
                    'JUL' => 7, 'AUG' => 8, 'SEP' => 9, 'OCT' => 10, 'NOV' => 11, 'DEC' => 12
                    };
                        
            String monthStr = parts[1].toUpperCase();
            Integer month = monthMap.containsKey(monthStr) ? monthMap.get(monthStr) : null;
            if (month == null) return null;
            
            Integer yearPart = Integer.valueOf(parts[2]);
            Integer year = (yearPart < 100) ? 2000 + yearPart : yearPart;
            
            return Date.newInstance(year, month, day);
        } 
        catch (Exception e) 
        {
            System.debug('Error parsing date: ' + dateStr + ' | ' + e.getMessage());
            return null;
        }
    }
    
    
}