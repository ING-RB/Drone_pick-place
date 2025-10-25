classdef (Hidden) IconIDStyle < matlab.ui.style.internal.ComponentStyle
        
    % IconIDStyle - Contains style related properties for icon ids
 
    % Copyright 2022 The MathWorks, Inc.
    
    properties
        IconID char = '';
        Width = '';
        Height= '';
    end
    
    properties (Access = ?matlab.ui.style.internal.ComponentStyle)
        DisplayPropertyOrder = ["IconID","Height","Width"];
    end
       
    methods
        function obj = IconIDStyle(varargin)
            obj = obj@matlab.ui.style.internal.ComponentStyle(varargin{:});
        end
    end
    
    methods (Access = ?matlab.ui.internal.SetGetDisplayAdapter)
        
        function linkDisplay(obj)
            % LINKDISPLAY - This method displays on the commandline all
            % properties in a display consistent with the property groups
            
            propertyGroupArray = matlab.mixin.util.PropertyGroup(properties(obj));
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj,propertyGroupArray);
        end
    end
end

