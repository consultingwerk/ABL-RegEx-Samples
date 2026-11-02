/**
 * Purpose: Legacy inventory management class with old-style ABL patterns
 * Notes:   Contains many refactorable patterns for Regex demonstration
 */
block-level on error undo, throw.

class classic.InventoryManager:

    define public variable inv-product-id as integer no-undo.
    define public variable inv-product-name as character no-undo.
    define public variable inv-product-desc as character no-undo.
    define public variable inv-sku as character no-undo.
    define public variable inv-upc as character no-undo.
    define public variable inv-category as character no-undo.
    define public variable inv-subcategory as character no-undo.
    define public variable inv-brand as character no-undo.
    define public variable inv-supplier as character no-undo.
    define public variable inv-quantity-on-hand as integer no-undo.
    define public variable inv-quantity-reserved as integer no-undo.
    define public variable inv-quantity-available as integer no-undo.
    define public variable inv-reorder-point as integer no-undo.
    define public variable inv-reorder-quantity as integer no-undo.
    define public variable inv-unit-cost as decimal no-undo.
    define public variable inv-unit-price as decimal no-undo.
    define public variable inv-weight as decimal no-undo.
    define public variable inv-length as decimal no-undo.
    define public variable inv-width as decimal no-undo.
    define public variable inv-height as decimal no-undo.
    define public variable inv-location as character no-undo.
    define public variable inv-bin as character no-undo.
    define public variable inv-status as character no-undo.
    define public variable inv-last-received as date no-undo.
    define public variable inv-last-sold as date no-undo.
    define public variable inv-created as date no-undo.
    define public variable inv-modified as date no-undo.

    define private variable iTransactionCount as integer no-undo.
    define private variable dTotalValue as decimal no-undo.
    define private variable cLastError as character no-undo.

    define private temp-table ttInventoryTransaction no-undo
        field trans-id as integer
        field trans-date as datetime
        field trans-type as character
        field quantity as integer
        field reference as character
        field notes as character
        field user-id as character
        index idx-trans-id is primary unique trans-id
        index idx-trans-date trans-date
        index idx-trans-type trans-type.

    constructor public InventoryManager():
        assign
            inv-product-id = 0
            inv-product-name = ""
            inv-product-desc = ""
            inv-sku = ""
            inv-upc = ""
            inv-category = ""
            inv-subcategory = ""
            inv-brand = ""
            inv-supplier = ""
            inv-quantity-on-hand = 0
            inv-quantity-reserved = 0
            inv-quantity-available = 0
            inv-reorder-point = 0
            inv-reorder-quantity = 0
            inv-unit-cost = 0
            inv-unit-price = 0
            inv-weight = 0
            inv-length = 0
            inv-width = 0
            inv-height = 0
            inv-location = ""
            inv-bin = ""
            inv-status = "ACTIVE"
            inv-last-received = ?
            inv-last-sold = ?
            inv-created = today
            inv-modified = today.
    end constructor.

    method public logical ValidateProduct():
        define variable lok as logical no-undo.
        lok = true.

        if inv-product-id = 0 or inv-product-id = ? then
            lok = false.
        if inv-product-name = "" or inv-product-name = ? then
            lok = false.
        if inv-sku = "" or inv-sku = ? then
            lok = false.
        if inv-unit-cost < 0 then
            lok = false.
        if inv-unit-price < 0 then
            lok = false.
        if inv-quantity-on-hand < 0 then
            lok = false.
        if inv-reorder-point < 0 then
            lok = false.
        if inv-reorder-quantity < 0 then
            lok = false.

        return lok.
    end method.

    method public void ReceiveInventory(piQuantity as integer, pcReference as character):
        define variable iNextId as integer no-undo.

        if piQuantity <= 0 then return.

        for each ttInventoryTransaction no-lock:
            if ttInventoryTransaction.trans-id > iNextId then
                iNextId = ttInventoryTransaction.trans-id.
        end.
        iNextId = iNextId + 1.

        create ttInventoryTransaction.
        assign
            ttInventoryTransaction.trans-id = iNextId
            ttInventoryTransaction.trans-date = now
            ttInventoryTransaction.trans-type = "RECEIVE"
            ttInventoryTransaction.quantity = piQuantity
            ttInventoryTransaction.reference = pcReference
            ttInventoryTransaction.notes = ""
            ttInventoryTransaction.user-id = "".

        assign
            inv-quantity-on-hand = inv-quantity-on-hand + piQuantity
            inv-quantity-available = inv-quantity-on-hand - inv-quantity-reserved
            inv-last-received = today
            inv-modified = today.
    end method.

    method public logical ShipInventory(piQuantity as integer, pcReference as character):
        define variable iNextId as integer no-undo.
        define variable lSuccess as logical no-undo.

        if piQuantity <= 0 then return false.
        if piQuantity > inv-quantity-available then return false.

        for each ttInventoryTransaction no-lock:
            if ttInventoryTransaction.trans-id > iNextId then
                iNextId = ttInventoryTransaction.trans-id.
        end.
        iNextId = iNextId + 1.

        create ttInventoryTransaction.
        assign
            ttInventoryTransaction.trans-id = iNextId
            ttInventoryTransaction.trans-date = now
            ttInventoryTransaction.trans-type = "SHIP"
            ttInventoryTransaction.quantity = piQuantity * -1
            ttInventoryTransaction.reference = pcReference
            ttInventoryTransaction.notes = ""
            ttInventoryTransaction.user-id = "".

        assign
            inv-quantity-on-hand = inv-quantity-on-hand - piQuantity
            inv-quantity-available = inv-quantity-on-hand - inv-quantity-reserved
            inv-last-sold = today
            inv-modified = today
            lSuccess = true.

        return lSuccess.
    end method.

    method public logical ReserveInventory(piQuantity as integer, pcReference as character):
        define variable iNextId as integer no-undo.
        define variable lSuccess as logical no-undo.

        if piQuantity <= 0 then return false.
        if piQuantity > inv-quantity-available then return false.

        for each ttInventoryTransaction no-lock:
            if ttInventoryTransaction.trans-id > iNextId then
                iNextId = ttInventoryTransaction.trans-id.
        end.
        iNextId = iNextId + 1.

        create ttInventoryTransaction.
        assign
            ttInventoryTransaction.trans-id = iNextId
            ttInventoryTransaction.trans-date = now
            ttInventoryTransaction.trans-type = "RESERVE"
            ttInventoryTransaction.quantity = piQuantity
            ttInventoryTransaction.reference = pcReference
            ttInventoryTransaction.notes = ""
            ttInventoryTransaction.user-id = "".

        assign
            inv-quantity-reserved = inv-quantity-reserved + piQuantity
            inv-quantity-available = inv-quantity-on-hand - inv-quantity-reserved
            inv-modified = today
            lSuccess = true.

        return lSuccess.
    end method.

    method public void ReleaseReservation(piQuantity as integer, pcReference as character):
        define variable iNextId as integer no-undo.

        if piQuantity <= 0 then return.
        if piQuantity > inv-quantity-reserved then
            piQuantity = inv-quantity-reserved.

        for each ttInventoryTransaction no-lock:
            if ttInventoryTransaction.trans-id > iNextId then
                iNextId = ttInventoryTransaction.trans-id.
        end.
        iNextId = iNextId + 1.

        create ttInventoryTransaction.
        assign
            ttInventoryTransaction.trans-id = iNextId
            ttInventoryTransaction.trans-date = now
            ttInventoryTransaction.trans-type = "RELEASE"
            ttInventoryTransaction.quantity = piQuantity * -1
            ttInventoryTransaction.reference = pcReference
            ttInventoryTransaction.notes = ""
            ttInventoryTransaction.user-id = "".

        assign
            inv-quantity-reserved = inv-quantity-reserved - piQuantity
            inv-quantity-available = inv-quantity-on-hand - inv-quantity-reserved
            inv-modified = today.
    end method.

    method public void AdjustInventory(piQuantity as integer, pcReason as character):
        define variable iNextId as integer no-undo.

        for each ttInventoryTransaction no-lock:
            if ttInventoryTransaction.trans-id > iNextId then
                iNextId = ttInventoryTransaction.trans-id.
        end.
        iNextId = iNextId + 1.

        create ttInventoryTransaction.
        assign
            ttInventoryTransaction.trans-id = iNextId
            ttInventoryTransaction.trans-date = now
            ttInventoryTransaction.trans-type = "ADJUST"
            ttInventoryTransaction.quantity = piQuantity
            ttInventoryTransaction.reference = ""
            ttInventoryTransaction.notes = pcReason
            ttInventoryTransaction.user-id = "".

        assign
            inv-quantity-on-hand = inv-quantity-on-hand + piQuantity
            inv-quantity-available = inv-quantity-on-hand - inv-quantity-reserved
            inv-modified = today.

        if inv-quantity-on-hand < 0 then
            inv-quantity-on-hand = 0.
        if inv-quantity-available < 0 then
            inv-quantity-available = 0.
    end method.

    method public logical NeedsReorder():
        define variable lNeedsReorder as logical no-undo.
        if inv-quantity-available <= inv-reorder-point then
            lNeedsReorder = true.
        else
            lNeedsReorder = false.
        return lNeedsReorder.
    end method.

    method public decimal GetInventoryValue():
        define variable dValue as decimal no-undo.
        dValue = inv-quantity-on-hand * inv-unit-cost.
        return dValue.
    end method.

    method public decimal GetRetailValue():
        define variable dValue as decimal no-undo.
        dValue = inv-quantity-on-hand * inv-unit-price.
        return dValue.
    end method.

    method public decimal GetProfitMargin():
        define variable dMargin as decimal no-undo.
        if inv-unit-price > 0 then
            dMargin = ((inv-unit-price - inv-unit-cost) / inv-unit-price) * 100.
        else
            dMargin = 0.
        return dMargin.
    end method.

    method public decimal GetMarkup():
        define variable dMarkup as decimal no-undo.
        if inv-unit-cost > 0 then
            dMarkup = ((inv-unit-price - inv-unit-cost) / inv-unit-cost) * 100.
        else
            dMarkup = 0.
        return dMarkup.
    end method.

    method public void SetPricing(pdCost as decimal, pdPrice as decimal):
        if pdCost >= 0 and pdPrice >= 0 then do:
            assign
                inv-unit-cost = pdCost
                inv-unit-price = pdPrice
                inv-modified = today.
        end.
    end method.

    method public void SetReorderLevels(piPoint as integer, piQuantity as integer):
        if piPoint >= 0 and piQuantity >= 0 then do:
            assign
                inv-reorder-point = piPoint
                inv-reorder-quantity = piQuantity
                inv-modified = today.
        end.
    end method.

    method public void SetDimensions(pdWeight as decimal, pdLength as decimal, 
                                     pdWidth as decimal, pdHeight as decimal):
        if pdWeight >= 0 and pdLength >= 0 and pdWidth >= 0 and pdHeight >= 0 then do:
            assign
                inv-weight = pdWeight
                inv-length = pdLength
                inv-width = pdWidth
                inv-height = pdHeight
                inv-modified = today.
        end.
    end method.

    method public decimal GetVolume():
        define variable dVolume as decimal no-undo.
        dVolume = inv-length * inv-width * inv-height.
        return dVolume.
    end method.

    method public void SetLocation(pcLocation as character, pcBin as character):
        assign
            inv-location = pcLocation
            inv-bin = pcBin
            inv-modified = today.
    end method.

    method public void SetStatus(pcStatus as character):
        if pcStatus = "ACTIVE" or pcStatus = "INACTIVE" or pcStatus = "DISCONTINUED" or 
           pcStatus = "BACKORDERED" or pcStatus = "ONHOLD" then do:
            inv-status = pcStatus.
            inv-modified = today.
        end.
    end method.

    method public void SetCategory(pcCategory as character, pcSubcategory as character):
        assign
            inv-category = pcCategory
            inv-subcategory = pcSubcategory
            inv-modified = today.
    end method.

    method public integer GetTransactionCount():
        define variable iCount as integer no-undo.
        for each ttInventoryTransaction no-lock:
            iCount = iCount + 1.
        end.
        return iCount.
    end method.

    method public character GetProductSummary():
        define variable cSummary as character no-undo.
        cSummary = "Product ID: " + string(inv-product-id) + chr(10).
        cSummary = cSummary + "Name: " + inv-product-name + chr(10).
        cSummary = cSummary + "SKU: " + inv-sku + chr(10).
        cSummary = cSummary + "Category: " + inv-category + "/" + inv-subcategory + chr(10).
        cSummary = cSummary + "On Hand: " + string(inv-quantity-on-hand) + chr(10).
        cSummary = cSummary + "Reserved: " + string(inv-quantity-reserved) + chr(10).
        cSummary = cSummary + "Available: " + string(inv-quantity-available) + chr(10).
        cSummary = cSummary + "Cost: $" + string(inv-unit-cost, ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Price: $" + string(inv-unit-price, ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Value: $" + string(this-object:GetInventoryValue(), ">>>,>>9.99") + chr(10).
        cSummary = cSummary + "Location: " + inv-location + "/" + inv-bin + chr(10).
        cSummary = cSummary + "Status: " + inv-status.
        return cSummary.
    end method.

    method public void ClearTransactions():
        for each ttInventoryTransaction exclusive-lock:
            delete ttInventoryTransaction.
        end.
    end method.

    method public void Reset():
        this-object:ClearTransactions().

        assign
            inv-product-id = 0
            inv-product-name = ""
            inv-product-desc = ""
            inv-sku = ""
            inv-upc = ""
            inv-category = ""
            inv-subcategory = ""
            inv-brand = ""
            inv-supplier = ""
            inv-quantity-on-hand = 0
            inv-quantity-reserved = 0
            inv-quantity-available = 0
            inv-reorder-point = 0
            inv-reorder-quantity = 0
            inv-unit-cost = 0
            inv-unit-price = 0
            inv-weight = 0
            inv-length = 0
            inv-width = 0
            inv-height = 0
            inv-location = ""
            inv-bin = ""
            inv-status = "ACTIVE"
            inv-last-received = ?
            inv-last-sold = ?
            inv-created = today
            inv-modified = today.
    end method.

end class.
