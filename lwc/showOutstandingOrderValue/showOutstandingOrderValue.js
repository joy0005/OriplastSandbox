import { LightningElement } from 'lwc';
import getTotalOutstandingValue from '@salesforce/apex/OutstandingOrderValue.getTotalOutstandingValue';
import getNumberTOWordConvertion from '@salesforce/apex/OutstandingOrderValue.getNumberTOWordConvertion';

export default class ShowOutstandingOrderValue extends LightningElement {

    totalOutstanding;
formattedTotal;
error;
totalInWords;
isLoading = true;

connectedCallback() {
    this.fetchTotalOutstanding();
}

fetchTotalOutstanding() {
        getTotalOutstandingValue()
            .then(result => {
                this.totalOutstanding = result;
                const totalValue =Number(result).toFixed(2);

                // Format number with commas & 2 decimals
                this.formattedTotal = new Intl.NumberFormat('en-IN', {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2
                }).format(result);

                // 🔥 Call second Apex method
                return getNumberTOWordConvertion({ num: totalValue });
            })
            .then(wordResult => {
                // Store returned string
                this.totalInWords = wordResult;
                this.error = undefined;
            })
            .catch(err => {
                this.error = err;
                this.totalOutstanding = undefined;
                this.formattedTotal = undefined;
                this.totalInWords = undefined;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}