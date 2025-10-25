classdef DesignTimeStateComponentController < ...
        matlab.ui.control.internal.controller.StateComponentController & ...
        appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController
    % DESIGNTIMESTATECOMPONENTCONTROLLER - This class contains design time logic
    % specific to components like the drop down

    % Copyright 2020-2024 The MathWorks, Inc.

    methods
        function obj = DesignTimeStateComponentController(component, parentController, proxyView, adapter)
            obj = obj@matlab.ui.control.internal.controller.StateComponentController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(component, proxyView, adapter);

            % If ItemsData is numeric and is not empty, add ItemsData and
            % Value to NumericProperties (g3530945)
            if (isnumeric(component.ItemsData) && ~isempty(component.ItemsData))
                obj.addItemsDataAndValueToNumericProperties();
            end
        end

        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.StateComponentController(obj, proxyView);

            % Destroy the visual comopnent's runtime listeners.  We will
            % not be needing these during design time.
            delete(obj.Listeners);
            obj.Listeners = [];

            % Create controllers and design time listeners
            populateView@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(obj, proxyView);
        end

        function adjustedProperties = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            adjustedProperties = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);
            % Ensures AspectRatioLimits is sent
            adjustedProperties = [adjustedProperties, {'AspectRatioLimits'}];
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
            % event to the runtime controllers via the handleEvent method.

            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                % Handle changes in the property editor that needs a
                % server side validation.  Use the handlePropertyEditorEdited
                % method to make this testable (g2159503).

                wasHandled = obj.handlePropertyEditorEdited(src, event);

                if (wasHandled)
                    return;
                end
            end

            % Defer to super otherwise
            % The property edit does not need to be specially handled
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

        function wasHandled = handlePropertyEditorEdited(obj, src, event)
            % HANDLEPROPERTYEDITOREDITED - Handle the property editor
            % edited event.  Determine if the edits need a server
            % evaluation.

            wasHandled = false;

            propertyName = event.Data.PropertyName;
            propertyValue = event.Data.PropertyValue;

            if(any(strcmp(propertyName, {'Value', 'Items'})))

                if(isempty(propertyValue) && isnumeric(propertyValue))
                    % g1416534
                    %
                    % Note if g1426526 is fixed, then this assumption
                    % that value needs {} and not [] may break.
                    propertyValue = {};

                    % Update the event data in line
                    setModelProperty(obj, ...
                        propertyName, ...
                        propertyValue, ...
                        event ...
                        );
                    wasHandled = true;
                end


            elseif(any(strcmp(propertyName, {'ItemsData'})))
                % g2159503 and g2060936.  If the PropertyValue for ItemsData
                % is a 1x1 cellstr, try to convert it to numeric values.
                % If it can be converted successfully to a numeric,
                % assign the numeric result to the ItemsData property.  If not,
                % proceed as usual by defering to the superclass.

                if(length(propertyValue)==1 && iscellstr(propertyValue)) %#ok<ISCLSTR>

                    propertyValueConvertedToArray = str2num(propertyValue{1}); %#ok<ST2NM>

                    if ~isempty(propertyValueConvertedToArray)
                        setModelProperty(obj, ...
                            propertyName, ...
                            propertyValueConvertedToArray, ...
                            event ...
                            );

                        wasHandled = true;

                        obj.addItemsDataAndValueToNumericProperties();
                    else
                        obj.removeItemsDataAndValueFromNumericProperties();
                    end
                else
                    obj.removeItemsDataAndValueFromNumericProperties();
                end

            end
        end

        function excludedProperties = getExcludedPositionPropertyNamesForView(obj)
            % Get the position related properties that should be excluded
            % from the list of properties sent to the view

            excludedProperties = {'ValueIndex'};

            excludedProperties = [excludedProperties; ...
                getExcludedPositionPropertyNamesForView@matlab.ui.control.internal.controller.mixin.PositionableComponentController(obj); ...
            ];

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

    methods(Access = private)
        function addItemsDataAndValueToNumericProperties(obj)
            % If ItemsData is assigned a double value, add it to the list of Numeric Properties.
            % This ensures the Value property is converted to a number before assigning the value to Model.
            if (~any(ismember(obj.NumericProperties, 'ItemsData')))
                obj.NumericProperties{end + 1} = 'ItemsData';
            end
            if (~any(ismember(obj.NumericProperties, 'Value')))
                obj.NumericProperties{end + 1} = 'Value';
            end
        end

        function removeItemsDataAndValueFromNumericProperties(obj)
            obj.NumericProperties(ismember(obj.NumericProperties,'ItemsData')) = [];
            obj.NumericProperties(ismember(obj.NumericProperties, 'Value')) = [];
        end
    end
end