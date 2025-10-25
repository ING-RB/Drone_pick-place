classdef DesignTimeListBoxController < ...
        matlab.ui.control.internal.controller.ListBoxController & ...
        appdesigner.internal.componentcontroller.DesignTimeStateComponentController
    %DESIGNTIMELISTBOXCONTROLLER - This class contains design time logic
    %specific to the LISTBOX

    % Copyright 2020-2024 The MathWorks, Inc.


    methods
        function obj = DesignTimeListBoxController(component, parentController, proxyView, adapter)
            obj = obj@matlab.ui.control.internal.controller.ListBoxController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeStateComponentController(component, parentController, proxyView, adapter);
        end

        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.ListBoxController(obj, proxyView);

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

        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view
            %
            % Examples:
            % - Children, Parent, are not needed by the view
            % - Position, InnerPosition, OuterPosition are not updated by
            % the view and are excluded so their peer node values don't
            % become stale

            excludedPropertyNames = {'StyleConfigurations'; 'ValueIndex'};

            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj); ...
            ];

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

        function adjustedProps = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            adjustedProps = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);
            adjustedProps = [adjustedProps, {'SelectedIndex'}];
        end
    end
end

