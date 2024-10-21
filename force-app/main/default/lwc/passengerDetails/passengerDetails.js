import { LightningElement, track } from 'lwc';

let idCounter = 1; 

export default class PassengerDetails extends LightningElement {
    @track passengers = [];
    @track columns = [
        { label: 'Name', fieldName: 'name', type: 'text', editable: true },
        { label: 'Age', fieldName: 'age', type: 'number', editable: true },
        { label: 'Gender', fieldName: 'gender', type: 'text', editable: true },
		 { label: 'Travel Class', fieldName: 'Travel_Class__c', type: 'text', editable: true },
		  { label: 'Airline PNR', fieldName: 'Airline_PNR__c', type: 'text', editable: true },
        { 
            type: 'button', 
            typeAttributes: { 
                label: 'Delete', 
                name: 'delete', 
                variant: 'destructive',
				iconName: 'utility:delete'
            } 
        }
    ];


    addPassenger() {
        const newPassenger = { id: `passenger-${idCounter++}`, name: 'New Passenger', age: 30, gender: 'Male' };
        this.passengers = [...this.passengers, newPassenger];
    }

    handleCellChange(event) {
        const { draftValues } = event.detail;
        this.passengers = this.passengers.map(passenger => {
            const updatedPassenger = draftValues.find(item => item.id === passenger.id);
            return updatedPassenger ? { ...passenger, ...updatedPassenger } : passenger;
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            this.deletePassenger(row.id);
        }
    }

    deletePassenger(id) {
        this.passengers = this.passengers.filter(passenger => passenger.id !== id);
    }

    goBack() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    submit() {
        //this.dispatchEvent(new CustomEvent('submit'));
        alert('Thanks for submit your response');
    }
}