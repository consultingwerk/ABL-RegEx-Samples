# Regular Expressions for ABL Developers

Slides and samples from the session **Regular Expressions for ABL Developers** by Sebastian Wandel
(Consultingwerk) at PUG Challenge 2026 Amsterdam.

The session covers the regex syntax you need day to day, search & replace with regex in VS Code and
Progress Developer Studio for OpenEdge (PDSOE), and the .NET `System.Text.RegularExpressions.Regex`
class in ABL code.

## Slides

- [`slides/Regular Expressions for ABL Developers.pdf`](slides/Regular%20Expressions%20for%20ABL%20Developers.pdf)
- [`slides/Regular Expressions for ABL Developers.pptx`](slides/Regular%20Expressions%20for%20ABL%20Developers.pptx), with speaker notes

## Requirements

- OpenEdge 12.8 (the samples use the .NET CLR bridge, tested on Windows)
- No database needed
- Optional: VS Code with the [OpenEdge ABL extension](https://marketplace.visualstudio.com/items?itemName=RiversideSoftware.openedge-abl-lsp), or PDSOE

## Getting started

All paths in the samples are relative to the repository root, so run everything from there.

- **VS Code:** open `ABL-RegEx-Samples.code-workspace`. The OpenEdge ABL extension picks up
  `openedge-project.json` (PROPATH `src`, `-assemblies ./assemblies`, `-T ./temp`).
- **PDSOE:** *File → Import → Existing Projects into Workspace* and select the repository folder.
- **Command line (batch client):** `scripts/run.p` puts `src` in front of the PROPATH and runs the
  procedure given in `-param`:

  ```
  %DLC%\bin\_progres.exe -b -p scripts/run.p -param src/demo/checkEMail.p -T temp -cpinternal utf-8 -cpstream utf-8 -cpcoll basic -assemblies ./assemblies
  ```

## Samples in `src/demo`

| File | Shows |
|---|---|
| `walkMatches.p` | `Match` / `NextMatch`, a named group, lookbehind and negative lookahead |
| `missingGroupDemo.p` | A group that did not take part returns `""` with `Success = no`, not `?` |
| `inputCharacter.p` | Regex on a `CHARACTER` value |
| `inputLongchar.p` | Regex on a `LONGCHAR` value |
| `inputFile.p` | Regex on a whole file, read by .NET and kept on the .NET side (reflection) |
| `parseDefineVariable.p` | The same parser as minified and formatted regex vs. minified and formatted ABL |
| `VatHelper.cls` | VAT number validation with named groups (`country`, `number`, `check`) |
| `EMailHelper.cls` | E-mail validation along RFC 5322, formatted with `IgnorePatternWhitespace` |
| `quantifier-demo.txt` | Greedy, lazy, possessive and atomic quantifiers, catastrophic backtracking |

## Live demos

| Demo | Files | Reset |
|---|---|---|
| 1 Finding code in PDSOE and VS Code | `src/shop`, patterns in `src/demo/demo1.txt` | nothing to reset |
| 2 Move a folder, fix every reference | `src/app`, pattern in `src/demo/demo2.txt` | `scripts/reset-demo2.ps1` |
| 3 Validating e-mail addresses | `src/demo/checkEMail.p`, `EMailHelper.cls`, `email-test-cases.xml` | nothing to reset |
| 4 Turning variables into properties | `src/demo/refactor.p`: `src/classic` → `src/modern` | `scripts/reset-demo4.ps1` |

Run the reset scripts with:

```
powershell -ExecutionPolicy Bypass -File scripts\reset-demo2.ps1
```

## Try your patterns

[regex101.com](https://regex101.com): choose the **.NET (C#)** flavor for patterns in ABL code and
**Java** for PDSOE.

## License

[MIT](LICENSE)
