classdef DragToRearrangeEventData < event.EventData
    %

    %   Copyright 2017-2019 The MathWorks, Inc.
    
    properties (SetAccess = {?matlab.graphics.chart.internal.heatmap.DragToRearrange,...
            ?matlab.graphics.chart.internal.parallelplot.DragToRearrange})
        Axis
        Item
        StartIndex
        EndIndex
        DragOccurred
        HitObject
    end
end
