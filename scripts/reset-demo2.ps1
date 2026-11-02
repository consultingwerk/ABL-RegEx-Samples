<#
    Live Demo 2 - "Move a Folder, Fix Every Reference"

    Recreates src/app in its starting state: the folder src/app/legacy with
    classes, procedures and an include, referenced as
        app.%L%.X        (class names)
        app/%L%/x.p      (RUN, include)
        app\%L%\x.i      (Windows-style path)
        app\\%L%\\x.p    (JSON string)
    plus the decoy app.legacyBridge, which must NOT be changed.

    %L% is a placeholder for "legacy", filled in by Write-Fixture. It keeps
    the demo's workspace search & replace from rewriting this script too.

    Usage (from anywhere):  powershell -ExecutionPolicy Bypass -File scripts\reset-demo2.ps1
    Only src/app is deleted and rewritten.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app  = Join-Path $root 'src\app'
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

class app.%L%.OrderService:

    method public void PrintReport ():
        run app/%L%/orderReport.p.
    end method.

    method public app.%L%.PriceCalculator GetCalculator ():
        return new app.%L%.PriceCalculator ().
    end method.

end class.
'@

Write-Fixture 'legacy\PriceCalculator.cls' @'
block-level on error undo, throw.

class app.%L%.PriceCalculator:

    {app/%L%/priceRules.i}

    method public decimal GrossPrice (pdNet as decimal):
        return pdNet * (1 + {&VAT_RATE}).
    end method.

end class.
'@

Write-Fixture 'legacy\orderReport.p' @'
/* Windows-style include path, works on Windows only */
{app\%L%\priceRules.i}

message "Order report, VAT rate" {&VAT_RATE}.
'@

Write-Fixture 'legacy\priceRules.i' @'
&global-define VAT_RATE 0.21
'@

Write-Fixture 'legacyBridge\Adapter.cls' @'
block-level on error undo, throw.

/* Decoy: app.legacyBridge must survive the refactoring unchanged */
class app.legacyBridge.Adapter:

    method public character Describe ():
        return "Adapter in app.legacyBridge":u.
    end method.

end class.
'@

Write-Fixture 'main.p' @'
using app.%L%.*.

define variable oService as app.%L%.OrderService   no-undo.
define variable oCalc    as PriceCalculator           no-undo.
define variable oAdapter as app.legacyBridge.Adapter  no-undo.

oService = new app.%L%.OrderService ().
oCalc    = oService:GetCalculator ().
oAdapter = new app.legacyBridge.Adapter ().

run app/%L%/orderReport.p.

message oCalc:GrossPrice (100) oAdapter:Describe ().
'@

Write-Fixture 'config\services.xml' @'
<?xml version="1.0" encoding="UTF-8"?>
<services>
    <service name="orders"  class="app.%L%.OrderService"   report="app/%L%/orderReport.p"/>
    <service name="prices"  class="app.%L%.PriceCalculator"/>
    <service name="bridge"  class="app.legacyBridge.Adapter"/>
</services>
'@

Write-Fixture 'config\services.json' @'
{
    "orders": {
        "class": "app.%L%.OrderService",
        "report": "app\\%L%\\orderReport.p"
    },
    "prices": {
        "class": "app.%L%.PriceCalculator",
        "rules": "app/%L%/priceRules.i"
    },
    "bridge": {
        "class": "app.legacyBridge.Adapter"
    }
}
'@

Write-Host "Demo 2 reset: $app"
