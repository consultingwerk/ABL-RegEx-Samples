/*------------------------------------------------------------------------
    File        : shop/LegacyCustomer.cls
    Purpose     : Live Demo 1 - "Customer" at the END of the name.
                  Old-style formatting on purpose.
  ----------------------------------------------------------------------*/
BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS shop.LegacyCustomer INHERITS shop.Customer:

    DEFINE PUBLIC PROPERTY LegacyCode AS CHARACTER NO-UNDO GET. SET.

    CONSTRUCTOR PUBLIC LegacyCustomer (piCustNum AS INTEGER, pcName AS CHARACTER):
        SUPER (piCustNum, pcName).
        LegacyCode = "L-" + STRING (piCustNum).
    END CONSTRUCTOR.

END CLASS.
