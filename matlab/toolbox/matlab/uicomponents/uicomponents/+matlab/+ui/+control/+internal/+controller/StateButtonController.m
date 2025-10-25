classdef (Hidden) StateButtonController < ...
        matlab.ui.control.internal.controller.BinaryComponentController & ...
        matlab.ui.control.internal.controller.mixin.IconableComponentController & ...
        matlab.ui.control.internal.controller.mixin.MultilineTextComponentController & ...
        matlab.ui.control.internal.controller.mixin.InterpretableComponentController
    %

    % Copyright 2014-2023 The MathWorks, Inc.

    methods
        function obj = StateButtonController(varargin)                      
            obj@matlab.ui.control.internal.controller.BinaryComponentController(varargin{:});
        end
        
        function excludedPropertyNames = getExcludedComponentSpecificPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view at Run time            
            
            % Get excluded property names for Iconable components
            excludedPropertyNames = obj.getExcludedPropertyNamesForIconableComponent();     
        end
    end
    
    methods(Access = 'protected')                
        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view
            
            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);
            
            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'IconID';...
                }];
        end
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
                getPropertiesForView@matlab.ui.control.internal.controller.BinaryComponentController(obj, propertyNames), ...
                ];  
            
            % Icon Specific
            viewPvPairs = [viewPvPairs, ...
                getIconPropertiesForView(obj, propertyNames);
                ];
            
            % Text related
            viewPvPairs = [viewPvPairs, ...
                getTextPropertiesForView(obj, propertyNames);
                ];                                                                                           
        end

        function handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handles properties changed from client
            
            changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.IconableComponentController(obj, changedPropertiesStruct);
			changedPropertiesStruct = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.MultilineTextComponentController(obj, changedPropertiesStruct);
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
		end				
        
        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.mixin.IconableComponentController(obj, src, event);
            handleEvent@matlab.ui.control.internal.controller.mixin.InterpretableComponentController(obj, src, event);

            % already handled PropertyEditorEdited for Icon
            if ~(strcmp(event.Data.Name, 'PropertyEditorEdited') && strcmp(event.Data.PropertyName, 'Icon'))
                handleEvent@matlab.ui.control.internal.controller.BinaryComponentController(obj, src, event);
            end               
        end        
    end
end


