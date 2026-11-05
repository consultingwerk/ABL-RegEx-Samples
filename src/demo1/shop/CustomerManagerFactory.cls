/*------------------------------------------------------------------------
    File        : demo1/shop/CustomerManagerFactory.cls
    Purpose     : Live Demo 1 - "Manager" in the MIDDLE of the name.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

class demo1.shop.CustomerManagerFactory:

    method public static demo1.shop.CustomerManager GetManager ():
        return new demo1.shop.CustomerManager ().
    end method.

end class.
