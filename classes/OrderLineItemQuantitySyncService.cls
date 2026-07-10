public without sharing class OrderLineItemQuantitySyncService {

   
    private static Boolean serviceRunning = false;

    public static void syncDraftLines(
        Set<String> productNames,
        Set<Id> creatorIds
    ) {
        if (serviceRunning) {
            System.debug(
                'syncDraftLines blocked — already running ' +
                'in this transaction'
            );
            return;
        }
        serviceRunning = true;

        try {
            /*
             * ------------------------------------------------
             * STEP 1
             * Get ALL matching line items from
             * Partially Delivered and Received by Navision orders
             * Filter: product name + creator id
             * ------------------------------------------------
             */
            List<Order_Line_Item__c> partialItems = [
                SELECT Id,
                       Quantity__c,
                       Remaining_Quantity__c,
                       Shipped_Quantity__c,
                       Unit_of_Measure__c,
                       Status__c,
                       Ori_Plast_Product_Name__c,
                       Ori_Plast_Product__r.Length_In_Meter__c,
                       Ori_Plast_Order__r.CreatedById,
                       Ori_Plast_Order__r.Order_Status__c
                FROM   Order_Line_Item__c
                WHERE  (
                    Ori_Plast_Order__r.Order_Status__c =
                        'Partially Delivered'
                    OR
                    Ori_Plast_Order__r.Order_Status__c =
                        'Received by Navision'
                )
                AND    Ori_Plast_Product_Name__c IN :productNames
                AND    Ori_Plast_Order__r.CreatedById IN :creatorIds
            ];

            System.debug(
                'STEP 1 => Partial Items Found: ' +
                partialItems.size()
            );

            /*
             * No partial items found
             * Nothing to calculate — exit early
             */
            if (partialItems.isEmpty()) {
                System.debug(
                    'STEP 1 => No partial items found. ' +
                    'Exiting syncDraftLines.'
                );
                return;
            }

            /*
             * ------------------------------------------------
             * STEP 2
             * Calculate total actual remaining quantity
             * Group by: ProductName + CreatedById
             *
             * Logic:
             * If nothing shipped → use full Quantity__c
             * If MTR + partially shipped → convert
             *   Remaining_Quantity__c back to pieces
             *   by dividing by Length_In_Meter
             * If PCS + partially shipped → use
             *   Remaining_Quantity__c directly
             * ------------------------------------------------
             */
            Map<String, Decimal> totalQtyMap =
                new Map<String, Decimal>();

            for (Order_Line_Item__c item : partialItems) {

                Decimal shippedQty =
                    item.Shipped_Quantity__c == null
                    ? 0
                    : item.Shipped_Quantity__c;

                Decimal lengthInMeter = 0;

                if (
                    item.Ori_Plast_Product__r != null &&
                    String.isNotBlank(
                        item.Ori_Plast_Product__r
                            .Length_In_Meter__c
                    )
                ) {
                    try {
                        lengthInMeter = Decimal.valueOf(
                            item.Ori_Plast_Product__r
                                .Length_In_Meter__c
                        );
                    } catch (Exception e) {
                        System.debug(
                            'STEP 2 => Invalid Length value ' +
                            'for product: ' +
                            item.Ori_Plast_Product_Name__c +
                            ' — defaulting to 0'
                        );
                        lengthInMeter = 0;
                    }
                }

                Decimal actualQty = 0;

                if (shippedQty <= 0) {
                    /*
                     * Nothing shipped yet
                     * Use full original quantity
                     */
                    actualQty =
                        item.Quantity__c == null
                        ? 0
                        : item.Quantity__c;

                } else if (
                    lengthInMeter > 0 &&
                    item.Unit_of_Measure__c != null &&
                    item.Unit_of_Measure__c.contains('MTR')
                ) {
                    /*
                     * MTR product — partially shipped
                     * Convert remaining meters to pieces
                     */
                     Decimal rawQty =
        item.Remaining_Quantity__c == null
        ? 0
        : item.Remaining_Quantity__c / lengthInMeter;

    actualQty = Math.ceil(rawQty);

    System.debug(
        'STEP 2 => MTR Calc => ' +
        'Remaining: ' + item.Remaining_Quantity__c +
        ' | LengthInMeter: ' + lengthInMeter +
        ' | RawQty: ' + rawQty +
        ' | CeiledQty: ' + actualQty
    );

                } else {
                    /*
                     * PCS product — partially shipped
                     * Use remaining quantity directly
                     */
                    actualQty =
                        item.Remaining_Quantity__c == null
                        ? 0
                        : item.Remaining_Quantity__c;
                }

                String key =
                    item.Ori_Plast_Product_Name__c +
                    '|' +
                    item.Ori_Plast_Order__r.CreatedById;

                Decimal running =
                    totalQtyMap.containsKey(key)
                    ? totalQtyMap.get(key)
                    : 0;

                totalQtyMap.put(key, running + actualQty);

                System.debug(
                    'STEP 2 => Key: ' + key +
                    ' | ShippedQty: ' + shippedQty +
                    ' | LengthInMeter: ' + lengthInMeter +
                    ' | ActualQty: ' + actualQty +
                    ' | RunningTotal: ' +
                    totalQtyMap.get(key)
                );
            }

            /*
             * ------------------------------------------------
             * STEP 3
             * Find ALL matching Draft order line items
             * for same product names and creator ids
             * ------------------------------------------------
             */
            List<Order_Line_Item__c> draftItems = [
                SELECT Id,
                       Quantity__c,
                       Ori_Plast_Product_Name__c,
                       Ori_Plast_Order__r.CreatedById,
                       Ori_Plast_Order__r.Order_Status__c,
                       OriPlast_Product_Unit_Price__c,
                       Trade_Discount__c,
                       Cash_Discount_Percentage__c,
                       CGST_Percentage__c,
                       SGST_Percentage__c,
                       Unit_of_Measure__c,
                       Ori_Plast_Product__r.Length_In_Meter__c,
                       Ori_Plast_Product__r.No_of_Pcs_in_one_box__c,
                       Box_Order_Quantity__c
                FROM   Order_Line_Item__c
                WHERE  Ori_Plast_Product_Name__c IN :productNames
                AND    Ori_Plast_Order__r.Order_Status__c = 'Draft'
                AND    Ori_Plast_Order__r.CreatedById IN :creatorIds
            ];

            System.debug(
                'STEP 3 => Draft Items Found: ' +
                draftItems.size()
            );

            if (draftItems.isEmpty()) {
                System.debug(
                    'STEP 3 => No draft items found. ' +
                    'Exiting syncDraftLines.'
                );
                return;
            }

            /*
             * ------------------------------------------------
             * STEP 4
             * For each Draft line item:
             * 1. Match by key (ProductName + CreatedById)
             * 2. Apply box rounding if applicable
             * 3. Skip if quantity unchanged
             * 4. Recalculate all financial fields
             * 5. Add to update list
             *
             * Financial calculation chain:
             * baseAmount         = erpQty × unitPrice
             * tradeDiscountAmt   = baseAmount × (TD% / 100)
             * cashDiscountAmt    = (baseAmount - tradeDiscountAmt)
             *                      × (CD% / 100)
             * priceAfterDiscount = baseAmount
             *                      - tradeDiscountAmt
             *                      - cashDiscountAmt
             * cgstAmt            = priceAfterDiscount
             *                      × (CGST% / 100)
             * sgstAmt            = priceAfterDiscount
             *                      × (SGST% / 100)
             * finalPrice         = priceAfterDiscount
             *                      + cgstAmt + sgstAmt
             * ------------------------------------------------
             */
            List<Order_Line_Item__c> itemsToUpdate =
                new List<Order_Line_Item__c>();

            for (Order_Line_Item__c draftItem : draftItems) {

                /*
                 * Skip if current quantity is null or zero
                 */
                if (
                    draftItem.Quantity__c == null ||
                    draftItem.Quantity__c == 0
                ) {
                    System.debug(
                        'STEP 4 => Skipping draft item ' +
                        draftItem.Id +
                        ' — Quantity is null or zero'
                    );
                    continue;
                }

                String key =
                    draftItem.Ori_Plast_Product_Name__c +
                    '|' +
                    draftItem.Ori_Plast_Order__r.CreatedById;

                /*
                 * No matching partial record for this key
                 * Do not touch this draft line item
                 */
                if (!totalQtyMap.containsKey(key)) {
                    System.debug(
                        'STEP 4 => No partial match for key: ' +
                        key + ' — skipping: ' + draftItem.Id
                    );
                    continue;
                }

                Decimal calculatedQty =
                    totalQtyMap.get(key);

                /*
                 * Box quantity rounding logic
                 * Only applies if draft was box order
                 * Math.ceil ensures partial boxes
                 * round up to full box
                 * e.g. 1.23 boxes → 2 boxes
                 */
                Decimal newBoxQty = null;

                Decimal boxSize =
                    draftItem.Ori_Plast_Product__r != null
                    ? draftItem.Ori_Plast_Product__r
                          .No_of_Pcs_in_one_box__c
                    : null;

                if (
                    draftItem.Box_Order_Quantity__c != null &&
                    draftItem.Box_Order_Quantity__c > 0 &&
                    boxSize != null &&
                    boxSize > 0
                ) {
                    if (calculatedQty > 0) {

                        Decimal totalBoxes =
                            Math.ceil(calculatedQty / boxSize);

                        calculatedQty = totalBoxes * boxSize;
                        newBoxQty     = totalBoxes;

                        System.debug(
                            'STEP 4 => Box Calc => ' +
                            'BoxSize: ' + boxSize +
                            ' | TotalBoxes: ' + totalBoxes +
                            ' | NewQty: ' + calculatedQty
                        );

                    } else {
                        calculatedQty = 0;
                        newBoxQty     = 0;
                    }
                }

                /*
                 * Skip if quantity has not changed
                 * Avoids unnecessary DML
                 */
                if (draftItem.Quantity__c == calculatedQty) {
                    System.debug(
                        'STEP 4 => Quantity unchanged ' +
                        'for draft item: ' + draftItem.Id +
                        ' — skipping'
                    );
                    continue;
                }

                /*
                 * Read all rate fields safely
                 * Default to 0 if null
                 */
                Decimal unitPrice =
                    draftItem.OriPlast_Product_Unit_Price__c
                    == null
                    ? 0
                    : draftItem.OriPlast_Product_Unit_Price__c;

                Decimal lengthInMeter = 0;

                if (
                    draftItem.Ori_Plast_Product__r != null &&
                    String.isNotBlank(
                        draftItem.Ori_Plast_Product__r
                            .Length_In_Meter__c
                    )
                ) {
                    try {
                        lengthInMeter = Decimal.valueOf(
                            draftItem.Ori_Plast_Product__r
                                .Length_In_Meter__c
                        );
                    } catch (Exception e) {
                        System.debug(
                            'STEP 4 => Invalid Length for ' +
                            'draft product: ' +
                            draftItem.Ori_Plast_Product_Name__c +
                            ' — defaulting to 0'
                        );
                        lengthInMeter = 0;
                    }
                }

                /*
                 * ERP quantity for financial calculation
                 * MTR → multiply pieces by length in meter
                 * PCS → use calculated quantity directly
                 */
                Decimal erpQtyForCalculation = calculatedQty;

                if (
                    draftItem.Unit_of_Measure__c != null &&
                    draftItem.Unit_of_Measure__c.contains('MTR') &&
                    lengthInMeter > 0
                ) {
                    erpQtyForCalculation =
                        calculatedQty * lengthInMeter;
                }

                Decimal tradeDiscountPct =
                    draftItem.Trade_Discount__c == null
                    ? 0
                    : draftItem.Trade_Discount__c;

                Decimal cashDiscountPct =
                    draftItem.Cash_Discount_Percentage__c == null
                    ? 0
                    : draftItem.Cash_Discount_Percentage__c;

                Decimal cgstPct =
                    draftItem.CGST_Percentage__c == null
                    ? 0
                    : draftItem.CGST_Percentage__c;

                Decimal sgstPct =
                    draftItem.SGST_Percentage__c == null
                    ? 0
                    : draftItem.SGST_Percentage__c;

                /*
                 * Step 1 — Base Amount
                 */
                Decimal baseAmount =
                    erpQtyForCalculation * unitPrice;

                /*
                 * Step 2 — Trade Discount Amount
                 */
                Decimal tradeDiscountAmt =
                    (baseAmount * tradeDiscountPct) / 100;

                /*
                 * Step 3 — Cash Discount Amount
                 * Applied on amount after trade discount
                 */
                Decimal cashDiscountAmt =
                    (baseAmount - tradeDiscountAmt) *
                    (cashDiscountPct / 100);

                /*
                 * Step 4 — Price After Discount
                 */
                Decimal priceAfterDiscount =
                    baseAmount -
                    tradeDiscountAmt -
                    cashDiscountAmt;

                /*
                 * Step 5 — CGST Amount
                 */
                Decimal cgstAmt =
                    priceAfterDiscount * (cgstPct / 100);

                /*
                 * Step 6 — SGST Amount
                 */
                Decimal sgstAmt =
                    priceAfterDiscount * (sgstPct / 100);

                /*
                 * Step 7 — Final Price
                 */
                Decimal finalPrice =
                    priceAfterDiscount + cgstAmt + sgstAmt;

                System.debug(
                    'STEP 4 => Financial Calc for ' +
                    draftItem.Id +
                    ' | UnitPrice: ' + unitPrice +
                    ' | ErpQty: ' + erpQtyForCalculation +
                    ' | Base: ' + baseAmount +
                    ' | TD%: ' + tradeDiscountPct +
                    ' | TDAmt: ' + tradeDiscountAmt +
                    ' | CD%: ' + cashDiscountPct +
                    ' | CDAmt: ' + cashDiscountAmt +
                    ' | PAD: ' + priceAfterDiscount +
                    ' | CGST%: ' + cgstPct +
                    ' | CGSTAmt: ' + cgstAmt +
                    ' | SGST%: ' + sgstPct +
                    ' | SGSTAmt: ' + sgstAmt +
                    ' | Final: ' + finalPrice
                );

                Order_Line_Item__c updateItem =
                    new Order_Line_Item__c(
                        Id                      = draftItem.Id,
                        Quantity__c             = calculatedQty,
                        Trade_Discount_TD__c    = tradeDiscountAmt,
                        Cash_Discount_CD__c     = cashDiscountAmt,
                        Price_After_Discount__c = priceAfterDiscount,
                        CGST__c                 = cgstAmt,
                        SGST__c                 = sgstAmt,
                        Final_Price__c          = finalPrice
                    );

                if (newBoxQty != null) {
                    updateItem.Box_Order_Quantity__c = newBoxQty;
                }

                itemsToUpdate.add(updateItem);
            }

            /*
             * ------------------------------------------------
             * STEP 5
             * Bulk DML with partial success
             * Log each failure with record Id for tracing
             * ------------------------------------------------
             */
            if (!itemsToUpdate.isEmpty()) {

                System.debug(
                    'STEP 5 => Updating ' +
                    itemsToUpdate.size() +
                    ' draft line items'
                );

                Database.SaveResult[] results =
                    Database.update(
                        itemsToUpdate,
                        false,
                        AccessLevel.SYSTEM_MODE
                    );

                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err :
                             results[i].getErrors()) {
                            System.debug(
                                'STEP 5 => DML FAILURE => ' +
                                'RecordId: ' +
                                itemsToUpdate[i].Id +
                                ' | StatusCode: ' +
                                err.getStatusCode() +
                                ' | Message: ' +
                                err.getMessage() +
                                ' | Fields: ' +
                                err.getFields()
                            );
                        }
                    } else {
                        System.debug(
                            'STEP 5 => DML SUCCESS => ' +
                            'RecordId: ' +
                            itemsToUpdate[i].Id
                        );
                    }
                }

            } else {
                System.debug(
                    'STEP 5 => No items to update — ' +
                    'all quantities unchanged or ' +
                    'no matching draft items found'
                );
            }

        } catch (Exception e) {
            System.debug(
                'CRITICAL ERROR in syncDraftLines => ' +
                e.getMessage() +
                ' | Stack: ' +
                e.getStackTraceString()
            );
        }
    
    }
}