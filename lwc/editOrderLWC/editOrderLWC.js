import { LightningElement, api, track, wire } from 'lwc';
import getOrderLineItems from '@salesforce/apex/EditOrderController.getOrderLineItems';
import deleteOrderLineItems from '@salesforce/apex/EditOrderController.deleteOrderLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getDiscountPercentage from '@salesforce/apex/CreateOrderLWCController.getDiscountPercentage';
import updateOrderLineItems from '@salesforce/apex/EditOrderController.updateOrderLineItems';
import getOriPlastOrder from '@salesforce/apex/EditOrderController.getOriPlastOrder';
import getDiscountMapping
    from '@salesforce/apex/CreateOrderLWCController.getDiscountMapping';

export default class EditOrderLWC extends NavigationMixin(LightningElement) {
    @track orderLines = [];
    @track orderLinesForAdd = [];
    @track selectedAction;
    @track selectedIds = [];
    @track editLines = [];
    @track showConfirm = false;
    @track isLoading = false;
    @track showPartialOrders = false;
    @track order = {};
    @track corretctTotalOutstandingValue = true;
    @api accountId;
    @track categoryValue = '';
    @track subCategoryValue = '';
    @track identifierValue = '';
    @track searchTerm = '';

    @track CategoryOptions = [];
    @track SubcategoryOptions = [];
    @track IdentifierOptions = [];

    @track isSubCategoryDisabled = false;
    @track isIdentifierDisabled = false;

    @track productList = [];
    @track filteredProductList = [];
    @track showCreateOrder = false;
    @api recordId;

    @wire(getOriPlastOrder, { orderId: '$recordId' })
    wiredOrder({ data, error }) {
        if (data && data.length) {
            this.order = data[0];
            // console.log('Wired Order Data:', JSON.stringify(this.order));

            // 🔥 SAFE POINT
            if (this.selectedAction === 'CREATE') {
                this.accountId = this.order.Account__r.Id;
                this.showCreateOrder = true;
            }
        }
    }

    options = [
        { label: 'Edit Order Line Items', value: 'EDIT' },
        { label: 'Delete Order Line Items', value: 'DELETE' },
        { label: 'Create Order Line Items', value: 'CREATE' }
    ];

    async loadLines(selectedAction) {
        try {
            this.orderLines = await getOrderLineItems({ orderId: this.recordId });
            this.orderLinesForAdd = this.orderLines;
            // console.log('Loaded Order Lines:', JSON.stringify(this.orderLines));
        } catch (e) {
            this.showToast('Error', 'Failed to load order lines', 'error');
        }
    }

    // async handleChange(event) {
    //     this.selectedAction = event.detail.value;
    //     this.selectedIds = [];
    //     this.editLines = [];
    //     await this.loadLines();

    //     if (this.selectedAction === 'CREATE') {
    //         this.accountId = this.order.Account__r.Id; // ✅ REQUIRED
    //         this.showTable = false;
    //         this.showEditTable = false;
    //         this.showConfirm = false;
    //     }
    // }

    async handleChange(event) {
        this.selectedAction = event.detail.value;
        this.selectedIds = [];
        this.editLines = [];

        await this.loadLines();

        if (this.selectedAction === 'CREATE') {
            this.accountId = this.order?.Account__r?.Id;
        }

    }
    get isOrderReady() {
        return this.selectedAction === 'CREATE' && this.order && this.order.Id;
    }

    closeCreateModal() {
        this.showCreateModal = false;
    }

    handleCreateSuccess() {
        this.showCreateModal = false;
        this.loadLines();   // refresh order line table
    }


    handleSelect(event) {
        const id = event.target.dataset.id;
        if (event.target.checked) {
            this.selectedIds = [...this.selectedIds, id];
        } else {
            this.selectedIds = this.selectedIds.filter(i => i !== id);
        }
    }

    handleNext() {
        if (this.selectedIds.length === 0) {
            this.showToast('Error', 'Select at least one item', 'error');
            return;
        }

        if (this.selectedAction === 'EDIT') {

            // console.log('Selected IDs for Edit:', JSON.stringify(this.selectedIds));
            this.editLines = this.orderLines
                .filter(r => this.selectedIds.includes(r.id))
                .map(r => ({ ...r })); // clone
            // console.log('Edit Lines:', JSON.stringify(this.editLines));
        }

        if (this.selectedAction === 'DELETE') {
            this.showConfirm = true;
        }
    }

    async handleQtyChange(event) {
        const id = event.target.dataset.id;
        let qty = parseInt(event.target.value, 10);

        if (isNaN(qty) || qty < 0) qty = 0;
        event.target.value = qty;

        const rows = JSON.parse(JSON.stringify(this.editLines));
        // console.log('Rows:', JSON.stringify(rows));
        const updated = [];

        for (let row of rows) {
            if (row.id !== id) {
                updated.push(row);
                continue;
            }
            /* ================= BASE PRICE ================= */
            let totalLength = 'N/A';
            // let totalLength = 0;
            if (row.Unit_of_Measure === 'MTR' && row.lengthInMeter) {
                totalLength = qty * row.lengthInMeter;
            }
            const basePrice =
                row.Unit_of_Measure === 'MTR' && totalLength !== 'N/A'
                    ? totalLength * (row.unitPrice || 0)
                    : qty * (row.unitPrice || 0);

            /* ================= DISCOUNT CODE ================= */
            if (!this.customerDiscGroup) {
                const acc = await getDiscountMapping({
                    accountId: this.order.Account__r.Id
                });
                this.customerDiscGroup =
                    acc?.[0]?.Customer_Disc_Group__c;

                // console.log(' Customer Discount Group Response:', JSON.stringify(acc) , this.customerDiscGroup);
            }
            let discountGroupCode = '';
            if (row.itemDiscGroup && this.customerDiscGroup) {
                discountGroupCode = `${this.customerDiscGroup}_${row.itemDiscGroup}`;
            }
            // console.log(' Discount Group Code:', discountGroupCode);
            /* ================= DEFAULT VALUES ================= */
            let tradeSpecialAmount = 0;
            let cashDiscountAmount = 0;
            let cashDiscountPercent = 0;
            let finalPriceAfterDiscount = basePrice;
            /* ================= FETCH DISCOUNT ================= */
            if (discountGroupCode) {
                try {
                    // console.log('Calling Apex → getDiscountPercentage');

                    const result = await getDiscountPercentage({ discountGroupCode });
                    // console.log(' Discount Response:', JSON.stringify(result));

                    if (result && result.length > 0) {
                        const disc = result[0];

                        const tradeDisc = disc.Discount__c || 0;
                        const specialDisc = disc.Special_Discount__c || 0;
                        cashDiscountPercent = disc.Cash_Discount__c || 0;

                        const tradeAndSpecialPercent = tradeDisc + specialDisc;

                        tradeSpecialAmount = (basePrice * tradeAndSpecialPercent) / 100;
                        const priceAfterTrade = basePrice - tradeSpecialAmount;

                        cashDiscountAmount = (priceAfterTrade * cashDiscountPercent) / 100;
                        finalPriceAfterDiscount = priceAfterTrade - cashDiscountAmount;

                        // console.log(
                        //     'Trade %:', tradeDisc,
                        //     'Special %:', specialDisc,
                        //     'Cash %:', cashDiscountPercent,
                        //     'Trade+Special Amt:', tradeSpecialAmount,
                        //     'Cash Amt:', cashDiscountAmount,
                        //     'After Discount:', finalPriceAfterDiscount
                        // );
                    }
                } catch (err) {
                    console.error(' Discount Apex Error:', JSON.stringify(err));
                }
            }
            /*
            // if (row.itemDiscGroup) {
            //     const discountGroupCode = `${this.customerDiscGroup}_${row.itemDiscGroup}`;
            //     const res = await getDiscountPercentage({ discountGroupCode });

            //     if (res?.length) {
            //         const d = res[0];
            //         const trade = d.Discount__c || 0;
            //         const special = d.Special_Discount__c || 0;
            //         const cash = d.Cash_Discount__c || 0;

            //         const tradePercent = trade + special;
            //         tradeSpecialAmount = (basePrice * tradePercent) / 100;

            //         const afterTrade = basePrice - tradeSpecialAmount;
            //         cashDiscountAmount = (afterTrade * cash) / 100;

            //         finalAfterDiscount = afterTrade - cashDiscountAmount;
            //     }
            // }

            // const gst = row.gstPercent || 0;


            // ================= GST ================= 
            // const gst = row.gstValue || 0;
            // const totalGST = (finalAfterDiscount * gst) / 100;
            // const cgst = totalGST / 2;
            // const sgst = totalGST / 2;
            // const finalPrice = finalAfterDiscount + totalGST;*/
            const gst = row.gstValue || 0;
            const totalGST = (finalPriceAfterDiscount * gst) / 100;
            const cgst = totalGST / 2;
            const sgst = totalGST / 2;
            const finalPrice = finalPriceAfterDiscount + totalGST;
            // console.log(
            //     ' GST %:', gst,
            //     'GST:', totalGST,
            //     'CGST:', cgst,
            //     'SGST:', sgst,
            //     'Final Price:', finalPrice
            // );

            // updated.push({
            //     ...row,
            //     quantity: qty,
            //     totalLength,
            //     basePrice,
            //     tradeSpecialAmount,
            //     cashDiscountAmount,
            //     priceAfterDiscount: finalAfterDiscount,
            //     cgst,
            //     sgst,
            //     totalGST,
            //     finalPrice
            // });
            updated.push({
                ...row,
                quantity: qty,
                totalLength,
                basePrice,
                tradeSpecialAmount,
                cashDiscountAmount,
                priceAfterDiscount: finalPriceAfterDiscount,
                totalGST,
                cgst,
                sgst,
                finalPrice: finalPrice,

                cashDiscountPercent: cashDiscountPercent,
                totalDiscountAmount: tradeSpecialAmount + cashDiscountAmount,
                totalPriceBeforeGST: finalPriceAfterDiscount,
                gstPercent: gst,
                totalPrice: finalPrice
            });
        }

        // console.log('<-------------------------------->');
        // console.log('Updated Rows after Qty Change:', JSON.stringify(updated));
        this.editLines = updated;
        // console.log('total Price:', updated);
    }

    get allEditTotal() {
        const total = this.editLines.reduce((sum, r) => {
            const price = Number(r.finalPrice);
            return sum + (isNaN(price) ? 0 : price);
        }, 0);

        return total.toFixed(2);
    }



    async confirmDelete() {
        try {
            // console.log('🗑 Delete started');
            // console.log('Selected IDs:', JSON.stringify(this.selectedIds));

            this.isLoading = true;

            const result = await deleteOrderLineItems({
                lineItemIds: this.selectedIds,
                orderId: this.recordId
            });

            this.showToast('Success', 'Deleted successfully', 'success');

            this.showConfirm = false;
            this.selectedIds = [];
            this.selectedAction = null;

            await this.refreshFullPage();
        } catch (e) {
            console.error(' Delete failed:', JSON.stringify(e));
            this.showToast('Error', 'Delete failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }


    closeConfirm() {
        this.showConfirm = false;
    }

    get showTable() {
        return this.selectedAction && this.selectedAction != 'CREATE' && this.editLines.length === 0;
    }

    get showEditTable() {
        return this.editLines.length > 0;
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    get hasSelectedItems() {
        return this.selectedIds && this.selectedIds.length > 0;
    }

    get disableNextButton() {
        return !this.selectedIds || this.selectedIds.length === 0;
    }

    async refreshFullPage() {
        window.location.reload();
    }


    async saveEdits() {
        try {
            this.isLoading = true;

            // console.log('Edit Lines:', JSON.stringify(this.editLines));

            const payload = this.editLines.map(row => ({
                Id: row.id,                                // ✅ MUST be "Id"
                Quantity__c: row.quantity,
                Final_Price__c: row.finalPrice,
                Price_After_Discount__c: row.priceAfterDiscount,
                CGST__c: row.cgst,
                SGST__c: row.sgst,
                Trade_Discount_TD__c: row.tradeSpecialAmount || 0,
                Cash_Discount_CD__c: row.cashDiscountAmount || 0
            }));


            // console.log('Payload sent to Apex:', JSON.stringify(payload));

            await updateOrderLineItems({ lines: payload });


            this.showToast('Success', 'Order lines updated', 'success');

            // Reset UI
            this.editLines = [];
            this.selectedIds = [];
            this.selectedAction = null;

            // Reload table from DB
            this.refreshFullPage();
            await this.loadLines();

        } catch (e) {
            console.error('Update failed', JSON.stringify(e));
            this.showToast('Error', 'Update failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

}