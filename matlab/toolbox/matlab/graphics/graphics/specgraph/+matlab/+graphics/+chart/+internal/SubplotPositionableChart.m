
%

%   Copyright 2017-2020 The MathWorks, Inc.

% Interface for charts that support full control by subplot

classdef (AllowedSubclasses = {...
        ?matlab.graphics.chart.internal.SubplotPositionableChartWithAxes,...
        ?matlab.graphics.chart.internal.UndecoratedTitledChart, ...
        ?matlab.graphics.chart.StackedLineChart}) ...
        SubplotPositionableChart ...
        < matlab.graphics.chart.Chart & ...
        matlab.graphics.internal.Layoutable & ...
        matlab.graphics.mixin.ChartLayoutable 

    % Protected properties that are also accessible by testing helper.
    properties (Abstract, Hidden, Access = {?ChartUnitTestFriend, ?matlab.graphics.chart.internal.SubplotPositionableChart})
        Axes
    end
    
    methods (Hidden, Access = {?ChartUnitTestFriend, ?matlab.graphics.chart.Chart, ...
                   ?matlab.graphics.mixin.Mixin})
        function hAx = getAxes(hObj)
            hAx = hObj.Axes;
        end
    end
    
    properties(Abstract, Hidden)
        % These properties are needed to pass object_is_axeslike in subplot
        % c++ code:
        Position_I matlab.internal.datatype.matlab.graphics.datatype.Position
    end
    
    properties(Abstract, Hidden, SetAccess = private)
        % These properties are needed to pass object_is_axeslike in subplot
        % c++ code:
        LooseInset matlab.internal.datatype.matlab.graphics.datatype.Inset
    end
    
    properties(Abstract, Hidden, SetAccess = private)
        OuterPosition_I matlab.internal.datatype.matlab.graphics.datatype.Position
        InnerPosition_I matlab.internal.datatype.matlab.graphics.datatype.Position
        TightInset matlab.internal.datatype.matlab.graphics.datatype.Inset
    end
    
    properties(Abstract)
        OuterPosition matlab.internal.datatype.matlab.graphics.datatype.Position
        InnerPosition matlab.internal.datatype.matlab.graphics.datatype.Position
        Position matlab.internal.datatype.matlab.graphics.datatype.Position
        Units matlab.internal.datatype.matlab.graphics.datatype.Units
    end
    
    properties(Abstract, NeverAmbiguous)
        PositionConstraint matlab.internal.datatype.matlab.graphics.datatype.PositionConstraint
    end
    
    properties(Abstract, Hidden) % subplot auto-layout interface
        ActivePositionProperty matlab.graphics.chart.datatype.ChartActivePositionType
        
        % Extra space needed by chart to leave room for e.g.
        % colorbar/legend and still fit inside the SubplotCellOuterPosition.
        % Stored in same units & format as TightInset
        % (container units)
        ChartDecorationInset matlab.internal.datatype.matlab.graphics.datatype.Inset
        
        % Maximum Inset space (as provided by subplot.m setup) for chart
        % decorations before subplot will start squashing the innerposition
        % of a chart. Stored in same units & format as TightInset
        % (container units)
        % subplot stores maximum tightInsets for an axes in axes'
        % looseInset property. For charts, subplot stores the maximum
        % tightInset in this property instead:
        MaxInsetForSubplotCell matlab.internal.datatype.matlab.graphics.datatype.Inset
        
        % Position of grid cell allocated for chart by subplot.
        SubplotCellOuterPosition matlab.internal.datatype.matlab.graphics.datatype.Position
        
    end
    
    methods (Access = protected)
        function unitPos = getUnitPositionObject(hObj)
            % Return a UnitPosition object from an axes. This object is
            % used to do unit conversions, so it should be updated with the
            % correct reference frame, screen resolution, DPI, etc. The
            % actual units and position value in the UnitPosition should
            % not be used for anything.
            hAx = hObj.Axes;
            if isa(hAx, 'matlab.graphics.axis.AbstractAxes') && ~isempty(hAx)
                unitPos = hAx(1).Camera.Viewport;
            else
                unitPos = matlab.graphics.general.UnitPosition;
            end
        end
    end
    
    methods(Hidden)
        function resetSubplotLayoutInfo(~)
        end
    end
end

