classdef (Hidden) PositionableComponentController < ...
        appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % Mixin Controller Class for components with Size, Location, OuterSize,
    % OuterLocation, AspectRatioLimits

    % Copyright 2011-2016 The MathWorks, Inc.

    events (NotifyAccess = 'protected')
        PositionFromClientHandled
    end

    properties (Constant)
        PositionRelatedProperties = [
            "Size", ...
            "Location",...
            "OuterSize", ...
            "OuterLocation",...
            ];
    end

    methods

        function additionalProperties = getAdditonalPositionPropertyNamesForView(obj)
            additionalProperties = matlab.ui.control.internal.controller.mixin.PositionPropertiesComponentController.getAdditonalPositionPropertyNamesForView(obj.Model);
        end

        function viewPvPairs = getPositionPropertiesForView(obj, propertyNames)
            viewPvPairs = matlab.ui.control.internal.controller.mixin.PositionPropertiesComponentController.getPositionPropertiesForView(obj.Model, propertyNames);
        end

        function excludedProperties = getExcludedPositionPropertyNamesForView(obj)
            % Get the position related properties that should be excluded
            % from the list of properties sent to the view

            % The view only updated Size/Location.
            % Remove Position, Inner/OuterPosition otherwise their peer
            % node value will become stale and also potentially trigger
            % unwanted propertiesSet events (g1396296)
            excludedProperties = {...
                'Position'; ...
                'InnerPosition'; ...
                'OuterPosition'; ...
                };
        end


    end

    methods (Access = 'protected')

        function wasHandled = handleEvent(obj, ~, event)
            % HANDLEEVENT is invoked each time a component is repositioned.
            % It allows the view to send the exact position of the inner and/or
            % outer art of the component to the model after the component
            % is repositioned.

            % Flag to keep track if the edit was handled by this controller
            %
            % Returned to caller so that same event is not processed twice
            wasHandled = false;
            switch event.Data.Name
                case 'PropertyEditorEdited'

                    propertyName = event.Data.PropertyName;
                    propertyValue = event.Data.PropertyValue;

                    if(strcmp(propertyName, 'Position'))

                        propertyValue = convertClientNumbertoServerNumber(obj, propertyValue);

                        setModelProperty(obj, propertyName, propertyValue, event);
                        wasHandled = true;

                    end

                case 'SizeLocationChanged'
                    % At runtime, position related properties are updated via an event
                    changedPropertiesStruct = event.Data;
                    changedProperties = string(fieldnames(changedPropertiesStruct));

                    % Look for specific Size / Location - related properties
                    if(any(appdesservices.internal.util.ismemberForStringArrays(obj.PositionRelatedProperties, changedProperties)))
                        handleSizeLocationPropertyChange(obj, changedPropertiesStruct);
                    end
            end

        end

        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handles Position - related properties changing and
            % Orientation changing

            % List of properties that changed
            changedProperties = fieldnames(changedPropertiesStruct);

            % Note this is order dependent, Orientation should be handled
            % first
            if(any(strcmp('Orientation', changedProperties)))
                changedPropertiesStruct = handleOrientationPropertyChange(obj, changedPropertiesStruct);
            end

            % Handle Position related properties
            %
            % Ignore the properties Position/InnerPosition/OuterPosition
            % because they are not updated by the view.
            % The view only updates the size/location properties.
            % However, they are still sent from the view when you DnD a new
            % component in the canvas (with non-updated values).
            propertiesToIgnore = {
                'Position',...
                'InnerPosition',...
                'OuterPosition',...
                };
            ignoredPropertiesIndices = isfield(changedPropertiesStruct, propertiesToIgnore);
            ignoredProperties = propertiesToIgnore(ignoredPropertiesIndices);
            changedPropertiesStruct = rmfield(changedPropertiesStruct, ignoredProperties);

            % Updated list of properties that changed
            changedProperties = string(fieldnames(changedPropertiesStruct));

            import appdesservices.internal.util.ismemberForStringArrays;
            % Look for specific Size / Location - related properties
            if(any(ismemberForStringArrays(obj.PositionRelatedProperties, changedProperties)))
                changedPropertiesStruct = handleSizeLocationPropertyChange(obj, changedPropertiesStruct);
            end

        end

    end

    methods(Access = 'protected')
        function changedPropertiesStruct =  handleOrientationPropertyChange(obj, changedPropertiesStruct)
            % While 'Orientation' is not common to all components, the best
            % way to share code amongst orientable gauges and switches was
            % to put that code here.

            % Orientation has changed
            %
            % In the Case of Orientation changing, then updated Size /
            % OuterSize values should also be sent to the model
            newOrientation = changedPropertiesStruct.Orientation;

            % Update the component
            obj.Model.handleOrientationChanged(newOrientation);

            % Mark orientation as handled
            changedPropertiesStruct = rmfield(changedPropertiesStruct, 'Orientation');

            % Properties that changed
            changedProperties = fieldnames(changedPropertiesStruct);

            % If the orientation changes from a "wider than tall"
            % to a "taller than wide" form factor (or vice versa), the
            % size constraints might need to be updated.
            % Note: when either AspectRatioLimits or IsSizeFixed is not
            % changed, it is filtered out by the peer node layer so we
            % need to update them separately
            if(any(strcmp('AspectRatioLimits', changedProperties)))
                newAspectRatioLimits = convertClientNumbertoServerNumber(obj, changedPropertiesStruct.AspectRatioLimits);
                obj.Model.handleAspectRatioLimitsChange(newAspectRatioLimits);

                % Mark the properties as handled
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'AspectRatioLimits');
            end

            if(any(strcmp('IsSizeFixed', changedProperties)))
                newIsSizeFixed = changedPropertiesStruct.IsSizeFixed;
                obj.Model.handleIsSizeFixedChange(newIsSizeFixed);

                % Mark the properties as handled
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'IsSizeFixed');
            end

        end

        function changedPropertiesStruct = handleSizeLocationPropertyChange(obj, changedPropertiesStruct)
            % Handles change of Position related properties

            import matlab.ui.control.internal.controller.mixin.PositionableComponentController;

            if obj.isPositionFromClientObsolete()
                % A new InnerPosition value is about to be sent to the
                % view.
                % Do not process the OuterLocation and/or OuterSize coming
                % back from the client side since they are already obsolete
                % and will be replaced by a new value.
                % Not updating the model with a obsolete value prevents a bug
                % where, when the controller is ready to send values to the
                % view, the controller grabs the obsolete value from the
                % model. 
                % g2433494.
                if isfield(changedPropertiesStruct, "OuterLocation")
                    changedPropertiesStruct = rmfield(changedPropertiesStruct,"OuterLocation");
                end
                if isfield(changedPropertiesStruct, "OuterSize")
                    changedPropertiesStruct = rmfield(changedPropertiesStruct,"OuterSize");
                end

            else
                
                [newInnerPosition, newOuterPosition] = PositionableComponentController.translatePositionEvent(obj.Model, changedPropertiesStruct);

                % Take the updated variables and update the component
                %
                % Note: When we transition Button to using the GBT position
                % mixin, we will need to revisit the call to
                % setPositionFromClient for the button because it causes an
                % assertion failure, see g1515620
                obj.Model.setPositionFromClient("positionChangedEvent", newInnerPosition, newOuterPosition);

                % Emit an event so uicontrol can update itself as well,
                % when this acts as a backing component for uicontrol.
                %
                % Note: Do not emit this event in the case where
                % OuterLocation / OuterSize were discarded. Otherwise, we
                % would be updating uicontrol with old values, thus 
                % overriding the new value that marked the component dirty
                % to begin with. 
                notify(obj, "PositionFromClientHandled");           
            end

            % return changedPropertiesStruct only if necessary
            if nargout > 0
                % Remove properties that were handled
                handledPropertiesLogicalMap = isfield(changedPropertiesStruct, obj.PositionRelatedProperties);
                handledPropertyNames = obj.PositionRelatedProperties(handledPropertiesLogicalMap);

                % Return the unhandled properties
                changedPropertiesStruct = rmfield(changedPropertiesStruct, handledPropertyNames);
            end
        end 

        function isObsolete = isPositionFromClientObsolete(obj)
            isObsolete = obj.Model.isPropertyMarkedDirty("InnerPosition");
        end

    end

    methods (Static, Access = public)

        function [newInnerPosition, newOuterPosition] = translatePositionEvent(model, changedPropertiesStruct)
            import matlab.ui.control.internal.controller.mixin.PositionableComponentController;
            % This handler makes an assumption that the model has both
            % InnerPosition and OuterPosition.  Verify before moving
            % forward.

            % Start by building up varaibles with the existing positional
            % state of the model, and then walk through the changed properties and
            % update each variable to the new state.
            newInnerPosition = model.InnerPosition;
            newOuterPosition = model.OuterPosition;

            % List of properties that changed
            changedProperties = string(fieldnames(changedPropertiesStruct));

            % Update each variable by looking at the changed properties
            for idx = 1:length(changedProperties)
                propertyName = changedProperties{idx};
                propertyValue = changedPropertiesStruct.(propertyName);

                % Look for specific property changes
                switch(propertyName)

                    case 'Location'
                        newInnerPosition(1:2) = PositionableComponentController.getPositionValue(propertyValue);
                    case 'Size'
                        newInnerPosition(3:4) = PositionableComponentController.getPositionValue(propertyValue);
                    case 'OuterLocation'
                        newOuterPosition(1:2) = PositionableComponentController.getPositionValue(propertyValue);
                    case 'OuterSize'
                        newOuterPosition(3:4) = PositionableComponentController.getPositionValue(propertyValue);
                end
            end
        end

        function val = getPositionValue(value)
            val = value;
            if isstruct(value) && isfield(value, 'Value')
                val = value.Value;
            end
        end

        function units = getPositionUnits(model)
            if isprop(model, 'Units') && strcmp(model.Units, 'normalized')
                units = 'normalized';
            else
                units = 'pixels';
            end
        end
    end
end
