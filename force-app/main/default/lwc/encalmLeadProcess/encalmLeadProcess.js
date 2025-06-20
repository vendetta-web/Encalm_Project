import { api, LightningElement, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STAGE_NAME from "@salesforce/schema/Lead.Status";
import RECORD_TYPE_ID from "@salesforce/schema/Lead.RecordTypeId";
import FOLLOWUP_FIELD from "@salesforce/schema/Lead.Set_Follow_up_Date_and_Time__c"; 
import UPDATED_BY_FLOW from "@salesforce/schema/Lead.Updated_By_Flow__c";
import LEAD_OWNER from "@salesforce/schema/Lead.OwnerId"; 
import LEAD_OWNER_USER from "@salesforce/schema/Lead.IsOwnerUser__c"; 
import REASON_FOR_CLOSE from "@salesforce/schema/Lead.Reason_For_Close__c"; 
import convertLead from '@salesforce/apex/LeadConversionController.convertLead';
import { NavigationMixin } from 'lightning/navigation'; 
import { refreshApex } from '@salesforce/apex';

import LEAD_OBJECT from '@salesforce/schema/Lead';
import LEAD_DISPOSITION from "@salesforce/schema/Lead.Disposition__c"; 
import LEAD_SUB_DISPOSITION from "@salesforce/schema/Lead.Sub_Disposition__c"; 

const fields = [STAGE_NAME, RECORD_TYPE_ID,UPDATED_BY_FLOW, FOLLOWUP_FIELD, LEAD_OWNER,LEAD_OWNER_USER, REASON_FOR_CLOSE, LEAD_DISPOSITION, LEAD_SUB_DISPOSITION]; 

export default class EncalmLeadProcess extends NavigationMixin(LightningElement) {
    @track reservationStages = ['Open', 'Awaiting Customer response','Customer Responded','Escalated', 'Closed/Converted'];
    @track salesStages = ['Open', 'Awaiting Customer response','Customer Responded','Discount Requested','Discount Approved','Pending Contract Signing','Escalated', 'Closed/Converted'];
    pathType = 'path';
    @api recordId;
    @track showcustompath = false;
    @track finalpathvalue = [];
    @track currentStage = '';
    @track pathValues = [];
    @track followUpDateTime = ''; 
    @track isStageClosed = false; 
    @track isStageFollowup = false; 
    @track leadOwnerId; 
    @track isOwnerUser = false;
    @track isLeadClose = false; 
    @track reasonForClose = ''; 
    @track isModalOpen = false; 
    @track isBookingOpen = false;
    @track selectedValue = ''; 
    @track finalStageOptions = [{ label: 'Close', value: 'Close' }, { label: 'Convert', value: 'Convert' }];
    @track showMarkStatusButton = false;
    @track isMarkStatusDisabled = true;

    @track recordTypeId;
    @track dispositionOptions = [];
    @track subDispositionOptions = [];
    @track selectedSubDispositionValue; 

    @wire(getRecord, { recordId: '$recordId', fields })
    getfieldValue({ error, data }) {
        if (data) {
            var result = JSON.parse(JSON.stringify(data));
            this.RecordType = data.recordTypeInfo.name;
            this.recordTypeId = result.fields.RecordTypeId.value;
            this.followUpFieldValue = result.fields.Set_Follow_up_Date_and_Time__c.value;
            this.updateFlag = result.fields.Updated_By_Flow__c.value; 
            this.leadOwnerId = result.fields.OwnerId.value;
            this.isOwnerUser = result.fields.IsOwnerUser__c.value; 
            this.showcustompath = true;
            this.pathValues = [];

            // Set stages based on record type
            this.setStagesBasedOnRecordType();

            let fieldValue = getFieldValue(data, this.objectApiName + '.' + 'Status');
            this.currentStage = fieldValue;

            // Set showMarkStatusButton based on the current stage
            this.showMarkStatusButton = this.currentStage === 'Open';
            console.log('Current Stage is ------->' + this.currentStage);

            this.showcustompath = true;

            // Check and open the follow-up modal if needed
            this.checkAndOpenFollowUpModal();
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: LEAD_DISPOSITION
    })
    wiredDispositionValues({ data, error }) {
        if (data) {
            this.dispositionOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: LEAD_SUB_DISPOSITION
    })
    wiredSubDispositionValues({ data, error }) {
        if (data) {
            this.subDispositionOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
    }

    handleSubDispositionChange(event) {
        this.selectedSubDispositionValue = event.detail.value;
    }

    // Set reservation or sales stages
    setStagesBasedOnRecordType() {
        if (this.RecordType === 'Reservation') {
            this.setPathValues(this.reservationStages);
        } 
         else if (this.RecordType === 'Sales') {
             this.setPathValues(this.salesStages);
         }
    }

    // Set path values based on stages
    setPathValues(stages) {
        this.pathValues = stages.map(stage => {
            let label = stage === 'Closed/Converted' ? 'Closed' : stage;
            return { label: stage, value: label };
        });
        this.finalpathvalue = this.pathValues;
    }

    checkAndOpenFollowUpModal() {
        if (this.currentStage === 'Awaiting Customer response' && this.updateFlag){ //!this.followUpFieldValue) {
            setTimeout(() => {
                this.isStageFollowup = true;
                this.isStageClosed = false;
                this.openModal();
            }, 3000); 
        }
    }

    handleStepClick(event) {
        const clickedStage = event.currentTarget.dataset.value;
        if (clickedStage === 'Closed' && this.currentStage !== clickedStage) {
            this.isMarkStatusDisabled = false;
        }else{
            this.isMarkStatusDisabled = true;
        } 
    }


    handleMarkStatus() {
         //if (!this.isLeadOwnerUser()) { 
        if(!this.isOwnerUser){
             this.showToast('info', 'Lead Owner must be a User to update the stage in Sales record.');
             return;
         }

        let newStage = this.getActiveStage();
        
        if (newStage === 'Closed') {
            this.isStageClosed = true;
            this.isStageFollowup = false;
            this.openModal();
            return;
        }

        if (newStage === 'Awaiting Customer response' && !this.followUpFieldValue) {
            this.isStageFollowup = true;
            this.isStageClosed = false;
            this.openModal();
            return;
        }

        this.updateRecord(newStage);
        refreshApex(this.wiredResult);
    }

    getActiveStage() {
        let newStage = '';
        this.template.querySelectorAll(".slds-path__item").forEach(currentItem => {
            if (currentItem.classList.contains('slds-is-active')) {
                newStage = currentItem.dataset.value;
            }
        });
        return newStage;
    }

    updateRecord(newStage) {
        const fields = {};
        if (newStage === 'Awaiting Customer response') {
            if (!this.followUpDateTime) {
            this.showToast( 'error' , 'Follow-up Date and Time is required.' );
            return;
            }
            
            const followUpDateTime = new Date(this.followUpDateTime);
            const now = new Date();
            
            if (followUpDateTime <= now) {
                this.showToast('error', 'Follow-up Date and Time must be a future date and time.');
                return;
            }
            fields[FOLLOWUP_FIELD.fieldApiName] = this.followUpDateTime;
        }
        fields[STAGE_NAME.fieldApiName] = newStage; // Set the new status value

        const recordInput = { fields };
        recordInput.fields.Id = this.recordId;

        updateRecord(recordInput)
            .then(() => {
                console.log('New Stage is  ' + newStage);
            })
            .catch(error => {
                this.handleError(error);
            });
            this.closeModal();
    }

    handleError(error) {
        let errorMessage = this.extractErrorMessages(error);
        if (errorMessage) {
            this.showToast('info', errorMessage);
        } else {
            this.showToast('error', error.body.message);
        }
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
        try {
            let responseJson = JSON.parse(JSON.stringify(err));
            let fieldErrors = responseJson?.body?.output?.fieldErrors || responseJson?.body?.output?.errors;
            return fieldErrors ? fieldErrors.map(e => e.message).join(",") : '';
        } catch (error) {
            return '';
        }
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.isBookingOpen = false;
    }

    handlePicklistChange(event) {
        this.selectedValue = event.target.value;
        this.isLeadClose = this.selectedValue === 'Lead Lost';
       // this.isLeadClose = this.selectedValue === 'Close';
    }

    handleReasonChange(event) {
        this.reasonForClose = event.target.value;
    }

    handleSubmit() {
        if (this.isStageClosed) {
            this.handleCloseOrConvert();
        } else if (this.isStageFollowup) {
            this.updateRecord('Awaiting Customer response');
        }
    }

    convertCurrentLead() {
        convertLead({ leadId: this.recordId })
            .then(result => {
                let recordIdToNavigate = this.recordId;
                if (result && result.accountId) {
                    recordIdToNavigate = result.accountId;
                }
                this.showToast('success', 'Lead converted successfully!');
    
                if (result && result.accountId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: recordIdToNavigate,
                            objectApiName: 'Account',
                            actionName: 'view'
                        }
                    });
                }
            })
            .catch(error => {
                this.showToast('error', error.body ? error.body.message : error.message);
            });
    }
    
    handleCloseOrConvert() {
        if (this.selectedValue) {
           // if (this.selectedValue === 'Close') {
            if (this.selectedValue === 'Lead Lost') {
                if(this.selectedSubDispositionValue == null || this.selectedSubDispositionValue == undefined){
                    this.showToast('Error', 'Please fill all the required fields before submit');
                }
                else{
                    this.closeLead();
                }
                
            } else if (this.selectedValue === 'Convert' && this.RecordType === 'Reservation') {
                this.isBookingOpen = true;
                this.isModalOpen = false;
            } else if (this.selectedValue === 'Convert' && this.RecordType === 'Sales') {
                this.convertCurrentLead();
            }
            else {
                alert('Please select an option before submitting.');
            }
        }
    }

    closeLead() {
        const fields = {
            [LEAD_DISPOSITION.fieldApiName]: this.selectedValue,
            [LEAD_SUB_DISPOSITION.fieldApiName]: this.selectedSubDispositionValue,
            [STAGE_NAME.fieldApiName]: 'Closed',
            [REASON_FOR_CLOSE.fieldApiName]: this.reasonForClose,
        };

        const recordInput = { fields };
        recordInput.fields.Id = this.recordId;

        updateRecord(recordInput)
            .then(() => {
                this.closeModal();
                this.showMarkStatusButton = false;
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    handleDateTimeChange(event) {
        this.followUpDateTime = event.target.value;
        console.log("Selected Date and Time: ", this.followUpDateTime);
    }

    // isLeadOwnerUser() {
    //     return this.leadOwnerId && this.leadOwnerId.startsWith('005');
    // }
}