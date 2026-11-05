/**
 * Purpose: Legacy report generation class with old-style ABL patterns
 * Notes:   Contains many refactorable patterns for Regex demonstration
 */
block-level on error undo, throw.

class demo4.classic.ReportGenerator:

    define public variable rpt-name as character no-undo.
    define public variable rpt-title as character no-undo.
    define public variable rpt-description as character no-undo.
    define public variable rpt-author as character no-undo.
    define public variable rpt-created as datetime no-undo.
    define public variable rpt-modified as datetime no-undo.
    define public variable rpt-format as character no-undo.
    define public variable rpt-orientation as character no-undo.
    define public variable rpt-page-size as character no-undo.
    define public variable rpt-margin-top as decimal no-undo.
    define public variable rpt-margin-bottom as decimal no-undo.
    define public variable rpt-margin-left as decimal no-undo.
    define public variable rpt-margin-right as decimal no-undo.
    define public variable rpt-header as character no-undo.
    define public variable rpt-footer as character no-undo.
    define public variable rpt-font-name as character no-undo.
    define public variable rpt-font-size as integer no-undo.
    define public variable rpt-output-path as character no-undo.
    define public variable rpt-status as character no-undo.

    define private variable iPageCount as integer no-undo.
    define private variable iLineCount as integer no-undo.
    define private variable iColumnCount as integer no-undo.
    define private variable lcContent as longchar no-undo.
    define private variable cCurrentSection as character no-undo.

    define private temp-table ttReportColumn no-undo
        field col-number as integer
        field col-name as character
        field col-label as character
        field col-width as integer
        field col-align as character
        field col-format as character
        field col-visible as logical
        index idx-col-number is primary unique col-number.

    define private temp-table ttReportData no-undo
        field row-number as integer
        field col-number as integer
        field cell-value as character
        index idx-row-col is primary unique row-number col-number.

    constructor public ReportGenerator():
        assign
            rpt-name = ""
            rpt-title = ""
            rpt-description = ""
            rpt-author = ""
            rpt-created = now
            rpt-modified = now
            rpt-format = "PDF"
            rpt-orientation = "PORTRAIT"
            rpt-page-size = "LETTER"
            rpt-margin-top = 1.0
            rpt-margin-bottom = 1.0
            rpt-margin-left = 0.75
            rpt-margin-right = 0.75
            rpt-header = ""
            rpt-footer = ""
            rpt-font-name = "Arial"
            rpt-font-size = 10
            rpt-output-path = ""
            rpt-status = "NEW".
    end constructor.

    method public void SetReportInfo(pcName as character, pcTitle as character,
                                     pcDescription as character):
        assign
            rpt-name = pcName
            rpt-title = pcTitle
            rpt-description = pcDescription
            rpt-modified = now.
    end method.

    method public void SetAuthor(pcAuthor as character):
        rpt-author = pcAuthor.
        rpt-modified = now.
    end method.

    method public void SetFormat(pcFormat as character):
        if pcFormat = "PDF" or pcFormat = "HTML" or pcFormat = "CSV" or
           pcFormat = "EXCEL" or pcFormat = "XML" or pcFormat = "TEXT" then do:
            rpt-format = pcFormat.
            rpt-modified = now.
        end.
    end method.

    method public void SetOrientation(pcOrientation as character):
        if pcOrientation = "PORTRAIT" or pcOrientation = "LANDSCAPE" then do:
            rpt-orientation = pcOrientation.
            rpt-modified = now.
        end.
    end method.

    method public void SetPageSize(pcSize as character):
        if pcSize = "LETTER" or pcSize = "LEGAL" or pcSize = "A4" or
           pcSize = "A3" or pcSize = "TABLOID" then do:
            rpt-page-size = pcSize.
            rpt-modified = now.
        end.
    end method.

    method public void SetMargins(pdTop as decimal, pdBottom as decimal,
                                  pdLeft as decimal, pdRight as decimal):
        if pdTop >= 0 and pdBottom >= 0 and pdLeft >= 0 and pdRight >= 0 then do:
            assign
                rpt-margin-top = pdTop
                rpt-margin-bottom = pdBottom
                rpt-margin-left = pdLeft
                rpt-margin-right = pdRight
                rpt-modified = now.
        end.
    end method.

    method public void SetHeaderFooter(pcHeader as character, pcFooter as character):
        assign
            rpt-header = pcHeader
            rpt-footer = pcFooter
            rpt-modified = now.
    end method.

    method public void SetFont(pcFontName as character, piFontSize as integer):
        if piFontSize > 0 and piFontSize <= 72 then do:
            assign
                rpt-font-name = pcFontName
                rpt-font-size = piFontSize
                rpt-modified = now.
        end.
    end method.

    method public void SetOutputPath(pcPath as character):
        rpt-output-path = pcPath.
        rpt-modified = now.
    end method.

    method public void AddColumn(pcName as character, pcLabel as character,
                                 piWidth as integer, pcAlign as character,
                                 pcFormat as character):
        define variable iNextCol as integer no-undo.

        for each ttReportColumn no-lock:
            if ttReportColumn.col-number > iNextCol then
                iNextCol = ttReportColumn.col-number.
        end.
        iNextCol = iNextCol + 1.

        create ttReportColumn.
        assign
            ttReportColumn.col-number = iNextCol
            ttReportColumn.col-name = pcName
            ttReportColumn.col-label = pcLabel
            ttReportColumn.col-width = piWidth
            ttReportColumn.col-align = pcAlign
            ttReportColumn.col-format = pcFormat
            ttReportColumn.col-visible = true.

        iColumnCount = iNextCol.
        rpt-modified = now.
    end method.

    method public void RemoveColumn(piColNumber as integer):
        find first ttReportColumn where ttReportColumn.col-number = piColNumber
            exclusive-lock no-error.
        if available ttReportColumn then do:
            delete ttReportColumn.
            rpt-modified = now.
        end.
    end method.

    method public void SetColumnVisible(piColNumber as integer, plVisible as logical):
        find first ttReportColumn where ttReportColumn.col-number = piColNumber
            exclusive-lock no-error.
        if available ttReportColumn then do:
            ttReportColumn.col-visible = plVisible.
            rpt-modified = now.
        end.
    end method.

    method public void SetColumnWidth(piColNumber as integer, piWidth as integer):
        find first ttReportColumn where ttReportColumn.col-number = piColNumber
            exclusive-lock no-error.
        if available ttReportColumn then do:
            ttReportColumn.col-width = piWidth.
            rpt-modified = now.
        end.
    end method.

    method public void AddDataRow(pcValues as character):
        define variable iNextRow as integer no-undo.
        define variable iCol as integer no-undo.
        define variable cValue as character no-undo.

        for each ttReportData no-lock:
            if ttReportData.row-number > iNextRow then
                iNextRow = ttReportData.row-number.
        end.
        iNextRow = iNextRow + 1.

        do iCol = 1 to num-entries(pcValues, "|"):
            cValue = entry(iCol, pcValues, "|").
            create ttReportData.
            assign
                ttReportData.row-number = iNextRow
                ttReportData.col-number = iCol
                ttReportData.cell-value = cValue.
        end.

        iLineCount = iNextRow.
        rpt-modified = now.
    end method.

    method public void SetCellValue(piRow as integer, piCol as integer, pcValue as character):
        find first ttReportData where ttReportData.row-number = piRow
            and ttReportData.col-number = piCol exclusive-lock no-error.
        if available ttReportData then do:
            ttReportData.cell-value = pcValue.
            rpt-modified = now.
        end.
    end method.

    method public character GetCellValue(piRow as integer, piCol as integer):
        find first ttReportData where ttReportData.row-number = piRow
            and ttReportData.col-number = piCol no-lock no-error.
        if available ttReportData then
            return ttReportData.cell-value.
        else
            return "".
    end method.

    method public integer GetRowCount():
        return iLineCount.
    end method.

    method public integer GetColumnCount():
        return iColumnCount.
    end method.

    method public logical Generate():
        define variable lSuccess as logical no-undo.

        if rpt-name = "" or rpt-name = ? then return false.
        if rpt-output-path = "" or rpt-output-path = ? then return false.
        if iColumnCount = 0 then return false.

        rpt-status = "GENERATING".
        rpt-modified = now.

        case rpt-format:
            when "PDF" then lSuccess = this-object:GeneratePDF().
            when "HTML" then lSuccess = this-object:GenerateHTML().
            when "CSV" then lSuccess = this-object:GenerateCSV().
            when "EXCEL" then lSuccess = this-object:GenerateExcel().
            when "XML" then lSuccess = this-object:GenerateXML().
            when "TEXT" then lSuccess = this-object:GenerateText().
            otherwise lSuccess = false.
        end case.

        if lSuccess then
            rpt-status = "COMPLETED".
        else
            rpt-status = "FAILED".

        rpt-modified = now.
        return lSuccess.
    end method.

    method private logical GeneratePDF():
        define variable lSuccess as logical no-undo.
        lcContent = "PDF Report: " + rpt-title + chr(10).
        lcContent = lcContent + "Generated: " + string(now) + chr(10).
        lcContent = lcContent + "Author: " + rpt-author + chr(10).
        lcContent = lcContent + "Pages: " + string(iPageCount) + chr(10).
        lSuccess = true.
        return lSuccess.
    end method.

    method private logical GenerateHTML():
        define variable lSuccess as logical no-undo.
        define variable iRow as integer no-undo.

        lcContent = "<html><head><title>" + rpt-title + "</title></head>".
        lcContent = lcContent + "<body><h1>" + rpt-title + "</h1>".
        lcContent = lcContent + "<p>" + rpt-description + "</p>".
        lcContent = lcContent + "<table border='1'>".

        lcContent = lcContent + "<tr>".
        for each ttReportColumn no-lock where ttReportColumn.col-visible = true:
            lcContent = lcContent + "<th>" + ttReportColumn.col-label + "</th>".
        end.
        lcContent = lcContent + "</tr>".

        do iRow = 1 to iLineCount:
            lcContent = lcContent + "<tr>".
            for each ttReportColumn no-lock where ttReportColumn.col-visible = true:
                lcContent = lcContent + "<td>" +
                    this-object:GetCellValue(iRow, ttReportColumn.col-number) + "</td>".
            end.
            lcContent = lcContent + "</tr>".
        end.

        lcContent = lcContent + "</table></body></html>".
        lSuccess = true.
        return lSuccess.
    end method.

    method private logical GenerateCSV():
        define variable lSuccess as logical no-undo.
        define variable cLine as character no-undo.
        define variable lFirst as logical no-undo.
        define variable iRow as integer no-undo.

        lcContent = "".
        lFirst = true.
        for each ttReportColumn no-lock where ttReportColumn.col-visible = true:
            if lFirst then do:
                cLine = ttReportColumn.col-label.
                lFirst = false.
            end.
            else
                cLine = cLine + "," + ttReportColumn.col-label.
        end.
        lcContent = cLine + chr(10).

        do iRow = 1 to iLineCount:
            cLine = "".
            lFirst = true.
            for each ttReportColumn no-lock where ttReportColumn.col-visible = true:
                if lFirst then do:
                    cLine = this-object:GetCellValue(iRow, ttReportColumn.col-number).
                    lFirst = false.
                end.
                else
                    cLine = cLine + "," + this-object:GetCellValue(iRow, ttReportColumn.col-number).
            end.
            lcContent = lcContent + cLine + chr(10).
        end.

        lSuccess = true.
        return lSuccess.
    end method.

    method private logical GenerateExcel():
        define variable lSuccess as logical no-undo.
        lcContent = "Excel Report: " + rpt-title + chr(10).
        lSuccess = true.
        return lSuccess.
    end method.

    method private logical GenerateXML():
        define variable lSuccess as logical no-undo.
        define variable iRow as integer no-undo.

        lcContent = "<?xml version='1.0' encoding='UTF-8'?>".
        lcContent = lcContent + "<report>".
        lcContent = lcContent + "<title>" + rpt-title + "</title>".
        lcContent = lcContent + "<description>" + rpt-description + "</description>".
        lcContent = lcContent + "<author>" + rpt-author + "</author>".
        lcContent = lcContent + "<generated>" + string(now) + "</generated>".
        lcContent = lcContent + "<data>".

        do iRow = 1 to iLineCount:
            lcContent = lcContent + "<row number='" + string(iRow) + "'>".
            for each ttReportColumn no-lock where ttReportColumn.col-visible = true:
                lcContent = lcContent + "<" + ttReportColumn.col-name + ">" +
                    this-object:GetCellValue(iRow, ttReportColumn.col-number) +
                    "</" + ttReportColumn.col-name + ">".
            end.
            lcContent = lcContent + "</row>".
        end.

        lcContent = lcContent + "</data></report>".
        lSuccess = true.
        return lSuccess.
    end method.

    method private logical GenerateText():
        define variable lSuccess as logical no-undo.
        define variable cLine as character no-undo.
        define variable iRow as integer no-undo.

        lcContent = rpt-title + chr(10).
        lcContent = lcContent + fill("-", length(rpt-title)) + chr(10).
        lcContent = lcContent + rpt-description + chr(10) + chr(10).

        cLine = "".
        for each ttReportColumn no-lock where ttReportColumn.col-visible = true:
            cLine = cLine + string(ttReportColumn.col-label, "x(" + string(ttReportColumn.col-width) + ")") + " ".
        end.
        lcContent = lcContent + cLine + chr(10).
        lcContent = lcContent + fill("-", length(cLine)) + chr(10).

        do iRow = 1 to iLineCount:
            cLine = "".
            for each ttReportColumn no-lock where ttReportColumn.col-visible = true:
                cLine = cLine + string(this-object:GetCellValue(iRow, ttReportColumn.col-number),
                    "x(" + string(ttReportColumn.col-width) + ")") + " ".
            end.
            lcContent = lcContent + cLine + chr(10).
        end.

        lSuccess = true.
        return lSuccess.
    end method.

    method public longchar GetContent():
        return lcContent.
    end method.

    method public logical SaveToFile():
        define variable lSuccess as logical no-undo.

        if rpt-output-path = "" or rpt-output-path = ? then return false.
        if lcContent = "" or lcContent = ? then return false.

        copy-lob lcContent to file rpt-output-path.
        lSuccess = true.
        return lSuccess.
    end method.

    method public void ClearData():
        for each ttReportData exclusive-lock:
            delete ttReportData.
        end.
        iLineCount = 0.
        rpt-modified = now.
    end method.

    method public void ClearColumns():
        for each ttReportColumn exclusive-lock:
            delete ttReportColumn.
        end.
        iColumnCount = 0.
        rpt-modified = now.
    end method.

    method public void Reset():
        this-object:ClearData().
        this-object:ClearColumns().
        lcContent = "".

        assign
            rpt-name = ""
            rpt-title = ""
            rpt-description = ""
            rpt-author = ""
            rpt-created = now
            rpt-modified = now
            rpt-format = "PDF"
            rpt-orientation = "PORTRAIT"
            rpt-page-size = "LETTER"
            rpt-margin-top = 1.0
            rpt-margin-bottom = 1.0
            rpt-margin-left = 0.75
            rpt-margin-right = 0.75
            rpt-header = ""
            rpt-footer = ""
            rpt-font-name = "Arial"
            rpt-font-size = 10
            rpt-output-path = ""
            rpt-status = "NEW".
    end method.

    method public character GetReportSummary():
        define variable cSummary as character no-undo.
        cSummary = "Report: " + rpt-name + chr(10).
        cSummary = cSummary + "Title: " + rpt-title + chr(10).
        cSummary = cSummary + "Format: " + rpt-format + chr(10).
        cSummary = cSummary + "Orientation: " + rpt-orientation + chr(10).
        cSummary = cSummary + "Page Size: " + rpt-page-size + chr(10).
        cSummary = cSummary + "Columns: " + string(iColumnCount) + chr(10).
        cSummary = cSummary + "Rows: " + string(iLineCount) + chr(10).
        cSummary = cSummary + "Status: " + rpt-status + chr(10).
        cSummary = cSummary + "Output: " + rpt-output-path.
        return cSummary.
    end method.

end class.
