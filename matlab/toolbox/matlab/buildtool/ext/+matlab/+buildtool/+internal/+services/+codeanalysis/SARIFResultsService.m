classdef SARIFResultsService < matlab.buildtool.internal.services.codeanalysis.ResultsExtensionService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        DefaultExtension = ".sarif"
    end

    methods
        function save(~, liaison)
            fpath = fileparts(liaison.ResultsFile);
            if strlength(fpath) ~= 0 && ~isfolder(fpath)
                success = mkdir(fpath);
                if ~success
                    error(message("MATLAB:buildtool:CodeIssuesTask:CannotCreateResultsFolder", fpath));
                end
            end
            liaison.CodeIssues.export(liaison.ResultsFile, FileFormat="sarif", SourceRoot=liaison.SourceRoot);
        end

        function formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
            arguments
                service matlab.buildtool.internal.services.codeanalysis.ResultsExtensionService
                liaison matlab.buildtool.internal.services.codeanalysis.ResultsExtensionLiaison
                labelAlignedStr matlab.automation.internal.diagnostics.LabelAlignedListString
            end

            import matlab.automation.internal.diagnostics.FormattableStringDiagnostic
            import matlab.automation.internal.diagnostics.CommandHyperlinkableString
            import matlab.automation.internal.diagnostics.escapeQuotes

            resultLabel = sprintf("%s", service.getStringFromCatalog("SARIFResultsLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultsFile, sprintf("edit('%s')", escapeQuotes(liaison.ResultsFile)));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end
    end

    methods (Access = protected)
        function tf = supports(service, resultsFile)
            [~, ~, fext] = fileparts(resultsFile);
            tf = ...
                fext == service.DefaultExtension || ...
                endsWith(resultsFile, ".sarif.json");
        end
    end
end