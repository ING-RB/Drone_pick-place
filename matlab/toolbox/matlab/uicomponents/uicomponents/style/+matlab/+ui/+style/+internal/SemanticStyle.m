classdef (Hidden) SemanticStyle < matlab.ui.style.internal.ComponentStyle
        
    % SEMANTCSTYLE - Contains style related properties for SemanticStyle object
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties
        BackgroundColor char = '';
        FontColor char = '';
    end
    
    properties (Access = ?matlab.ui.style.internal.ComponentStyle)
        DisplayPropertyOrder = ["BackgroundColor", "FontColor"];
    end
       
    methods
        function obj = SemanticStyle(varargin)
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

