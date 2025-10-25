function reportLocation = createReportAndView(leftSource, rightSource, reportFolder, reportName, format, diffResult, leftText, rightText)
%

%   Copyright 2023-2024 The MathWorks, Inc.

    arguments
        leftSource (1,1) comparisons.internal.FileSource
        rightSource (1,1)  comparisons.internal.FileSource
        reportFolder {mustBeFolder}
        reportName (1,:) char
        format (1,1) comparisons.internal.report.ReportFormat
        diffResult (1,1) comparisons.text.viewmodel.mfzero.SequenceDiffResult
        leftText {mustBeTextScalar}
        rightText {mustBeTextScalar}  
    end

    reportLocation = appdesigner.internal.comparison.report.createReport({leftSource, rightSource}, reportFolder , reportName, format, diffResult, {leftText, rightText});

    comparisons.internal.report.view(reportLocation);
end
