classdef (Hidden) VerboseProgressPlugin < matlab.buildtool.plugins.runprogress.DetailedProgressPlugin
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2024 The MathWorks, Inc.

    methods (Access = ?matlab.buildtool.plugins.BuildRunProgressPlugin)
        function plugin = VerboseProgressPlugin(varargin)
            plugin = plugin@matlab.buildtool.plugins.runprogress.DetailedProgressPlugin(varargin{:});
        end
    end
end