classdef MATFileResultsService < matlab.buildtool.internal.services.codeanalysis.ResultsExtensionService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        Extension = ".mat"
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
            eval(liaison.CodeIssuesVarName + " = liaison.CodeIssues;");
            save(liaison.ResultsFile, liaison.CodeIssuesVarName);
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

            resultLabel = sprintf("%s", service.getStringFromCatalog("MATFileResultsLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultsFile, sprintf("ans = load('%s').('%s')", escapeQuotes(liaison.ResultsFile), liaison.CodeIssuesVarName));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end
    end
end