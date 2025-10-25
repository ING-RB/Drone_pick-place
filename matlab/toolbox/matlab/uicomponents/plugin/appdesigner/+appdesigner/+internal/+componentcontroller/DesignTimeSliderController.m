classdef DesignTimeSliderController < ...
        matlab.ui.control.internal.controller.SliderController & ...
        appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController
    %DESIGNTIMEINTERACTIVETICKCOMPONENTCONTROLLER - This class contains design time logic
    %specific to components with ticks like the slider
    
    % Copyright 2020-2025 The MathWorks, Inc.
    
    
    methods
        function obj = DesignTimeSliderController(component, parentController, proxyView, adapter)
            obj = obj@matlab.ui.control.internal.controller.SliderController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(component, proxyView, adapter);
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.SliderController(obj, proxyView);
 
            % Destroy the visual comopnent's runtime listeners.  We will
            % not be needing these during design time.
            delete(obj.Listeners);
            obj.Listeners = [];
            
            % Create controllers and design time listeners
            populateView@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(obj, proxyView);
        end

        function adjustedProps = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            adjustedProps = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);
                % If Step is in the list of adjusted properties then we need to account for the StepMode being 'manual' instead of the default 'auto'
                if any(contains(adjustedProps, 'Step'))
                    adjustedProps = [adjustedProps, {'StepMode'}];
                % If the Step property is not set but the Limits property is,
                % then add the Step property to the list of adjusted properties to get the correct Step value
                % since when StepMode is 'auto' the Step property is set based on the Limits (Limits(1)-Limits(0))/1000
                elseif any(contains(adjustedProps, 'Limits'))
                    adjustedProps = [adjustedProps, {'Step'}];
                end
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

