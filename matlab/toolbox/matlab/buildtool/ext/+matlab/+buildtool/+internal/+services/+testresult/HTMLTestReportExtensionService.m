classdef HTMLTestReportExtensionService < matlab.buildtool.internal.services.testresult.TestResultExtensionService
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        Extension = ".html"
    end

    methods
        function customizeTestRunner(~, liaison, runner)
            import matlab.unittest.plugins.TestReportPlugin

            pluginOptions = struct();
            if optionWasProvided(liaison.PluginProviderData, "LoggingLevel")
                pluginOptions.LoggingLevel = liaison.PluginProviderData.Options.LoggingLevel;
            end
            pluginOptions = namedargs2cell(pluginOptions);

            runner.addPlugin(TestReportPlugin.producingHTML(liaison.ResultsFile, pluginOptions{:}));
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

            resultLabel = sprintf("%s", service.getStringFromCatalog("HTMLTestReportLabel"));
            resultStr = CommandHyperlinkableString(liaison.ResultsFile, sprintf("web('%s', '-noaddressbox', '-new')", escapeQuotes(liaison.ResultsFile)));
            formattedStr = labelAlignedStr.addLabelAndString(sprintf("%s:", resultLabel), FormattableStringDiagnostic(resultStr).DiagnosticText);
        end        
    end
end