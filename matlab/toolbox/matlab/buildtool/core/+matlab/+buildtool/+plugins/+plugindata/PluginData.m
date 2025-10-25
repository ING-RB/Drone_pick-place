classdef (Hidden) PluginData < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % PluginData - Data object passed to BuildRunnerPlugin methods
    %
    %   The matlab.buildtool.plugins.plugindata.PluginData class defines the
    %   data passed by the build runner to various plugin methods. The build
    %   runner instantiates this class, so you are not required to create an
    %   object of the class directly.
    
    %   Copyright 2021-2022 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        % Name - Name of content being run
        %
        %   Name of content being run within the scope of the plugin method,
        %   returned as a string scalar. Use the Name property for informational,
        %   labeling, and display purposes.
        Name (1,1) string
    end
    
    methods (Access = {?matlab.buildtool.BuildRunner, ?matlab.buildtool.plugins.plugindata.PluginData})
        function data = PluginData(name)
            arguments
                name (1,1) string = ""
            end
            data.Name = name;
        end
    end
end

