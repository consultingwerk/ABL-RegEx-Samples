/*------------------------------------------------------------------------
    File        : shop/OrderCustomerLookup.cls
    Purpose     : Live Demo 1 - "Customer" INSIDE the name.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using shop.*.

class shop.OrderCustomerLookup:

    define   private   variable   iLookupCount   as   integer   no-undo.

    method public Customer FindCustomer (piCustNum as integer):
        iLookupCount = iLookupCount + 1.
        return NEW Customer( piCustNum, "Customer " + string (piCustNum)).
    end method.

end class.
