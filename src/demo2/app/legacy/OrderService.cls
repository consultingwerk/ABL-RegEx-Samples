block-level on error undo, throw.

class demo2.app.legacy.OrderService:

    method public void PrintReport ():
        run demo2/app/legacy/orderReport.p.
    end method.

    method public demo2.app.legacy.PriceCalculator GetCalculator ():
        return new demo2.app.legacy.PriceCalculator ().
    end method.

end class.