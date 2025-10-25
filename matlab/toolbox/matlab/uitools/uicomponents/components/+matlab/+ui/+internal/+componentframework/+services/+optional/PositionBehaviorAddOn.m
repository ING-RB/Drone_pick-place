classdef PositionBehaviorAddOn < matlab.ui.internal.componentframework.services.optional.BehaviorAddOn
    %

    %   Copyright 2016-2022 The MathWorks, Inc.
    events 
        PositionFromClientHandled
    end

    methods ( Access=protected )

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      defineViewProperties
         %
         %  Description: Within the context of MVC ( Model-View-Controller )
         %               software paradigm, this is the method the "Controller"
         %               layer uses to define which properties will be consumed by
         %               the web-based user interface.
         %  Inputs:      None
         %  Outputs:     None
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function defineViewProperties( ~, propManagementService )
            % Define model properties that concern the view.
            propManagementService.defineViewProperty( "Position" );
            propManagementService.defineViewProperty( "Units" );

         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      definePropertyDependencies
         %  Description: Within the context of MVC ( Model-View-Controller )
         %               software paradigm, this is the method the "Controller"
         %               layer uses to establish property dependencies between
         %               a property (or set of properties) defined by the "Model"
         %               layer and dependent "View" layer property.
         %  Inputs:      None
         %  Outputs:     None
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function definePropertyDependencies( ~, propManagementService )
            % The constructor of this class calls this method on the derived
            % class. This function needs to exist for correct binding.
            propManagementService.definePropertyDependency( "Units", "Position");
         end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineRequireUpdateProperties
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to establish property which needs updates
        %               before updating them to view.
        %  Inputs:      PropManagementService
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function defineRequireUpdateProperties( ~, propManagementService )
            propManagementService.defineRequireUpdateProperty("Position");
        end
    end

    methods

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:  Constructor
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function this = PositionBehaviorAddOn( propManagementService )
           % Super constructor
           this = this@matlab.ui.internal.componentframework.services.optional.BehaviorAddOn( propManagementService );
         end

         function handled = handleClientPositionEvent(obj, ~, eventStructure, model)
            import matlab.ui.internal.componentframework.services.optional.PositionBehaviorAddOn;

            handled = false;
            switch ( eventStructure.Name )
                case 'insetsChangedEvent'
                    positionStruct = PositionBehaviorAddOn.translateClientInsetsEvent(model, eventStructure);

                    % update the model with the new values
                    % (setPositionFromClient expects the values in pixels)
                    model.setPositionFromClient(eventStructure.Name, ...
                                                       positionStruct.InnerWithOneOrigin, ...
                                                       positionStruct.OuterWithOneOrigin,...
                                                       positionStruct.RefFrameSize);

                     % No need to emit any event for the case of this
                     % component acting as a backing component for
                     % uicontrol since the only component impacted is
                     % uicontrol frame, which has no need for insets
                     % (it cannot host children)

                case 'positionChangedEvent'

                    if ~obj.isPositionFromClientObsolete(model)                       

                        positionStruct = PositionBehaviorAddOn.translateClientPositionEvent(eventStructure);

                        % update the model with the new values
                        model.setPositionFromClient(eventStructure.Name, ...
                                                       positionStruct.InnerWithOneOrigin, ...
                                                       positionStruct.OuterWithOneOrigin,...
                                                       positionStruct.RefFrameSize);

                        % Emit an event so uicontrol can update itself as well,
                        % when the component acts as a backing component for uicontrol.
                        %
                        % Note: Do not emit this event in the case where
                        % the position values are discarded. Otherwise, we
                        % would be updating uicontrol with old values, thus 
                        % overriding the newest value on the component that made 
                        % those values obsolete to begin with. 
                        notify(obj, "PositionFromClientHandled");      
                    end

                    handled = true;
                case 'default'
                    % should we do anything here?
            end

         end

         function isObsolete = isPositionFromClientObsolete(~, model) 
             % TODO: checking for Position_I should be enough since that's
             % the property that is marked dirty
            isObsolete = model.isPropertyMarkedDirty('Position') || model.isPropertyMarkedDirty('Position_I');            
         end

         function newPosValue = updatePosition(obj, model)
            newPosValue = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getUnitsValueDataForView(model);

            unitsForView = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getUnits(newPosValue);
            if (strcmpi(unitsForView, "Pixels"))
                % If the value is in pixels,
                % convert it from (1,1) to (0,0) origin
                pixValue = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getValue(newPosValue);
                zeroOriginValue = obj.convertPixelPositionFromOneToZeroOrigin(pixValue);

                % Put the newly calculated value back into the struct
                newPosValue = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.setValueInUnitsValueDataForView(...
                                                newPosValue, zeroOriginValue);
            end

         end

         function zeroOriginValue = updatePositionInPixels(obj, oneOriginValue)
            zeroOriginValue = obj.convertPixelPositionFromOneToZeroOrigin(oneOriginValue);
         end

    end

    methods (Static, Access = public)

        function positionStruct = translateClientPositionEvent(eventStructure)
            import matlab.ui.internal.componentframework.services.optional.PositionBehaviorAddOn;
            % Ensure inner position was sent in pixels
            innerValUnits = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getUnitsFromUnitsServiceClientEventData(...
                eventStructure, 'InnerPosition');
            assert (strcmpi(innerValUnits, 'Pixels'));

            % Get inner position from the event structure
            innerWithZeroOrigin = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getValueFromUnitsServiceClientEventData(...
                eventStructure, 'InnerPosition');

            % Ensure outer position was sent in pixels
            outerValUnits = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getUnitsFromUnitsServiceClientEventData(...
                eventStructure, 'OuterPosition');
            assert (strcmpi(outerValUnits, 'Pixels'));

            % Get outer position from the event structure
            outerWithZeroOrigin = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getValueFromUnitsServiceClientEventData(...
                eventStructure, 'OuterPosition');

            refFrameSize = [0 0 0 0];

            if (isfield(eventStructure, 'refFrameSize'))
                refFrameSize = [1 1 eventStructure.refFrameSize];
            end

            % Convert from (0,0) to (1,1) origin
            innerWithOneOrigin = PositionBehaviorAddOn.convertPixelPositionFromZeroToOneOrigin(innerWithZeroOrigin);
            outerWithOneOrigin = PositionBehaviorAddOn.convertPixelPositionFromZeroToOneOrigin(outerWithZeroOrigin);

            positionStruct = struct('InnerWithOneOrigin', innerWithOneOrigin, ...
                'OuterWithOneOrigin', outerWithOneOrigin, ...
                'RefFrameSize', refFrameSize ...
            );
        end

        function positionStruct = translateClientInsetsEvent(model, eventStructure)
            insets = eventStructure.insets;

            outerWithOneOrigin = getpixelposition(model);
            innerWithOneOrigin = [...
                outerWithOneOrigin(1) + insets.left, ...
                outerWithOneOrigin(2) + insets.bottom, ...
                max(0, outerWithOneOrigin(3) - (insets.left + insets.right)), ...
                max(0, outerWithOneOrigin(4) - (insets.bottom + insets.top))];
            refFrameSize = [1,1,model.Parent.InnerPosition(3:4)];

            positionStruct = struct('InnerWithOneOrigin', innerWithOneOrigin, ...
                'OuterWithOneOrigin', outerWithOneOrigin, ...
                'RefFrameSize', refFrameSize ...
            );
        end
    end

    methods (Static, Access = protected)

        function valZeroOrigin = convertPixelPositionFromOneToZeroOrigin(pixValue)
            valZeroOrigin = pixValue;
            valZeroOrigin(1) = valZeroOrigin(1) - 1;
            valZeroOrigin(2) = valZeroOrigin(2) - 1;
        end

        function valZeroOrigin = convertPixelPositionFromZeroToOneOrigin(pixValue)
            valZeroOrigin = pixValue;
            valZeroOrigin(1) = valZeroOrigin(1) + 1;
            valZeroOrigin(2) = valZeroOrigin(2) + 1;
        end

    end
end
