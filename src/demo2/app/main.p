using demo2.app.legacy.*.

define variable oService as demo2.app.legacy.OrderService   no-undo.
define variable oCalc    as PriceCalculator           no-undo.
define variable oAdapter as demo2.app.legacyBridge.Adapter  no-undo.

oService = new demo2.app.legacy.OrderService ().
oCalc    = oService:GetCalculator ().
oAdapter = new demo2.app.legacyBridge.Adapter ().

run demo2/app/legacy/orderReport.p.

message oCalc:GrossPrice (100) oAdapter:Describe ().