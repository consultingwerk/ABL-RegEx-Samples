/*------------------------------------------------------------------------
    File        : demo/inputPerformance.p
    Purpose     : Measures the claims of the slide "CHARACTER, LONGCHAR
                  or a Whole File": every .NET call converts an ABL value
                  into a new System.String.
                  1. CHARACTER: converted on every call, but small - cheap
                  2. LONGCHAR:  converted on every call - grows with the text
                  3. Nested ReadAllText: converted to ABL and back
                  4. ReadAllText into a System.Object, Match via
                     reflection: no conversion at all
    Notes       : Run from the project root. The first run writes a test
                  file of about 100 MB into the session temp directory
                  (-T), later runs reuse it.
                  The pattern matches at the very first character, so the
                  regex itself costs nothing: the times are the conversion.
  ----------------------------------------------------------------------*/
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

@lowercase.

define variable iLines   as integer   no-undo initial 1200000. /* about 100 MB */
define variable iCalls   as integer   no-undo initial 5.       /* repeated calls per variant */

define variable cFile    as character                    no-undo.
define variable cLine    as character                    no-undo.
define variable cShort   as character                    no-undo.
define variable lcText   as longchar                     no-undo.
define variable oText    as System.Object                no-undo.
define variable oRegex   as Regex                        no-undo.
define variable oMatch   as Match                        no-undo.
define variable oTypes   as "System.Type[]"              no-undo.
define variable oArgs    as "System.Object[]"            no-undo.
define variable oMethod  as System.Reflection.MethodInfo no-undo.
define variable oInfo    as System.IO.FileInfo           no-undo.
define variable cResult  as character                    no-undo.
define variable iFirst   as int64                        no-undo.
define variable iRead    as int64                        no-undo.
define variable i        as integer                      no-undo.

define stream sOut.

/* ---------------------------------------------------------------- setup */
cFile = System.IO.Path:Combine (System.IO.Path:GetFullPath (session:temp-directory),
                                "regex-performance.txt":u).

if not System.IO.File:Exists (cFile) then do:
    cLine = "  order 4711 for Nordwind Trading, shipped on 2026-11-06, status ok, line ":u.
    output stream sOut to value (cFile).
    put stream sOut unformatted "Nordwind test data":u skip.
    do i = 1 to iLines:
        put stream sOut unformatted cLine i skip.
    end.
    output stream sOut close.
end.

/* matches at position 0: no scanning, only the conversion is measured */
oRegex = new Regex ("^Nordwind":u).

/* Regex.Match(System.String), for calls with a System.Object argument */
oTypes = new "System.Type[]" (1).
oTypes:SetValue (Progress.Util.TypeHelper:GetType ("System.String":u), 0).
oMethod = oRegex:GetType ():GetMethod ("Match":u, oTypes).

oInfo   = new System.IO.FileInfo (cFile).
cResult = substitute ("Test file: &1 MB, &2 repeated calls~n~n":u,
                      round (oInfo:Length / 1048576, 0),
                      iCalls).

/* ------------------------------------------------- 1. CHARACTER, 30 KB */
cShort = "Nordwind ":u + fill ("x":u, 30000).

etime (yes).
do i = 1 to iCalls:
    oMatch = oRegex:Match (cShort).
end.
cResult = cResult + substitute ("1. CHARACTER, 30 KB, &1 calls: &2 ms~n~n":u, iCalls, etime).

/* ------------------------------------------------------- 2. LONGCHAR */
etime (yes).
copy-lob from file cFile to lcText.
iRead = etime (yes).
oMatch = oRegex:Match (lcText).
iFirst = etime (yes).
do i = 1 to iCalls:
    oMatch = oRegex:Match (lcText).
end.
cResult = cResult + substitute ("2. LONGCHAR~n   copy-lob &1 ms, first Match &2 ms, &3 more calls &4 ms~n~n":u,
                                iRead, iFirst, iCalls, etime).
lcText = "":u.

/* --------------------------------------------- 3. nested ReadAllText */
etime (yes).
oMatch = oRegex:Match (System.IO.File:ReadAllText (cFile)).
cResult = cResult + substitute ("3. Match (ReadAllText (...)) nested~n   read + Match &1 ms~n~n":u, etime).

/* ------------------------------ 4. System.Object, Match via reflection */
etime (yes).
oText = System.IO.File:ReadAllText (cFile).
iRead = etime (yes).

oArgs = new "System.Object[]" (1).
oArgs:SetValue (oText, 0).

oMatch = cast (oMethod:Invoke (oRegex, oArgs), Match).
iFirst = etime (yes).
do i = 1 to iCalls:
    oMatch = cast (oMethod:Invoke (oRegex, oArgs), Match).
end.
cResult = cResult + substitute ("4. System.Object + reflection~n   ReadAllText &1 ms, first Match &2 ms, &3 more calls &4 ms":u,
                                iRead, iFirst, iCalls, etime).

if not oMatch:Success then
    undo, throw new Progress.Lang.AppError ("The pattern did not match the test file.":u, 0).

message cResult view-as alert-box.
