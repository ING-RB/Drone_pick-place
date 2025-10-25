% WEBUICONTAINERCONTROLLER Web-based controller for UIContainer.
classdef WebUIContainerController < matlab.ui.internal.controller.WebCanvasContainerController
    %

    %   Copyright 2019-2023 The MathWorks, Inc.

    events (NotifyAccess = 'protected')
        PositionFromClientHandled
    end

    properties(Access = 'protected')
        positionBehavior
        layoutBehavior
        hasContextMenuBehavior
    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebUIContainerController( model, varargin  )

            % Super constructor
            obj = obj@matlab.ui.internal.controller.WebCanvasContainerController( model, varargin{:} );
            obj.positionBehavior = matlab.ui.internal.componentframework.services.optional.PositionBehaviorAddOn(obj.PropertyManagementService);
            addlistener(obj.positionBehavior, 'PositionFromClientHandled', @obj.handlePositionFromClientHandled);
            obj.layoutBehavior = matlab.ui.internal.componentframework.services.optional.LayoutBehaviorAddOn(obj.PropertyManagementService);
            obj.hasContextMenuBehavior = matlab.ui.internal.componentframework.services.optional.HasContextMenuBehaviorAddOn(obj.PropertyManagementService);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updatePosition
        %
        %  Description: Method invoked when panel position changes.
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newPosValue = updatePosition( obj )
            newPosValue = obj.positionBehavior.updatePosition(obj.Model);
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateLayoutConstraints
        %
        %  Description: Method invoked when panel Layout Constraints change.
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function constraintsStruct = updateLayoutConstraints( obj )
            constraintsStruct = obj.layoutBehavior.updateLayout(obj.Model.Layout);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateContextMenuID
        %
        %  Description: Method invoked when panel UIContextMenu property changes.
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newUIContextMenu = updateContextMenuID( obj )

            newUIContextMenu = obj.hasContextMenuBehavior.updateContextMenuID(obj.Model.UIContextMenu);
        end

        function className = getViewModelType(obj, ~)
            if obj.Model.isInAppBuildingFigure()
                className = 'matlab.ui.container.internal.UIContainer';
            else
                className = 'matlab.ui.container.internal.LegacyUIContainer';
            end
        end

        function interactionObject = constructInteractionObject(obj, interactionInformation)
            % CONSTRUCTINTERACTIONOBJECT - Construct the object to be used
            % with InteractionInformation.
            interactionObject = constructInteractionObject@matlab.ui.internal.componentframework.WebComponentController(obj, interactionInformation);
        end

        function newInteractionInformation = addComponentSpecificInteractionInformation(obj, interactionInformation, eventdata)
            % ADDCOMPONENTSPECIFICINTERACTIONINFORMATION - Add any
            % InteractionInformation that is specific to this component.
            newInteractionInformation = addComponentSpecificInteractionInformation@matlab.ui.internal.componentframework.WebComponentController(obj, interactionInformation, eventdata);
        end

    end

    methods( Access = 'protected' )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( obj )
            defineViewProperties@matlab.ui.internal.controller.WebCanvasContainerController( obj );
            obj.PropertyManagementService.defineViewProperty('Visible');
            obj.PropertyManagementService.defineViewProperty('BackgroundColor');
        end


        function handleEvent( obj, src, event )

            if( obj.EventHandlingService.isClientEvent( event ) )

                eventStructure = obj.EventHandlingService.getEventStructure( event );
                handled = obj.positionBehavior.handleClientPositionEvent( src, eventStructure, obj.Model);
                if (~handled)
                    handled = obj.hasContextMenuBehavior.handleEvent(obj, obj.Model, src, eventStructure);
                end
                if (~handled)
                    % Now, defer to the base class for common event processing
                    handleEvent@matlab.ui.internal.controller.WebCanvasContainerController( obj, src, event );
                end
            end

        end

        function handlePositionFromClientHandled(obj, ~, ~)
            % Just re-emit the event so uicontrol can update itself as well,
            % when this acts as a backing component for uicontrol.
            notify(obj, "PositionFromClientHandled");
        end

    end

end

