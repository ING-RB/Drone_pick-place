classdef DesignTimeHTMLController < ...
        matlab.ui.control.internal.controller.HTMLController & ...
        appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController
    %DesignTimeHTMLController - This class contains design time logic
    %specific to the html component.
    
    % Copyright 2020 The MathWorks, Inc.
    
    
    methods
        function obj = DesignTimeHTMLController(component, parentController, proxyView, adapter)
            obj = obj@matlab.ui.control.internal.controller.HTMLController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(component, proxyView, adapter);
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.HTMLController(obj, proxyView);
            
            % Destroy the visual comopnent's runtime listeners.  We will
            % not be needing these during design time.
            delete(obj.Listeners);
            obj.Listeners = [];
            
            % Create controllers and design time listeners
            populateView@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(obj, proxyView);
        end
    end
    
    methods (Access = 'protected')
        
        function handleDesignTimePropertiesChanged(obj, src, changedPropertiesStruct)
            % HANDLEDESIGNTIMEPROPERTIESCHANGED - Delegates the logic of
            % handling the event to the runtime controllers via the
            % handlePropertiesChanged method
            handlePropertiesChanged(obj, changedPropertiesStruct);
        end
        
        function handleDesignTimeEvent(obj, src, event)
            % HANDLEDESIGNTIMEEVENT - Delegates the logic of handling the
            % event to the runtime controllers via the handleEvent method
            
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                
                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;
                
                if(strcmp(propertyName, 'HTMLSource'))
                    % When editing from the Inspector, value will be a
                    % cell array because it uses a multi line editor.
                    
                    % Split it into a single line
                    %
                    % (This can be improved likely by having the command
                    % line take a cell array and preserve it as a cell
                    % array, will look to see if it makes sense for API to
                    % support)
                    if(iscell(propertyValue))
                        propertyValue = [propertyValue{:}];
                    end
                    
                    % Strip new lines
                    propertyValue = erase(propertyValue,char(10));
                    
                    % update the model
                    setModelProperty(obj, ...
                        propertyName, ...
                        propertyValue, ...
                        event ...
                        );
                    return;
                end                
                
                
                if(strcmp(propertyName, 'Data'))                                       
                    
                    % Convert to number if it is one
                    propertyValue = convertClientNumbertoServerNumber(obj, propertyValue);
                    
                    % update the model
                    setModelProperty(obj, ...
                        propertyName, ...
                        propertyValue, ...
                        event ...
                        );
                    return;
                end
                
            end
            handleEvent(obj, src, event);
        end
        
        function changedPropertiesStruct = handleSizeLocationPropertyChange(obj, changedPropertiesStruct)
            % Handles change of Position related properties
            % Override of the method defined in
            % PositionableComponentController (runtime)
            
            % Call super first
            changedPropertiesStruct = handleSizeLocationPropertyChange@matlab.ui.control.internal.controller.mixin.PositionableComponentController(obj, changedPropertiesStruct);
            
            % Design time specific business logic
            % This needs to be done after the call to super because the run
            % time method will update Position / InnerPosition /
            % OuterPosition, and the set below relies on those properties
            % being updated
            %
            % To keep Position up to date in the client, need to
            % update it after things like move, resize , etc...
            obj.ViewModel.setProperties({
                'Position', obj.Model.Position, ...
                'InnerPosition', obj.Model.InnerPosition, ...
                'OuterPosition', obj.Model.OuterPosition});
        end
    end
    
    methods
        function excludedProperties = getExcludedPositionPropertyNamesForView(obj)
            % Get the position related properties that should be excluded
            % from the list of properties sent to the view
            
            excludedProperties = getExcludedPositionPropertyNamesForView@matlab.ui.control.internal.controller.mixin.PositionableComponentController(obj);
            
            % The runtime controller removes Position, Inner/OuterPosition.
            % Since those properties need to be sent to the view at design
            % time (e.g. for the inspector), remove those properties from
            % the list of excluded properties
            positionProperties = {...
                'Position', ...
                'InnerPosition', ...
                'OuterPosition', ...
                };
            
            excludedProperties = setdiff(excludedProperties, positionProperties);
        end
    end
end
