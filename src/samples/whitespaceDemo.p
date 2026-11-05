/*------------------------------------------------------------------------
    File        : samples/whitespaceDemo.p
    Purpose     : How the .NET regex engine sees whitespace that comes
                  from ABL strings. Backup for questions, not shown.
                  1. "~t" puts a real TAB into the pattern, "~\t" the
                     regex escape \t - IgnorePatternWhitespace drops the
                     real TAB, but keeps \t.
                  2. A space with IgnorePatternWhitespace: "\ ", "[ ]",
                     "\x20" work, a plain space is ignored.
                  3. \s is Unicode in .NET: it also matches a
                     non-breaking space, [ ] and \x20 do not.
                  4. Line breaks: $ stops before \n, not before \r\n;
                     .NET has no \R.
                  5. Replacement strings do not know \n: use ~n in ABL.
    Notes       : Run from the project root, e.g.
                  _progres -b -p scripts/run.p -param src/samples/whitespaceDemo.p
                  Tested 5 Nov 2026 on OpenEdge 12.8: TAB match / no match /
                  match; space no match, then 3x match; non-breaking space
                  match / no match / no match; CR/LF no match / match /
                  match / ArgumentException (no \R in .NET); replace with
                  "\n" gives backslash + n, with ~n a real line feed.
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable cResult as character no-undo.
define variable cNbsp   as character no-undo.
define variable cOut    as character no-undo.

function Test returns character
    (pcLabel as character, pcPattern as character, pcInput as character, poOptions as RegexOptions):

    define variable lMatch as logical no-undo.

    lMatch = Regex:IsMatch (pcInput, pcPattern, poOptions).

    return substitute ("  &1: &2~n":u, pcLabel, string (lMatch, "match/no match":u)).

    catch oError as System.ArgumentException:
        return substitute ("  &1: ArgumentException - &2~n":u, pcLabel, oError:Message).
    end catch.

end function.

/* U+00A0 non-breaking space, created by .NET to avoid code page questions */
cNbsp = System.Char:ConvertFromUtf32 (160).

/* 1. ABL escape vs. regex escape */
cResult = "1. TAB: ABL ~~t vs. regex ~\t~n":u
        + Test ("~~t,  no options             ":u, "a~tb":u,  "a~tb":u, RegexOptions:None)
        + Test ("~~t,  IgnorePatternWhitespace":u, "a~tb":u,  "a~tb":u, RegexOptions:IgnorePatternWhitespace)
        + Test ("~\t,  IgnorePatternWhitespace":u, "a~\tb":u, "a~tb":u, RegexOptions:IgnorePatternWhitespace).

/* 2. matching a space while pattern whitespace is ignored */
cResult = cResult + "~n2. Space with IgnorePatternWhitespace~n":u
        + Test ("'a b'    ":u, "a b":u,      "a b":u, RegexOptions:IgnorePatternWhitespace)
        + Test ("'a~\ b'   ":u, "a~\ b":u,    "a b":u, RegexOptions:IgnorePatternWhitespace)
        + Test ("'a[ ]b'  ":u, "a[ ]b":u,    "a b":u, RegexOptions:IgnorePatternWhitespace)
        + Test ("'a~\x20b' ":u, "a~\x20b":u,  "a b":u, RegexOptions:IgnorePatternWhitespace).

/* 3. \s is Unicode: non-breaking space */
cResult = cResult + "~n3. Non-breaking space (U+00A0) between a and b~n":u
        + Test ("a~\sb  ":u, "a~\sb":u,   "a":u + cNbsp + "b":u, RegexOptions:None)
        + Test ("a[ ]b ":u, "a[ ]b":u,   "a":u + cNbsp + "b":u, RegexOptions:None)
        + Test ("a~\x20b":u, "a~\x20b":u, "a":u + cNbsp + "b":u, RegexOptions:None).

/* 4. line breaks: Windows CR/LF */
cResult = cResult + "~n4. Input 'first<CR><LF>second', Multiline~n":u
        + Test ("^first$            ":u, "^first$":u,                 "first~r~nsecond":u, RegexOptions:Multiline)
        + Test ("^first~\r?$         ":u, "^first~\r?$":u,             "first~r~nsecond":u, RegexOptions:Multiline)
        + Test ("first~\r?~\nsecond   ":u, "first~\r?~\nsecond":u,      "first~r~nsecond":u, RegexOptions:None)
        + Test ("first~\Rsecond (Java)":u, "first~\Rsecond":u,         "first~r~nsecond":u, RegexOptions:None).

/* 5. replacement strings: no \n, \t there */
cOut    = Regex:Replace ("a b":u, " ":u, "~\n":u).
cResult = cResult + "~n5. Replace ' ' in 'a b'~n":u
        + substitute ("  with '~\n': &1~n":u, cOut).
cOut    = Regex:Replace ("a b":u, " ":u, "~n":u).
cResult = cResult
        + substitute ("  with ABL ~~n: &1~n":u, replace (cOut, "~n":u, "<LF>":u)).

message cResult view-as alert-box.
