classdef DataChangedEventData < event.EventData
    %
    
    %   Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess = ?matlab.graphics.chart.HeatmapChart)
        % SourceTable, XVariable, YVariable, ColorVariable, and/or ColorMethod changed.
        %
        % This flag is meant to indicate that table related data has
        % changed. Setting table properties will set this property to true
        % and will indirectly set Matrix to true.
        %
        % Set to true within updateData when UsingTableForData and
        % DataDirty are both true.
        Table (1,1) logical = false
        
        % XData, YData, and/or ColorData changed.
        %
        % This flag is meant to indicate that the core data of the chart
        % has changed. Setting table properties will indirectly set XData,
        % YData, and ColorData. Therefore, if Table is true, then Matrix is
        % guaranteed to also be true.
        %
        % Set to true within set.XData_I, set.YData_I, and set.ColorData_I.
        Matrix (1,1) logical = false
        
        % XDisplayData or XDisplayLabels changed.
        %
        % This flag is meant to indicate that the names and/or labels of
        % the columns have changed (including a change in order). Setting
        % XData switches XDisplayDataMode to 'auto', therefore setting
        % XData is guaranteed to also cause XDisplay to be true. However,
        % setting XData_I will only cause XDisplay to be true if
        % XDisplayDataMode is 'auto'.
        %
        % Set to true within set.XDisplay_I.
        XDisplay (1,1) logical = false
        
        % YDisplayData or YDisplayLabels changed.
        %
        % This flag is meant to indicate that the names and/or labels of
        % the rows have changed (including a change in order). Setting
        % YData switches YDisplayDataMode to 'auto', therefore setting
        % YData is guaranteed to also cause YDisplay to be true. However,
        % setting YData_I will only cause YDisplay to be true if
        % YDisplayDataMode is 'auto'.
        %
        % Set to true within set.YDisplay_I.
        YDisplay (1,1) logical = false
        
        % XVariable or XData changed.
        %
        % This flag is meant to indicate that the user changed the data
        % used for the XData. This flag is used to reset the original view
        % used by the home icon. Changing the data in the SourceTable may
        % indirectly result in the XData changing, but this will not cause
        % this flag to be set to true.
        %
        % Set to true within set.XVariable and set.XData.
        XData (1,1) logical = false
        
        % YVariable or YData changed.
        %
        % This flag is meant to indicate that the user changed the data
        % used for the YData. This flag is used to reset the original view
        % used by the home icon. Changing the data in the SourceTable may
        % indirectly result in the YData changing, but this will not cause
        % this flag to be set to true.
        %
        % Set to true within set.YVariable and set.YData.
        YData (1,1) logical = false
    end
    
    methods
        function tf = hasDataChanged(eventData)
            tf = eventData.Table || eventData.Matrix ...
                || eventData.XDisplay || eventData.YDisplay ...
                || eventData.XData || eventData.YData;
        end
    end
end
