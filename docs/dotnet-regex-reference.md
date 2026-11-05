# .NET Regex reference for ABL developers

A compact reference for `System.Text.RegularExpressions` as you use it from ABL. It belongs to the
session *Regular Expressions for ABL Developers* (PUG Challenge 2026 Amsterdam).

On Windows, OpenEdge 12.8 runs on **.NET Framework 4.8**, so this page lists what 4.8 offers.
Members that only exist in newer .NET versions (for example with `-clrnetcore` on Linux) are marked
**.NET 5+** or **.NET 7+**.

```abl
using System.Text.RegularExpressions.* from assembly.
```

## Things that differ from ABL

| Topic | What to know |
|---|---|
| Positions | `Index` is zero-based. ABL's `index` and `substring` count from 1, so add 1. |
| Missing groups | A group that did not take part returns `""` with `Success = no`, never `?`. A misspelled group name does the same, without an error. |
| Options | `RegexOptions` are bit flags: combine them with `or`, e.g. `RegexOptions:Compiled or RegexOptions:IgnoreCase`. |
| Escaping | ABL removes `~` at compile time: `\d{4}` is written `"~\d~{4~}"` in an ABL string. Test the unescaped pattern on regex101.com (.NET flavor). |
| Strings | Every `CHARACTER` or `LONGCHAR` argument is converted to a new `System.String` on every call. For very large text, keep it on the .NET side (see `src/samples/inputFile.p`). |
| Comments | A multi-line ABL string literal contains no line breaks. With `IgnorePatternWhitespace`, use `(?# ... )` comments, not `#`. |
| Indexers | `oMatch:Groups:Item[1]`, `oMatch:Groups:Item["name"]`, `oMatches:Item[0]`. |

## `Regex`

### Constructors

| Constructor | Notes |
|---|---|
| `new Regex (pattern)` | |
| `new Regex (pattern, options)` | |
| `new Regex (pattern, options, matchTimeout)` | `matchTimeout` is a `System.TimeSpan`, e.g. `System.TimeSpan:FromSeconds (2)`. Exceeding it throws `RegexMatchTimeoutException` (see `src/samples/catastrophicBacktracking.p`). |

The constructor parses the pattern: an invalid pattern throws `System.ArgumentException` here, not later.

Everything on this page marked without a version was checked on OpenEdge 12.8 (Windows, .NET Framework 4.8)
or comes from the Microsoft documentation for .NET Framework 4.8.

### Instance methods

| Method | Returns | Use it to |
|---|---|---|
| `IsMatch (input)`, `IsMatch (input, startat)` | `logical` | validate input |
| `Match (input)`, `Match (input, startat)`, `Match (input, beginning, length)` | `Match` | get the first hit |
| `Matches (input)`, `Matches (input, startat)` | `MatchCollection` | get all hits |
| `Replace (input, replacement)` | `character` | replace all hits |
| `Replace (input, replacement, count)`, `Replace (input, replacement, count, startat)` | `character` | replace the first `count` hits (`-1` = all) |
| `Replace (input, evaluator)` and overloads with `count`, `startat` | `character` | compute each replacement in a `MatchEvaluator` delegate |
| `Split (input)`, `Split (input, count)`, `Split (input, count, startat)` | `character[]` | cut the text at every hit |
| `GetGroupNames ()` | `character[]` | list group names (`"0"`, `"1"`, ..., and every name) |
| `GetGroupNumbers ()` | `integer[]` | list group numbers |
| `GroupNameFromNumber (i)`, `GroupNumberFromName (name)` | | translate between both |
| `ToString ()` | `character` | get the pattern back |
| `Count (input)` | `integer` | **.NET 7+**: count hits without building `Match` objects |

`startat` is zero-based as well. With `Split`, capturing groups in the pattern are included in the result
array, so use `(?:...)` if you only want the parts between the hits.

### Properties

| Property | Meaning |
|---|---|
| `Options` | the `RegexOptions` the object was built with |
| `MatchTimeout` | the timeout, `Regex:InfiniteMatchTimeout` if none |
| `RightToLeft` | `yes` if built with `RegexOptions:RightToLeft` |

### Static members

| Member | Notes |
|---|---|
| `Regex:IsMatch`, `Match`, `Matches`, `Replace`, `Split` | same as the instance methods with `(input, pattern [, options [, matchTimeout]])`. Handy for one-off calls. |
| `Regex:CacheSize` | how many patterns the static methods keep parsed (default 15) |
| `Regex:Escape (text)` | escapes metacharacters, so the text matches literally (e.g. user input inside a pattern) |
| `Regex:Unescape (text)` | the reverse |

`Regex:Escape` escapes `\ * + ? | { [ ( ) ^ $ . #` and white space, not `]` and `}`. There is no `\Q...\E`
in .NET (it throws); Java and PCRE have it. User text in a **replacement** needs `$` doubled:
`replace (cText, "$":u, "$$":u)`. See `src/samples/escapeUserInput.p`.
| `Regex:InfiniteMatchTimeout` | the "no timeout" value |

## Result objects

A `Match` is one hit. Its `Groups` hold one `Group` per pair of parentheses, and every `Group` holds one
`Capture` per repetition.

```
Regex ──Match()/Matches()──> Match ──Groups──> Group ──Captures──> Capture
                               │
                               └─ NextMatch() ─> next Match
```

| Class | Members |
|---|---|
| `Capture` | `Value`, `Index`, `Length` |
| `Group` (is a `Capture`) | `Success`, `Name`, `Captures`. `Value`, `Index`, `Length` are those of the **last** capture. |
| `Match` (is a `Group`) | `Groups`, `NextMatch ()`, `Result (replacement)` (expands `$1`, `${name}`, ... for this hit), static `Match:Empty`. `Groups:Item[0]` is the whole match. |
| `MatchCollection` | `Count`, `Item[i]`. Evaluated lazily: `Count` runs the whole search. |
| `GroupCollection` | `Count`, `Item[i]`, `Item["name"]` |
| `CaptureCollection` | `Count`, `Item[i]` |

Walk all hits with `Match` and `NextMatch` (see `src/samples/walkMatches.p`):

```abl
oMatch = oRegex:Match (lcText).
do while oMatch:Success:
    cResult = substitute ("&1&2~n":u, cResult, oMatch:Groups:Item["classname":u]:Value).
    oMatch = oMatch:NextMatch ().
end.
```

## `RegexOptions`

| Option | Inline | Effect |
|---|---|---|
| `None` | | defaults |
| `IgnoreCase` | `(?i)` | case-insensitive matching |
| `Multiline` | `(?m)` | `^` and `$` match at every line, not only at the start and end of the text |
| `Singleline` | `(?s)` | `.` also matches `\n` |
| `ExplicitCapture` | `(?n)` | only named groups capture; `( )` acts like `(?: )` |
| `IgnorePatternWhitespace` | `(?x)` | unescaped whitespace in the pattern is ignored, `#` starts a comment |
| `Compiled` | | the pattern is compiled to IL: slower to build, faster to run. Build it once and keep it in a static property. |
| `CultureInvariant` | | ignores the current culture for `IgnoreCase` (matters e.g. for the Turkish i) |
| `RightToLeft` | | searches from right to left |
| `ECMAScript` | | JavaScript-compatible behaviour; only together with `IgnoreCase`, `Multiline` and `Compiled` |
| `NonBacktracking` | | **.NET 7+**: linear run time, no catastrophic backtracking; no lookarounds, backreferences or atomic groups |

Inline options can switch on and off for a part of the pattern: `(?i:define)`, `(?-i)`.

### `Multiline` and `Singleline`

Despite the names, the two are independent: `Multiline` changes `^` and `$`, `Singleline` changes `.`.
Results on OpenEdge 12.8 for the text `"end.~ndefine x.~nend.~n"`:

| Options | `^` and `$` | `.` | `^.+$` finds |
|---|---|---|---|
| neither | start and end of the text (`$` also before a final line break) | not `\n` | nothing |
| `Multiline` | start and end of every line | not `\n` | every line (3 hits) |
| `Singleline` | start and end of the text | also `\n` | the whole text (1 hit) |
| both | start and end of every line | also `\n` | the whole text: a greedy `.*` runs over the line ends |

With both options, use `[^\n]*` or a lazy `.*?` to stay inside one line.

**Windows line breaks:** with `Multiline`, `$` matches before `\n`, not before `\r\n`. In a CRLF text
`^end\.$` finds nothing, `^end\.\r?$` finds every line. `\z` is the absolute end of the text.

## Replacement tokens

| Token | Inserts |
|---|---|
| `$1`, `$2`, ... | a numbered group |
| `${name}` | a named group |
| `$0`, `$&` | the whole match |
| `` $` `` | the text before the match |
| `$'` | the text after the match |
| `$+` | the last group |
| `$_` | the whole input |
| `$$` | a literal `$` |

## Further reading

- Regular expression language, quick reference: https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-language-quick-reference
- Regular expression options: https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-options
- Substitutions: https://learn.microsoft.com/dotnet/standard/base-types/substitutions-in-regular-expressions
- `Regex` class: https://learn.microsoft.com/dotnet/api/system.text.regularexpressions.regex
