/*------------------------------------------------------------------------
    File        : shop/CustomerManager.cls
    Purpose     : Live Demo 1 - "Customer" at the START of the name.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

class shop.CustomerManager:

    define private variable iCustomerCount as integer no-undo.
    def private var iRetryCount as int no-undo.

    define public property CustomerCount as integer no-undo
    get():
        return iCustomerCount.
    end get.

    method public void AddCustomer (poCustomer as shop.Customer):
        if valid-object (poCustomer) then
            iCustomerCount = iCustomerCount + 1.
        else
            iRetryCount = iRetryCount + 1.
    end method.

end class.
