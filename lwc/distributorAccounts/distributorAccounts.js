import { LightningElement, wire } from 'lwc';
import getDistributorAccounts from '@salesforce/apex/DistributorAccountController.getDistributorAccounts';

export default class DistributorAccounts extends LightningElement {

    accounts;
    error;

    @wire(getDistributorAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }
}