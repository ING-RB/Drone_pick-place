% WEBTABCONTROLLER Web-based controller for UITab.
classdef WebTabController < matlab.ui.internal.controller.WebCanvasContainerController
    %

    %   Copyright 2014-2023 The MathWorks, Inc.

    properties(Access = 'protected')
        positionBehavior
        scrollableBehavior
        hasContextMenuBehavior
    end

    methods

        function className = getViewModelType(obj, ~)
            if obj.Model.isInAppBuildingFigure()
                className = 'matlab.ui.container.Tab';
            else
                className = 'matlab.ui.container.LegacyTab';
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebTabController( model, varargin )

            % Super constructor
            obj = obj@matlab.ui.internal.controller.WebCanvasContainerController( model, varargin{:} );

            obj.positionBehavior = matlab.ui.internal.componentframework.services.optional.PositionBehaviorAddOn(obj.PropertyManagementService);
            obj.scrollableBehavior = matlab.ui.internal.componentframework.services.optional.ScrollableBehaviorAddOn(obj.PropertyManagementService, obj.EventHandlingService);
            obj.hasContextMenuBehavior = matlab.ui.internal.componentframework.services.optional.HasContextMenuBehaviorAddOn(obj.PropertyManagementService);
        end

        function add(obj, component, parentController)
            % add Adds this component to the view
            %    add(Controller, Component, ParentController) adds the Controller
            %    whose model is Component underneath the component who's controller
            %    is ParentController.
            add@matlab.ui.internal.controller.WebCanvasContainerController(obj, component, parentController);
            parentController.triggerUpdateOnDependentViewProperty('SelectedTab');
        end

        function attachPropertyListeners( obj )

            obj.EventHandlingService.attachPropertyListeners( @obj.handlePropertyUpdate, ...
                @obj.handlePropertyDeletion );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updatePosition
        %
        %  Description: Method invoked when the model's Position property changes.
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newPosValue = updatePosition( obj )
            % Always called at initialization
            % Does not seem to make any difference...
            % @TODO probably we need to investigate why the model sets the prop
            oneOriginPosValue = obj.Model.Position;
            newPosValue = obj.positionBehavior.updatePositionInPixels(oneOriginPosValue);
        end

        function newUnitsValue = updateUnits( obj )
            newUnitsValue = obj.positionBehavior.updateUnits(obj.Model);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateScrollTarget
        %
        %  Description: Converts the ScrollTarget property to a view-compatible value
        %
        %  Outputs:     Value to be set on the view model
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = updateScrollTarget( obj )
            result = obj.scrollableBehavior.updateScrollTarget( obj.Model );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      updateContextMenuID
        %
        %  Description: Method invoked when Tab UIContextMenu property changes.
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function newContextMenuID = updateContextMenuID( obj )
            newContextMenuID = obj.hasContextMenuBehavior.updateContextMenuID(obj.Model.UIContextMenu);
        end

        function interactionObject = constructInteractionObject(obj, interactionInformation)
            % CONSTRUCTINTERACTIONOBJECT - Add any InteractionInformation
            % that is specific to this component.
            interactionObject = constructInteractionObject@matlab.ui.internal.componentframework.WebComponentController(obj, interactionInformation);
        end

        function newInteractionInformation = addComponentSpecificInteractionInformation(obj, interactionInformation, eventdata)
            % ADDCOMPONENTSPECIFICINTERACTIONINFORMATION - Construct the object
            %  to be used with InteractionInformation.
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

            % Add model properties specific to the panel, then call super
            obj.PropertyManagementService.defineViewProperty( 'BackgroundColor' );
            obj.PropertyManagementService.defineViewProperty( 'ForegroundColor' );
            obj.PropertyManagementService.defineViewProperty( 'FontName' );
            obj.PropertyManagementService.defineViewProperty( 'FontWeight' );
            obj.PropertyManagementService.defineViewProperty( 'FontAngle' );
            obj.PropertyManagementService.defineViewProperty( 'Tag' );
            obj.PropertyManagementService.defineViewProperty( 'Title' );
            obj.PropertyManagementService.defineViewProperty( 'AutoResizeChildren' );
            obj.PropertyManagementService.defineViewProperty( 'Tooltip' );

            defineViewProperties@matlab.ui.internal.controller.WebCanvasContainerController( obj );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function definePropertyDependencies( obj )
            definePropertyDependencies@matlab.ui.internal.controller.WebCanvasContainerController( obj );
        end


        function handleEvent( obj, src, event )

            if( obj.EventHandlingService.isClientEvent( event ) )
                eventStructure = obj.EventHandlingService.getEventStructure( event );
                handled = obj.positionBehavior.handleClientPositionEvent( src, eventStructure, obj.Model );
                if ~handled
                    handled = obj.scrollableBehavior.handleClientScrollEvent( src, eventStructure, obj.Model );
                end
                if ~handled
                    handled = obj.hasContextMenuBehavior.handleEvent(obj, obj.Model, src, eventStructure);
                end
                if (~handled)
                    % Now, defer to the base class for common event processing
                    handleEvent@matlab.ui.internal.controller.WebCanvasContainerController( obj, src, event );
                end

            end

        end

        

    end

end
