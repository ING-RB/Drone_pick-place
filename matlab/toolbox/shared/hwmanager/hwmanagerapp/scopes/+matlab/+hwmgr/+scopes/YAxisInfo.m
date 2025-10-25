classdef YAxisInfo
    %YAXISINFO Holds information about customization for each y axis

    % Copyright 2024 The MathWorks, Inc.

    properties
        %YScale Y-axis scale
        %   Specify the Y-axis scale as one of 'linear' or 'log'. The
        %   default is 'Linear'.
        YScale (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(YScale, ["linear", "log"])} = "linear"

        %YLabel Y-axis label
        %   Specify the y-axis label as a string. The default value is "".
        YLabel (1, 1) string = ""

        %YLimMode auto or manual y limits
        %   Specify whether the y limits automatically change with input
        %   data. When set to "auto", y limits automatically adjust to
        %   include the full range of data. When set to "manual", it
        %   uses the value provided in YLimits. The default is "auto".
        YLimMode (1, 1) string {matlab.hwmgr.internal.util.mustBeMemberCaseInsensitive(YLimMode, ["manual", "auto"])} = "auto"

        %YLimits Y-axis limits
        %   Specify the y-axis limits as a two-element numeric vector:
        %   [ymin ymax]. The default is [0 1].
        YLimits (1, 2) double = [0, 1]
    end

    methods
        function obj = YAxisInfo(varargin)
            if isempty(varargin)
                return
            end

            p = inputParser;

            addParameter(p, "YLabel", "");
            addParameter(p, "YLimits", [0, 1]);
            addParameter(p, "YLimMode", "auto");
            addParameter(p, "YScale", "linear");

            parse(p, varargin{:});

            obj.YLabel = p.Results.YLabel;

            obj.YLimits = p.Results.YLimits;

            obj.YLimMode = p.Results.YLimMode;

            obj.YScale = p.Results.YScale;

        end
    end
end

