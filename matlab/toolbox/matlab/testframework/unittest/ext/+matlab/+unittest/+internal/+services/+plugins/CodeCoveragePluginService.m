classdef CodeCoveragePluginService < matlab.unittest.internal.services.plugins.TestRunnerPluginService
    %
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    methods
        function plugin = providePlugins(~, pluginOptions)
            import matlab.unittest.plugins.TestRunnerPlugin;
            import matlab.unittest.plugins.codecoverage.CoverageReport;
            
            if pluginOptions.optionWasProvided("ReportCoverageFor")
                coverageFormat = [CoverageReport , pluginOptions.Options.GetCoverageResults_];
                plugin = matlab.unittest.plugins.CodeCoveragePlugin.forSource(pluginOptions.Options.ReportCoverageFor,...
                   "Producing",coverageFormat); 
            else
               plugin = TestRunnerPlugin.empty; 
            end
            
        end
    end
end

% matlab.unittest.internal.services.plugins