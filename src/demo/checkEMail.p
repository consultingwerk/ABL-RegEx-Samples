/*------------------------------------------------------------------------
    File    : checkEMail.p
    Purpose : Runs a set of valid/invalid e-mail addresses through
              demo.EMailHelper and prints a pass/fail summary. The test
              addresses, expected result and explanation live entirely in
              email-test-cases.xml - nothing here gives away the answer,
              so the audience can be asked to guess before it's revealed.
  ----------------------------------------------------------------------*/

@lowercase.

using demo.* from propath.

block-level on error undo, throw.

define temp-table ttEMailTest no-undo
    xml-node-name "EMailTest":u
    field EMailAddress as character
    field Expected     as logical
    field Note         as character.

define dataset dsEMailTests xml-node-name "EMailTests":u
    for ttEMailTest.

define variable lActual    as logical no-undo.
define variable lPassed    as logical no-undo.
define variable iPassCount as integer no-undo.
define variable iFailCount as integer no-undo.

dataset dsEMailTests:read-xml ("file":u, "src/demo/email-test-cases.xml":u, ?, ?, ?).

for each ttEMailTest:
    message substitute ("'&1'":u, ttEMailTest.EMailAddress)
        view-as alert-box.

    lActual = EMailHelper:IsValidEMailAddress (ttEMailTest.EMailAddress).
    lPassed = lActual = ttEMailTest.Expected.

    if lPassed then
        iPassCount = iPassCount + 1.
    else
        iFailCount = iFailCount + 1.

    message
        (if lPassed then "PASS":u else "FAIL":u)
        ttEMailTest.EMailAddress
        substitute ("(expected &1, got &2)":u,
                    string (ttEMailTest.Expected, "valid/invalid":u),
                    string (lActual, "valid/invalid":u)) skip(1)
            ttEMailTest.Note
        view-as alert-box.
end.

message substitute ("&1 of &2 checks matched the expected result (&3 unexpected).":u,
                     iPassCount,
                     iPassCount + iFailCount,
                     iFailCount).

catch oError as Progress.Lang.Error:
    message substitute ("ERROR: &1":u, oError:GetMessage (1)) view-as alert-box.
end catch.