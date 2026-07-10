/**
 description=Returns total actual remaining quantity from all Partially Delivered line items
 *
 * Actual Qty Logic:
 *   - No shipped qty          → actualQty = Quantity__c
 *   - Shipped + MTR unit      → actualQty = Remaining_Quantity__c / Length_In_Meter__c
 *   - Shipped + non-MTR unit  → actualQty = Remaining_Quantity__c
 *
 * @author     Pratik Mondal
 */
public with sharing class GetHighestRemainingQty {

    // ─────────────────────────────────────────────
    // INPUT
    // ─────────────────────────────────────────────
    public class Request {

        @InvocableVariable(
            label='Pending Line Items'
            description='Collection of Order_Line_Item__c records passed from Flow'
            required=true
        )
        public List<Order_Line_Item__c> pendingLineItems;
    }

    // ─────────────────────────────────────────────
    // OUTPUT
    // ─────────────────────────────────────────────
    public class Response {

        @InvocableVariable(label='Order Id')
        public String orderId;

        @InvocableVariable(label='Product Name')
        public String productName;

        @InvocableVariable(label='Highest Remaining Quantity')
        public Decimal highestQuantity;

        @InvocableVariable(label='Order Line Item Number')
        public String orderLineItemNo;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    // ─────────────────────────────────────────────
    // INVOCABLE METHOD
    // ─────────────────────────────────────────────
    @InvocableMethod(
        label='Get Highest Remaining Quantity'
        description='Returns the Partially Delivered line item with the highest actual remaining quantity'
        category='Order Management'
    )
    public static List<Response> getHighestQty(List<Request> requests) {

        List<Response> responseList = new List<Response>();

        for (Request req : requests) {

            Response res = new Response();

            try {

                //  skip empty requests ──────────────────
                if (req == null || req.pendingLineItems == null || req.pendingLineItems.isEmpty()) {
                    res.errorMessage = 'No line items provided in request.';
                    responseList.add(res);
                    continue;
                }

                // ── Collect IDs from Flow collection ────────────
                Set<Id> lineItemIds = new Set<Id>();
                for (Order_Line_Item__c itm : req.pendingLineItems) {
                    if (itm.Id != null) {
                        lineItemIds.add(itm.Id);
                    }
                }

                if (lineItemIds.isEmpty()) {
                    res.errorMessage = 'None of the provided line items have a valid Id.';
                    responseList.add(res);
                    continue;
                }

                // ── Re-query to get formula & relationship fields ─
               
                List<Order_Line_Item__c> lineItems = [
                    SELECT  Id,
                            Name,
                            Quantity__c,
                            Remaining_Quantity__c,
                            Shipped_Quantity__c,
                            Unit_of_Measure__c,
                            Status__c,
                            Ori_Plast_Product_Name__c,
                            Ori_Plast_Order__r.Order_No__c,
                            Ori_Plast_Order__r.Name,
                            Ori_Plast_Product__r.Length_In_Meter__c
                    FROM    Order_Line_Item__c
                    WHERE   Id IN :lineItemIds
                    AND    (Ori_Plast_Order__r.Order_Status__c = 'Partially Delivered'
                            OR
                            Ori_Plast_Order__r.Order_Status__c = 'Received by Navision')
                   
                ];

                // ── Find highest actual remaining quantity ────────
                // Decimal maxQty = -1;

                // for (Order_Line_Item__c item : lineItems) {

                //     // Only process Partially Delivered items
                //     if (item.Status__c != 'Partially Delivered'
                //         || item.Remaining_Quantity__c == null) {
                //         continue;
                //     }

                //     Decimal actualQty     = 0;
                //     Decimal shippedQty    = (item.Shipped_Quantity__c != null)
                //                             ? item.Shipped_Quantity__c
                //                             : 0;
                //     Decimal remainingQty  = item.Remaining_Quantity__c;
                //     Decimal lengthInMeter = 0;

                //     // Safely read Length_In_Meter__c (Text field on Product)
                //     if (item.Ori_Plast_Product__r != null
                //         && String.isNotBlank(item.Ori_Plast_Product__r.Length_In_Meter__c)) {

                //         try {
                //             lengthInMeter = Decimal.valueOf(
                //                 item.Ori_Plast_Product__r.Length_In_Meter__c
                //             );
                //         } catch (TypeException te) {
                //             // Non-numeric value — treat as zero, no division
                //             lengthInMeter = 0;
                //         }
                //     }

                //     /*
                //      * ACTUAL QTY LOGIC
                //      *
                //      * Case 1 – Nothing shipped yet
                //      *          → use the full ordered Quantity__c
                //      *
                //      * Case 2 – Partially shipped & MTR unit
                //      *          → Remaining_Quantity__c is in metres (raw length)
                //      *             divide by Length_In_Meter__c to get piece count
                //      *
                //      * Case 3 – Partially shipped & non-MTR unit
                //      *          → Remaining_Quantity__c is already in the correct unit
                //      */
                //     if (shippedQty <= 0) {

                //         // Case 1
                //         actualQty = (item.Quantity__c != null) ? item.Quantity__c : 0;

                //     } else if (item.Unit_of_Measure__c != null
                //                && item.Unit_of_Measure__c.toUpperCase().contains('MTR')
                //                && lengthInMeter > 0) {

                //         // Case 2
                //         actualQty = remainingQty / lengthInMeter;

                //     } else {

                //         // Case 3
                //         actualQty = remainingQty;
                //     }

                //     // ── Track the winner ─────────────────────────
                //     if (actualQty > maxQty) {

                //         maxQty = actualQty;

                //         res.orderId         = item.Ori_Plast_Order__r?.Name;
                //         res.productName     = item.Ori_Plast_Product_Name__c;
                //         res.highestQuantity = actualQty;
                //         res.orderLineItemNo = item.Name;
                //     }
                // }


// ── Find total actual remaining quantity ────────
Decimal totalQty = 0;

for (Order_Line_Item__c item : lineItems) {

    // Only process Partially Delivered items
    /* if (item.Status__c != 'Partially Delivered'
        || item.Remaining_Quantity__c == null) {
        continue;
    }*/
    
if (item.Remaining_Quantity__c == null) {
    continue;
}
//if (item.Status__c != null && item.Status__c != 'Partially Delivered') {
  //  continue;
//}

    if (String.isNotBlank(item.Status__c) && item.Status__c != 'Partially Delivered') {
    continue;
}

    Decimal actualQty     = 0;
    Decimal shippedQty    = (item.Shipped_Quantity__c != null)
                            ? item.Shipped_Quantity__c
                            : 0;
    Decimal remainingQty  = item.Remaining_Quantity__c;
    Decimal lengthInMeter = 0;

    // Safely read Length_In_Meter__c
    if (item.Ori_Plast_Product__r != null
        && String.isNotBlank(item.Ori_Plast_Product__r.Length_In_Meter__c)) {

        try {

            lengthInMeter = Decimal.valueOf(
                item.Ori_Plast_Product__r.Length_In_Meter__c
            );

        } catch (TypeException te) {

            lengthInMeter = 0;
        }
    }

    /*
     * ACTUAL QTY LOGIC
     */


// Case 1 → No shipped qty
if (shippedQty <= 0) {

    actualQty =
        (item.Quantity__c != null)
        ? item.Quantity__c
        : 0;


// Case 2 → MTR product
} else if (
    item.Unit_of_Measure__c != null &&
    item.Unit_of_Measure__c.contains('MTR') &&
    lengthInMeter > 0
) {

    actualQty =
        remainingQty / lengthInMeter;

// Case 3 → Non-MTR product
} else {

    actualQty = remainingQty;
}



    // ── SUM quantity ─────────────────────────
    totalQty += actualQty;

    // Optional informational values
    res.orderId         = item.Ori_Plast_Order__r?.Name;
    res.productName     = item.Ori_Plast_Product_Name__c;
    res.orderLineItemNo = item.Name;
}

// Final summed quantity
res.highestQuantity = totalQty;
            }

          


            catch (Exception ex) {

                res.errorMessage = 'Error in GetHighestRemainingQty: '
                                 + ex.getMessage()
                                 + ' | Line: ' + ex.getLineNumber();
            }

            responseList.add(res);
        }

        return responseList;
    }
}