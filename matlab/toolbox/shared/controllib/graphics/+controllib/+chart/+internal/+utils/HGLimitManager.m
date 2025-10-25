classdef HGLimitManager < handle
    % HGManager class as a wrapper for HG objects to be added to controls
    % chart

    properties (Access = {?controllib.chart.internal.foundation.AbstractPlot,...
            ?controllib.chart.internal.utils.HGManager})
        HG
        FocusAxes
    end

    properties (Dependent)
        XLimits
        YLimits
    end

    methods
        function this = HGLimitManager(hgObject,focusAxes)
            arguments
                hgObject (1,1) {mustBeA(hgObject,["matlab.graphics.primitive.Line",...
                    "matlab.graphics.primitive.Patch","matlab.graphics.chart.primitive.Scatter",...
                    "matlab.graphics.chart.primitive.Stair","matlab.graphics.chart.primitive.Stem"])}
                focusAxes (1,2) double
            end

            this.HG = hgObject;
            this.FocusAxes = focusAxes;
        end

        function XLimits = get.XLimits(this)
            XLimits = [min(this.HG.XData),max(this.HG.XData)];
        end

        function YLimits = get.YLimits(this)
            YLimits = [min(this.HG.YData),max(this.HG.YData)];
        end
    end
end