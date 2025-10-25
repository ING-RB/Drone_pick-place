classdef TestContentCreationPluginData < matlab.unittest.plugins.plugindata.PluginData & ...
        matlab.unittest.internal.plugins.plugindata.TestResultDetailsAccessorMixin
    % TestContentCreationPluginData - Data about creating test content.
    %
    %   The TestContentCreationPluginData class holds information about test
    %   content being created.
    %
    %   TestContentCreationPluginData properties:
    %       Name          - Name of the content being created
    %       ResultDetails - Modifier of test result details
    %
    %   See also:
    %       matlab.unittest.plugins.TestRunnerPlugin
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    methods (Hidden, Access={?matlab.unittest.TestRunner,?matlab.unittest.plugins.plugindata.PluginData})
        function p = TestContentCreationPluginData(name, testRunData, locationProvider, varargin)
            parser = matlab.unittest.internal.strictInputParser;
            parser.addParameter('ForLeafResult',false,...
                @(x) validateattributes(x,{'logical'},{'scalar'},'','ForLeafResult'));
            parser.parse(varargin{:});
                        
            p@matlab.unittest.plugins.plugindata.PluginData(name);
            p@matlab.unittest.internal.plugins.plugindata.TestResultDetailsAccessorMixin(testRunData, locationProvider, ~parser.Results.ForLeafResult);
        end
    end
end

% LocalWords:  plugindata
