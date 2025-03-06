import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import importCSVFile from '@salesforce/apex/FlightDetailsDataImportController.importCSVFile';

export default class CsvUploader extends LightningElement {
    @track fileData;
    @track disableButton = true;
    
    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            let reader = new FileReader();
            reader.onload = () => {
                let csv = reader.result;
                this.fileData = csv;
            };
            reader.readAsText(file);
            this.disableButton = false;
        }
    }

    handleUpload() {
        if (this.fileData) {
            importCSVFile({ csvString: this.fileData })
                .then(result => {
                    this.showToast('Success', 'File processed successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        } else {
            this.showToast('Error', 'Please select a file first', 'error');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}











/*import { LightningElement, track } from 'lwc';
import insertFlightData from '@salesforce/apex/FlightDetailsDataImportController.insertFlightData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FlightUploader extends LightningElement {
    @track csvData = [];
    @track csvColumns = [];
    @track fieldMapping = {};
    @track showMapping = false;

    objectFieldOptions = [
        { label: 'Flight Number', value: 'Flight_Number__c' },
        { label: 'Origin', value: 'Departure_Airport__c' },
        { label: 'Destination', value: 'Arrival_Airport__c' },
        { label: 'Arrival Terminal', value: 'Arrival_Terminal__c' },
        { label: 'Departure Terminal', value: 'Departure_Terminal__c' },
        { label: 'Arrival Time (STA)', value: 'STA__c' },
        { label: 'Departure Time (STD)', value: 'STD__c' },
        { label: 'From Date', value: 'From_Date__c' },
        { label: 'To Date', value: 'To_Date__c' },
        { label: 'Frequency', value: 'Frequency__c' }
    ];

    handleFileUpload(event) {
        const file = event.target.files[0];

        if (!file || !file.name.endsWith('.csv')) {
            this.showToast('Error', 'Please upload a valid CSV file.', 'error');
            return;
        }

        let reader = new FileReader();
        reader.onload = (e) => {
            let csv = e.target.result;
            this.processCSV(csv);
        };
        reader.readAsText(file);
    }

    processCSV(csv) {
        let rows = csv.split("\n").map(row => row.trim()).filter(row => row.length > 0);
        let headers = rows[0].split(",").map(header => header.trim());
        this.csvColumns = headers;

        let jsonData = [];
        for (let i = 1; i < rows.length; i++) {
            let values = rows[i].split(",");
            let obj = {};
            headers.forEach((header, index) => {
                obj[header] = values[index] ? values[index].trim() : "";
            });
            jsonData.push(obj);
        }

        this.csvData = jsonData;
        this.showMapping = true;
    }

    handleMappingChange(event) {
        const column = event.target.dataset.column;
        const selectedField = event.detail.value;
        this.fieldMapping[column] = selectedField;
    }

    insertRecords() {
        if (Object.keys(this.fieldMapping).length === 0) {
            this.showToast('Error', 'Please map CSV columns to object fields.', 'error');
            return;
        }

        let mappedData = this.csvData.map(row => {
            let mappedRow = {};
            for (let [csvColumn, objectField] of Object.entries(this.fieldMapping)) {
                mappedRow[objectField] = row[csvColumn];
            }
            return mappedRow;
        });

        insertFlightData({ flightList: mappedData })
            .then(() => {
                this.showToast('Success', 'Flight records inserted successfully!', 'success');
                this.showMapping = false;
                this.csvData = [];
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}*/