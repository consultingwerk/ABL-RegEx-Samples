/*------------------------------------------------------------------------
    File        : samples/walkMatches.p
    Purpose     : Walking the Match object: Match -> NextMatch, reading a
                  named group. Lists the assembly names in
                  assemblies/assemblies.xml without the version suffix,
                  e.g. "Infragistics4.Documents.Core" from
                  name="Infragistics4.Documents.Core.v23.1, Version=...".
    Notes       : Run from the project root (relative file name).
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable lcContent as longchar  no-undo.
define variable oRegex    as Regex     no-undo.
define variable oMatch    as Match     no-undo.
define variable cResult   as character no-undo.
define variable iCount    as integer   no-undo.

copy-lob from file "assemblies/assemblies.xml":u to lcContent.

oRegex = new Regex ('
    (?<= name=" )         (?# must be preceded by name=" )
    (?<classname>         (?# named group, read by name below )
        (?:
            ~\w+ ~\d? ~\.
            (?! v~\d+ )   (?# only the dots that are not followed by a version number )
        )*
        ~\w+
    )':u,
    RegexOptions:IgnorePatternWhitespace).

oMatch = oRegex:Match (lcContent).

do while oMatch:Success:
    assign
        iCount  = iCount + 1
        cResult = substitute ("&1&2~n":u, cResult, oMatch:Groups:Item["classname":u]:Value)
        oMatch  = oMatch:NextMatch ().
end.

message substitute ("&1 assemblies:~n&2":u, iCount, cResult)
    view-as alert-box.
