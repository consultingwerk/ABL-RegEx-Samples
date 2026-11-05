/*------------------------------------------------------------------------
    File        : samples/anchorModes.p
    Purpose     : Multiline moves the anchors, Singleline moves the dot.
                  Runs four patterns against "first~nsecond~nthird" with
                  no option, Multiline, Singleline and both, then shows
                  the two classic traps: $ accepts a final line break
                  (use \z), and $ stops before \n, not before \r\n.
    Notes       : Run from the project root, e.g.
                  _progres -b -p scripts/run.p -param src/samples/anchorModes.p
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable cText    as character    no-undo.
define variable cResult  as character    no-undo.
define variable cPattern as character    no-undo extent 4.
define variable cLabel   as character    no-undo extent 4
    initial ["none":u, "Multiline":u, "Singleline":u, "both":u].
define variable oOptions as RegexOptions no-undo extent 4.
define variable i        as integer      no-undo.
define variable j        as integer      no-undo.

function Hit returns character (pcPattern as character, pcInput as character, poOptions as RegexOptions):
    return string (Regex:IsMatch (pcInput, pcPattern, poOptions), "yes/no":u).
end function.

assign
    cText       = "first~nsecond~nthird":u
    cPattern[1] = "^second$":u
    cPattern[2] = "first.second":u
    cPattern[3] = "^second.third":u
    cPattern[4] = "~\Asecond":u
    oOptions[1] = RegexOptions:None
    oOptions[2] = RegexOptions:Multiline
    oOptions[3] = RegexOptions:Singleline
    oOptions[4] = RegexOptions:Multiline or RegexOptions:Singleline.

cResult = "Input: first\nsecond\nthird~n~n":u
        + string ("Pattern":u, "x(16)":u) + " none Multiline Singleline both~n":u.

do i = 1 to extent (cPattern):
    cResult = cResult + string (cPattern[i], "x(16)":u).
    do j = 1 to extent (oOptions):
        cResult = cResult + " ":u + string (Hit (cPattern[i], cText, oOptions[j]),
                                            substitute ("x(&1)":u, length (cLabel[j]))).
    end.
    cResult = cResult + "~n":u.
end.

cResult = cResult + "~nInput: first\nsecond\nthird\n (final line break)~n":u
        + "  third$    ":u + Hit ("third$":u,    cText + "~n":u, RegexOptions:None) + "~n":u
        + "  third~\Z   ":u + Hit ("third~\Z":u, cText + "~n":u, RegexOptions:None) + "~n":u
        + "  third~\z   ":u + Hit ("third~\z":u, cText + "~n":u, RegexOptions:None) + "~n":u.

cResult = cResult + "~nInput: first\r\nsecond\r\nthird (Windows line breaks), Multiline~n":u
        + "  ^second$     ":u + Hit ("^second$":u,      replace (cText, "~n":u, "~r~n":u), RegexOptions:Multiline) + "~n":u
        + "  ^second~\r?$  ":u + Hit ("^second~\r?$":u, replace (cText, "~n":u, "~r~n":u), RegexOptions:Multiline) + "~n":u.

message cResult view-as alert-box.
