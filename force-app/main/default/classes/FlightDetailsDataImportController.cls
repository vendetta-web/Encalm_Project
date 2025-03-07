public class FlightDetailsDataImportController {
    @AuraEnabled
    public static void importCSVFile(String csvString, String airportCodeFromFileName) {
        List<String> rows = csvString.split('\\n');
        Map<String, String> daysOfWeekMap = new Map<String, String>{'Sunday' => '1', 'Monday' => '2', 'Tuesday' => '3', 'Wednesday' => '4', 'Thursday' => '5', 'Friday' => '6', 'Saturday' => '7'};
        Map<String, Map<String, Map<String, Flight_Detail__c>>> flightDetailsMap = new Map<String, Map<String, Map<String, Flight_Detail__c>>>();

        Map<String, Airline__c> airlineMap = new Map<String, Airline__c>();
        Map<String, Airport__c> airportMap = new Map<String, Airport__c>();
        Map<String, Map<String, Terminal__c>> terminalMap = new Map<String, Map<String, Terminal__c>>();
        Map<Integer, List<Id>> rowVsDepartureArrivalFlightIds = new Map<Integer, List<Id>>();

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

        try{
            for(Flight_Detail__c fdetail : [SELECT id, Flight_Number__c, Arrival_Airport__c, Departure_Airport__c FROM Flight_Detail__c LIMIT 49999]){
            if (!flightDetailsMap.containsKey(fdetail.Flight_Number__c)) {
                    flightDetailsMap.put(fdetail.Flight_Number__c, new Map<String, Map<String, Flight_Detail__c>>());
                }
                if (!flightDetailsMap.get(fdetail.Flight_Number__c).containsKey(fdetail.Arrival_Airport__c)) {
                    flightDetailsMap.get(fdetail.Flight_Number__c).put(fdetail.Arrival_Airport__c, new Map<String, Flight_Detail__c>());
                }
                if (!flightDetailsMap.get(fdetail.Flight_Number__c).get(fdetail.Arrival_Airport__c).containsKey(fdetail.Departure_Airport__c)) {
                    flightDetailsMap.get(fdetail.Flight_Number__c).get(fdetail.Arrival_Airport__c).put(fdetail.Departure_Airport__c, fdetail);
                }
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

            System.debug('rows.size()-->'+rows.size());
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
                    if(!flightDetailsMap.containsKey(flightNumberDeparture) || !flightDetailsMap.get(flightNumberDeparture).containsKey(airportMap.get(destination).Id)
                    || !flightDetailsMap.get(flightNumberDeparture).get(airportMap.get(destination).Id).containsKey(airportMap.get(airportCodeFromFileName).Id))
                    {
                        System.debug('--flightNumberDepartue does not exist---');
                        flightDetail = new Flight_Detail__c(
                            Airline_Id__c = airlineMap.get(airline).Id,
                            Flight_Number__c = flightNumberDeparture,
                            Arrival_Airport__c = airportMap.get(destination).Id,
                            Departure_Airport__c = airportMap.get(airportCodeFromFileName).Id
                        );
                        flightDetailsToInsert.add(flightDetail);
                    }
                }

                if(flightNumberArrival != null && flightNumberArrival != ''){
                    if(!flightDetailsMap.containsKey(flightNumberArrival) || !flightDetailsMap.get(flightNumberArrival).containsKey(airportMap.get(airportCodeFromFileName).Id)
                    || !flightDetailsMap.get(flightNumberArrival).get(airportMap.get(airportCodeFromFileName).Id).containsKey(airportMap.get(origin).Id))
                    {
                        System.debug('--flightNumberArrival does not exist---');
                        flightDetail = new Flight_Detail__c(
                            Airline_Id__c = airlineMap.get(airline).Id,
                            Flight_Number__c = flightNumberArrival,
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

                    if (!flightDetailsMap.containsKey(fd.Flight_Number__c)) {
                        flightDetailsMap.put(fd.Flight_Number__c, new Map<String, Map<String, Flight_Detail__c>>());
                    }
                    if (!flightDetailsMap.get(fd.Flight_Number__c).containsKey(fd.Arrival_Airport__c)) {
                        flightDetailsMap.get(fd.Flight_Number__c).put(fd.Arrival_Airport__c, new Map<String, Flight_Detail__c>());
                    }
                    if (!flightDetailsMap.get(fd.Flight_Number__c).get(fd.Arrival_Airport__c).containsKey(fd.Departure_Airport__c)) {
                        flightDetailsMap.get(fd.Flight_Number__c).get(fd.Arrival_Airport__c).put(fd.Departure_Airport__c, fd);
                    }
                }
                System.debug('flightDetailsMap.values()-->'+flightDetailsMap.values());
            }

            // Process Flight_Schedule__c records
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
            
                // Ensure flightDetail is retrieved correctly
                if (flightNumberDeparture != null && flightNumberDeparture != '' )
                {
                    if(flightDetailsMap.containsKey(flightNumberDeparture) && flightDetailsMap.get(flightNumberDeparture).containsKey(airportMap.get(destination).Id)
                    && flightDetailsMap.get(flightNumberDeparture).get(airportMap.get(destination).Id).containsKey(airportMap.get(airportCodeFromFileName).Id))

                    {
                        Id flightDetailId = flightDetailsMap.get(flightNumberDeparture).get(airportMap.get(destination).Id).get(airportMap.get(airportCodeFromFileName).Id).Id;
                        Date currentDate = fromDate;
                        while (currentDate <= toDate) {
                            System.debug('currentDate-->'+currentDate);
                            DateTime fromDateTime = (DateTime)currentDate;
                            String dayOfWeek = daysOfWeekMap.get(fromDateTime.format('EEEE'));
                            System.debug('dayOfWeek-->'+dayOfWeek);
                        
                            if(frequency.contains(dayOfWeek)){
                                Integer minutes = Integer.valueOf(departureTime.substring(departureTime.length() - 2));
                                Integer hours = (departureTime.length() > 2) ? Integer.valueOf(departureTime.substring(0, departureTime.length() - 2)) : 0;

                                flightSchedulesToInsert.add(new Flight_Schedule__c(
                                        Flight_Detail__c = flightDetailId,
                                        Flight_Date__c = currentDate,
                                        Departure_Terminal__c = terminalMap.get(airportMap.get(airportCodeFromFileName).Id).get(departureTerminal).Id,
                                        STD__c = Time.newInstance(hours, minutes, 0, 0)
                                    ));
                            }   
                            currentDate = currentDate.addDays(1);
                        } 
                        if(!rowVsDepartureArrivalFlightIds.containsKey(i))
                        {
                            rowVsDepartureArrivalFlightIds.put(i, new List<Id>{flightDetailId});
                        }
                        else{
                            rowVsDepartureArrivalFlightIds.get(i).add(flightDetailId);
                        }
                        System.debug('departure--rowVsDepartureArrivalFlightIds.get(i)-->'+rowVsDepartureArrivalFlightIds.get(i));   
                    }
                }

                if (flightNumberArrival != null && flightNumberArrival != '' )
                {
                    if(flightDetailsMap.containsKey(flightNumberArrival) && flightDetailsMap.get(flightNumberArrival).containsKey(airportMap.get(airportCodeFromFileName).Id)
                    && flightDetailsMap.get(flightNumberArrival).get(airportMap.get(airportCodeFromFileName).Id).containsKey(airportMap.get(origin).Id))
                    {
                        Id flightDetailId = flightDetailsMap.get(flightNumberArrival).get(airportMap.get(airportCodeFromFileName).Id).get(airportMap.get(origin).Id).Id;
                        Date currentDate = fromDate;
                        while (currentDate <= toDate) {
                            System.debug('currentDate-->'+currentDate);
                            DateTime fromDateTime = (DateTime)currentDate;
                            String dayOfWeek = daysOfWeekMap.get(fromDateTime.format('EEEE'));
                            System.debug('dayOfWeek-->'+dayOfWeek);
                        
                            if(frequency.contains(dayOfWeek)){
                                Integer minutes = Integer.valueOf(arrivalTime.substring(arrivalTime.length() - 2));
                                Integer hours = (arrivalTime.length() > 2) ? Integer.valueOf(arrivalTime.substring(0, arrivalTime.length() - 2)) : 0;

                                flightSchedulesToInsert.add(new Flight_Schedule__c(
                                        Flight_Detail__c = flightDetailId,
                                        Flight_Date__c = currentDate,
                                        Arrival_Terminal__c = terminalMap.get(airportMap.get(airportCodeFromFileName).Id).get(arrivalTerminal).Id,
                                        STA__c = Time.newInstance(hours, minutes, 0, 0)
                                    ));
                            }
                            currentDate = currentDate.addDays(1);
                        }
                        if(!rowVsDepartureArrivalFlightIds.containsKey(i))
                            {
                                rowVsDepartureArrivalFlightIds.put(i, new List<Id>{flightDetailId});
                            }
                            else{
                                rowVsDepartureArrivalFlightIds.get(i).add(flightDetailId);
                            }
                            System.debug('arrival--rowVsDepartureArrivalFlightIds.get(i)-->'+rowVsDepartureArrivalFlightIds.get(i));
                    }
                }
                
            }

            // Insert Flight_Schedule__c records
            if (!flightSchedulesToInsert.isEmpty()) {
                insert flightSchedulesToInsert;
            }

            //Insert Transit_Flight_Detail__c records (only when a row has both Arrival and Departure details)
            if(!rowVsDepartureArrivalFlightIds.isEmpty()){
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
            }

            if(!transitFlightDetailsToInsert.isEmpty()){
                insert transitFlightDetailsToInsert;
            }

        }
        catch(Exception e){
            System.debug('exception-->'+e.getMessage());
            if(e.getMessage().contains('Invalid date'))
                throw new AuraHandledException('Please make sure to have the From (Date) & To (Date) in dd/mm/yyyy format');
            else
                throw new AuraHandledException(e.getMessage());
        }     
    }
}