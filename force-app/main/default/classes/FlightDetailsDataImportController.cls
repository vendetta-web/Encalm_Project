public class FlightDetailsDataImportController {
    @AuraEnabled
    public static void importCSVFile(String csvString) {
        List<String> rows = csvString.split('\\n');
        Map<String, String> daysOfWeekMap = new Map<String, String>{'Sunday' => '1', 'Monday' => '2', 'Tuesday' => '3', 'Wednesday' => '4', 'Thursday' => '5', 'Friday' => '6', 'Saturday' => '7'};
        Map<String, Map<String, Map<String, Flight_Detail__c>>> flightDetailsMap = new Map<String, Map<String, Map<String, Flight_Detail__c>>>();

        Map<String, Airline__c> airlineMap = new Map<String, Airline__c>();
        Map<String, Airport__c> airportMap = new Map<String, Airport__c>();
        Map<String, Map<String, Terminal__c>> terminalMap = new Map<String, Map<String, Terminal__c>>();

        List<Flight_Detail__c> flightDetailsToInsert = new List<Flight_Detail__c>();
        List<Flight_Schedule__c> flightSchedulesToInsert = new List<Flight_Schedule__c>();


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

        for(Airline__c aline : [SELECT id, Airline_Code__c, Airline_Name__c  FROM Airline__c ]){
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

            if(flightNumberArrival != null && flightNumberArrival != ''){
                 flightDetail = new Flight_Detail__c(
                    Airline_Id__c = airlineMap.get(airline).Id,
                    Flight_Number__c = flightNumberArrival,
                    Arrival_Airport__c = airportMap.get('DEL').Id, //'DEL',
                    Departure_Airport__c = airportMap.get(origin).Id
                );
                flightDetailsToInsert.add(flightDetail);
            }
            if(flightNumberDeparture != null && flightNumberDeparture != ''){
                 flightDetail = new Flight_Detail__c(
                    Airline_Id__c = airlineMap.get(airline).Id,
                    Flight_Number__c = flightNumberDeparture,
                    Arrival_Airport__c = airportMap.get(destination).Id,
                    Departure_Airport__c = airportMap.get('DEL').Id
                );
                flightDetailsToInsert.add(flightDetail);
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
           
            System.debug('fromDate-->'+fromDate);
            System.debug('frequency --->'+frequency);
            // Ensure flightDetail is retrieved correctly
            if (flightNumberArrival != null && flightNumberArrival != '' )
            {
                if(flightDetailsMap.containsKey(flightNumberArrival) && flightDetailsMap.get(flightNumberArrival).containsKey(airportMap.get('DEL').Id)
                && flightDetailsMap.get(flightNumberArrival).get(airportMap.get('DEL').Id).containsKey(airportMap.get(origin).Id))

                {
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
                                    Flight_Detail__c = flightDetailsMap.get(flightNumberArrival).get(airportMap.get('DEL').Id).get(airportMap.get(origin).Id).Id,
                                    Arrival_Terminal__c = terminalMap.get(airportMap.get('DEL').Id).get(arrivalTerminal).Id,
                                   // Departure_Terminal__c = departureTerminal,
                                    Flight_Date__c = currentDate,
                                    STA__c = Time.newInstance(hours, minutes, 0, 0)
                                    //STD__c = Time.valueOf(departureTime)
                                ));

                        }
                        currentDate = currentDate.addDays(1);
                    }
                }
            }
            if (flightNumberDeparture != null && flightNumberDeparture != '' )
            {
                if(flightDetailsMap.containsKey(flightNumberDeparture) && flightDetailsMap.get(flightNumberDeparture).containsKey(airportMap.get(destination).Id)
                && flightDetailsMap.get(flightNumberDeparture).get(airportMap.get(destination).Id).containsKey(airportMap.get('DEL').Id))

                {
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
                                    Flight_Detail__c = flightDetailsMap.get(flightNumberDeparture).get(airportMap.get(destination).Id).get(airportMap.get('DEL').Id).Id,
                                    //Arrival_Terminal__c = terminalMap.get(airportMap.get('DEL').Id).get(arrivalTerminal).Id,
                                    Departure_Terminal__c = terminalMap.get(airportMap.get('DEL').Id).get(departureTerminal).Id,
                                    Flight_Date__c = currentDate,
                                    //STA__c = Time.newInstance(hours, minutes, 0, 0)
                                    STD__c = Time.newInstance(hours, minutes, 0, 0)
                                ));

                        }
                        currentDate = currentDate.addDays(1);
                    }
                }
            }
        }

        // Insert Flight_Schedule__c records
        if (!flightSchedulesToInsert.isEmpty()) {
            insert flightSchedulesToInsert;
        }
    }
}