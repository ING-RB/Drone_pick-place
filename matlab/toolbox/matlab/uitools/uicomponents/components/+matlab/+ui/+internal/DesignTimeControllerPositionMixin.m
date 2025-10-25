classdef DesignTimeControllerPositionMixin < handle
    % DesignTimeControllerPositionMixin is position mixin class for
    % design time controllers, which encapsulates design-time position
    % behaviors. 
    % This mixin class is for use by the HMI/Standard components' 
    % design time controllers.  It also serves as a base class for the
    % design time controller position mixin class used by the GBT components.
    
    % Copyright 2016-2025 The MathWorks, Inc. 
    
    properties (Access='private')
        Model;
    end
    
    methods
        %Constructor
        function obj = DesignTimeControllerPositionMixin(model, ~ ...
                )
            obj.Model = model;
        end
        
        function excludedProperties = getExcludedPositionPropertyNamesForView(obj)
            % Get the position related properties that should be excluded
            % from the list of properties sent to the view
            
            % The view only updated Size/Location.
            % Remove Position, Inner/OuterPosition otherwise their peer
            % node value will become stale and also potentially trigger
            % unwanted propertiesSet events (g1396296)
            excludedProperties = matlab.ui.control.internal.controller.mixin.PositionPropertiesComponentController.getExcludedPositionPropertyNamesForView();
            
            % The runtime controller removes Position, Inner/OuterPosition.
            % Since those properties need to be sent to the view at design
            % time (e.g. for the inspector), remove those properties from
            % the list of excluded properties
            positionPropertiesToBeIncludedAtDesignTime = {...
                'Position', ...
                'InnerPosition', ...
                'OuterPosition', ...
                };
            
            excludedProperties = setdiff(excludedProperties, positionPropertiesToBeIncludedAtDesignTime);
        end
        
    end    
    
    methods (Access = 'protected')
        
        function updatePositionWithSizeLocationPropertyChanges(obj, changedPropertiesStruct)
            propertyList = fields(changedPropertiesStruct);
            
            % Start by building up varaibles with the existing positional
            % state of the model, and then walk through the changed properties and
            % update each variable to the new state.
            newPosition = obj.Model.Position;

            % Update each variable by looking at the changed properties
            for idx = 1:length(propertyList)
                propertyName = propertyList{idx};
                propertyValue = changedPropertiesStruct.(propertyName);

                % Look for specific property changes
                % At this point, all GBT components are such that
                % InnerPosition == OuterPosition for the purpose of
                % AppDesigner (see getSizeLocationPropertiesForView in
                % DesignTimeGBTControllerPositionMixin).
                switch(propertyName)                    

                    case 'Location'
                        newPosition(1:2) = propertyValue;

                    case 'Size'
                        newPosition(3:4) = propertyValue;
                        
                    case 'OuterLocation'
                        newPosition(1:2) = propertyValue;

                    case 'OuterSize'
                        newPosition(3:4) = propertyValue;

                end
            end

            % TODO: Cannot use setPositionFromClient method, because
            % current all position related property sets for GBT
            % components resolve to Position.  Will need to distinguish
            % between inner and outer.

            % turn off the warning information when setting position to component inside grid.
            previousWarning = warning('off', 'MATLAB:ui:components:noPositionSetWhenInLayoutContainer');
            obj.Model.Position = newPosition;
            warning(previousWarning);

            % when resizing panel in grid, we will update size and location from clientside.
            % and then the position of the panel wil be calcuated this method and then we will send the 
            % value of position back to server side to update the position property in the peerNode of panel.
            % however, the model does not accpet the value updating of position if it's child of grid, therefore
            % we need to use newPosition as the value to send back to client just to make sure client will get the
            % correct position value.
            obj.ViewModel.setProperty('Position', newPosition);
        end
        
        function changedPropertiesStruct = handleSizeLocationPropertyChange(obj, changedPropertiesStruct)
            propertyList = fields(changedPropertiesStruct);
            
            % Look for specific Size / Location - related properties
            positionRelatedProperties = {
                'Size', ...
                'Location',...
                'OuterSize', ...
                'OuterLocation',...
                };
            if(any(ismember(positionRelatedProperties, propertyList)))
                obj.updatePositionWithSizeLocationPropertyChanges(changedPropertiesStruct);
                
                % Remove properties that were handled
                handledPropertiesLogicalMap = isfield(changedPropertiesStruct, positionRelatedProperties);
                handledPropertyNames = positionRelatedProperties(handledPropertiesLogicalMap);

                % Return the unhandled properties
                changedPropertiesStruct = rmfield(changedPropertiesStruct, handledPropertyNames);
                
                % g1497198: Remove Position property because App Designer 
                % client side doesn't maintain it when pasting/duplicating,
                % and hence its value could be obselete, only ensuring
                % Location/OuterLocation/Size/OuterSize correct
                % Todo: in long term, client side should move to Position 
                % or update its value correct accordingly.
                % Since component is client-driven, it's good to make sure 
                % the property/value sent to server side is correct.
                % At least, in the AddComponentCommand.js, client side 
                % already tries to ensure Position keeping updated with 
                % Location/Size to ensure Position is available as well (for Inspector)
                % For other cases: moving/resizing, client side will only 
                % send Location/OuterLocation/Size/OuterSize
                % to the server for property updating.
                % For loading, server side model already has the correct 
                % property value by reusing the de-serialized object, no
                % property updating request from client side
                if isfield(changedPropertiesStruct, 'Position')
                    changedPropertiesStruct = rmfield(changedPropertiesStruct, 'Position');
                end
            end
            
        end

        function handlePositionUpdate(obj, propertyName, propertyValue)
            % Turn off the warning information when setting position to component inside grid.
            previousWarning = warning('off', 'MATLAB:ui:components:noPositionSetWhenInLayoutContainer');
            oc = onCleanup(@() warning(previousWarning));
            
            switch propertyName
                case {'Location', 'OuterLocation'}
                    % g3546375: Don't update the Position or View Model
                    % properties if there is no change
                    if all(obj.Model.Position(1:2) == propertyValue(1:2))
                        return
                    end
                    obj.Model.Position(1:2) = propertyValue(1:2);

                    obj.ViewModel.setProperty('Position', obj.Model.Position);
                    obj.ViewModel.setProperty('Location', obj.Model.Position(1:2));
                    obj.ViewModel.setProperty('OuterLocation', obj.Model.Position(1:2));
                    
                case {'Size', 'OuterSize'}
                    % g3546375: Don't update the Position or View Model
                    % properties if there is no change
                    if all(obj.Model.Position(3:4) == propertyValue(1:2))
                        return
                    end
                    % @TODO
                    % We should not be clobbering the outer size (Position property)
                    % with the incoming inner size--this may result in the
                    % wrong values
                    obj.Model.Position(3:4) = propertyValue(1:2);

                    obj.ViewModel.setProperty('Position', obj.Model.Position);
                    obj.ViewModel.setProperty('Size', obj.Model.Position(3:4));
                    obj.ViewModel.setProperty('OuterSize', obj.Model.Position(3:4));
            end
        end
    end
end
