classdef (Hidden) LabelController < ...
        matlab.ui.control.internal.controller.ComponentController & ...        
        matlab.ui.control.internal.controller.mixin.MultilineTextComponentController & ...
        matlab.ui.control.internal.controller.mixin.InterpretableComponentController
    % LabelController class is the controller class for Labels
    
    
    % Copyright 2011-2021 The MathWorks, Inc.
    
    methods
        function obj = LabelController(varargin)                        
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
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
                getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames), ...
                ];            
            
            
            % Text related
            viewPvPairs = [viewPvPairs, ...
                getTextPropertiesForView(obj, propertyNames);
                ];
        end            		
		
        function handleEvent(obj, src, event)
			% Allow super classes to handle their events
			handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
			
            % Event handling goes here
            handleEvent@matlab.ui.control.internal.controller.mixin.InterpretableComponentController(obj, src, event);
        end
        
		function handlePropertiesChanged(obj, changedPropertiesStruct)									
			% defer to mixin and super class
			changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.MultilineTextComponentController(obj, changedPropertiesStruct);
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
		end
		
		function propertyNames = getAdditonalComponentSpecificPropertyNamesForView(obj)
            % GETADDITIONALCOMPONENTSPECIFICPROPERTYNAMESFORVIEW - Specify
            % per component if there are any non-public properties that
            % should be sent to the view at runtime.
            propertyNames = {'Interpreter'; 'HorizontalClipping'};
        end
    end
end

