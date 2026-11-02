block-level on error undo, throw.

class app.legacy.OrderService:

    method public void PrintReport ():
        run app/legacy/orderReport.p.
    end method.

    method public app.legacy.PriceCalculator GetCalculator ():
        return new app.legacy.PriceCalculator ().
    end method.

end class.