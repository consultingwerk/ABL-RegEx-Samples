using app.legacy.*.

define variable oService as app.legacy.OrderService   no-undo.
define variable oCalc    as PriceCalculator           no-undo.
define variable oAdapter as app.legacyBridge.Adapter  no-undo.

oService = new app.legacy.OrderService ().
oCalc    = oService:GetCalculator ().
oAdapter = new app.legacyBridge.Adapter ().

run app/legacy/orderReport.p.

message oCalc:GrossPrice (100) oAdapter:Describe ().