import { LightningElement, track, wire, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DEMO_PRODUCT_OBJECT from '@salesforce/schema/OriPlast_Product__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CATEGORY_FIELD from '@salesforce/schema/OriPlast_Product__c.Category_Picklist__c';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import Identifire_Picklist from '@salesforce/schema/OriPlast_Product__c.Identifire_Picklist__c';
import SUBCATEGORY_FIELD from '@salesforce/schema/OriPlast_Product__c.Sub_Category_Picklist__c';
import getProducts from '@salesforce/apex/CreateOrderLWCController.getProducts';
import getSelectedProductDetails from '@salesforce/apex/CreateOrderLWCController.getSelectedProductDetails';
import getDistributorAccounts from '@salesforce/apex/CreateOrderLWCController.getDistributorAccounts';
import getLoggedinUserAccounts from '@salesforce/apex/CreateOrderLWCController.getLoggedinUserAccounts';
import processProductDetailsAfterCreate from '@salesforce/apex/CreateOrderLWCController.processProductDetailsAfterCreate';
import getAccountOutstandingAmount from '@salesforce/apex/CreateOrderLWCController.getAccountOutstandingAmount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import PerPageInventoryProducts from '@salesforce/label/c.PerPageInventoryProducts';
import PerPageProducts from '@salesforce/label/c.PerPageProducts';
import getIdentifiers from '@salesforce/apex/CreateOrderLWCController.getIdentifiers';
import getPartiallyDeliveredOrders from '@salesforce/apex/CreateOrderLWCController.getPartiallyDeliveredOrders';
import getDiscountPercentage from '@salesforce/apex/CreateOrderLWCController.getDiscountPercentage';
import getOrderWithAccount from '@salesforce/apex/CreateOrderLWCController.getOrderWithAccount';


export default class CreateOrderLWC extends NavigationMixin(LightningElement) {

    @api orderId;
    @track noOfRecordToBeShown = PerPageInventoryProducts;
    showSelection = true
    @track noOfRecordToBeShownForAllProducts = PerPageProducts;
    @track isLoading = false;
    userId = Id;
    @track userProfileName = '';
    @track isSalesUser = false;
    @track CategoryOptions = [];
    @track SubcategoryOptions = [];
    @track IdentifierOptions = [];
    @track IdentifierOptions_copy = [];
    @track distributorAccountOptions = [];
    @track userAccountOptions = [];
    @track categoryData;
    @track subCategoryData;
    @track identifierData;
    @track typeValue = '';
    @track categoryValue = '';
    @track identifierValue = '';
    @track subCategoryValue = '';
    @track productList = [];
    @track filteredProductList = [];
    @track invproductList = [];
    @track inventoryProductList = [];
    @track showRecomendedProductList = false;
    @track showInventoryProductList = false
    @track selectedCount = 0;
    @track selectedCountInv = 0;
    @track searchTerm = '';
    @track searchSize = null;
    @track InvsearchTerm = '';
    @track InvsearchSize = null;
    @track isModalOpen = false;
    selectedProductIds
    selectedInvProductIds
    selectedAllProductIds
    selectedAllProducts
    @track selectedProductList = [];
    @track inventoryProductList = []
    @track quantity = 1;
    selectedCustomerDisGroup
    selectedAccountId
    @track showAttributes = false
    @track filteredInvProductList = [];
    @track isFilteredINV = false;
    @track displayedListLengthINV = 0;
    //@track noOfRecordToBeShown = 1;
    @track totalPage = 0;
    @track currentPage = 1;
    @track showButton = false
    @track filteredAllProductList = [];
    @track isFilteredProduct = false;
    @track displayedListLengthProduct = 0;
    @track totalPageForAllProduct = 0;
    @track currentPageForAllProduct = 1;
    @track showButtonForAllProduct = false
    //@track noOfRecordToBeShownForAllProducts = 10;
    @track isSubCategoryDisabled = false
    @track isIdentifierDisabled = false
    @track TotalOutstandingOrderValue = 0.00
    @track corretctTotalOutstandingValue = true
    @track showReturnedValue = false
    @track returnedValueFromApex = ''
    @track CreatedOrderId = ''
    @track isAllDistributorShown = false
    @track selectedDistributorValue;
    @track MAX_SELECTION = 90;
    @track partiallyDeliveredOrders = [];
    @track showPartialOrders = false;
    @track accountId;
    @track accountName;
    @track customerDiscGroup;
    @track isAccountLocked = false;
    @track TotalOutstandingOrderValueMinLimit = 3000000;


    connectedCallback() {

        // 🔹 CASE 1: Opened from Edit Order
        if (this.orderId) {
            getOrderWithAccount({ orderId: this.orderId })
                .then(res => {
                    this.accountId = res.Account__c;
                    this.accountName = res.Account__r.Name;
                    this.customerDiscGroup = res.Account__r.Customer_Disc_Group__c;

                    this.isAccountLocked = true;   // 🔒 lock account
                    this.showSelection = false;    // hide dropdown
                })
                .catch(err => {
                    console.error('Order account fetch failed', err);
                });
        }

        // 🔹 CASE 2: Standalone Create Order
        else {
            this.isAccountLocked = false;  // dropdown visible
            this.showSelection = true;
        }
    }



    // Fetch User Profile Information
    @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
                if (this.userProfileName === 'Sales' || this.userProfileName === 'System Administrator') {
                    this.isAllDistributorShown = true;
                    this.fetchDistributorAccounts();   // Show ALL distributors
                } else {
                    this.isAllDistributorShown = false;
                    this.fetchLoggedinUserAccounts();  // Show only mapped distributor
                }

            }
        } else if (error) {
            console.error('Error For Finding Profile Name:', error);
        }
    }


    // Fetch Object Information
    @wire(getObjectInfo, { objectApiName: DEMO_PRODUCT_OBJECT }) productInfo;

    // Fetch Sub_Category__c Picklist Values
    @wire(getPicklistValues, { recordTypeId: '$productInfo.data.defaultRecordTypeId', fieldApiName: SUBCATEGORY_FIELD })
    wiredSubCategoryValues({ data, error }) {
        if (data) {
            this.subCategoryData = data;
        } else if (error) {
            console.error('Error loading Sub Category Picklist Values:', error);
        }
    }
    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }


    // Fetch Category__c Picklist Values
    @wire(getPicklistValues, { recordTypeId: '$productInfo.data.defaultRecordTypeId', fieldApiName: Identifire_Picklist })
    wiredIdentifierValues({ data, error }) {
        if (data) {
            this.identifierData = data;
            // console.log('Identifier Data:', JSON.stringify(data));
        } else if (error) {
            console.error('Error loading Category Picklist Values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$productInfo.data.defaultRecordTypeId', fieldApiName: CATEGORY_FIELD })
    wiredCategoryValues({ data, error }) {
        if (data) {
            this.categoryData = data;
            this.CategoryOptions = data.values;
            const noneOptionCategory = { label: 'None', value: 'None' };
            this.CategoryOptions = [noneOptionCategory, ...this.CategoryOptions];
        } else if (error) {
            console.error('Error loading Category Picklist Values:', error);
        }
    }

    fetchDistributorAccounts() {
        getDistributorAccounts()
            .then((result) => {
                this.distributorAccountOptions = result.map(account => ({
                    label: account.Name, // Display name in the picklist
                    value: JSON.stringify({
                        customerDiscGroup: account.Customer_Disc_Group__c, // Store Customer_Disc_Group__c
                        accountId: account.Id // Store Account Id
                    })
                }));
                // console.log('Distributor Accounts fetched:', JSON.stringify(this.distributorAccountOptions));
            })
            .catch((error) => {
                this.distributorAccountOptions = [];
                console.error('Error fetching accounts:', error);
            });
    }

    fetchLoggedinUserAccounts() {
        getLoggedinUserAccounts({ UserId: Id })   // 👈 always valid
            .then(result => {
                this.distributorAccountOptions = result.map(account => ({
                    label: account.Name,
                    value: JSON.stringify({
                        customerDiscGroup: account.Customer_Disc_Group__c,
                        accountId: account.Id
                    })
                }));
                // Auto select first value
                if (this.distributorAccountOptions.length > 0) {
                    this.selectedDistributorValue = this.distributorAccountOptions[0].value;

                    this.handleAccountChange({
                        detail: { value: this.selectedDistributorValue }
                    });
                }
            })
            .catch(error => {
                console.error('Error fetching logged-in user accounts', error);
                this.distributorAccountOptions = [];
            });
    }


    handleDistributorChange(event) {
        const selectedValue = JSON.parse(event.detail.value); // Parse the stringified value

        // Log the selected value
        this.selectedAccountId = selectedValue.accountId;
        this.selectedCustomerDisGroup = selectedValue.customerDiscGroup;

        if (this.selectedAccountId) {
            this.showAttributes = true
            this.showInventoryProductList = true
            this.fetchProductInventory(); // REQUIRED
            //this.getAccountWiseInventoryProducts(this.selectedAccountId);
            this.getAccountOutstandingAmount(this.selectedAccountId);
            this.loadPartiallyDeliveredOrders();
        } else {
            this.showAttributes = false
        }
    }


    handleAccountChange(event) {
        const selectedValue = JSON.parse(event.detail.value); // Parse the stringified value

        this.selectedAccountId = selectedValue.accountId;
        this.selectedCustomerDisGroup = selectedValue.customerDiscGroup;

        if (this.selectedAccountId) {
            this.showAttributes = true
            this.showInventoryProductList = true
            this.fetchProductInventory();
            this.getAccountOutstandingAmount(this.selectedAccountId);
            this.loadPartiallyDeliveredOrders();
        } else {
            this.showAttributes = false
        }
    }
    loadPartiallyDeliveredOrders() {
        getPartiallyDeliveredOrders({ accountId: this.selectedAccountId })
            .then(result => {
                this.partiallyDeliveredOrders = result;
                this.showPartialOrders = result.length > 0;
            })
            .catch(error => {
                console.error('Error loading partially delivered orders', error);
                this.partiallyDeliveredOrders = [];
                this.showPartialOrders = false;
            });
    }

    navigateToOrder(event) {
        const orderId = event.target.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: orderId,
                actionName: 'view'
            }
        });
    }

    getAccountOutstandingAmount(selectedAccountId) {
        getAccountOutstandingAmount({ AccountId: selectedAccountId })
            .then(result => {
                this.TotalOutstandingOrderValue = result.Total_Outstanding_Order_Value__c;
                if (this.TotalOutstandingOrderValue > this.TotalOutstandingOrderValueMinLimit) {
                    this.corretctTotalOutstandingValue = false
                } else {
                    this.corretctTotalOutstandingValue = true
                }
            })
    }

    handleCategoryChange(event) {
        const selectedCategory = event.target.value; // Get the selected category value
        const selectedCategoryKey = this.subCategoryData.controllerValues[selectedCategory];
        const selectedCategoryKeyForIdentifier = this.identifierData.controllerValues[selectedCategory];

        if (this.subCategoryData && this.subCategoryData.values) {
            this.SubcategoryOptions = this.subCategoryData.values.filter(option =>
                option.validFor.includes(selectedCategoryKey)
            );
        } else {
            this.SubcategoryOptions = [];
        }
        const noneOptionSubCategory = { label: 'None', value: 'None' };
        this.SubcategoryOptions = [noneOptionSubCategory, ...this.SubcategoryOptions];

        if (this.identifierData && this.identifierData.values) {
            this.IdentifierOptions = this.identifierData.values.filter(option =>
                option.validFor.includes(selectedCategoryKeyForIdentifier) // Ensure category key is present in validFor
            );
        } else {
            this.IdentifierOptions = [];
        }

        const noneOptionIdentifier = { label: 'None', value: 'None' };
        this.IdentifierOptions = [noneOptionIdentifier, ...this.IdentifierOptions];
        this.subCategoryValue = null;
        this.identifierValue = null;
        this.categoryValue = selectedCategory;
        if (selectedCategory === 'None') {
            this.isSubCategoryDisabled = false;
            this.isIdentifierDisabled = false;
        } else {
            this.isSubCategoryDisabled = false; // Reset before applying
            this.isIdentifierDisabled = false; // Reset before applying
        }
        this.filterResults();
    }


    handleSubCategoryChange(event) {
        this.subCategoryValue = event.target.value;

        // Reset identifier selection
        this.identifierValue = null;
        this.IdentifierOptions = [{ label: 'Loading...', value: '' }];
        this.isIdentifierDisabled = true;

        // Guard clause
        if (
            !this.categoryValue ||
            this.categoryValue === 'None' ||
            !this.subCategoryValue ||
            this.subCategoryValue === 'None'
        ) {
            this.IdentifierOptions = [{ label: 'None', value: 'None' }];
            this.isIdentifierDisabled = false;
            return;
        }

        // ✅ CALL APEX
        getIdentifiers({
            categoryValue: this.categoryValue,
            subCategoryValue: this.subCategoryValue
        })
            .then(result => {
                // Convert List<String> → combobox options
                this.IdentifierOptions = result.map(idVal => ({
                    label: idVal,
                    value: idVal
                }));

                // Add None option
                this.IdentifierOptions = [
                    { label: 'None', value: 'None' },
                    ...this.IdentifierOptions
                ];

                this.isIdentifierDisabled = false;
            })
            .catch(error => {
                console.error('Error fetching identifiers:', error);
                this.IdentifierOptions = [{ label: 'None', value: 'None' }];
                this.isIdentifierDisabled = false;
            });

        // Optional: update product filtering
        this.filterResults();
    }


    handleIdentifierChange(event) {
        this.identifierValue = event.target.value;
        this.filterResults();
    }
    filterResults() {
        if (this.categoryValue == 'None') {
            this.categoryValue = ''
        }
        if (this.subCategoryValue == 'None') {
            this.subCategoryValue = ''
        }
        if (this.identifierValue == 'None') {
            this.identifierValue = ''
        }

        if (!this.searchTerm && !this.categoryValue && !this.subCategoryValue && !this.identifierValue) {
            // No filters applied, show all items
            this.filteredAllProductList = [...this.productList];
            this.isFilteredProduct = false;
        } else {
            // Apply filters
            this.filteredAllProductList = this.productList.filter(item => {
                const matchesCategory = !this.categoryValue || item.productType === this.categoryValue;
                const matchesSubCategory = !this.subCategoryValue || item.productSubCategory.toLowerCase().includes(this.subCategoryValue.toLowerCase());
                const matchesIdentifier = !this.identifierValue || item.productCategory === this.identifierValue;
                const matchesSearchTerm = !this.searchTerm || item.productName.toLowerCase().includes(this.searchTerm);

                return matchesCategory && matchesSubCategory && matchesIdentifier && matchesSearchTerm;
            });
            this.isFilteredProduct = true;
        }

        // Update pagination and displayed list length
        this.currentPageForAllProduct = 1;
        this.totalPageForAllProduct = Math.ceil(this.filteredAllProductList.length / this.noOfRecordToBeShownForAllProducts);
        this.updateDataAfterFilterProduct();
        this.displayedListLengthProduct = this.filteredAllProductList.length;
    }

    fetchProductInventory() {
        this.isLoading = true;
        if (this.categoryValue == 'None') {
            this.categoryValue = ''
        }
        if (this.subCategoryValue == 'None') {
            this.subCategoryValue = ''
        }
        if (this.identifierValue == 'None') {
            this.identifierValue = ''
        }

        getProducts({
            accountId: this.accountId,
            CategoryValue: this.categoryValue,
            subCategoryValue: this.subCategoryValue,
            identifierValue: this.identifierValue
        })
            .then(data => {
                if (data) {
                    this.productList = data.map((product, index) => {
                        return {
                            key: `product-${index}`, // Unique key for each product
                            productId: product.Id, // Product ID
                            productName: product.Name, // Product Name
                            productType: product.Category_Picklist__c || 'N/A', // Product Type
                            productSize: product.Size__c || 'N/A', // Product Size
                            ProductCategoryCode: product.Product_Category_Code_Picklist__c,
                            productCategory: product.Identifire_Picklist__c || 'N/A', // Product Category
                            productSubCategory: product.Sub_Category_Picklist__c || 'N/A', // Product Sub-Category
                            unitOfMeasurement: product.Base_Unit_of_Measure__c || 'N/A', // Base Unit of Measurement
                            selected: false, // Initialize as not selected
                            rowClass: '', // Initialize rowClass
                            oriPlast_Product_Unique_Key: product.OriPlast_Product_Unique_Key__c || 'N/A'
                        };
                    });

                    // Initialize filteredProductList to the full productList initially
                    this.filteredProductList = [...this.productList];
                    // console.log('filter prod 1 :- ' , JSON.stringify(this.filteredProductList));
                    // Initialize pagination variables
                    this.showButtonForAllProduct = true;

                    this.filterResults();
                } else {
                    this.productList = [];
                    this.filteredProductList = [];
                }
            })
            .catch(error => {
                console.error(
                    'Error fetching product inventory:',
                    error?.body?.message
                ); this.productList = [];
                this.filteredProductList = [];
            })
            .finally(() => {
                this.isLoading = false;
                this.showRecomendedProductList = true; // Ensure this is set to true after processing
            });
    }

    updateDataAfterFilterProduct() {
        const start = (this.currentPageForAllProduct - 1) * this.noOfRecordToBeShownForAllProducts;
        const end = this.currentPageForAllProduct * this.noOfRecordToBeShownForAllProducts;
        this.filteredProductList = this.filteredAllProductList.slice(start, end);
        // console.log('filter prod 2 :- ' , JSON.stringify(this.filteredProductList));
    }

    get disablePreviousForAllProduct() {
        return this.currentPageForAllProduct <= 1;
    }
    get disableNextForAllProduct() {
        return this.currentPageForAllProduct >= this.totalPageForAllProduct;
    }
    previousHandlerForAllProduct() {
        if (this.currentPageForAllProduct > 1) {
            this.currentPageForAllProduct = this.currentPageForAllProduct - 1;

            this.updateDataAfterFilterProduct(); // Update filtered data if search is applied

        }
    }
    nextHandlerForAllProduct() {
        if (this.currentPageForAllProduct < this.totalPageForAllProduct) {
            this.currentPageForAllProduct = this.currentPageForAllProduct + 1;

            this.updateDataAfterFilterProduct(); // Update filtered data if search is applied

        }

    }
    @track selectedProducts = [];

    handleCheckboxChange(event) {
        try {
            const index = parseInt(event.currentTarget.dataset.index, 10);
            const productListToUpdate = this.filteredAllProductList;
            const globalIndex = (this.currentPageForAllProduct - 1) * this.noOfRecordToBeShownForAllProducts + index;

            const product = productListToUpdate[globalIndex];

            // 🔥 BLOCK 91st selection
            if (!product.selected && this.selectedProducts.length >= this.MAX_SELECTION) {
                this.showToast(
                    'Limit Reached',
                    'You can select only 90 products in one order.',
                    'warning'
                );

                // Force UI checkbox back to false
                event.target.checked = false;
                return;
            }


            product.selected = !product.selected;

            product.rowClass = product.selected
                ? 'highlight-selected slds-hint-parent'
                : 'slds-hint-parent';

            event.currentTarget.classList.toggle('checked', product.selected);

            this.updateDataAfterFilterProduct();

            // Manage global selection list
            if (product.selected) {
                if (!this.selectedProducts.some(p => p.productId === product.productId)) {
                    this.selectedProducts = [...this.selectedProducts, product];
                }
            } else {
                this.selectedProducts = this.selectedProducts.filter(p => p.productId !== product.productId);
            }

            // console.log('Selected Products:', JSON.stringify(this.selectedProducts));

            // Update selected count and IDs
            this.selectedCount = productListToUpdate.filter(p => p.selected).length;
            //this.selectedProductIds = productListToUpdate.filter(p => p.selected).map(p => p.productId);
            this.selectedAllProducts = this.selectedProducts.map(p => p.productId);
            this.ShowSelectedRecord();
            // console.log('Selected IDs:', JSON.stringify(this.selectedAllProducts));
        } catch (error) {
            console.error('Error in handleCheckboxChange:', error);
        }
    }
    handleSelectAllChange(event) {
        const isChecked = event.target.checked;

        // Determine the correct list to update (filtered or original)
        const productListToUpdate = this.filteredAllProductList;

        const start = (this.currentPageForAllProduct - 1) * this.noOfRecordToBeShownForAllProducts;
        const end = this.currentPageForAllProduct * this.noOfRecordToBeShownForAllProducts;

        // Update the selection state for the current page in the chosen list
        for (let i = start; i < end && i < productListToUpdate.length; i++) {

            if (isChecked && !productListToUpdate[i].selected) {
                if (this.selectedProducts.length >= this.MAX_SELECTION) {
                    this.showToast(
                        'Limit Reached',
                        'You can select only 90 products in one order.',
                        'warning'
                    );
                    break;
                }
            }

            productListToUpdate[i].selected = isChecked;
            productListToUpdate[i].rowClass = isChecked ? 'highlight-selected slds-hint-parent' : 'slds-hint-parent';

            if (isChecked) {
                if (!this.selectedProducts.some(p => p.productId === productListToUpdate[i].productId)) {
                    this.selectedProducts = [...this.selectedProducts, productListToUpdate[i]];
                }
            } else {
                this.selectedProducts = this.selectedProducts.filter(p => p.productId !== productListToUpdate[i].productId);
            }
        }

        this.updateDataAfterFilterProduct(); // Update filtered data if search is applied

        // Update the selected count and IDs based on the chosen list
        this.selectedCount = productListToUpdate.filter(product => product.selected).length;
        this.selectedAllProducts = this.selectedProducts
            .filter(product => product.selected)
            .map(product => product.productId);

        this.ShowSelectedRecord();
    }

    @track AllSelectedProducts = [];

    ShowSelectedRecord() {
        // Filter selected products from both lists
        const safeAllSelectedRecord = this.selectedProducts.filter(product => product.selected);
        const safeSelectedInvProduct = this.selectedINVProducts.filter(product => product.selected);

        // Combine and remove duplicates
        const uniqueProducts = [
            ...new Map(
                [...safeAllSelectedRecord, ...safeSelectedInvProduct].map(product => [
                    product.productId,
                    product,
                ])
            ).values(),
        ];

        // Add serial numbers to each product
        this.AllSelectedProducts = uniqueProducts.map((product, index) => ({
            ...product,
            slNo: index + 1,
        }));

        // console.log('!!Show Selected Products with Sl. No:', JSON.stringify(this.AllSelectedProducts));
    }



    get isSelectAllCheckedForAllProduct() {
        const start = (this.currentPageForAllProduct - 1) * this.noOfRecordToBeShownForAllProducts;
        const end = this.currentPageForAllProduct * this.noOfRecordToBeShownForAllProducts;

        const productListToCheck = this.filteredAllProductList;

        // Check if all products on the current page are selected
        return productListToCheck.slice(start, end).every(product => product.selected);
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterResults();
    }
    updateData1st() {
        const start = (this.currentPage - 1) * this.noOfRecordToBeShown;
        const end = this.currentPage * this.noOfRecordToBeShown;
        this.inventoryProductList = this.invproductList.slice(start, end);

    }
    // Update data based on the filtered list
    updateDataAfterSearch() {
        // console.log('Entering');
        const start = (this.currentPage - 1) * this.noOfRecordToBeShown;
        const end = this.currentPage * this.noOfRecordToBeShown;
        this.inventoryProductList = this.filteredInvProductList.slice(start, end);
        // console.log('inventoryProductList', JSON.stringify(this.inventoryProductList));
    }
    get disablePrevious() {
        return this.currentPage <= 1;
    }
    get disableNext() {
        return this.currentPage >= this.totalPage;
    }
    previousHandler() {
        if (this.currentPage > 1) {
            this.currentPage = this.currentPage - 1;
            this.updateData1st();
        }
    }
    nextHandler() {
        if (this.currentPage < this.totalPage) {
            this.currentPage = this.currentPage + 1;
            this.updateData1st();
        }

    }

    get isSelectionMade() {
        return this.selectedCount !== 0 || this.selectedCountInv !== 0;
    }

    @track selectedINVProducts = [];

    handleInvCheckboxChange(event) {
        const pageIndex = parseInt(event.currentTarget.dataset.index, 10); // Index on the current page
        const productListToUpdate = this.isFilteredINV ? this.filteredInvProductList : this.invproductList;

        // Calculate the global index based on current page and item index on the page
        const originalIndex = (this.currentPage - 1) * this.noOfRecordToBeShown + pageIndex;

        // Validate index to ensure no out-of-bounds error
        if (originalIndex >= productListToUpdate.length) {
            console.error('Invalid index for product selection:', originalIndex);
            return;
        }

        // Retrieve the product from the correct list and toggle its selected state
        const product = productListToUpdate[originalIndex];
        product.selected = !product.selected;

        // Update the rowClass based on selection
        product.rowClass = product.selected
            ? 'highlight-selected slds-hint-parent'
            : 'slds-hint-parent';

        // Apply the .checked class to the circular checkbox visually
        event.currentTarget.classList.toggle('checked', product.selected);

        // Reflect changes in the displayed list
        if (this.isFilteredINV) {
            this.updateDataAfterSearch(); // Refresh filtered data
        } else {
            this.updateData1st(); // Refresh unfiltered data
        }
        // Manage global selection list
        if (product.selected) {
            if (!this.selectedINVProducts.some(p => p.productId === product.productId)) {
                this.selectedINVProducts = [...this.selectedINVProducts, product];
            }
        } else {
            this.selectedINVProducts = this.selectedINVProducts.filter(p => p.productId !== product.productId);
        }
        // console.log('Selected Products:', JSON.stringify(this.selectedINVProducts));
        // Update selected product count and IDs across all pages
        this.selectedCountInv = this.invproductList.filter(p => p.selected).length;
        this.selectedInvProductIds = this.invproductList
            .filter(p => p.selected)
            .map(p => p.productId);
        this.ShowSelectedRecord();

    }

    handleSelectAllInvChange(event) {
        const isChecked = event.target.checked;

        // Choose the correct list to update (filtered or original list)
        const productListToUpdate = this.isFilteredINV ? this.filteredInvProductList : this.invproductList;

        // Calculate the range of records for the current page
        const start = (this.currentPage - 1) * this.noOfRecordToBeShown;
        const end = this.currentPage * this.noOfRecordToBeShown;

        // Update selected state for the current page in the chosen list
        for (let i = start; i < end && i < productListToUpdate.length; i++) {
            if (isChecked && this.selectedProducts.length >= this.MAX_SELECTION) {
                this.showToast(
                    'Limit Reached',
                    'You can select a maximum of 90 products.',
                    'warning'
                );
                break;
            }

            productListToUpdate[i].selected = isChecked;
            productListToUpdate[i].rowClass = isChecked ? 'highlight-selected slds-hint-parent' : 'slds-hint-parent';

            if (isChecked) {
                if (!this.selectedINVProducts.some(p => p.productId === productListToUpdate[i].productId)) {
                    this.selectedINVProducts = [...this.selectedINVProducts, productListToUpdate[i]];
                }
            } else {
                this.selectedINVProducts = this.selectedINVProducts.filter(p => p.productId !== productListToUpdate[i].productId);
            }
        }

        // Refresh the displayed data
        if (this.isFilteredINV) {
            this.updateDataAfterSearch();
        } else {
            this.updateData1st();
        }

        // Update the selected count and IDs for the chosen list
        this.selectedCountInv = productListToUpdate.filter(product => product.selected).length;
        this.selectedInvProductIds = this.selectedINVProducts
            .filter(product => product.selected)
            .map(product => product.productId);

        this.ShowSelectedRecord();
        // console.log('Selected INV Product IDs:', JSON.stringify(this.selectedInvProductIds));
        // console.log('All Products Selected on Current Page:', isChecked);
    }


    get isSelectAllChecked() {
        const start = (this.currentPage - 1) * this.noOfRecordToBeShown;
        const end = this.currentPage * this.noOfRecordToBeShown;

        // Check if all products on the current page are selected
        return this.inventoryProductList.every(product => product.selected);
    }

    handleInvSearchChange(event) {
        this.InvsearchTerm = event.target.value.toLowerCase();
        // console.log('Search term:', this.InvsearchTerm);

        if (this.InvsearchTerm) {
            // Filter against the full product list
            this.filteredInvProductList = this.invproductList.filter(product =>
                product.productName.toLowerCase().includes(this.InvsearchTerm)
            );
            this.isFilteredINV = true;
            // console.log('Entering If:');
        } else {
            // Reset to the full product list if the search term is empty
            this.filteredInvProductList = [...this.invproductList];
            this.isFilteredINV = false;
            // console.log('Entering Else:');
        }
        // Update the length of the displayed list (filtered or unfiltered)
        this.displayedListLengthINV = this.isFilteredINV ? this.filteredInvProductList.length : this.invproductList.length;
        // Update pagination based on the filtered list
        this.currentPage = 1;
        this.totalPage = Math.ceil(this.filteredInvProductList.length / this.noOfRecordToBeShown);

        // Update the displayed products
        this.updateDataAfterSearch();
    }

    // ##################### OLD #######################
    async handleProceed() {
        this.showRecomendedProductList = false;
        this.showAttributes = false;
        this.showButtonForAllProduct = false;
        this.isLoading = true;

        if (!this.selectedCustomerDisGroup) {
            this.showToast(
                'Error',
                'Customer Discount Group not loaded yet. Please reselect Account.',
                'error'
            );
            return;
        }


        try {
            /* ================= GET SELECTED IDS ================= */

            const safeSelectedProductIds = this.selectedAllProducts ?? [];
            const safeSelectedInvProductIds = this.selectedInvProductIds ?? [];

            this.selectedAllProductIds = [
                ...new Set([...safeSelectedProductIds, ...safeSelectedInvProductIds])
            ];


            /* ================= FETCH PRODUCTS ================= */

            const result = await getSelectedProductDetails({
                productIds: this.selectedAllProductIds
            });

            if (!result || result.length === 0) {
                this.isModalOpen = false;
                this.isLoading = false;
                return;
            }

            /* ================= BUILD BASE PRODUCT LIST ================= */

            this.selectedProductList = result.map(product => {

                const unitOfMeasure = product.Base_Unit_of_Measure__c || 'PCS';
                const quantity = product.quantity || 1;

                let unitPrice = 0;
                let productPrice = '';

                if (product.Product_Prices__r?.length > 0) {
                    unitPrice = product.Product_Prices__r[0].Unit_Price__c || 0;
                    productPrice = product.Product_Prices__r[0].Id;
                }

                let totalLength = 'NOT APPLICABLE';
                if (unitOfMeasure === 'MTR' && product.Length_In_Meter__c > 0) {
                    totalLength = quantity * product.Length_In_Meter__c;
                }

                const basePrice =
                    unitOfMeasure === 'MTR' && totalLength !== 'NOT APPLICABLE'
                        ? totalLength * unitPrice
                        : quantity * unitPrice;

                let discountGroupCode = '';
                if (product.Item_Disc_Group__c && this.selectedCustomerDisGroup) {
                    discountGroupCode = `${this.selectedCustomerDisGroup}_${product.Item_Disc_Group__c}`;
                }


                return {
                    ...product,
                    unitOfMeasure,
                    unitPrice,
                    quantity,
                    totalLength,
                    basePrice,
                    discountGroupCode,
                    selectedAccId: this.selectedAccountId,
                    productPrice
                };
            });

            /* ================= APPLY DISCOUNT & GST ================= */
            this.selectedProductList = await Promise.all(
                this.selectedProductList.map(p => this.calculatePricing(p))
            );


            this.isModalOpen = true;
        }
        catch (error) {
            console.error(' handleProceed Error:', JSON.stringify(error));
            this.isModalOpen = false;
            this.showRecomendedProductList = true;
            this.showAttributes = true;
            this.showButtonForAllProduct = true;
        }
        finally {
            this.isLoading = false;
        }
    }


    async calculatePricing(product) {
        let tradeSpecialAmount = 0;
        let cashDiscountPercent = 0;
        let cashDiscountAmount = 0;
        let finalPriceAfterDiscount = product.basePrice;

        try {
            if (product.discountGroupCode) {
                const res = await getDiscountPercentage({
                    discountGroupCode: product.discountGroupCode
                });

                if (res && res.length > 0) {
                    const d = res[0];

                    const tradePercent =
                        (d.Discount__c || 0) + (d.Special_Discount__c || 0);

                    cashDiscountPercent = d.Cash_Discount__c || 0;

                    tradeSpecialAmount =
                        (product.basePrice * tradePercent) / 100;

                    const afterTrade = product.basePrice - tradeSpecialAmount;

                    cashDiscountAmount =
                        (afterTrade * cashDiscountPercent) / 100;

                    //finalPriceAfterDiscount = (afterTrade - cashDiscountAmount).toFixed(2);
                    finalPriceAfterDiscount = afterTrade - cashDiscountAmount;

                }
            }
        } catch (err) {
            console.error(
                '❌ Discount fetch failed for:',
                product.Name,
                err?.body?.message || err
            );
        }

        // const gstPercent = product.GST_Value__c || 0;
        // const totalGST = ((finalPriceAfterDiscount * gstPercent) / 100 ).toFixed(2);
        const gstPercent = Number(product.GST_Value__c) || 0;

        const totalGST = Number(
            ((finalPriceAfterDiscount * gstPercent) / 100).toFixed(2)
        );

        const finalTotal = Number(
            (finalPriceAfterDiscount + totalGST).toFixed(2)
        );
        console.log('finalTotal', finalTotal);

        return {
            ...product,
            tradeSpecialAmount,
            tradeDiscountPercent:
                tradeSpecialAmount > 0
                    ? (tradeSpecialAmount * 100) / product.basePrice
                    : 0,
            cashDiscountPercent,
            cashDiscountAmount,
            finalPriceAfterDiscount,
            totalPrice: finalTotal,
            cgst: totalGST / 2,
            sgst: totalGST / 2
        };
    }



    calculateFinalPrice(quantity, unitPrice, discountRecord, gstPercent) {
        const totalOrderValue = quantity * unitPrice;

        const tradeDiscount = discountRecord?.Discount__c || 0;
        const specialDiscount = discountRecord?.Special_Discount__c || 0;
        const cashDiscount = discountRecord?.Cash_Discount__c || 0;

        const totalDiscountPercent = tradeDiscount + specialDiscount;

        const tradeDiscountAmount = (totalOrderValue * totalDiscountPercent) / 100;
        const priceAfterTD = totalOrderValue - tradeDiscountAmount;

        const cashDiscountAmount = (priceAfterTD * cashDiscount) / 100;
        const finalPriceAfterAllDiscount = priceAfterTD - cashDiscountAmount;

        const gstAmount = (finalPriceAfterAllDiscount * gstPercent) / 100;
        const cgst = gstAmount / 2;
        const sgst = gstAmount / 2;
        const finalPayableAmount = finalPriceAfterAllDiscount + gstAmount;

        return {
            //totalOrderValue,
            totalDiscountPercent,
            tradeDiscountAmount,
            priceAfterTD,
            cashDiscountAmount,
            finalPriceAfterAllDiscount,
            gstAmount,
            cgst,
            sgst,
            finalPayableAmount
        };
    }

    async handleQuantityChange(event) {
        const productId = event.target.dataset.id;
        let newQuantity = parseInt(event.target.value, 10);

        if (isNaN(newQuantity) || newQuantity < 0) newQuantity = 0;
        event.target.value = newQuantity;

        const updatedList = [];

        for (let product of this.selectedProductList) {

            if (product.Id !== productId) {
                updatedList.push(product);
                continue;
            }

            /* ================= BASE PRICE ================= */

            let totalLength = 'N/A';
            if (product.unitOfMeasure === 'MTR' && product.Length_In_Meter__c) {
                totalLength = newQuantity * product.Length_In_Meter__c;
            }

            let basePrice = 0;

            if (product.unitOfMeasure === 'MTR') {
                const length = product.Length_In_Meter__c || 1; // fallback
                basePrice = newQuantity * length * product.unitPrice;
            } else {
                basePrice = newQuantity * product.unitPrice;
            }

            /* ================= DISCOUNT CODE ================= */

            let discountGroupCode = '';
            if (product.Item_Disc_Group__c && this.selectedCustomerDisGroup) {
                discountGroupCode = `${this.selectedCustomerDisGroup}_${product.Item_Disc_Group__c}`;
            }

            /* ================= DEFAULT VALUES ================= */

            let tradeSpecialAmount = 0;
            let cashDiscountPercent = 0;
            let cashDiscountAmount = 0;
            let finalPriceAfterDiscount = basePrice;

            /* ================= FETCH DISCOUNT ================= */

            if (discountGroupCode) {
                try {
                    const result = await getDiscountPercentage({ discountGroupCode });

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

            // const gstPercent = product.GST_Value__c || 0;
            // const totalGST = (finalPriceAfterDiscount * gstPercent) / 100;
            // const cgst = totalGST / 2;
            // const sgst = totalGST / 2;
            // const finalPrice = finalPriceAfterDiscount + totalGST;

            const gstPercent = Number(product.GST_Value__c) || 0;

            const totalGST = Number(
                ((finalPriceAfterDiscount * gstPercent) / 100).toFixed(2)
            );

            const cgst = Number((totalGST / 2).toFixed(2));
            const sgst = Number((totalGST / 2).toFixed(2));

            const finalPrice = Number(
                (finalPriceAfterDiscount + totalGST).toFixed(2)
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

                finalPriceAfterDiscount,
                totalPriceBeforeGST: finalPriceAfterDiscount,

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

    get allTotalPrice() {
        return this.selectedProductList.reduce((total, product) => {
            return total + (parseFloat(product.totalPrice) || 0); // Sum all totalPrice values, default to 0 if undefined
        }, 0).toFixed(2); // Format to 2 decimal places for consistency
    }

    closeModal() {
        this.isModalOpen = false;
        this.showRecomendedProductList = true;
        this.showAttributes = true
        this.showButtonForAllProduct = true;
    }

    confirmProceed() {
        // Add logic to proceed with the selected product(s)
        this.sendProductDetailsToApex();
    }


    sendProductDetailsToApex() {

        // Validate quantities
        const invalidProducts = this.selectedProductList.filter(
            p => !p.quantity || p.quantity <= 0
        );

        if (invalidProducts.length > 0) {
            this.showToast('Error', 'Please enter valid quantity for all products', 'error');
            return;
        }

        // Call Apex        
        processProductDetailsAfterCreate({
            products: JSON.stringify(this.selectedProductList),
            accountId: this.selectedAccountId
        })
            .then(result => {
                console.log(' Selected Product List:', JSON.stringify(this.selectedProductList));
                // console.log(' Apex Result:', JSON.stringify(result));

                if (result.CreatedorderId) {
                    this.CreatedOrderId = result.CreatedorderId;

                    this.showToast(
                        'Success',
                        `Order created successfully! Order No: ${result.orderName}`,
                        'success'
                    );

                    this.isModalOpen = false;
                    this.navigateToRecord(this.CreatedOrderId);
                }
                else {
                    this.showToast('Error', 'Order creation failed', 'error');
                }
            })
            .catch(error => {
                console.error(' Apex Error:', JSON.stringify(error));
                this.showToast('Error', 'Failed to create order', 'error');
            });
    }



    handlecloseModal() {
        this.showReturnedValue = false;
        this.showRecomendedProductList = true;
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(toastEvent);
    }
    navigateToRecord(orderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: orderId,
                actionName: 'view'
            }
        });
    }
}