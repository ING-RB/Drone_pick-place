classdef CoverageResultService < matlab.buildtool.internal.services.coverage.CoverageResultsService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        Extension = ".mat"
        CoverageFormatClass = "matlab.unittest.plugins.codecoverage.CoverageResult"
    end

    methods
        function format = constructCoverageFormat(~, ~)
            import matlab.unittest.plugins.codecoverage.CoverageResult

            format = CoverageResult();
        end

        function formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
            arguments
                service (1,1) matlab.buildtool.internal.services.codecoverage.CoverageResultService
                liaison (1,1) matlab.buildtool.internal.services.codecoverage.CodeCoverageResultsLiaison
                labelAlignedStr (1,1) matlab.automation.internal.diagnostics.LabelAlignedListString
            end

            import matlab.automation.internal.diagnostics.FormattableStringDiagnostic
            import matlab.automation.internal.diagnostics.CommandHyperlinkableString
            import matlab.automation.internal.diagnostics.escapeQuotes

            resultLabel = sprintf("%s", service.getStringFromCatalog("MATFileCoverageResultsLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultPath, sprintf("ans = load('%s').('%s')", escapeQuotes(liaison.ResultPath), liaison.ResultVarName));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end
    end
end