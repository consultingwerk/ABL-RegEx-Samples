/*------------------------------------------------------------------------
    File        : scripts/run.p
    Purpose     : Starts a sample from the command line with src in the
                  PROPATH, so classes like demo3.EMailHelper are found.
                  VS Code and PDSOE set the PROPATH themselves.
    Usage       : from the repository root
                  _progres -b -p scripts/run.p -param src/demo3/checkEMail.p
                           -T temp -assemblies ./assemblies
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

propath = "src,":u + propath.

run value (session:parameter).
