classdef (UseClassDefaultsOnLoad, ConstructOnLoad) PieChart < matlab.graphics.chart.internal.AbstractPieChart
    %

    %   Copyright 2023 The MathWorks, Inc.
    
    methods(Access=protected)
        function t = getTypeName(~)
            t = 'piechart';
        end
    end
end
