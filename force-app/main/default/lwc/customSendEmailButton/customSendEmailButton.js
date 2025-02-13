import { LightningElement,api, track } from 'lwc';
export default class CustomSendEmailButton extends LightningElement {
//    @api recordId; // Record ID of the record for which you want to send the email

//     handleSendEmail() {
//         const quickActionAPI = new QuickActionAPI(this);
//         quickActionAPI.invokeAction({
//             actionName: 'SendEmail', // API name of the standard Send Email action
//             recordId: this.recordId
//         }).then(() => {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Success',
//                     message: 'Email sent successfully',
//                     variant: 'success'
//                 })
//             );
//         }).catch(error => {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: error.body.message,
//                     variant: 'error'
//                 })
//             );
//         });
//     }

//   connectedCallback() {
//         this.openEmailComposer();
//     }

//     openEmailComposer() {
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordAction',
//             attributes: {
//                 recordId: this.recordId,
//                 objectApiName: 'Lead', // Change to 'Lead' or 'Opportunity' if needed
//                 actionName: 'SendEmail' // Standard Email action
//             }
//         });
//     }



    // handleSendEmail() {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordAction',
    //         attributes: {
    //             recordId: this.recordId,
    //             objectApiName: 'Lead', // Change to Lead, Opportunity, etc., if needed
    //             actionName: 'SendEmail'
    //         }
    //     });
    // }
    //     openEmailComposer() {
    //     let url = '/_ui/core/email/author/EmailAuthor?p3_lkid=' + this.recordId;
        
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__webPage',
    //         attributes: {
    //             url: url
    //         }
    //     });
    // }

    // handleClose() {
    //     this.dispatchEvent(new CustomEvent('close')); // Closes the Quick Action
    // }

    @api recordId;
    @track subject = '';
    @track body = '';

    handleChange(event) {
        const field = event.target.dataset.id;
        if (field === 'subject') {
            this.subject = event.target.value;
        } else if (field === 'body') {
            this.body = event.target.value;
        }
    }

    sendEmail() {
        sendEmailApex({ leadId: this.recordId, subject: this.subject, body: this.body })
            .then(() => {
                // Show success message or handle success
                console.log('Email sent successfully');
            })
            .catch(error => {
                // Show error message or handle error
                console.error('Error sending email: ', error);
            });
    }
}