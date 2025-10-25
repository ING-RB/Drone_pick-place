classdef (Hidden) RadioButtonController < ...
        matlab.ui.control.internal.controller.MutualExclusiveComponentController & ...
        matlab.ui.control.internal.controller.mixin.MultilineTextComponentController & ...
        matlab.ui.control.internal.controller.mixin.InterpretableComponentController
    %

    % Copyright 2013-2023 The MathWorks, Inc.   
    
    methods
        function obj = RadioButtonController(varargin)                      
            obj@matlab.ui.control.internal.controller.MutualExclusiveComponentController(varargin{:});
        end
    end
    
    methods(Access = 'protected')                
        
        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.
            
            
            viewPvPairs = {};                        
            
            % Properties from Super
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.control.internal.controller.MutualExclusiveComponentController(obj, propertyNames), ...
                ];            
            
            % Text related
            viewPvPairs = [viewPvPairs, ...
                getTextPropertiesForView(obj, propertyNames);
                ];                                                                                           
        end

        function handleEvent(obj, src, event)
			% Allow super classes to handle their events
			handleEvent@matlab.ui.control.internal.controller.MutualExclusiveComponentController(obj, src, event);
			
            % Event handling goes here
            handleEvent@matlab.ui.control.internal.controller.mixin.InterpretableComponentController(obj, src, event);
        end
		
		function handlePropertiesChanged(obj, changedPropertiesStruct)									
			% defer to mixin and super class
			changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.MultilineTextComponentController(obj, changedPropertiesStruct);
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
		end                
    end
end


