@lowercase.

using samples.* from propath.
using System.Text.RegularExpressions.* from assembly.

block-level on error undo, throw.

class samples.VatHelper:

    define private static variable oVatRegex as Regex no-undo.

    define protected static property VatRegex as Regex no-undo
    get():
        if not valid-object (oVatRegex) then
            oVatRegex = VatHelper:BuildVatRegex ().
        return oVatRegex.
    end get.
    private set.

    method private static Regex BuildVatRegex ():

        define variable oRegex as Regex no-undo.

        /* Plausibility check only - NOT a checksum/MOD-97 validation.
           Demonstrates a .NET Regex feature most other engines forbid:
           the same named groups ("country", "number", "check") are reused
           in every alternation branch - .NET merges them, so callers only
           ever look at one name.
           check: the check digit(s)/character, where the format has one.
           FR: the two characters in front of the 9-digit SIREN are the key. */
        {&_proparse_ prolint-nowarn(backslash)}
        oRegex = new Regex ("
                        ^
                        (?:
                              (?<country>AT)(?<number>U~\d~{7~}(?<check>~\d))
                            | (?<country>BE)(?<number>[01]~\d~{7~}(?<check>~\d~{2~}))
                            | (?<country>DE)(?<number>~\d~{8~}(?<check>~\d))
                            | (?<country>DK)(?<number>~\d~{8~})
                            | (?<country>ES)(?<number>[A-Z0-9]~\d~{7~}(?<check>[A-Z0-9]))
                            | (?<country>FR)(?<number>(?<check>[A-Z0-9]~{2~})~\d~{9~})
                            | (?<country>NL)(?<number>~\d~{9~}B~\d~{2~})
                        )
                        $
                        ":u,
                        RegexOptions:IgnoreCase
                        or RegexOptions:Compiled
                        or RegexOptions:IgnorePatternWhitespace).

        return oRegex.

    end method.

    method public static logical IsPlausibleVatNumber (pcVatNumber as character):

        define variable cNormalized as character no-undo.

        if pcVatNumber = ? then
            return false.

        cNormalized = replace(pcVatNumber, " ":u, "":u).
        cNormalized = replace(cNormalized, "-":u, "":u).

        return VatHelper:VatRegex:IsMatch (cNormalized).

    end method.

    method public static logical SplitVatNumber (pcVatNumber as character,
                                                 output pcCountry as character,
                                                 output pcNumber as character):

        define variable cNormalized as character no-undo.
        define variable oMatch      as System.Text.RegularExpressions.Match no-undo.

        if pcVatNumber = ? then
            return false.

        cNormalized = replace(pcVatNumber, " ":u, "":u).
        cNormalized = replace(cNormalized, "-":u, "":u).

        oMatch = VatHelper:VatRegex:Match (cNormalized).

        /* no IF per country: every branch fills the same groups */
        assign pcCountry = caps (oMatch:Groups:Item["country":u]:Value)
               pcNumber  = caps (oMatch:Groups:Item["number":u]:Value).

        return oMatch:Success.

    end method.

end class.