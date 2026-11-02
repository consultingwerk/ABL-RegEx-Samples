/*------------------------------------------------------------------------
    File        : demo/inputCharacter.p
    Purpose     : Regex input variant 1 - a CHARACTER value.
                  Like a LONGCHAR, the value is converted to a new
                  System.String on every .NET call - cheap, because a
                  CHARACTER is never more than about 32 KB.
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable cText    as character       no-undo
    initial "Order 4711 shipped on 2026-11-06, order 4712 on 2026-11-09.":u.
define variable oMatches as MatchCollection no-undo.
define variable cResult  as character       no-undo.
define variable i        as integer         no-undo.

/* ISO dates: \d{4}-\d{2}-\d{2} - braces and backslashes escaped for ABL */
oMatches = Regex:Matches (cText, "~\d~{4~}-~\d~{2~}-~\d~{2~}":u).

do i = 0 to oMatches:Count - 1:
    cResult = cResult + oMatches:Item[i]:Value + "~n":u.
end.

message substitute ("&1 dates found:~n&2":u, oMatches:Count, cResult)
    view-as alert-box.
