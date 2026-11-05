@lowercase.

using System.Text.RegularExpressions.* from assembly.
using demo3.*                           from propath.

block-level on error undo, throw.

class demo3.EMailHelper:

    define private static variable oEMailRegex as Regex no-undo.

    define protected static property EMailRegex as Regex no-undo
    get():
        if not valid-object (oEMailRegex) then
            oEMailRegex = EMailHelper:BuildEMailRegex ().
        return oEMailRegex.
    end get.
    private set.

    method private static Regex BuildEMailRegex ():

        define variable oRegex         as Regex    no-undo. // https://datatracker.ietf.org/doc/html/rfc5322
        define variable cLocalDotAtom  as character no-undo. // RFC 5322 3.2.3 atext
        define variable cDomainDotAtom as character no-undo. // RFC 5322 3.2.5 / RFC 1035 label
        define variable cDomainLiteral as character no-undo. // RFC 5322 3.4.1 dot-decimal octet

        {&_proparse_ prolint-nowarn(backslash)}
        assign
            //
            cLocalDotAtom  = "[A-Za-z0-9!#$%&'*+/=?^_`~{|~}-]+":u
            cDomainDotAtom = "[A-Za-z0-9]
                              (?:
                                  [A-Za-z0-9-]~{0,61~}
                                  [A-Za-z0-9]
                              )?":u
            cDomainLiteral = "(?:
                                    25[0-5]
                                  | 2[0-4]~\d
                                  | 1~\d~\d
                                  | [1-9]?~\d
                              )":u
            oRegex         = new Regex (substitute ("(?# RFC 5322 3.4.1 addr-spec )
                                                     ^
                                                     (?<localpart>
                                                         (?# RFC 5322 3.2.3 dot-atom )
                                                         (
                                                             &1
                                                             (?:~\.&1)*
                                                         )
                                                         |
                                                         (?# RFC 5322 3.2.4 quoted-string )
                                                         ~"
                                                         (?:
                                                               (?# qtext: the only allowed qtext char below '#' )
                                                               !
                                                             |
                                                               (?# qtext: '#'..'[' - digits, most punctuation, and 'A'-'Z' )
                                                               [#-~\[]
                                                             |
                                                               (?# qtext: ']'..'~' - 'a'-'z' and the remaining punctuation )
                                                               [~\]-~~]
                                                             |
                                                               (?# FWS: a space or tab between qcontent is allowed, RFC 5322 3.2.4. Line breaks are not, they only fold long header lines )
                                                               [~\x20~\x09]
                                                             |
                                                               (?# quoted-pair per 3.2.1: backslash + VCHAR or WSP, escapes '~"' or '~\' itself. RFC 2822 allowed any ASCII char here, ~\x00 to ~\x7F - RFC 5322 narrows it to printable chars + tab/space, control chars now only valid via obs-qp when PARSING legacy mail, not for new addresses )
                                                               ~\~\[~\x09~\x20-~\x7E]
                                                         )*
                                                         ~"
                                                     )
                                                     @
                                                     (?<domain>
                                                         (?# RFC 5322 3.2.5 domain dot-atom )
                                                         (
                                                             &2
                                                             (?:~\.&2)*
                                                         )
                                                         |
                                                         (?# RFC 5322 3.4.1 domain-literal IPv4 )
                                                         ~\[
                                                             (
                                                                 &3
                                                                 (?:~\.&3)~{3~}
                                                             )
                                                         ~\]
                                                     )
                                                     $
                                                     ":u,
                                                     cLocalDotAtom,
                                                     cDomainDotAtom,
                                                     cDomainLiteral),
                                        RegexOptions:Compiled
                                        or RegexOptions:IgnorePatternWhitespace).

        return oRegex.

    end method.

    method public static logical IsValidEMailAddress (pcEMailAddress as character):

        if pcEMailAddress = ? then
            return false.

        return EMailHelper:EMailRegex:IsMatch (trim (pcEMailAddress)).

    end method.

end class.
