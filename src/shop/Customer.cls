/*------------------------------------------------------------------------
    File        : shop/Customer.cls
    Purpose     : Live Demo 1 - one of several classes with similar names.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

class shop.Customer:

    define public property CustNum as integer   no-undo get. set.
    define public property Name    as character no-undo get. set.

    constructor public Customer (piCustNum as integer, pcName as character):
        assign CustNum = piCustNum
               Name    = pcName.
    end constructor.

end class.
