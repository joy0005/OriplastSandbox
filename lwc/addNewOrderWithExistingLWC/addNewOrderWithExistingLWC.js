import { LightningElement, track, api, wire } from 'lwc';
import getProducts from '@salesforce/apex/CreateOrderLWCController.getProductsforAdd';
import processProductDetailsAfterCreateAdd
    from '@salesforce/apex/CreateOrderLWCController.processProductDetailsAfterCreateAdd';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getSelectedProductDetails
    from '@salesforce/apex/CreateOrderLWCController.getSelectedProductDetails';

import PerPageProducts from '@salesforce/label/c.PerPageProducts';
import getAccountOutstandingAmount
    from '@salesforce/apex/CreateOrderLWCController.getAccountOutstandingAmount';
import getDiscountPercentage
    from '@salesforce/apex/CreateOrderLWCController.getDiscountPercentage';
import getDiscountMapping
    from '@salesforce/apex/CreateOrderLWCController.getDiscountMapping';
import getCategories from '@salesforce/apex/CreateOrderLWCController.getCategories';
import getSubCategories from '@salesforce/apex/CreateOrderLWCController.getSubCategories';
import getIdentifiers from '@salesforce/apex/CreateOrderLWCController.getIdentifiers';
import getCategoryPicklistLabels
    from '@salesforce/apex/CreateOrderLWCController.getCategoryPicklistLabels';

export default class AddNewOrderWithExistingLWC extends NavigationMixin(LightningElement) {



    /* ================= STATE ================= */
    @track isLoading = false;
    @track isAccountLocked = false;
    @track selectedAccountId;
    @track productList = [];
    @track filteredAllProductList = [];
    @track filteredProductList = [];
    @track selectedProducts = [];
    @track selectedProductIds = new Set();
    @track AllSelectedProducts = [];
    @track existingProduct = [];
    @track selectedProductList = [];
    @track showAttributes = false;
    @track showRecomendedProductList = false;
    @track isModalOpen = false;
    @track products = [];

    // combobox options
    categoryOptions = [];
    subCategoryOptions = [];
    identifierOptions = [];
    categoryOptions = [];
    categoryLabelMap = {};
    // selected values
    selectedCategory;
    selectedSubCategory;
    selectedIdentifier;

    // disable flags
    isSubCategoryDisabled = true;
    isIdentifierDisabled = true;

    MAX_SELECTION = 90;
    preselectedMap = new Map();

    /* ================= PAGINATION ================= */
    @track noOfRecordToBeShownForAllProducts = PerPageProducts;
    @track currentPageForAllProduct = 1;
    @track totalPageForAllProduct = 0;
    @track showButtonForAllProduct = false;

    @track selectedCount = 0;
    searchTerm = '';
    /* ================= API INPUTS ================= */
    _accountId;
    _orderLinesForAdd = [];
    _accountReady = false;
    _linesReady = false;


    _order;
    _orderReady = false;

    @api
    set order(value) {
        this._order = value;
        this._orderReady = true;
        this.tryInit();
    }

    get order() {
        return this._order;
    }


    @api
    set accountId(value) {
        this._accountId = value;
        this._accountReady = true;
        this.tryInit();
    }
    get accountId() {
        return this._accountId;
    }

    @api
    set orderLinesForAdd(value) {
        this._orderLinesForAdd = Array.isArray(value) ? value : [];
        this._linesReady = true;
        this.tryInit();
    }
    get orderLinesForAdd() {
        return this._orderLinesForAdd;
    }

    @track accountName;

    tryInit() {

        // console.log('Lines:', JSON.stringify(this._orderLinesForAdd));
        // console.log('Order:', this._order);
        if (!this._accountId || !this._orderLinesForAdd.length || !this._order) {
            return; // wait until both exist
        }

        // 🔥 RESET ONCE
        this._accountReady = false;
        this._linesReady = false;
        this._orderReady = false;

        this.isAccountLocked = true;
        this.selectedAccountId = this._accountId;

        // FETCH ACCOUNT NAME
        getAccountOutstandingAmount({ AccountId: this._accountId })
            .then(acc => {
                this.accountName = acc?.Name || '';
            })
            .catch(() => {
                this.accountName = '';
            });

        this.preparePreselectedProducts();
        this.syncSelectionState();
        this.fetchProductInventory({});
        this.syncSelectionState();
        this.loadCategories();
    }


    // ************************************************

    // ---------------- CATEGORY ----------------
    async loadCategories() {
        const data = await getCategories();
        this.categoryOptions = data.map(v => ({ label: v, value: v }));
    }

    async handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;

        this.resetSubCategory();
        this.resetIdentifier();

        try {
            // Load products for Category only
            await this.loadProducts();

            // Load sub-categories
            const data = await getSubCategories({
                categoryValue: this.selectedCategory
            });

            this.subCategoryOptions = data.map(v => ({
                label: v,
                value: v
            }));

            this.isSubCategoryDisabled = false;

        } catch (error) {
            console.error('Category Change Error:', error);
            this.subCategoryOptions = [];
            this.isSubCategoryDisabled = true;
        }
    }


    // ---------------- SUB CATEGORY ----------------
    async handleSubCategoryChange(event) {
        this.selectedSubCategory = event.detail.value;

        this.resetIdentifier();

        // 🔹 Load products with category + sub-category
        await this.loadProducts();

        const data = await getIdentifiers({
            categoryValue: this.selectedCategory,
            subCategoryValue: this.selectedSubCategory
        });

        this.identifierOptions = data.map(v => ({ label: v, value: v }));
        this.isIdentifierDisabled = false;
    }

    // ---------------- IDENTIFIER ----------------
    async handleIdentifierChange(event) {
        this.selectedIdentifier = event.detail.value;

        // 🔹 Load products with category + sub-category + identifier
        await this.loadProducts();
    }

    // ---------------- PRODUCTS (DYNAMIC) ----------------
    async loadProducts() {
        // console.log('accountId:', this._accountId);
        this.fetchProductInventory({
            accountId: this._accountId,
            CategoryValue: this.selectedCategory || null,
            identifierValue: this.selectedIdentifier || null,
            subCategoryValue: this.selectedSubCategory || null
        });
    }

    // ---------------- RESET HELPERS ----------------
    resetSubCategory() {
        this.selectedSubCategory = null;
        this.subCategoryOptions = [];
        this.isSubCategoryDisabled = true;
    }

    resetIdentifier() {
        this.selectedIdentifier = null;
        this.identifierOptions = [];
        this.isIdentifierDisabled = true;
    }


    async loadCategories() {
        // 1️⃣ API values used in data
        const values = await getCategories();

        // 2️⃣ Label mapping
        this.categoryLabelMap = await getCategoryPicklistLabels();

        // 3️⃣ Build combobox options (LABEL shown, VALUE stored)
        this.categoryOptions = values.map(v => ({
            label: this.categoryLabelMap[v] || v,
            value: v
        }));
    }

    // ************************************************
    /* ================= DERIVED ================= */
    get isSelectionMade() {
        return this.AllSelectedProducts.length > 0;
    }

    get isSelectAllCheckedForAllProduct() {
        // console.log('Checking select all:', JSON.stringify(this.filteredProductList));
        return (this.filteredProductList.length && this.filteredProductList.every(p => p.selected || p.disabled));
    }

    /* ================= PRESELECT EXISTING LINES ================= */
    preparePreselectedProducts() {
        this.preselectedMap.clear();
        this.selectedProducts = [];


        if (!Array.isArray(this._orderLinesForAdd)) {
            return;
        }

        this._orderLinesForAdd.forEach(line => {
            this.preselectedMap.set(line.productId, true);

            this.selectedProducts.push({
                orderLineItemId: line.orderLineItemId,
                productId: line.productId,
                productName: line.productName,
                productType: line.productType,
                productSize: line.productSize,
                unitOfMeasure: line.uom,
                unitPrice: line.unitPrice,
                quantity: line.quantity,
                totalPrice: line.finalPrice,
                selected: true,
                itemDiscGroup: line.itemDiscGroup,
                disabled: true,
                lengthInMeter: line.lengthInMeter
            });
        });
        this.refreshSelectedView();
    }


    /* ================= FETCH PRODUCTS ================= */
    fetchProductInventory({
        accountId,
        CategoryValue,
        identifierValue,
        subCategoryValue
    }) {
        this.isLoading = true;

        getProducts({
            accountId: accountId ? accountId : this.selectedAccountId,
            CategoryValue: CategoryValue ? CategoryValue : '',
            identifierValue: identifierValue ? identifierValue : '',
            subCategoryValue: subCategoryValue ? subCategoryValue : ''
        })
            .then(data => {
                this.productList = data.map((p, index) => {
                    const locked = this.preselectedMap.has(p.Id);

                    return {
                        key: `product-${index}`,
                        productId: p.Id,
                        productName: p.Name,
                        productType: p.Category_Picklist__c,
                        productSize: p.Size__c,
                        unitOfMeasure: p.Base_Unit_of_Measure__c,
                        itemDiscGroup: p.Item_Disc_Group__c,
                        selected: locked,
                        disabled: locked,
                        productCategory: p.Category_Picklist__c || 'N/A', // Product Category
                        productSubCategory: p.Sub_Category_Picklist__c || 'N/A', // Product Sub-Category
                        unitOfMeasurement: p.Base_Unit_of_Measure__c || 'N/A', // Base Unit of Measurement
                        oriPlast_Product_Unique_Key: p.OriPlast_Product_Unique_Key__c || 'N/A'
                    };
                });


                this.filteredAllProductList = [...this.productList];
                // console.log('----- 1 ---------- ✅ Fetched Products:', JSON.stringify(this.filteredAllProductList));
                // console.log('Fetched Products:', JSON.stringify(this.productList));
                this.totalPageForAllProduct = Math.ceil(
                    this.filteredAllProductList.length / this.noOfRecordToBeShownForAllProducts
                );
                this.currentPageForAllProduct = 1;
                this.showButtonForAllProduct = true;
                this.updateDataAfterFilterProduct();

                this.showAttributes = true;
                this.showRecomendedProductList = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /* ================= PAGINATION ================= */
    updateDataAfterFilterProduct() {
        const start =
            (this.currentPageForAllProduct - 1) *
            this.noOfRecordToBeShownForAllProducts;
        const end =
            this.currentPageForAllProduct *
            this.noOfRecordToBeShownForAllProducts;

        this.filteredProductList =
            this.filteredAllProductList.slice(start, end);

        // console.log(" filteredProductList :- ", this.filteredProductList);
    }

    previousHandlerForAllProduct() {
        if (this.currentPageForAllProduct > 1) {
            this.currentPageForAllProduct--;
            this.updateDataAfterFilterProduct();
        }
    }

    nextHandlerForAllProduct() {
        if (this.currentPageForAllProduct < this.totalPageForAllProduct) {
            this.currentPageForAllProduct++;
            this.updateDataAfterFilterProduct();
        }
    }

    get disablePreviousForAllProduct() {
        return this.currentPageForAllProduct <= 1;
    }

    get disableNextForAllProduct() {
        return this.currentPageForAllProduct >= this.totalPageForAllProduct;
    }

    /* ================= CHECKBOX ================= */
    get hasItems() {
        return this.addNewItemOnEdit && this.addNewItemOnEdit.length > 0;
    }


    handleCheckboxChange(event) {
        const index = Number(event.currentTarget.dataset.index);
        this.addNewItemOnEdit = [];
        const globalIndex = (this.currentPageForAllProduct - 1) * this.noOfRecordToBeShownForAllProducts + index;

        const product = this.filteredAllProductList[globalIndex];

        if (product.disabled) {
            event.target.checked = true;
            return;
        }

        const alreadySelectedIndex = this.selectedProducts.findIndex(
            p => p.productId === product.productId
        );

        // ================= SELECT =================
        if (alreadySelectedIndex === -1) {
            if (this.selectedProducts.length >= this.MAX_SELECTION) {
                this.showToast(
                    'Limit Reached',
                    'Maximum 90 products allowed',
                    'warning'
                );
                event.target.checked = false;
                return;
            }

            this.selectedProducts = [
                ...this.selectedProducts,
                {
                    productId: product.productId,
                    productName: product.productName,
                    productType: product.productType,
                    productSize: product.productSize,
                    unitOfMeasure: product.uom,
                    unitPrice: product.unitPrice,
                    quantity: 1,
                    totalPrice: product.unitPrice,
                    selected: true,
                    disabled: false,
                    itemDiscGroup: product.itemDiscGroup
                }
            ];

            // Add New Item On Edit
            this.addNewItemOnEdit.push(product);
        }
        // ================= DESELECT =================
        else {
            this.selectedProducts = this.selectedProducts.filter(
                p => p.productId !== product.productId
            );

            // Add New Item On Edit
            this.addNewItemOnEdit = this.addNewItemOnEdit.filter(
                p => p.productId !== product.productId
            );
            // console.log('❌ Product removed');
        }

        // 🔄 Sync UI state from selectedProducts
        // console.log('Sync selection state');
        // this.syncSelectionState();
        console.log('Refresh selected view');
        this.refreshSelectedView();
        console.log('Update data after filter product');
        this.updateDataAfterFilterProduct();
    }

    handleSelectAllChange(event) {
        const checked = event.target.checked;

        this.filteredAllProductList = this.filteredAllProductList.map(p => {
            if (p.disabled) return p;

            if (checked && !p.selected) {
                // this.selectedProducts.push(p);
                this.selectedProducts.push({
                    productId: p.productId,
                    productName: p.productName,
                    productType: p.productType,
                    productSize: p.productSize,
                    unitOfMeasure: p.uom,
                    itemDiscGroup: p.itemDiscGroup,
                    lengthInMeter: p.lengthInMeter,
                    unitPrice: p.unitPrice,
                    quantity: 1,
                    totalPrice: p.unitPrice,
                    selected: true,
                    disabled: false
                });

                return { ...p, selected: true };
            }

            if (!checked && p.selected) {
                this.selectedProducts =
                    this.selectedProducts.filter(x => x.productId !== p.productId);
                return { ...p, selected: false };
            }

            return p;
        });
        // console.log('----- 2 ---------- ✅ Fetched Products:', JSON.stringify(this.filteredAllProductList));

        this.refreshSelectedView();
        this.updateDataAfterFilterProduct();
    }

    // closeModal() {
    //     this.isModalOpen = false;
    // }
    closeModal() {
        this.isModalOpen = false;

        if (this.originalSelectedProductList) {
            this.selectedProductList = JSON.parse(
                JSON.stringify(this.originalSelectedProductList)
            );
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    round(value) {
        return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value.toLowerCase();

        if (!this.searchTerm) {
            this.filteredAllProductList = [...this.productList];
        } else {
            this.filteredAllProductList = this.productList.filter(p =>
                p.productName?.toLowerCase().includes(this.searchTerm)
            );
        }
        // console.log('----- 3 ---------- ✅ Fetched Products:', JSON.stringify(this.filteredAllProductList));
        // console.log('Filtered Products:', JSON.stringify(this.filteredAllProductList));
        // console.log(' Selected Product List:', JSON.stringify(this.selectedProducts));


        // 🔁 Reset pagination after search
        this.currentPageForAllProduct = 1;
        this.totalPageForAllProduct = Math.ceil(
            this.filteredAllProductList.length / this.noOfRecordToBeShownForAllProducts
        );

        this.updateDataAfterFilterProduct();
    }

    get allTotalPrice() {
        return this.selectedProductList
            .reduce((sum, p) => sum + (p.totalPrice || 0), 0)
            .toFixed(2);
    }

    mergeProductArrays(arrayA, arrayB) {
        const map = new Map();

        // Step 1: Put arrayA first
        arrayA.forEach(item => {
            map.set(item.productId, { ...item });
        });

        // Step 2: Merge / override with arrayB
        arrayB.forEach(item => {
            const existing = map.get(item.productId) || {};
            map.set(item.productId, {
                ...existing,
                ...item   // 🔥 arrayB overrides arrayA
            });
        });

        return Array.from(map.values());
    }
    getUnitPrice(productId) {
        return (
            this.selectedProductList.find(p => p.productId === productId)
                ?.unitPrice || 0
        );
    }

    refreshSelectedView() {
        this.selectedCount = this.selectedProducts.length;

        this.AllSelectedProducts = this.selectedProducts.map((p, i) => ({
            ...p,
            slNo: i + 1
        }));

        // console.log('All Selected Products:', JSON.stringify(this.AllSelectedProducts));

        this.selectedProductList = this.selectedProducts.map(p => ({
            orderLineItemId: p.orderLineItemId || null,
            Id: p.productId,
            productId: p.productId,
            Name: p.productName,
            unitOfMeasure: p.unitOfMeasure,
            unitPrice: p.unitPrice,
            quantity: (p.quantity ? p.quantity : 1),
            itemDiscGroup: p.itemDiscGroup,
            totalPrice: p.totalPrice || (p.unitPrice * (p.quantity || 1)),
            disabled: p.disabled,
            lengthInMeter: p.lengthInMeter
        }));

        // console.log('Selected Product List------:', JSON.stringify(this.selectedProductList));
    }

    async handleProceed() {
        // console.log('<------------------ Handel Proceed START -----------------> ', this.selectedProductList);
        this.isLoading = true;

        try {
            const productIds = this.selectedProductList.map(p => p.productId);
            const oldSelectedProductList = [...this.selectedProductList];
            this.originalSelectedProductList = JSON.parse(JSON.stringify(this.selectedProductList));

            const result = await getSelectedProductDetails({ productIds });

            this.selectedProductList = await Promise.all(
                result.map(async p => {
                    // console.log(' Product:', p);
                    const qty = oldSelectedProductList.find(op => op.productId === p.Id)?.quantity || 0;
                    // console.log(' qty:', qty);
                    const quantity = qty ? qty : 1;
                    const priceRec = p.Product_Prices__r?.[0];
                    const unitPrice = priceRec?.Unit_Price__c || 0;
                    const lengthInMeter = p.Length_In_Meter__c || 0;
                    const unitOfMeasure = p.Base_Unit_of_Measure__c;
                    const totalLength = p.Length__c;
                    let productPriceId = priceRec.Id ? priceRec.Id : null;

                    const base =
                        unitOfMeasure === 'MTR' && (totalLength !== 'undefined' || totalLength !== null)
                            ? lengthInMeter * unitPrice
                            : quantity * unitPrice;

                    /* ================= DISCOUNT ================= */
                    let tradeSpecialAmount = 0;
                    let cashDiscountPercent = 0;
                    let cashDiscountAmount = 0;
                    let finalPriceAfterDiscount = base;
                    let tradeSpecialPercent = 0;

                    if (!this.selectedCustomerDisGroup) {
                        const acc = await getDiscountMapping({
                            accountId: this.order.Account__r.Id
                        });
                        this.selectedCustomerDisGroup =
                            acc?.[0]?.Customer_Disc_Group__c;
                    }

                    let discountGroupCode = '';
                    if (p.Item_Disc_Group__c && this.selectedCustomerDisGroup) {
                        discountGroupCode = `${this.selectedCustomerDisGroup}_${p.Item_Disc_Group__c}`;
                    }

                    if (discountGroupCode) {
                        const discRes = await getDiscountPercentage({ discountGroupCode });

                        if (discRes?.length) {
                            const disc = discRes[0];
                            const tradeDisc = disc.Discount__c || 0;
                            const specialDisc = disc.Special_Discount__c || 0;
                            cashDiscountPercent = disc.Cash_Discount__c || 0;

                            tradeSpecialPercent = tradeDisc + specialDisc;

                            tradeSpecialAmount = (base * tradeSpecialPercent) / 100;

                            const afterTrade = base - tradeSpecialAmount;
                            cashDiscountAmount = (afterTrade * cashDiscountPercent) / 100;

                            finalPriceAfterDiscount = afterTrade - cashDiscountAmount;
                        }
                    }


                    // const gstPercent = p.GST_Value__c || 0;
                    // const totalGST = (finalPriceAfterDiscount * gstPercent) / 100;
                    // const cgst = totalGST / 2;
                    // const sgst = totalGST / 2;
                    // const finalPrice = finalPriceAfterDiscount + totalGST;

                    const gstPercent = Number(p.GST_Value__c) || 0;

                    const totalGST = this.round(
                        (finalPriceAfterDiscount * gstPercent) / 100
                    );

                    const cgst = this.round(totalGST / 2);
                    const sgst = this.round(totalGST / 2);

                    const finalPrice = this.round(
                        finalPriceAfterDiscount + totalGST
                    );

                    return {
                        Id: p.Id,
                        productId: p.Id,
                        Name: p.Name,
                        unitOfMeasure: p.Base_Unit_of_Measure__c,

                        quantity,
                        gstPercent,
                        cgst,
                        sgst,
                        totalPrice: finalPrice,
                        selected: true,
                        disabled: this.selectedProductList?.some(
                            sp => sp.productId === p.Id && sp.disabled
                        ),
                        itemDiscGroup: p.Item_Disc_Group__c,
                        lengthInMeter: p.Length_In_Meter__c,
                        finalPriceAfterDiscount: finalPriceAfterDiscount
                        ,
                        cashDiscountPercent: cashDiscountPercent,
                        tradeSpecialPercent: tradeSpecialPercent,
                        unitPrice: unitPrice,
                        tradeSpecialAmount: tradeSpecialAmount,
                        cashDiscountAmount: cashDiscountAmount,
                        productPriceId: productPriceId
                    };
                })
            );


            this.isModalOpen = true; // ✅ OPEN ONLY AFTER SUCCESS
            // console.log(' Proceed Selected Product List:', JSON.stringify(this.selectedProductList));
        }
        catch (err) {
            console.error('Proceed Error:', JSON.stringify(err));
            this.showToast(
                'Error',
                err?.body?.message || 'Failed to load product details',
                'error'
            );
        }
        finally {
            this.isLoading = false;
            // console.log(' Final Selected Product List for Modal:', JSON.stringify(this.selectedProductList));
        }
    }

    syncSelectionState() {
        const selectedIds = new Set(
            this.selectedProducts.map(p => p.productId)
        );

        // console.log('----- 4 ---------- ✅ Fetched Products:', JSON.stringify(this.productList));
        this.productList = this.productList.map(p => {
            const isSelected = this.isProductSelected(p.productId);
            const isPreselected = this.preselectedMap.has(p.productId);

            return {
                ...p,
                selected: isSelected,
                disabled: isPreselected
            };
        });

        this.filteredAllProductList = [...this.productList];
        this.updateDataAfterFilterProduct();
    }

    isProductSelected(productId) {
        return this.selectedProducts.some(p => p.productId === productId);
    }

    // PREVIOUSLY CODE
    confirmProceed() {
        this.sendProductDetailsToApex2();
    }

    sendProductDetailsToApex2() {
        // console.log(' <-- CALL sendProductDetailsToApex -->');

        // ONLY newly added products
        const newlyAddedProducts = this.selectedProductList
            .filter(p => p.disabled === false)
            .map(p => {
                return {
                    orderId: this.order.Id,               // 👈 REQUIRED
                    selectedAccId: this.accountId,        // 👈 REQUIRED
                    unitPrice: p.unitPrice,

                    Id: p.productId,                      // 👈 Product Id
                    productPriceId: p.productPriceId || null, // 👈 if available

                    quantity: p.quantity,
                    unitOfMeasure: p.unitOfMeasure,

                    finalPriceAfterDiscount: p.finalPriceAfterDiscount ? p.finalPriceAfterDiscount : (p.totalPrice - (p.cgst + p.sgst)),               // base before GST
                    totalPrice: p.totalPrice,

                    tradeSpecialPercent: p.tradeSpecialPercent || 0,
                    cashDiscountPercent: p.cashDiscountPercent || 0,
                    tradeSpecialAmount: p.tradeSpecialAmount || 0,
                    cashDiscountAmount: p.cashDiscountAmount || 0,
                    cgst: p.cgst,
                    sgst: p.sgst,
                };

            });

        // console.log(
        //     'Payload Sent to Apex:',
        //     JSON.stringify(newlyAddedProducts, null, 2)
        // );


        processProductDetailsAfterCreateAdd({
            products: JSON.stringify(newlyAddedProducts)
        })
            .then(res => {
                this.showToast(
                    'Success',
                    'Products added successfully',
                    'success'
                );
                this.refreshFullPage();
            })
            .catch(error => {
                console.error(error);
                this.showToast(
                    'Error',
                    error.body?.message || 'Something went wrong',
                    'error'
                );
            });


    }

    async refreshFullPage() {
        window.location.reload();
        //this.dispatchEvent(new CloseActionScreenEvent());
    }


    async handleQuantityChange(event) {
        const productId = event.target.dataset.id;
        let newQuantity = parseInt(event.target.value, 10);

        if (isNaN(newQuantity) || newQuantity < 0) newQuantity = 0;
        event.target.value = newQuantity;

        // console.log('🔹 Quantity Changed → ProductId:', productId, 'Qty:', newQuantity);
        // console.log('Selected Product List:', JSON.stringify(this.selectedProductList));

        const updatedList = [];

        for (let product of this.selectedProductList) {

            if (product.Id !== productId) {
                updatedList.push(product);
                continue;
            }

            // console.log(' Processing Product:', product.Name);

            /* ================= BASE PRICE ================= */

            let totalLength = 'N/A';
            if (product.unitOfMeasure === 'MTR' && product.lengthInMeter) {
                totalLength = newQuantity * product.lengthInMeter;
            }
            // console.log(' Total Length:', totalLength, 'unitOfMeasure:', product.unitOfMeasure, 'lengthInMeter:', product.lengthInMeter);

            const basePrice =
                product.unitOfMeasure === 'MTR' && totalLength !== 'N/A'
                    ? totalLength * (product.unitPrice || 0)
                    : newQuantity * (product.unitPrice || 0);

            // console.log(' Unit:', product.unitOfMeasure, 'Length:', totalLength, 'Base Price:', basePrice);

            /* ================= DISCOUNT CODE ================= */
            if (!this.selectedCustomerDisGroup) {
                const acc = await getDiscountMapping({
                    accountId: this.order.Account__r.Id
                });
                this.selectedCustomerDisGroup =
                    acc?.[0]?.Customer_Disc_Group__c;

                // console.log(' Customer Discount Group Response:', JSON.stringify(acc) , this.customerDiscGroup);
            }

            let discountGroupCode = '';
            if (product.itemDiscGroup && this.selectedCustomerDisGroup) {
                discountGroupCode = `${this.selectedCustomerDisGroup}_${product.itemDiscGroup}`;
            }

            // console.log(' Discount Group Code:', discountGroupCode);

            /* ================= DEFAULT VALUES ================= */

            let tradeSpecialAmount = 0;
            let cashDiscountPercent = 0;
            let cashDiscountAmount = 0;
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

            /* ================= GST ================= */

            // const gstPercent = product.gstPercent || 0;
            // const totalGST = (finalPriceAfterDiscount * gstPercent) / 100;
            // const cgst = totalGST / 2;
            // const sgst = totalGST / 2;
            // const finalPrice = finalPriceAfterDiscount + totalGST;

            const gstPercent = Number(product.gstPercent) || 0;

            const totalGST = this.round(
                (finalPriceAfterDiscount * gstPercent) / 100
            );

            const cgst = this.round(totalGST / 2);
            const sgst = this.round(totalGST / 2);

            const finalPrice = this.round(
                finalPriceAfterDiscount + totalGST
            );

            /* ================= PUSH ================= */

            updatedList.push({
                ...product,
                quantity: newQuantity,
                totalLength,
                basePrice,

                tradeSpecialAmount,
                cashDiscountPercent,
                cashDiscountAmount,
                totalDiscountAmount: tradeSpecialAmount + cashDiscountAmount,

                finalPriceAfterDiscount: this.round(finalPriceAfterDiscount),
                totalPriceBeforeGST: this.round(finalPriceAfterDiscount),

                gstPercent,
                totalGST,
                cgst,
                sgst,

                totalPrice: finalPrice
            });


            // console.log(' Final Line Item:', JSON.stringify(updatedList[updatedList.length - 1]));
        }

        this.selectedProductList = updatedList;

        // console.log(' Updated Product List:', JSON.stringify(this.selectedProductList));
    }


}