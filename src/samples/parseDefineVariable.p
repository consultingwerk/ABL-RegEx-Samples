/*------------------------------------------------------------------------
    File        : samples/parseDefineVariable.p
    Purpose     : The two versions from the slide "Which One Would You
                  Rather Maintain?" - both parse
                      define [public|protected|private] variable <name> as <type> [no-undo].
                  and return name and type.
                  parseRegexMinified / parseAblMinified: as on the slide.
                  parseRegexFormatted / parseAblFormatted: as on "Treat a
                  Regex Like Source Code" (the slide shortens the ABL).
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable cTests  as character no-undo extent 7
    initial ["define variable cName as character no-undo.":u,
             "DEF VAR iCount AS INTEGER.":u,
             "define   private   variable   cust-name   as   character   no-undo  .":u,
             "define protected variable oRegex as System.Text.RegularExpressions.Regex no-undo.":u,
             "define variable cName as character no-undo":u,
             "define temp-table ttCustomer no-undo.":u,
             "define.":u].
define variable cResult as character no-undo.
define variable cName   as character no-undo.
define variable cType   as character no-undo.
define variable i       as integer   no-undo.

do i = 1 to extent (cTests):
    cResult = cResult + cTests[i] + "~n":u.

    run parseRegexMinified (cTests[i], output cName, output cType).
    cResult = cResult + substitute ("  regex minified  : &1 / &2~n":u, cName, cType).

    run parseRegexFormatted (cTests[i], output cName, output cType).
    cResult = cResult + substitute ("  regex formatted : &1 / &2~n":u, cName, cType).

    /* the minified ABL has no guard against too few words */
    do on error undo, leave:
        run parseAblMinified (cTests[i], output cName, output cType).
        cResult = cResult + substitute ("  ABL minified    : &1 / &2~n":u, cName, cType).

        catch oError as Progress.Lang.Error:
            cResult = cResult + substitute ("  ABL minified    : ERROR &1~n":u, oError:GetMessage (1)).
        end catch.
    end.

    run parseAblFormatted (cTests[i], output cName, output cType).
    cResult = cResult + substitute ("  ABL formatted   : &1 / &2~n~n":u, cName, cType).
end.

message cResult. // view-as alert-box.

procedure parseRegexMinified:
    define input  parameter p as character no-undo.
    define output parameter n as character no-undo.
    define output parameter t as character no-undo.

    define variable m as Match no-undo.

    m = Regex:Match (p, "^~\s*def(?:ine)?~\s+(?:(?:public|protected|private)~\s+)?var(?:iable)?~\s+([~\w-]+)~\s+as~\s+([~\w.]+)(?:~\s+no-undo)?~\s*~\.~\s*$":u,
                     RegexOptions:IgnoreCase).
    if m:Success then
        assign n = m:Groups:Item[1]:Value
               t = m:Groups:Item[2]:Value.
end procedure.

procedure parseRegexFormatted:
    define input  parameter pcStmt as character no-undo.
    define output parameter pcName      as character no-undo.
    define output parameter pcType      as character no-undo.

    define variable oMatch as Match no-undo.

    oMatch = Regex:Match (pcStmt, "
        ^ ~\s*
        def(?:ine)? ~\s+    (?# def|define )
        (?: (?:public
             | protected
             | private
            ) ~\s+
        )?                  (?# access )
        var(?:iable)? ~\s+  (?# var|variable )
        (?<name> [~\w-]+ )  (?# may contain - )
        ~\s+ as ~\s+
        (?<type> [~\w.]+ )  (?# qualified )
        (?: ~\s+ no-undo )?
        ~\s* ~\. ~\s* $
        ":u, RegexOptions:IgnoreCase or RegexOptions:IgnorePatternWhitespace).

    if oMatch:Success then
        assign pcName = oMatch:Groups:Item["name":u]:Value
               pcType = oMatch:Groups:Item["type":u]:Value.
end procedure.

procedure parseAblMinified:
    def input  param p as c no-undo.
    def output param n as c no-undo.
    def output param t as c no-undo.

    def var c as c no-undo.
    def var i as i no-undo.

c=trim(replace(p,"~t"," ")).
do while index(c,"  ")>0: c=replace(c,"  "," "). end.
if substr(c,length(c))<>"." then return.
c=right-trim(substr(c,1,length(c) - 1)).
if lookup(entry(1,c," "),"def,define")=0 then return.
i=2. if lookup(entry(i,c," "),"public,protected,private")
>0 then i=i + 1. if lookup(entry(i,c," "),"var,variable")
=0 or entry(i + 2,c," ")<>"as" then return.
n=entry(i + 1,c," "). t=entry(i + 3,c," ").
end procedure.

procedure parseAblFormatted:
    define input  parameter pcStmt as character no-undo.
    define output parameter pcName      as character no-undo.
    define output parameter pcType      as character no-undo.

    define variable cStmt as character no-undo.
    define variable iPos  as integer   no-undo.

    /* one space between all words */
    cStmt = trim(replace(pcStmt, "~t":u, " ":u)).
    do while index(cStmt, "  ":u) > 0:
        cStmt = replace(cStmt, "  ":u, " ":u).
    end.
    /* must end with a period */
    if substring(cStmt, length(cStmt)) <> ".":u
        then return.
    cStmt = right-trim(cStmt, " .":u).
    if lookup(entry(1, cStmt, " ":u),
              "def,define":u) = 0 then return.
    /* optional access modifier */
    iPos = 2 + (if lookup(entry(2, cStmt, " ":u),
      "public,protected,private":u) > 0
      then 1 else 0).
    /* var | variable <name> as <type> */
    if num-entries(cStmt, " ":u) < iPos + 3
        then return.
    if lookup(entry(iPos, cStmt, " ":u),
              "var,variable":u) = 0
        then return.
    if entry(iPos + 2, cStmt, " ":u) <> "as":u
        then return.
    assign
        pcName = entry(iPos + 1, cStmt, " ":u)
        pcType = entry(iPos + 3, cStmt, " ":u).

    /* "define." or "define x." - not enough words for entry() */
    catch oError as Progress.Lang.Error:
        assign pcName = "":u
               pcType = "":u.
    end catch.
end procedure.
