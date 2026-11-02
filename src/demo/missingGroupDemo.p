/*------------------------------------------------------------------------
    File        : demo/missingGroupDemo.p
    Purpose     : What does Groups:Item["name"] return when the group did
                  not take part in the match (other branch of an
                  alternation) or does not exist in the pattern at all?
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable oRegex  as Regex     no-undo.
define variable oMatch  as Match     no-undo.
define variable cInput  as character no-undo extent 2
    initial ["demo.VatHelper.cls":u, "demo/checkEMail.p":u].
define variable cGroups as character no-undo
    initial "classname,procname,nosuch":u.
define variable cResult as character no-undo.
define variable i       as integer   no-undo.
define variable j       as integer   no-undo.

/* classname only takes part in the first branch, procname only in the second */
oRegex = new Regex ("^(?:(?<classname>[~\w.]+)~\.cls|(?<procname>[~\w/]+)~\.p)$":u).

do i = 1 to extent (cInput):
    oMatch = oRegex:Match (cInput[i]).
    cResult = cResult + substitute ("&1  (match: &2)~n":u, cInput[i], oMatch:Success).

    do j = 1 to num-entries (cGroups):
        run showGroup (oMatch, entry (j, cGroups)).
    end.
    cResult = cResult + "~n":u.
end.

message cResult view-as alert-box.

procedure showGroup:
    define input parameter poMatch as Match     no-undo.
    define input parameter pcName  as character no-undo.

    define variable oGroup as Group no-undo.

    oGroup = poMatch:Groups:Item[pcName].

    cResult = cResult + substitute ("  &1: valid-object=&2 Success=&3 Value=&4 Value=?: &5 Index=&6 Length=&7~n":u,
                                    string (pcName, "x(9)":u),
                                    valid-object (oGroup),
                                    oGroup:Success,
                                    quoter (oGroup:Value),
                                    oGroup:Value = ?,
                                    oGroup:Index,
                                    oGroup:Length).
end procedure.
