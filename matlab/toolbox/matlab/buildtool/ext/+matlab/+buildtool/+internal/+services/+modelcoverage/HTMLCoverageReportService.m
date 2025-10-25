classdef HTMLCoverageReportService < matlab.buildtool.internal.services.coverage.CoverageResultsService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        Extension = ".html"
        CoverageDataExtension = ".cvt"
        CoverageFormatClass = "sltest.plugins.coverage.ModelCoverageReport"
    end

    methods
        function format = constructCoverageFormat(~, liaison)
            % Interpret the results file as a
            % folder to consolidate all *.html files. For e.g reports for
            % various referenced models or when running a homogeneous suite
            % of Simulink test files using a single instance of
            % ModelCoveragePlugin.            
            reportFolder = liaison.ResultPath;
            [~, reportName] = fileparts(liaison.ResultPath);
            format = matlab.buildtool.internal.tasks.constructModelCoverageReportFormat(reportFolder, ReportName=reportName);
        end

        function formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
            arguments
                service (1,1) matlab.buildtool.internal.services.modelcoverage.HTMLCoverageReportService
                liaison (1,1) matlab.buildtool.internal.services.modelcoverage.ModelCoverageResultsLiaison
                labelAlignedStr (1,1) matlab.automation.internal.diagnostics.LabelAlignedListString
            end

            import matlab.automation.internal.diagnostics.FormattableStringDiagnostic
            import matlab.automation.internal.diagnostics.CommandHyperlinkableString
            import matlab.automation.internal.diagnostics.escapeQuotes

            resultLabel = sprintf("%s", service.getStringFromCatalog("HTMLCoverageReportLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultPath, sprintf("web('%s', '-noaddressbox', '-new')", escapeQuotes(liaison.ResultPath)));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end
    end

    methods (Static)
        function createResultsFolder(liaison)
            fpath = liaison.ResultPath;
            if ~isfolder(fpath)
                success = mkdir(fpath);
                if ~success
                    error(message("MATLAB:buildtool:TestTask:CannotCreateResultsFolder", fpath));
                end
            end
        end
    end
end