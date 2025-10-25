classdef TableInteraction < matlab.mixin.CustomDisplay & ...
         matlab.ui.eventdata.internal.Interaction
    %

    % Do not remove above white space
    
    % Copyright 2022 The MathWorks, Inc.

    properties (SetAccess = immutable)
        DisplayRow
        DisplayColumn
        Row
        Column
        RowHeader
        ColumnHeader
    end

    methods
        function obj = TableInteraction(options)
            obj@matlab.ui.eventdata.internal.Interaction(options);
            obj.DisplayRow = options.DisplayRow;
            obj.DisplayColumn = options.DisplayColumn;
            obj.Row = options.Row;
            obj.Column = options.Column;
            obj.RowHeader = options.RowHeader;
            obj.ColumnHeader = options.ColumnHeader;
        end
    end
    methods (Access = protected, Sealed = true)
        function footer = getFooter(obj)
            footer = '';
            if  isscalar(obj)
                names = obj.getPropertyGroupNames();
                footer = matlab.ui.internal.SetGetDisplayAdapter.getFooter(obj, names, inputname(1));
            end
        end
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            % Add the super class properties to the end of the display
            names = {'DisplayRow', 'DisplayColumn', 'Location', 'ScreenLocation'};
                
        end
        function propgrp = getPropertyGroups(obj)
            % GETPROPERTYGROUPS - Specify property-value pairs to show in
            % the object display.
            
            propsNonDefault = obj.getPropertyGroupNames();
            propgrp = matlab.mixin.util.PropertyGroup(propsNonDefault);
        end
    end
    methods (Access = ?matlab.ui.internal.SetGetDisplayAdapter)
        
        function linkDisplay(obj)
            % LINKDISPLAY - This method displays on the commandline all
            % properties in a display consistent with the property groups
            % This is required by the SetGetDisplayAdapter
            
            propertyGroupArray = matlab.mixin.util.PropertyGroup(properties(obj));
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj,propertyGroupArray);
        end
    end
end