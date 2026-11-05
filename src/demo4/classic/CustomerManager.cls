/**
 * Purpose: Legacy customer management class with old-style ABL patterns
 * Notes:   Contains many refactorable patterns for Regex demonstration
 */
block-level on error undo, throw.

class demo4.classic.CustomerManager:

    define public variable cust-name as character no-undo.
    define public variable cust-address as character no-undo.
    define public variable cust-city as character no-undo.
    define public variable cust-state as character no-undo.
    define public variable cust-zip as character no-undo.
    define public variable cust-country as character no-undo.
    define public variable cust-phone as character no-undo.
    define public variable cust-email as character no-undo.
    define public variable cust-balance as decimal no-undo.
    define public variable cust-credit-limit as decimal no-undo.
    define public variable cust-status as character no-undo.
    define public variable cust-type as character no-undo.
    define public variable cust-created as date no-undo.
    define public variable cust-modified as date no-undo.
    define public variable cust-notes as character no-undo.
    define public variable cust-region as character no-undo.
    define public variable cust-sales-rep as character no-undo.
    define public variable cust-discount as decimal no-undo.
    define public variable cust-terms as character no-undo.
    define public variable cust-ship-via as character no-undo.

    define protected variable testVar as character no-undo.

    define private variable iCounter as integer no-undo.
    define private variable cTempValue as character no-undo.
    define private variable lSuccess as logical no-undo.
    define private variable dAmount as decimal no-undo.
    define private variable dtDate as date no-undo.

    constructor public CustomerManager():
        assign
            cust-name = ""
            cust-address = ""
            cust-city = ""
            cust-state = ""
            cust-zip = ""
            cust-country = ""
            cust-phone = ""
            cust-email = ""
            cust-balance = 0
            cust-credit-limit = 0
            cust-status = "ACTIVE"
            cust-type = "STANDARD"
            cust-created = today
            cust-modified = today
            cust-notes = ""
            cust-region = ""
            cust-sales-rep = ""
            cust-discount = 0
            cust-terms = "NET30"
            cust-ship-via = "GROUND".
    end constructor.

    method public logical ValidateCustomer():
        define variable lok as logical no-undo.
        lok = true.

        if cust-name = "" or cust-name = ? then
            lok = false.
        if cust-address = "" or cust-address = ? then
            lok = false.
        if cust-city = "" or cust-city = ? then
            lok = false.
        if cust-state = "" or cust-state = ? then
            lok = false.
        if cust-zip = "" or cust-zip = ? then
            lok = false.
        if cust-email = "" or cust-email = ? then
            lok = false.
        if cust-phone = "" or cust-phone = ? then
            lok = false.
        if cust-balance < 0 then
            lok = false.
        if cust-credit-limit < 0 then
            lok = false.
        if cust-discount < 0 or cust-discount > 100 then
            lok = false.

        return lok.
    end method.

    method public character GetFullAddress():
        define variable cResult as character no-undo.
        define variable cSecondVar as character no-undo initial "test".
        cResult = cust-address + ", " + cust-city + ", " + cust-state + " " + cust-zip.
        if cust-country <> "" and cust-country <> ? then
            cResult = cResult + ", " + cust-country.
        return cResult.
    end method.

    method public void UpdateBalance(pdAmount as decimal):
        cust-balance = cust-balance + pdAmount.
        cust-modified = today.
    end method.

    method public void SetCreditLimit(pdLimit as decimal):
        if pdLimit >= 0 then do:
            cust-credit-limit = pdLimit.
            cust-modified = today.
        end.
    end method.

    method public logical IsOverCreditLimit():
        define variable lOver as logical no-undo.
        if cust-balance > cust-credit-limit then
            lOver = true.
        else
            lOver = false.
        return lOver.
    end method.

    method public void ApplyDiscount(pdPercent as decimal):
        if pdPercent >= 0 and pdPercent <= 100 then do:
            cust-discount = pdPercent.
            cust-modified = today.
        end.
    end method.

    method public decimal CalculateDiscountedAmount(pdAmount as decimal):
        define variable dDiscounted as decimal no-undo.
        dDiscounted = pdAmount - (pdAmount * cust-discount / 100).
        return dDiscounted.
    end method.

    method public void SetStatus(pcStatus as character):
        if pcStatus = "ACTIVE" or pcStatus = "INACTIVE" or pcStatus = "SUSPENDED" or pcStatus = "CLOSED" then do:
            cust-status = pcStatus.
            cust-modified = today.
        end.
    end method.

    method public void SetType(pcType as character):
        if pcType = "STANDARD" or pcType = "PREMIUM" or pcType = "VIP" or pcType = "WHOLESALE" then do:
            cust-type = pcType.
            cust-modified = today.
        end.
    end method.

    method public void AssignSalesRep(pcRep as character):
        cust-sales-rep = pcRep.
        cust-modified = today.
    end method.

    method public void AssignRegion(pcRegion as character):
        cust-region = pcRegion.
        cust-modified = today.
    end method.

    method public void SetShippingMethod(pcMethod as character):
        if pcMethod = "GROUND" or pcMethod = "EXPRESS" or pcMethod = "OVERNIGHT" or pcMethod = "FREIGHT" then do:
            cust-ship-via = pcMethod.
            cust-modified = today.
        end.
    end method.

    method public void SetPaymentTerms(pcTerms as character):
        if pcTerms = "NET30" or pcTerms = "NET60" or pcTerms = "NET90" or pcTerms = "COD" or pcTerms = "PREPAID" then do:
            cust-terms = pcTerms.
            cust-modified = today.
        end.
    end method.

    method public void AddNote(pcNote as character):
        if cust-notes = "" or cust-notes = ? then
            cust-notes = pcNote.
        else
            cust-notes = cust-notes + chr(10) + pcNote.
        cust-modified = today.
    end method.

    method public void ClearNotes():
        cust-notes = "".
        cust-modified = today.
    end method.

    method public integer GetDaysSinceCreated():
        define variable iDays as integer no-undo.
        iDays = today - cust-created.
        return iDays.
    end method.

    method public integer GetDaysSinceModified():
        define variable iDays as integer no-undo.
        iDays = today - cust-modified.
        return iDays.
    end method.

    method public character GetCustomerSummary():
        define variable cSummary as character no-undo.
        cSummary = "Customer: " + cust-name + chr(10).
        cSummary = cSummary + "Address: " + this-object:GetFullAddress() + chr(10).
        cSummary = cSummary + "Phone: " + cust-phone + chr(10).
        cSummary = cSummary + "Email: " + cust-email + chr(10).
        cSummary = cSummary + "Status: " + cust-status + chr(10).
        cSummary = cSummary + "Type: " + cust-type + chr(10).
        cSummary = cSummary + "Balance: " + string(cust-balance) + chr(10).
        cSummary = cSummary + "Credit Limit: " + string(cust-credit-limit) + chr(10).
        cSummary = cSummary + "Discount: " + string(cust-discount) + "%" + chr(10).
        cSummary = cSummary + "Sales Rep: " + cust-sales-rep + chr(10).
        cSummary = cSummary + "Region: " + cust-region.
        return cSummary.
    end method.

    method public void CopyFrom(poSource as demo4.classic.CustomerManager):
        assign
            cust-name = poSource:cust-name
            cust-address = poSource:cust-address
            cust-city = poSource:cust-city
            cust-state = poSource:cust-state
            cust-zip = poSource:cust-zip
            cust-country = poSource:cust-country
            cust-phone = poSource:cust-phone
            cust-email = poSource:cust-email
            cust-balance = poSource:cust-balance
            cust-credit-limit = poSource:cust-credit-limit
            cust-status = poSource:cust-status
            cust-type = poSource:cust-type
            cust-created = poSource:cust-created
            cust-modified = today
            cust-notes = poSource:cust-notes
            cust-region = poSource:cust-region
            cust-sales-rep = poSource:cust-sales-rep
            cust-discount = poSource:cust-discount
            cust-terms = poSource:cust-terms
            cust-ship-via = poSource:cust-ship-via.
    end method.

    method public void Reset():
        assign
            cust-name = ""
            cust-address = ""
            cust-city = ""
            cust-state = ""
            cust-zip = ""
            cust-country = ""
            cust-phone = ""
            cust-email = ""
            cust-balance = 0
            cust-credit-limit = 0
            cust-status = "ACTIVE"
            cust-type = "STANDARD"
            cust-created = today
            cust-modified = today
            cust-notes = ""
            cust-region = ""
            cust-sales-rep = ""
            cust-discount = 0
            cust-terms = "NET30"
            cust-ship-via = "GROUND".
    end method.

end class.
