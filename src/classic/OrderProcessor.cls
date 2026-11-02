/**
 * Purpose: Legacy order processing class with old-style ABL patterns
 * Notes:   Contains many refactorable patterns for Regex demonstration
 */
block-level on error undo, throw.

class classic.OrderProcessor:

    define public variable order-number         as integer   no-undo.
    define public variable order-date           as date      no-undo.
    define public variable order-status         as character no-undo.
    define public variable order-total          as decimal   no-undo.
    define public variable order-tax            as decimal   no-undo.
    define public variable order-shipping       as decimal   no-undo.
    define public variable order-discount       as decimal   no-undo.
    define public variable order-subtotal       as decimal   no-undo.
    define public variable order-customer-id    as integer   no-undo.
define public variable order-ship-date      as date      no-undo.
define public variable order-ship-method    as character no-undo.
define public variable order-ship-address   as character no-undo.
define public variable order-ship-city      as character .
define public variable order-ship-state     as character no-undo.
    define public variable order-ship-zip       as character .
    define public variable order-ship-country   as character no-undo.
    define public variable order-bill-address   as character no-undo.
    define public variable order-bill-city      as character no-undo.
        define public variable order-bill-state     as character .
        define public variable order-bill-zip       as character no-undo.
        define public variable order-bill-country   as character no-undo.
        define public variable order-notes          as character no-undo.
    define public variable order-priority       as character no-undo.
    define public variable order-source         as character no-undo.
    define public variable order-payment-method as character no-undo.
    define public variable order-payment-status as character no-undo.

    define private variable iLineCount as integer no-undo.
    define private variable dLineTotal as decimal no-undo.
    define private variable cErrorMessage as character no-undo.
    define private variable lProcessed as logical no-undo.

    define private temp-table ttOrderLine no-undo
        field line-number as integer
        field product-id as integer
        field product-name as character
        field quantity as integer
        field unit-price as decimal
        field line-total as decimal
        field discount-percent as decimal
        field tax-rate as decimal
        field notes as character
        index idx-line-number is primary unique line-number
        index idx-product-id product-id.

    constructor public OrderProcessor():
        assign
            order-number = 0
            order-date = today
            order-status = "NEW"
            order-total = 0
            order-tax = 0
            order-shipping = 0
            order-discount = 0
            order-subtotal = 0
            order-customer-id = 0
            order-ship-date = ?
            order-ship-method = "GROUND"
            order-ship-address = ""
            order-ship-city = ""
            order-ship-state = ""
            order-ship-zip = ""
            order-ship-country = ""
            order-bill-address = ""
            order-bill-city = ""
            order-bill-state = ""
            order-bill-zip = ""
            order-bill-country = ""
            order-notes = ""
            order-priority = "NORMAL"
            order-source = "WEB"
            order-payment-method = "CREDIT"
            order-payment-status = "PENDING".
    end constructor.

    method public logical ValidateOrder():
        define variable lok as logical no-undo.
        lok = true.

        if order-number = 0 or order-number = ? then
            lok = false.
        if order-customer-id = 0 or order-customer-id = ? then
            lok = false.
        if order-date = ? then
            lok = false.
        if order-status = "" or order-status = ? then
            lok = false.
        if order-ship-address = "" or order-ship-address = ? then
            lok = false.
        if order-ship-city = "" or order-ship-city = ? then
            lok = false.
        if order-ship-state = "" or order-ship-state = ? then
            lok = false.
        if order-ship-zip = "" or order-ship-zip = ? then
            lok = false.
        if order-total < 0 then
            lok = false.
        if order-tax < 0 then
            lok = false.
        if order-shipping < 0 then
            lok = false.

        return lok.
    end method.

    method public void AddOrderLine(piProductId as integer, pcProductName as character,
                                    piQuantity as integer, pdUnitPrice as decimal):
        define variable iNextLine as integer no-undo.

        for each ttOrderLine no-lock:
            if ttOrderLine.line-number > iNextLine then
                iNextLine = ttOrderLine.line-number.
        end.
        iNextLine = iNextLine + 1.

        create ttOrderLine.
        assign
            ttOrderLine.line-number = iNextLine
            ttOrderLine.product-id = piProductId
            ttOrderLine.product-name = pcProductName
            ttOrderLine.quantity = piQuantity
            ttOrderLine.unit-price = pdUnitPrice
            ttOrderLine.line-total = piQuantity * pdUnitPrice
            ttOrderLine.discount-percent = 0
            ttOrderLine.tax-rate = 0
            ttOrderLine.notes = "".

        this-object:RecalculateTotals().
    end method.

    method public void RemoveOrderLine(piLineNumber as integer):
        find first ttOrderLine where ttOrderLine.line-number = piLineNumber exclusive-lock no-error.
        if available ttOrderLine then do:
            delete ttOrderLine.
            this-object:RecalculateTotals().
        end.
    end method.

    method public void UpdateLineQuantity(piLineNumber as integer, piNewQuantity as integer):
        find first ttOrderLine where ttOrderLine.line-number = piLineNumber exclusive-lock no-error.
        if available ttOrderLine then do:
            assign
                ttOrderLine.quantity = piNewQuantity
                ttOrderLine.line-total = piNewQuantity * ttOrderLine.unit-price.
            this-object:RecalculateTotals().
        end.
    end method.

    method public void ApplyLineDiscount(piLineNumber as integer, pdDiscountPercent as decimal):
        find first ttOrderLine where ttOrderLine.line-number = piLineNumber exclusive-lock no-error.
        if available ttOrderLine then do:
            assign
                ttOrderLine.discount-percent = pdDiscountPercent
                ttOrderLine.line-total = ttOrderLine.quantity * ttOrderLine.unit-price *
                                         (1 - pdDiscountPercent / 100).
            this-object:RecalculateTotals().
        end.
    end method.

    method public void SetLineTaxRate(piLineNumber as integer, pdTaxRate as decimal):
        find first ttOrderLine where ttOrderLine.line-number = piLineNumber exclusive-lock no-error.
        if available ttOrderLine then do:
            ttOrderLine.tax-rate = pdTaxRate.
            this-object:RecalculateTotals().
        end.
    end method.

    method private void RecalculateTotals():
        define variable dSubtotal as decimal no-undo.
        define variable dTax as decimal no-undo.

        dSubtotal = 0.
        dTax = 0.

        for each ttOrderLine no-lock:
            dSubtotal = dSubtotal + ttOrderLine.line-total.
            dTax = dTax + (ttOrderLine.line-total * ttOrderLine.tax-rate / 100).
        end.

        assign
            order-subtotal = dSubtotal
            order-tax = dTax
            order-total = dSubtotal + dTax + order-shipping - order-discount.
    end method.

    method public integer GetLineCount():
        define variable iCount as integer no-undo.
        for each ttOrderLine no-lock:
            iCount = iCount + 1.
        end.
        return iCount.
    end method.

    method public decimal GetLineTotal(piLineNumber as integer):
        find first ttOrderLine where ttOrderLine.line-number = piLineNumber no-lock no-error.
        if available ttOrderLine then
            return ttOrderLine.line-total.
        else
            return 0.
    end method.

    method public void SetShippingCost(pdShipping as decimal):
        if pdShipping >= 0 then do:
            order-shipping = pdShipping.
            this-object:RecalculateTotals().
        end.
    end method.

    method public void ApplyOrderDiscount(pdDiscount as decimal):
        if pdDiscount >= 0 then do:
            order-discount = pdDiscount.
            this-object:RecalculateTotals().
        end.
    end method.

    method public void SetStatus(pcStatus as character):
        if pcStatus = "NEW" or pcStatus = "PROCESSING" or pcStatus = "SHIPPED" or
           pcStatus = "DELIVERED" or pcStatus = "CANCELLED" or pcStatus = "RETURNED" then do:
            order-status = pcStatus.
        end.
    end method.

    method public void SetPriority(pcPriority as character):
        if pcPriority = "LOW" or pcPriority = "NORMAL" or pcPriority = "HIGH" or pcPriority = "URGENT" then do:
            order-priority = pcPriority.
        end.
    end method.

    method public void SetPaymentMethod(pcMethod as character):
        if pcMethod = "CREDIT" or pcMethod = "DEBIT" or pcMethod = "PAYPAL" or
           pcMethod = "CHECK" or pcMethod = "WIRE" or pcMethod = "COD" then do:
            order-payment-method = pcMethod.
        end.
    end method.

    method public void SetPaymentStatus(pcStatus as character):
        if pcStatus = "PENDING" or pcStatus = "AUTHORIZED" or pcStatus = "CAPTURED" or
           pcStatus = "REFUNDED" or pcStatus = "FAILED" then do:
            order-payment-status = pcStatus.
        end.
    end method.

    method public void SetShippingAddress(pcAddress as character, pcCity as character,
                                          pcState as character, pcZip as character,
                                          pcCountry as character):
        assign
            order-ship-address = pcAddress
            order-ship-city = pcCity
            order-ship-state = pcState
            order-ship-zip = pcZip
            order-ship-country = pcCountry.
    end method.

    method public void SetBillingAddress(pcAddress as character, pcCity as character,
                                         pcState as character, pcZip as character,
                                         pcCountry as character):
        assign
            order-bill-address = pcAddress
            order-bill-city = pcCity
            order-bill-state = pcState
            order-bill-zip = pcZip
            order-bill-country = pcCountry.
    end method.

    method public void CopyShippingToBilling():
        assign
            order-bill-address = order-ship-address
            order-bill-city = order-ship-city
            order-bill-state = order-ship-state
            order-bill-zip = order-ship-zip
            order-bill-country = order-ship-country.
    end method.

    method public character GetShippingAddress():
        define variable cResult as character no-undo.
        cResult = order-ship-address + ", " + order-ship-city + ", " +
                  order-ship-state + " " + order-ship-zip.
        if order-ship-country <> "" and order-ship-country <> ? then
            cResult = cResult + ", " + order-ship-country.
        return cResult.
    end method.

    method public character GetBillingAddress():
        define variable cResult as character no-undo.
        cResult = order-bill-address + ", " + order-bill-city + ", " +
                  order-bill-state + " " + order-bill-zip.
        if order-bill-country <> "" and order-bill-country <> ? then
            cResult = cResult + ", " + order-bill-country.
        return cResult.
    end method.

    method public void AddNote(pcNote as character):
        if order-notes = "" or order-notes = ? then
            order-notes = pcNote.
        else
            order-notes = order-notes + chr(10) + pcNote.
    end method.

    method public void ClearNotes():
        order-notes = "".
    end method.

    method public void SetShipDate(pdDate as date):
        order-ship-date = pdDate.
    end method.

    method public void SetShipMethod(pcMethod as character):
        if pcMethod = "GROUND" or pcMethod = "EXPRESS" or pcMethod = "OVERNIGHT" or
           pcMethod = "FREIGHT" or pcMethod = "PICKUP" then do:
            order-ship-method = pcMethod.
        end.
    end method.

    method public logical IsShipped():
        define variable lShipped as logical no-undo.
        if order-status = "SHIPPED" or order-status = "DELIVERED" then
            lShipped = true.
        else
            lShipped = false.
        return lShipped.
    end method.

    method public logical IsPaid():
        define variable lPaid as logical no-undo.
        if order-payment-status = "CAPTURED" then
            lPaid = true.
        else
            lPaid = false.
        return lPaid.
    end method.

    method public logical CanCancel():
        define variable lCanCancel as logical no-undo.
        if order-status = "NEW" or order-status = "PROCESSING" then
            lCanCancel = true.
        else
            lCanCancel = false.
        return lCanCancel.
    end method.

    method public void CancelOrder():
        if this-object:CanCancel() then do:
            order-status = "CANCELLED".
        end.
    end method.

    method public character GetOrderSummary():
        define variable cSummary as character no-undo.
        cSummary = "Order #: " + string(order-number) + chr(10).
        cSummary = cSummary + "Date: " + string(order-date) + chr(10).
        cSummary = cSummary + "Status: " + order-status + chr(10).
        cSummary = cSummary + "Customer ID: " + string(order-customer-id) + chr(10).
        cSummary = cSummary + "Subtotal: $" + string(order-subtotal, ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Tax: $" + string(order-tax, ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Shipping: $" + string(order-shipping, ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Discount: $" + string(order-discount, ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Total: $" + string(order-total, ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Lines: " + string(this-object:GetLineCount()) + chr(10).
        cSummary = cSummary + "Ship To: " + this-object:GetShippingAddress().
        return cSummary.
    end method.

    method public void ClearOrder():
        for each ttOrderLine exclusive-lock:
            delete ttOrderLine.
        end.

        assign
            order-number = 0
            order-date = today
            order-status = "NEW"
            order-total = 0
            order-tax = 0
            order-shipping = 0
            order-discount = 0
            order-subtotal = 0
            order-customer-id = 0
            order-ship-date = ?
            order-ship-method = "GROUND"
            order-ship-address = ""
            order-ship-city = ""
            order-ship-state = ""
            order-ship-zip = ""
            order-ship-country = ""
            order-bill-address = ""
            order-bill-city = ""
            order-bill-state = ""
            order-bill-zip = ""
            order-bill-country = ""
            order-notes = ""
            order-priority = "NORMAL"
            order-source = "WEB"
            order-payment-method = "CREDIT"
            order-payment-status = "PENDING".
    end method.

end class.
