/*------------------------------------------------------------------------
    File        : demo/catastrophicBacktracking.p
    Purpose     : Catastrophic backtracking, and three ways out.
                  Not part of the talk - read, run, experiment.

    The task    : Does a statement consist of words and end with a period?

    The trap    : ^(?:[\w-]+\s*)+\.$
                  Looks harmless. But \s* may match NOTHING, so the
                  outer + can split a single word in any way it likes:
                  "abc" = "abc" | "ab"+"c" | "a"+"bc" | "a"+"b"+"c".
                  A word of n characters has 2^(n-1) splits. As long as
                  the period is there, the first try succeeds and nobody
                  notices. When it is missing, a backtracking engine
                  (.NET, Java/PDSOE, PCRE2) tries EVERY split before it
                  gives up: each extra character doubles the time.

    Way out 1   : Make the pattern unambiguous - every piece of text
                  can be matched in exactly one way.
                      ^[\w-]+(?:\s+[\w-]+)*\.$
                  The separator is mandatory (\s+), so a word can no
                  longer be cut into pieces. Fails in linear time.
                  Rule of thumb: never nest quantifiers ((x+)+, (x*)*)
                  unless something mandatory separates the repetitions.

    Way out 2   : Atomic group (?>...) - not covered in the talk.
                      ^(?:(?>[\w-]+)\s*)+\.$
                  Once [\w-]+ has taken a word, the engine never comes
                  back to give characters away. .NET, Java and PCRE2
                  know atomic groups; Java and PCRE2 also have the
                  possessive short form [\w-]++ (.NET does not).

    Safety net  : A match timeout. Regex(pattern, options, TimeSpan)
                  throws RegexMatchTimeoutException instead of hanging
                  the session. Use it whenever the pattern or the input
                  comes from outside.

    Not affected: The default engine of the VS Code Search view
                  (ripgrep) is not a backtracking engine and runs the
                  trap pattern in linear time. The VS Code Find widget
                  (JavaScript) is affected.

    Measured    : OpenEdge 12.8 batch, .NET Framework 4.8, 4 Nov 2026,
                  "run p" + name of n characters, no period:
                      n=16    25 ms     n=20   366 ms
                      n=18    89 ms     n=22  1572 ms
                      n=24  timeout after 2 s
                  The unambiguous and the atomic pattern: 0 ms throughout.

    See also    : src/demo/quantifier-demo.txt, section 3.
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable oTrap    as Regex     no-undo.
define variable oClear   as Regex     no-undo.
define variable oAtomic  as Regex     no-undo.
define variable cText    as character no-undo.
define variable cResult  as character no-undo.
define variable iLength  as integer   no-undo.

/* Times one IsMatch call, or reports the timeout */
function TimeMatch returns character (poRegex as Regex, pcText as character):

    define variable iStart  as int64     no-undo.
    define variable lMatch  as logical   no-undo.

    iStart = etime.

    lMatch = poRegex:IsMatch (pcText).

    return substitute ("&1 (&2 ms)":u, lMatch, etime - iStart).

    catch oTimeout as RegexMatchTimeoutException:
        return substitute ("TIMEOUT (&1 ms)":u, etime - iStart).
    end catch.
end function.

/* All three with a 2 second safety net */
assign
    oTrap   = new Regex ("^(?:[~\w-]+~\s*)+~\.$":u,
                         RegexOptions:None, System.TimeSpan:FromSeconds (2))
    oClear  = new Regex ("^[~\w-]+(?:~\s+[~\w-]+)*~\.$":u,
                         RegexOptions:None, System.TimeSpan:FromSeconds (2))
    oAtomic = new Regex ("^(?:(?>[~\w-]+)~\s*)+~\.$":u,
                         RegexOptions:None, System.TimeSpan:FromSeconds (2)).

/* With the period: all three answer at once */
cText = "define variable cCustomerName as character no-undo.":u.

cResult = substitute ("With period:~n  trap &1, clear &2, atomic &3~n~n":u,
                      TimeMatch (oTrap, cText), TimeMatch (oClear, cText), TimeMatch (oAtomic, cText)).

/* Without the period: the trap doubles its time with every character. Every
   word counts, so the full define statement above would already time out -
   a short RUN statement makes the doubling visible */
cResult = cResult + "Without period, ~"run p...~" with a name of n characters:~n":u.

do iLength = 16 to 28 by 2:
    cText = substitute ("run p&1":u, fill ("x":u, iLength - 1)).

    cResult = substitute ("&1  n=&2: trap &3, clear &4, atomic &5~n":u,
                          cResult, iLength,
                          TimeMatch (oTrap, cText), TimeMatch (oClear, cText), TimeMatch (oAtomic, cText)).
end.

message cResult
    view-as alert-box.
