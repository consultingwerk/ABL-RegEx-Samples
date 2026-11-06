/*------------------------------------------------------------------------
    File        : samples/balancedParentheses.p
    Purpose     : .NET balancing groups: a named group is a stack.
                  (?<Open>\()       push: every "(" adds a capture to Open
                  (?<-Open>\))      pop:  every ")" removes the last one,
                                    fails if Open is empty
                  (?<Inner-Open>\)) pop Open and store the text between
                                    the "(" and the ")" in Inner
                  (?(Open)(?!))     at the end: Open must be empty,
                                    (?!) is a lookahead that always fails
                  1. Is the whole text balanced?
                  2. Find calls with nested parentheses in ABL code.
                  3. Inner: every bracketed part, in the order the ")"
                     are found, so inner parts come before outer ones.
                  4. Limit: one stack per bracket type counts correctly
                     but does not check the order, a[(1]) passes.
                  5. Mixed brackets with order: remove innermost pairs
                     in a loop (plain regex, works in every engine).
    Notes       : Run from the project root, e.g.
                  _progres -b -p scripts/run.p -param src/samples/balancedParentheses.p
                  .NET only: Java, JavaScript and ripgrep do not have
                  balancing groups (PCRE2 solves it with recursion (?R)).
                  Source: https://learn.microsoft.com/dotnet/standard/base-types/grouping-constructs-in-regular-expressions#balancing-group-definitions
                  Parentheses inside string literals or comments are
                  counted too: regex sees characters, not ABL syntax.
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable cBalanced as character no-undo.
define variable cCall     as character no-undo.
define variable cInner    as character no-undo.
define variable cTwoKinds as character no-undo.
define variable cCode     as character no-undo.
define variable cResult   as character no-undo.
define variable cTest     as character no-undo extent 7 initial
    ["a (b) c":u, "f(g(h(1)), 2)":u, "()":u, "no brackets":u, "(a))(":u, "f(g(1)":u, ")(":u].
define variable i         as integer   no-undo.
define variable oMatch    as Match     no-undo.
define variable oGroup    as Group     no-undo.

function BalancedMixed returns logical (pcText as character) forward.

/* 1. The whole text is balanced: push on "(", pop on ")", stack empty at the end */
{&_proparse_ prolint-nowarn(backslash)}
cBalanced = "
    ^
    (?:
          [^()]          (?# any other character )
        | (?<Open>~\()   (?# push )
        | (?<-Open>~\))  (?# pop, fails if nothing is open )
    )*
    (?(Open)(?!))        (?# something is still open: fail )
    $
    ":u.

cResult = "1. Balanced?~n":u.
do i = 1 to extent (cTest):
    cResult = cResult + substitute ("   &1 &2~n":u,
                                    string (Regex:IsMatch (cTest[i], cBalanced, RegexOptions:IgnorePatternWhitespace), "yes/no ":u),
                                    cTest[i]).
end.

/* 2. A call with its complete argument list, however deep the nesting */
{&_proparse_ prolint-nowarn(backslash)}
cCall = "
    ~\b(?<name>substitute|can-find)~\s*
    ~\(
    (?<args>
        (?>                       (?# atomic: no backtracking into the loop )
              [^()]+
            | ~\( (?<Depth>)      (?# push an empty capture, only the count matters )
            | ~\) (?<-Depth>)     (?# pop )
        )*
        (?(Depth)(?!))
    )
    ~\)
    ":u.

cCode = "cMsg = substitute (~"&1 (&2)~":u, trim (cName), string (iCount)).~n":u
      + "if can-find (first Customer where Customer.CustNum = integer (entry (1, cKey))) then~n":u
      + "    cLabel = substitute (~"&1~":u, upper (substring (cName, 1, 1))).":u.

cResult = cResult + "~n2. Calls with nested parentheses~n":u.
oMatch  = Regex:Match (cCode, cCall, RegexOptions:IgnorePatternWhitespace or RegexOptions:IgnoreCase).
do while oMatch:Success:
    cResult = cResult + substitute ("   &1: &2~n":u, oMatch:Groups["name":u]:Value, oMatch:Groups["args":u]:Value).
    oMatch  = oMatch:NextMatch ().
end.

/* 3. (?<Inner-Open>~\)) pops Open and captures the text in between */
{&_proparse_ prolint-nowarn(backslash)}
cInner = "
    ^
    (?:
          [^()]
        | (?<Open>~\()
        | (?<Inner-Open>~\))
    )*
    (?(Open)(?!))
    $
    ":u.

cResult = cResult + "~n3. Captures of Inner for f(g(h(1)), k(2))~n":u.
oMatch  = Regex:Match ("f(g(h(1)), k(2))":u, cInner, RegexOptions:IgnorePatternWhitespace).
oGroup  = oMatch:Groups["Inner":u].
do i = 0 to oGroup:Captures:Count - 1:
    cResult = cResult + substitute ("   &1~n":u, oGroup:Captures[i]:Value).
end.

/* 4. Two kinds of brackets with one stack each: counts are right, order is not checked */
{&_proparse_ prolint-nowarn(backslash)}
cTwoKinds = "
    ^
    (?:
          [^()~\[~\]]
        | (?<Paren>~\() | (?<-Paren>~\))
        | (?<Square>~\[) | (?<-Square>~\])
    )*
    (?(Paren)(?!))
    (?(Square)(?!))
    $
    ":u.

cResult = cResult + "~n4. One stack per bracket type~n":u
        + substitute ("   &1 a[(1)]~n":u, string (Regex:IsMatch ("a[(1)]":u, cTwoKinds, RegexOptions:IgnorePatternWhitespace), "yes/no ":u))
        + substitute ("   &1 a[(1])   <- wrong order, still accepted~n":u, string (Regex:IsMatch ("a[(1])":u, cTwoKinds, RegexOptions:IgnorePatternWhitespace), "yes/no ":u)).

/* 5. Mixed brackets, order checked: remove innermost pairs until nothing changes */
cResult = cResult + "~n5. Remove innermost pairs in a loop~n":u
        + substitute ("   &1 a[(1)]~n":u, string (BalancedMixed ("a[(1)]":u), "yes/no ":u))
        + substitute ("   &1 a[(1])~n":u, string (BalancedMixed ("a[(1])":u), "yes/no ":u))
        + substitute ("   &1 x[f(y[1], z(2))]~n":u, string (BalancedMixed ("x[f(y[1], z(2))]":u), "yes/no ":u)).

message cResult view-as alert-box.

function BalancedMixed returns logical (pcText as character):
    define variable oPair as Regex     no-undo.
    define variable cLast as character no-undo.

    /* only the brackets matter, then an empty pair is () or [] */
    pcText = Regex:Replace (pcText, "[^()~\[~\]]":u, "":u).
    oPair  = new Regex ("~\(~\)|~\[~\]":u).

    do while pcText <> cLast:
        assign cLast  = pcText
               pcText = oPair:Replace (pcText, "":u).
    end.

    return pcText = "":u.
end function.
