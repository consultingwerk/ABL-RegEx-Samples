/*------------------------------------------------------------------------
    File        : demo/inputLongchar.p
    Purpose     : Regex input variant 2 - a LONGCHAR value.
                  ABL reads the file, the LONGCHAR is converted to a
                  System.String on EVERY call of a Regex method. Fine for
                  normal source files, costly for very large values.
    Notes       : Run from the project root (relative file name).
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable lcText  as longchar  no-undo.
define variable oRegex  as Regex     no-undo.
define variable oMatch  as Match     no-undo.
define variable cResult as character no-undo.

copy-lob from file "src/demo/EMailHelper.cls":u to lcText.

oRegex = new Regex ("define~\s+(?:(?:private|protected|public)~\s+)?(?:static~\s+)?variable~\s+(?<name>[~\w-]+)":u,
                    RegexOptions:IgnoreCase).

oMatch = oRegex:Match (lcText).

do while oMatch:Success:
    cResult = cResult + oMatch:Groups:Item["name":u]:Value + "~n":u.
    oMatch  = oMatch:NextMatch ().
end.

message substitute ("Variables in EMailHelper.cls:~n&1":u, cResult)
    view-as alert-box.
