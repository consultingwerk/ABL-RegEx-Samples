/*------------------------------------------------------------------------
    File        : demo1/shop/orderEntry.p
    Purpose     : Live Demo 1 - inconsistent formatting on purpose:
                  abbreviations, upper case, extra spaces.
  ----------------------------------------------------------------------*/
using demo1.shop.*.

DEF VAR oManager AS CustomerManager NO-UNDO.
define   variable   oLookup as OrderCustomerLookup no-undo.
define variable iOrderCount as integer no-undo.
DEFINE VARIABLE iCustomerNum AS INTEGER NO-UNDO.

oManager = CustomerManagerFactory:GetManager().

oManager:AddCustomer(new Customer(1, "Nordwind Sport")).
oManager:AddCustomer(NEW    LegacyCustomer (2, "Nordwind Outlet")).

oLookup = new OrderCustomerLookup ().
do iCustomerNum = 3 to 5:
    oManager:AddCustomer(oLookup:FindCustomer(iCustomerNum)).
    iOrderCount = iOrderCount + 1.
end.

message "Customers:" oManager:CustomerCount "Orders:" iOrderCount
    view-as alert-box.
