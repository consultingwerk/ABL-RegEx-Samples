/*------------------------------------------------------------------------
    File        : shop/CustomerManagerFactory.cls
    Purpose     : Live Demo 1 - "Manager" in the MIDDLE of the name.
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

class shop.CustomerManagerFactory:

    method public static shop.CustomerManager GetManager ():
        return new shop.CustomerManager ().
    end method.

end class.
