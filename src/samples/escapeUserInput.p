/*------------------------------------------------------------------------
    File        : samples/escapeUserInput.p
    Purpose     : User input that goes into a pattern or a replacement
                  must be escaped first.
                  1. Pattern: Regex:Escape turns metacharacters into
                     literals; without it "." and "( )" are regex syntax.
                  2. Unbalanced input like "price (EUR" even throws.
                  3. \Q...\E (Java, PCRE) does not exist in .NET.
                  4. Replacement: "$" must be doubled, otherwise "$1" in
                     the user text inserts a group.
    Notes       : Run from the project root, e.g.
                  _progres -b -p scripts/run.p -param src/samples/escapeUserInput.p
                  ABL escaping (~\, ~{) only applies to literals in the
                  source: a value typed by the user never passes the compiler.
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable cText    as character no-undo.
define variable cInput   as character no-undo.
define variable cEscaped as character no-undo.
define variable cResult  as character no-undo.

function FirstHit returns character (pcPattern as character, pcInput as character):
    define variable oMatch as Match no-undo.

    oMatch = Regex:Match (pcInput, pcPattern).
    return (if oMatch:Success then substitute ("~"&1~" at index &2":u, oMatch:Value, oMatch:Index)
                              else "no match":u).

    catch oError as System.ArgumentException:
        return "ArgumentException: ":u + oError:Message.
    end catch.
end function.

cText = "Fields: cust-name old, cust.name (old)":u.

/* 1. user input as a pattern */
cInput   = "cust.name (old)":u.
cEscaped = Regex:Escape (cInput).
cResult  = substitute ("Text:  &1~n~n1. User input &2~n":u, cText, cInput)
         + "   as typed:          ":u + FirstHit (cInput, cText) + "~n":u
         + "   Regex:Escape:      ":u + cEscaped + "~n":u
         + "   escaped:           ":u + FirstHit (cEscaped, cText) + "~n":u
         + "   Regex:Unescape:    ":u + Regex:Unescape (cEscaped) + "~n":u
         + "   escaped + IgnorePatternWhitespace: ":u
         + string (Regex:IsMatch (cText, cEscaped, RegexOptions:IgnorePatternWhitespace), "match/no match":u) + "~n":u.

/* 2. unbalanced input */
cInput  = "price (EUR":u.
cResult = cResult + substitute ("~n2. User input &1~n":u, cInput)
        + "   as typed:          ":u + FirstHit (cInput, "price (EUR) 10":u) + "~n":u
        + "   escaped:           ":u + FirstHit (Regex:Escape (cInput), "price (EUR) 10":u) + "~n":u.

/* 3. \Q...\E is Java/PCRE syntax */
cResult = cResult + "~n3. ~\Q...~\E in .NET~n":u
        + "   ~\Qcust.name~\E:     ":u + FirstHit ("~\Qcust.name~\E":u, cText) + "~n":u.

/* 4. user input as a replacement */
cInput  = "costs $1":u.
cResult = cResult + substitute ("~n4. Replace the number in ~"price: 10~" with the user text &1~n":u, cInput)
        + "   as typed:          ":u + Regex:Replace ("price: 10":u, "(~\d+)":u, cInput) + "~n":u
        + "   $ doubled:         ":u + Regex:Replace ("price: 10":u, "(~\d+)":u, replace (cInput, "$":u, "$$":u)) + "~n":u.

message cResult view-as alert-box.
