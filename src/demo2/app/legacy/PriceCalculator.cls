block-level on error undo, throw.

class demo2.app.legacy.PriceCalculator:

    {demo2/app/legacy/priceRules.i}

    method public decimal GrossPrice (pdNet as decimal):
        return pdNet * (1 + {&VAT_RATE}).
    end method.

end class.