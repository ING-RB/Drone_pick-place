classdef TestResultExtensionLiaison < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        ResultsFile (1,1) string
        PluginProviderData (1,1) matlab.unittest.internal.plugins.PluginProviderData
    end

    properties (Constant)
        TestResultsVarName (1,1) string {mustBeValidVariableName} = "result"
    end

    properties (Dependent, SetAccess = private)
        Extension
    end

    methods
        function liaison = TestResultExtensionLiaison(resultsFile, pluginProviderOptions)
            arguments
                resultsFile (1,1) string
                pluginProviderOptions (1,1) struct = struct
            end
            liaison.ResultsFile = resultsFile;
            liaison.PluginProviderData = PluginProviderData(pluginProviderOptions);
        end

        function extension = get.Extension(liaison)
            [~, ~, extension] = fileparts(liaison.ResultsFile);
        end
    end
end

function d = PluginProviderData(varargin)
d = matlab.unittest.internal.plugins.PluginProviderData(varargin{:});
end