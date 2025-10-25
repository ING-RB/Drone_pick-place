classdef CoberturaFormatService < matlab.buildtool.internal.services.coverage.CoverageResultsService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        Extension = ".xml"
        CoverageFormatClass = "matlab.unittest.plugins.codecoverage.CoberturaFormat"
    end

    methods
        function format = constructCoverageFormat(~, liaison)
            import matlab.unittest.plugins.codecoverage.CoberturaFormat

            format = CoberturaFormat(liaison.ResultPath);
        end

        function formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
            arguments
                service (1,1) matlab.buildtool.internal.services.modelcoverage.CoberturaFormatService
                liaison (1,1) matlab.buildtool.internal.services.modelcoverage.ModelCoverageResultsLiaison
                labelAlignedStr (1,1) matlab.automation.internal.diagnostics.LabelAlignedListString
            end

            import matlab.automation.internal.diagnostics.FormattableStringDiagnostic
            import matlab.automation.internal.diagnostics.CommandHyperlinkableString
            import matlab.automation.internal.diagnostics.escapeQuotes

            resultLabel = sprintf("%s", service.getStringFromCatalog("CoberturaFormatLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultPath, sprintf("open('%s')", escapeQuotes(liaison.ResultPath)));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end
    end
end