classdef (Hidden) ColorPickerController < ...
        matlab.ui.control.internal.controller.ComponentController & ...
        matlab.ui.control.internal.controller.mixin.IconableComponentController
    %
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods
        function obj = ColorPickerController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end
        
        function excludedPropertyNames = getExcludedComponentSpecificPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view at Run time            
            
            % Get excluded property names for Iconable components
            excludedPropertyNames = obj.getExcludedPropertyNamesForIconableComponent();        
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
            
            % Icon Specific
            viewPvPairs = [viewPvPairs, ...
                getIconPropertiesForView(obj, propertyNames);
                ];     
        end
        
        function handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handles properties changed from client
            
            changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.IconableComponentController(obj, changedPropertiesStruct);
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
        
        function handleEvent(obj, src, event)
			% Allow super classes to handle their events
			handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
			
			if(strcmp(event.Data.Name, 'ValueChanged'))
				% Handles when the user changes the text in the ui
				
				% Get the previous value
				previousValue = obj.Model.Value;
				
				% Get the new value
				newValue = hgcastvalue('matlab.graphics.datatype.RGBColor', event.Data.Value);
				
				% Create event data
				eventData = matlab.ui.eventdata.ValueChangedData(newValue, previousValue);
				
				% Update the model and emit 'ValueChanged' which in turn will
				% trigger the user callback
				obj.handleUserInteraction('ValueChanged', event.Data, {'ValueChanged', eventData, 'PrivateValue', newValue});
			end
		end
    end
end