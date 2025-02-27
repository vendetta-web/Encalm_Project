import { api, LightningElement, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STAGE_NAME from "@salesforce/schema/Lead.Status";
import RECORD_TYPE_ID from "@salesforce/schema/Lead.RecordTypeId";
import FOLLOWUP_FIELD from "@salesforce/schema/Lead.Set_Follow_up_Date_and_Time__c"; 
import LEAD_OWNER from "@salesforce/schema/Lead.OwnerId"; 
import REASON_FOR_CLOSE from "@salesforce/schema/Lead.Reason_For_Close__c"; // Add this import
import { NavigationMixin } from 'lightning/navigation'; 

const fields = [STAGE_NAME, RECORD_TYPE_ID, FOLLOWUP_FIELD, LEAD_OWNER, REASON_FOR_CLOSE]; // Add REASON_FOR_CLOSE to fields

export default class EncalmLeadProcess extends NavigationMixin(LightningElement) {
    @track reservationStages = ['Open', 'Awaiting Customer response', 'Escalated to supervisor', 'Closed/Converted'];
    @track salesStages = ['Open', 'Awaiting Customer response', 'Escalated to supervisor', 'Closed/Converted'];
    pathType = 'path';
    @api recordId;
    @track showcustompath = false;
    @track finalpathvalue = [];
    @track currentStage = '';
    @track pathValues = [];
    @track followUpDateTime= ''; 
    @track isStageClosed= false; 
    @track isStageFollowup= false; 
    @track leadOwnerId; 
    @track isLeadClose = false; 
    @track reasonForClose = ''; // Track Reason_For_Close__c value

    @track isModalOpen = false; // Track modal visibility
    @track isBookingOpen = false;
    @track selectedValue = ''; // Track selected picklist value
    @track finalStageOptions = [{ label: 'Close', value: 'Close' }, { label: 'Convert', value: 'Convert' }];
    @track showMarkStatusButton = false;

    @wire(getRecord, { recordId: '$recordId', fields })
    getfieldValue({ error, data }) {
        if (data) {
            var result = JSON.parse(JSON.stringify(data));
            console.log("result", result);
            this.RecordType = data.recordTypeInfo.name;
            this.recordTypeId = result.fields.RecordTypeId.value;
            this.followUpFieldValue = result.fields.Set_Follow_up_Date_and_Time__c.value; 
            this.leadOwnerId = result.fields.OwnerId.value; 
            this.showcustompath = true;
            this.pathValues = [];
            console.log("recordTypeId", this.recordTypeId);
            console.log("RecordType", this.RecordType);
            console.log("followUpFieldValue", this.followUpFieldValue);
            if (this.RecordType == 'Reservation') {
                let i = 1;
                this.reservationStages.forEach(currentItem => {
                    let currentVal = currentItem;
                    if (currentItem == 'Closed/Converted')
                        currentVal = 'Closed';
                    this.pathValues.push({
                        label: currentItem,
                        value: currentVal
                    });
                    ++i;
                });
                this.finalpathvalue = this.pathValues;
            }
            else if (this.RecordType == 'Sales') {
                console.log('Sales : ');
                let i = 1;
                this.salesStages.forEach(currentItem => {
                    let currentVal = currentItem;
                    if (currentItem == 'Closed/Converted')
                        currentVal = 'Closed';
                    this.pathValues.push({
                        label: currentItem,
                        value: currentVal
                    });
                    ++i;
                });
                this.finalpathvalue = this.pathValues;
            }

            let fieldValue = getFieldValue(data, this.objectApiName + '.' + 'Status');
            this.currentStage = fieldValue;

            // Set showMarkStatusButton based on the current status
            this.showMarkStatusButton = this.currentStage === 'Awaiting Customer response';
            // if (this.currentStage != 'Closed')
            //     this.showMarkStatusButton = true;
            console.log('Current Stage is ------->' + this.currentStage);
            console.log('OUTPUTSaurabh : ',this.followUpFieldValue);
            console.log('final path - >' + JSON.stringify(this.finalpathvalue));

            this.showcustompath = true;

            // Check if the status is "Awaiting Customer response" and open the modal if necessary
            this.checkAndOpenFollowUpModal();
        }
    }

    /*checkAndOpenFollowUpModal() {
        if (this.currentStage === 'Awaiting Customer response' && (this.followUpFieldValue == null || this.followUpFieldValue === undefined)) {
            this.isStageFollowup = true;
            this.isStageClosed = false;
            this.openModal();
        }
    }*/
     checkAndOpenFollowUpModal() {
        if (this.currentStage === 'Awaiting Customer response' && (this.followUpFieldValue == null || this.followUpFieldValue === undefined)) {
            setTimeout(() => {
                this.isStageFollowup = true;
                this.isStageClosed = false;
                this.openModal();
            }, 3000); 
        }
    }

    handleMarkStatus() {
        if (this.RecordType === 'Sales' && !this.isLeadOwnerUser()) { 
            this.showToast('info', 'Lead Owner must be a User to update the stage in Sales record.');
            return; // Don't proceed with stage update
        } else {
            let newStage = ''
            this.template.querySelectorAll(".slds-path__item").forEach(currentItem => {
                if (currentItem.classList.contains('slds-is-active')) {
                    newStage = currentItem.dataset.value;
                }
            });

            console.log('newStage -> ' + newStage);

            if (newStage == 'Closed') {
                this.isStageClosed = true;
                this.isStageFollowup = false;       
                this.openModal();
                return;
            }
            
            // Add New changes by Saurabh
            if (newStage == 'Awaiting Customer response' && (this.followUpFieldValue == null || this.followUpFieldValue === undefined)) {
                console.log('Test');
                this.isStageFollowup = true;
                this.isStageClosed = false;
                this.openModal();
                return;
            }
            console.log('OUTPUT : nnnnnnn>>>>>>>>>');
            this.updateRecord(newStage);
        }
    }

    updateRecord(newStage) {
        console.log('OUTPUT : New', newStage);
        const fields = {};
        console.log('followUpFieldValue : ',this.followUpFieldValue);
        if(newStage == 'Awaiting Customer response' && this.RecordType === 'Reservation' && this.followUpDateTime){
            console.log('OUTPUT :>>>>>>>>>>> ');
            fields[FOLLOWUP_FIELD.fieldApiName] = this.followUpDateTime;
            fields[STAGE_NAME.fieldApiName] = newStage;
        } else {
            console.log('OUTPUT : >>>>>>>>>>>>>>>>>',);
            fields[STAGE_NAME.fieldApiName] = newStage; // Set the new status value
            console.log('OUTPUT : ',fields);    
        }
        console.log('OUTPUT : nnnnnnnnewwwwwwwwwwww',fields[STAGE_NAME.fieldApiName]);
        console.log('fields : ',fields);
        const recordInput = { fields };
        recordInput.fields.Id = this.recordId;
        // Update the record
        console.log('recordInput : ',recordInput);
        updateRecord(recordInput)
            .then(() => {
                console.log('New Stage is  ' + newStage);
            })
            .catch(error => {
                console.log(JSON.stringify(error));
                let errorMessage = this.extractErrorMessages(error);
                if (errorMessage) {
                    this.showToast('info', errorMessage);
                }
                else {
                    // Show error toast
                    this.showToast('error', error.body.message);
                }
            });
    }

    showToast(type, msg) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: type,
                message: msg,
                variant: type,
            })
        );
    }

    extractErrorMessages(err) {
        const errorMessages = [];
        try {
            let responseJson = JSON.parse(JSON.stringify(err));
            let fieldErrors;
            if(Object.keys(responseJson?.body?.output?.fieldErrors).length > 0) {
                fieldErrors = JSON.parseresponseJson?.body?.output?.fieldErrors;
            }
            else if(Object.keys(responseJson?.body?.output?.errors).length > 0) {
                fieldErrors =  responseJson?.body?.output?.errors;
            }
            // Iterate over each field and extract messages
            for (const index in fieldErrors) {
                errorMessages.push(fieldErrors[index].message);
            }
        } catch (error) {
            // Handle cases where the JSON structure is not as expected
            return '';
        }
        return errorMessages.join(",");
    }

    // Open the modal
    openModal() {
        this.isModalOpen = true;
    }

    // Close the modal
    closeModal() {
        this.isModalOpen = false;
        this.isBookingOpen = false;
    }

    // Handle picklist change
    handlePicklistChange(event) {
        this.selectedValue = event.target.value;
        
        if(this.selectedValue == 'Close'){
            this.isLeadClose = true; 
            console.log('test close');
        } else {
            this.isLeadClose = false;
        }
    }

    // Handle Reason_For_Close__c change
    handleReasonChange(event) {
        this.reasonForClose = event.target.value;
    }

    // Handle form submission
    handleSubmit() {
        if(this.isStageClosed){ 
            if(this.selectedValue){
                if (this.selectedValue == 'Close') {
                    const fields = {};
                    fields[STAGE_NAME.fieldApiName] = 'Closed';
                    fields[REASON_FOR_CLOSE.fieldApiName] = this.reasonForClose; // Set the Reason_For_Close__c field
                    const recordInput = { fields };
                    recordInput.fields.Id = this.recordId;
                    updateRecord(recordInput)
                        .then(() => {
                            this.closeModal();
                            this.showMarkStatusButton = false;
                        })
                        .catch(error => {
                            console.log(JSON.stringify(error));
                            let errorMessage = this.extractErrorMessages(error);
                            if (errorMessage) {
                                this.showToast('info', errorMessage);
                            }
                            else {
                                // Show error toast
                                this.showToast('error', error.body.message);
                            }
                        });
                } else if(this.selectedValue == 'Convert') {
                    // this.openEncalmBookingAction();
                    this.isBookingOpen = true;
                    this.isModalOpen = false;
                }
                else {
                    alert('Please select an option before submitting.');
                }
            }
        }
        
        else if (this.isStageFollowup){
            this.updateRecord('Awaiting Customer response');
            this.closeModal();
        }
    }

    handleDateTimeChange(event) { 
        this.followUpDateTime = event.target.value;
        console.log("Selected Date and Time: ", this.followUpDateTime);
    }

    isLeadOwnerUser() { 
        return this.leadOwnerId && this.leadOwnerId.startsWith('005');
    }
}