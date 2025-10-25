classdef DesignTimePushButtonController < ...
        matlab.ui.control.internal.controller.PushButtonController & ...
        appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController & ...
        appdesigner.internal.componentcontroller.DesignTimeIconHandler
    %DESIGNTIMEPUSHBUTTONCONTROLLER - This class contains design time logic
    %specific to the PushButton
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods
        function obj = DesignTimePushButtonController(component, parentController, proxyView, adapter)
            obj = obj@matlab.ui.control.internal.controller.PushButtonController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(component, proxyView, adapter);
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.PushButtonController(obj, proxyView);
            
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
        
        function handleEvent(obj, src, event)
            % HANDLEEVENT - Implement design-time specific event handling
            % methods.
            
            if strcmp(event.Data.Name, 'PropertyEditorEdited') && strcmp(event.Data.PropertyName, 'Icon')
                
                propertyName = event.Data.PropertyName;
                
                % Validate the inputted Image file
                [fileNameWithExtension, validationStatus, imageRelativePath] = obj.validateImageFile(propertyName, event);
                
                if validationStatus
                    obj.ViewModel.setProperties({'ImageRelativePath', imageRelativePath});
                    % this is an event callback and we're adjusting the 
                    % event data. Since it's called from handleEvent, it's
                    % a client event.
                    obj.handleComponentDynamicDesignTimeProperties(struct('ImageRelativePath', imageRelativePath), true);
                end

                setModelProperty(obj, ...
                    propertyName, ...
                    fileNameWithExtension, ...
                    event ...
                    );
            else
                handleEvent@matlab.ui.control.internal.controller.PushButtonController(obj, src, event);
                
            end
            
        end
        
        function handleDesignTimeEvent(obj, src, event)
            % HANDLEDESIGNTIMEEVENT - Delegates the logic of handling the
            % event to the runtime controllers via the handleEvent method
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