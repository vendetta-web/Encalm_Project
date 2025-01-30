import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CustomSendEmailButton extends NavigationMixin(LightningElement) {
    handleSendEmail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__quickAction',
            attributes: {
                actionName: 'Lead.SendEmail',
                objectApiName: 'Lead'
            }
        });
    }
}