function reportLocation = createReport(sources, reportFolder, reportName, format, diffResult, texts)
    % Entry point to create a MATLAB App Designer comparison report
    
    % Copyright 2023 The MathWorks, Inc.

    arguments
        sources (1,2) {comparisons.internal.report.Utils.mustBeCellArrayOfFileSources}
        reportFolder {mustBeFolder}
        reportName (1,:) char
        format (1,1) comparisons.internal.report.ReportFormat
        diffResult (1,1) comparisons.text.viewmodel.mfzero.SequenceDiffResult
        texts (1,2) {comparisons.internal.report.Utils.mustBeCellArrayOfTextScalar}
    end

    reportLocation = comparisons.internal.report.Utils.constructPath(reportFolder, reportName, format);
    report = mlappComparisonReport(sources, reportLocation, format, diffResult, texts);
    report.fill();

    function report = mlappComparisonReport(sources, reportLocation, rptFormat, diffResult, texts)
        report = comparisons.internal.report.text.ComparisonReport(sources, reportLocation, rptFormat, diffResult, texts);
        report.ShouldSyntaxHighlight = @(s) true;
    end
    
end
