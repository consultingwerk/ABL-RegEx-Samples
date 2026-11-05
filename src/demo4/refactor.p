block-level on error undo, throw.

@lowercase.

using Progress.Collections.*           from propath.
using Progress.Lang.*                  from propath.
using System.Text.RegularExpressions.* from assembly.

define variable cSourceDir             as character no-undo initial "src/demo4/classic":u.
define variable cTargetDir             as character no-undo initial "src/demo4/modern":u.
define variable lcCode                 as longchar  no-undo.
define variable cShortName             as character no-undo.
define variable cLongName              as character no-undo.
define variable cFileType              as character no-undo.
define variable oPublicVariable        as Regex     no-undo.
define variable oPackage               as Regex     no-undo.
define variable oCompound              as Regex     no-undo.
define variable iLines                 as integer   no-undo.
define variable iLine                  as integer   no-undo.
define variable cLine                  as character no-undo.
define variable oInitialDefineVariable as Regex     no-undo.
define variable oDefineVariable        as Regex     no-undo.

session:error-stack-trace = true.

{&_proparse_ prolint-nowarn(backslash)}
assign
    oPublicVariable = new Regex("
                    (?<=^~\s*)
                    define ~\s+
                    (
                          public
                        | (?<access>protected\s)
                     )
                    ~\s* variable
                    ~\s+ (?<name>[~\w-_]+)
                    ~\s+ as
                    ~\s+ (?<type>[~\w-_]+)
                    (?: ~\s+ no-undo)?
                    ~\.":u,
                     RegexOptions:Compiled
                     or RegexOptions:IgnorePatternWhitespace)
    oPackage = new Regex ("
                    \bclassic~\.(?<name>\w+)":u,
                    RegexOptions:Compiled
                    or RegexOptions:IgnorePatternWhitespace)
    oCompound = new Regex ("
                    (?<=^~\s*) (?<var>~\w+)~\s+=~\s+~\k<var>~\s+(?<op>[+~\-*?/])~\s":u,
                    RegexOptions:Compiled
                    or RegexOptions:IgnorePatternWhitespace)
    oInitialDefineVariable = new Regex ("
                    (?<=^~\s*) define ~\s+ variable ~\s+ (?<name>[~\w-_]+) ~\s+ as ~\s+ (?<type>[~\w-_]+) ~\s+ (?:no-undo)? ~\s+ initial ~\s+ (?<initial>.+?) ~\s* ~\.":u,
                    RegexOptions:Compiled
                    or RegexOptions:IgnorePatternWhitespace)
    oDefineVariable = new Regex ("
                    (?<=^~\s*) define ~\s+ variable ~\s+ (?<name>[~\w-_]+) ~\s+ as ~\s+ (?<type>[~\w-_]+) ~\s+ (?:no-undo)? ~\s* ~\.":u,
                    RegexOptions:Compiled
                    or RegexOptions:IgnorePatternWhitespace).

os-create-dir value (cTargetDir).

input from os-dir (cSourceDir).
repeat:
    import cShortName cLongName cFileType.

    if cFileType matches "*F*":u and cShortName <> ".":u and cShortName <> "..":u  and not cShortName matches "*.r":u then do:
        message "Processing " + cLongName.
        copy-lob from file cLongName to lcCode.

        iLines = num-entries (lcCode, "~n":u).
        do iLine = iLines to 1 by -1:
            assign
                cLine = entry (iLine, lcCode, "~n":u)
                cLine = oCompound:Replace (cLine, "$~{var~} $~{op~}= ":u)
                cLine = oPublicVariable:Replace (cLine, "define public property $~{name~} as $~{type~} no-undo ~n~tget.~n~t$~{access~}set.~n":u)
                cLine = oPackage:Replace (cLine, "modern.$~{name~}":u)
                cLine = oInitialDefineVariable:Replace (cLine, "var $~{type~} $~{name~} = $~{initial~}.":u)
                cLine = oDefineVariable:Replace (cLine, "var $~{type~} $~{name~}.":u)
                entry (iLine, lcCode, "~n":u) = cLine
                .
        end.

        copy-lob from lcCode to file substitute ("&1/&2":u, cTargetDir, cShortName).
    end.
end.

catch e as Progress.Lang.Error:
    message "Error: " e:getMessage(1) skip e:CallStack .
end catch.