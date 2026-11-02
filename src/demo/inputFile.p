/*------------------------------------------------------------------------
    File        : demo/inputFile.p
    Purpose     : Regex input variant 3 - a whole file, read by .NET.
                  System.IO.File:ReadAllText returns a System.String. Kept
                  in a System.Object variable it never becomes an ABL
                  LONGCHAR. Regex:Match is called via reflection, because
                  a direct call would convert the text to ABL and back:
                      oRegex:Match (System.IO.File:ReadAllText (cFile))
    Notes       : Run from the project root (relative file name).
                  Measured with a 100 MB file on OpenEdge 12.8:
                  nested ReadAllText call ~860 ms, this variant ~730 ms,
                  copy-lob + Match(LONGCHAR) ~820 ms plus ~100 ms
                  conversion on every further call.
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable oText   as System.Object                no-undo.
define variable oRegex  as Regex                        no-undo.
define variable oTypes  as "System.Type[]"              no-undo.
define variable oArgs   as "System.Object[]"            no-undo.
define variable oMethod as System.Reflection.MethodInfo no-undo.
define variable oMatch  as Match                        no-undo.
define variable cResult as character                    no-undo.

oRegex = new Regex ("define~\s+(?:(?:private|protected|public)~\s+)?(?:static~\s+)?variable~\s+(?<name>[~\w-]+)":u,
                    RegexOptions:IgnoreCase).

/* the text stays a System.String on the .NET side */
oText = System.IO.File:ReadAllText (System.IO.Path:GetFullPath ("src/demo/EMailHelper.cls":u)).

/* Regex.Match(System.String) */
oTypes = new "System.Type[]" (1).
oTypes:SetValue (Progress.Util.TypeHelper:GetType ("System.String":u), 0).
oMethod = oRegex:GetType ():GetMethod ("Match":u, oTypes).

oArgs = new "System.Object[]" (1).
oArgs:SetValue (oText, 0).

oMatch = cast (oMethod:Invoke (oRegex, oArgs), Match).

/* from here on the Match object works as usual */
do while oMatch:Success:
    cResult = cResult + oMatch:Groups:Item["name":u]:Value + "~n":u.
    oMatch  = oMatch:NextMatch ().
end.

message substitute ("Variables in EMailHelper.cls:~n&1":u, cResult)
    view-as alert-box.
