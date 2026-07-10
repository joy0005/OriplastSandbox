import { LightningElement } from 'lwc';
import getReminderMessage from '@salesforce/apex/InvoiceReminderController.getReminderMessage';

export default class InvoiceReminderPopup extends LightningElement {

    showModal = false;
    message;

    connectedCallback() {
        getReminderMessage()
            .then(result => {
                if(result){
                    this.message = result;
                    this.showModal = true;
                }
            })
            .catch(error => {
                console.error(error);
            });
    }

    closeModal() {
        this.showModal = false;
    }
}