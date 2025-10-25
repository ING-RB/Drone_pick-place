classdef JUnitXMLTestResultsExtensionService < matlab.buildtool.internal.services.testresult.TestResultExtensionService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        Extension = ".xml"
    end

    methods
        function customizeTestRunner(~, liaison, runner)
            import matlab.unittest.plugins.XMLPlugin

            pluginOptions = struct();
            if optionWasProvided(liaison.PluginProviderData, "OutputDetail")
                pluginOptions.OutputDetail = liaison.PluginProviderData.Options.OutputDetail;
            end
            pluginOptions = namedargs2cell(pluginOptions);

            runner.addPlugin(XMLPlugin.producingJUnitFormat(liaison.ResultsFile, pluginOptions{:}));
        end

        function formattedStr = addLabelAndString(service, liaison, labelAlignedStr)
            arguments
                service (1,1) matlab.buildtool.internal.services.testresult.TestResultExtensionService
                liaison (1,1) matlab.buildtool.internal.services.testresult.TestResultExtensionLiaison
                labelAlignedStr (1,1) matlab.automation.internal.diagnostics.LabelAlignedListString
            end

            import matlab.automation.internal.diagnostics.FormattableStringDiagnostic
            import matlab.automation.internal.diagnostics.CommandHyperlinkableString
            import matlab.automation.internal.diagnostics.escapeQuotes

            resultLabel = sprintf("%s", service.getStringFromCatalog("JUnitTestResultsLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultsFile, sprintf("open('%s')", escapeQuotes(liaison.ResultsFile)));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end        
    end
end
