import { LightningElement, wire, track } from 'lwc';
import getDistributorAccounts from '@salesforce/apex/DistributorAccountController.getDistributorAccounts';
import updateAccountLimit from '@salesforce/apex/DistributorAccountController.updateAccountLimit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DistributorSelector extends LightningElement {

    @track accounts = [];

    selectedAccountId;
    selectedAccountName = 'Select Account';
    showDropdown = false;

    startDate;
    duration;
    limitValue;

    // fetch accounts
    @wire(getDistributorAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accounts = data;
        }
    }

    toggleDropdown(){
        this.showDropdown = !this.showDropdown;
    }

    handleSelect(event){

        const id = event.currentTarget.dataset.id;
        const name = event.currentTarget.dataset.name;

        // ADDED LOGIC FOR SPECIAL OPTIONS
        if(id === 'none'){
            this.selectedAccountId = null;
            this.selectedAccountName = 'Select Account';
            this.showDropdown = false;
            return;
        }

        if(id === 'all'){
            this.selectedAccountId = 'all';
            this.selectedAccountName = 'All Selected';
            this.showDropdown = false;
            return;
        }

        // EXISTING LOGIC
        this.selectedAccountId = id;
        this.selectedAccountName = name;
        this.showDropdown = false;
    }

    handleStartDate(event){
        this.startDate = event.target.value;
    }

    handleDuration(event){
        this.duration = event.target.value;
    }

    handleLimit(event){
        this.limitValue = event.target.value;
    }

    handleOk(){

        if(!this.selectedAccountId){
            this.showToast('Error','Please select an account','error');
            return;
        }

        if(!this.startDate || !this.duration || !this.limitValue){
            this.showToast('Error','Please fill all fields','error');
            return;
        }

        // ADDED LOGIC FOR ALL ACCOUNTS
        let accountIds = [];

        if(this.selectedAccountId === 'all'){
            accountIds = this.accounts.map(acc => acc.Id);
        }else{
            accountIds.push(this.selectedAccountId);
        }

        updateAccountLimit({
            accountId: this.selectedAccountId === 'all' ? null : this.selectedAccountId,
            accountIds: accountIds,
            startDate: this.startDate,
            duration: parseInt(this.duration,10),
            newLimit: parseFloat(this.limitValue)
        })
        .then(result=>{

             let variant = 'success';
            let title = 'Success';

            // Detect warning from Apex
            if(result && result.includes('History field')){
                variant = 'warning';
                title = 'Warning';
            }
            this.showToast(title, result, 'success');
            this.resetForm();
        })
        .catch(error=>{
            this.showToast('Error', error.body.message, 'error');
        });
    }

     resetForm(){
        this.selectedAccountId = null;
        this.selectedAccountName = 'Select Account';
        this.showDropdown = false;

        this.startDate = null;
        this.duration = null;
        this.limitValue = null;

        // Clear UI inputs
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            input.value = null;
        });
    }

    get endDate(){
        if(!this.startDate || !this.duration){
            return null;
        }
        let start=new Date(this.startDate);
        start.setDate(start.getDate() + parseInt(this.duration,10));
        return start.toISOString().split('T')[0];
    }

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}