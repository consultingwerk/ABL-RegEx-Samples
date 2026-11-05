<#
    Live Demo 2 - "Move a Folder, Fix Every Reference"

    Recreates src/demo2/app in its starting state: the folder src/demo2/app/legacy with
    classes, procedures and an include, referenced as
        demo2.app.%L%.X        (class names)
        demo2/app/%L%/x.p      (RUN, include)
        demo2\app\%L%\x.i      (Windows-style path)
        demo2\\app\\%L%\\x.p    (JSON string)
    plus the decoy demo2.app.legacyBridge, which must NOT be changed.

    %L% is a placeholder for "legacy", filled in by Write-Fixture. It keeps
    the demo's workspace search & replace from rewriting this script too.

    Usage (from anywhere):  powershell -ExecutionPolicy Bypass -File scripts\reset-demo2.ps1
    Only src/demo2/app is deleted and rewritten.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app  = Join-Path $root 'src\demo2\app'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Fixture([string]$relPath, [string]$content) {
    $file = Join-Path $app $relPath
    New-Item -ItemType Directory -Force (Split-Path -Parent $file) | Out-Null
    $content = $content.Replace('%L%', 'legacy')
    [System.IO.File]::WriteAllText($file, $content.Replace("`r`n", "`n").Replace("`n", "`r`n"), $utf8)
}

if (Test-Path $app) { Remove-Item -Recurse -Force $app }

Write-Fixture 'legacy\OrderService.cls' @'
block-level on error undo, throw.

class demo2.app.%L%.OrderService:

    method public void PrintReport ():
        run demo2/app/%L%/orderReport.p.
    end method.

    method public demo2.app.%L%.PriceCalculator GetCalculator ():
        return new demo2.app.%L%.PriceCalculator ().
    end method.

end class.
'@

Write-Fixture 'legacy\PriceCalculator.cls' @'
block-level on error undo, throw.

class demo2.app.%L%.PriceCalculator:

    {demo2/app/%L%/priceRules.i}

    method public decimal GrossPrice (pdNet as decimal):
        return pdNet * (1 + {&VAT_RATE}).
    end method.

end class.
'@

Write-Fixture 'legacy\orderReport.p' @'
/* Windows-style include path, works on Windows only */
{demo2\app\%L%\priceRules.i}

message "Order report, VAT rate" {&VAT_RATE}.
'@

Write-Fixture 'legacy\priceRules.i' @'
&global-define VAT_RATE 0.21
'@

Write-Fixture 'legacyBridge\Adapter.cls' @'
block-level on error undo, throw.

/* Decoy: demo2.app.legacyBridge must survive the refactoring unchanged */
class demo2.app.legacyBridge.Adapter:

    method public character Describe ():
        return "Adapter in demo2.app.legacyBridge":u.
    end method.

end class.
'@

Write-Fixture 'main.p' @'
using demo2.app.%L%.*.

define variable oService as demo2.app.%L%.OrderService   no-undo.
define variable oCalc    as PriceCalculator           no-undo.
define variable oAdapter as demo2.app.legacyBridge.Adapter  no-undo.

oService = new demo2.app.%L%.OrderService ().
oCalc    = oService:GetCalculator ().
oAdapter = new demo2.app.legacyBridge.Adapter ().

run demo2/app/%L%/orderReport.p.

message oCalc:GrossPrice (100) oAdapter:Describe ().
'@

Write-Fixture 'config\services.xml' @'
<?xml version="1.0" encoding="UTF-8"?>
<services>
    <service name="orders"  class="demo2.app.%L%.OrderService"   report="demo2/app/%L%/orderReport.p"/>
    <service name="prices"  class="demo2.app.%L%.PriceCalculator"/>
    <service name="bridge"  class="demo2.app.legacyBridge.Adapter"/>
</services>
'@

Write-Fixture 'config\services.json' @'
{
    "orders": {
        "class": "demo2.app.%L%.OrderService",
        "report": "demo2\\app\\%L%\\orderReport.p"
    },
    "prices": {
        "class": "demo2.app.%L%.PriceCalculator",
        "rules": "demo2/app/%L%/priceRules.i"
    },
    "bridge": {
        "class": "demo2.app.legacyBridge.Adapter"
    }
}
'@

Write-Host "Demo 2 reset: $app"
