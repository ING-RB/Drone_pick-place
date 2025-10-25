classdef SkyPlotChartAccessor < matlab.plottools.service.accessor.ChartAccessor
%SKYPLOTCHARTACCESSOR Defines skyplot behavior for the figure ecosystem

%   Copyright 2024 The MathWorks, Inc.

    methods
        function obj = SkyPlotChartAccessor()
            obj = obj@matlab.plottools.service.accessor.ChartAccessor();
        end

        function id = getIdentifier(~)
            id = 'nav.graphics.chart.SkyPlotChart';
        end
    end

    % SupportsFeature Method Overrides
    methods(Access='protected')
        function result = supportsTitle(~)
            result = true;
        end
        function result = supportsLegend(~)
            result = true;
        end

        function setTitle(obj, value)
            title(obj.ReferenceObject, value);
        end
        
        function setLegend(obj, value)
            if value == "off"
                legend(obj.ReferenceObject,"off");
            else
                legend(obj.ReferenceObject);
            end
        end
    end
end