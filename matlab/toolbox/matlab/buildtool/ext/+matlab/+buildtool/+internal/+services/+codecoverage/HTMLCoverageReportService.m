classdef HTMLCoverageReportService < matlab.buildtool.internal.services.coverage.CoverageResultsService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        Extension = ".html"
        CoverageFormatClass = "matlab.unittest.plugins.codecoverage.CoverageReport"
    end

    methods
        function format = constructCoverageFormat(~, liaison)
            import matlab.unittest.plugins.codecoverage.CoverageReport

            [fpath, fname, fext] = fileparts(liaison.ResultPath);
            format = CoverageReport(fpath, MainFile=fname+fext);
        end

        function formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
            arguments
                service (1,1) matlab.buildtool.internal.services.codecoverage.HTMLCoverageReportService
                liaison (1,1) matlab.buildtool.internal.services.codecoverage.CodeCoverageResultsLiaison
                labelAlignedStr (1,1) matlab.automation.internal.diagnostics.LabelAlignedListString
            end

            import matlab.automation.internal.diagnostics.FormattableStringDiagnostic
            import matlab.automation.internal.diagnostics.CommandHyperlinkableString
            import matlab.automation.internal.diagnostics.escapeQuotes

            resultLabel = sprintf("%s", service.getStringFromCatalog("HTMLCoverageReportLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultPath, sprintf("web('%s', '-noaddressbox', '-new')", escapeQuotes(liaison.ResultPath)));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end

        function files = listSupportingOutputFiles(service, liaison) %#ok<INUSD>
            import matlab.unittest.plugins.codecoverage.CoverageReport
            import matlab.buildtool.io.FileCollection

            files = CoverageReport.listSupportingFiles();
            files = fullfile(fileparts(liaison.ResultPath), files);
            files = FileCollection.fromPaths(files);
        end
    end
end