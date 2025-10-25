classdef WebMenuController < matlab.ui.internal.componentframework.WebContainerController
    %WEBMENUCONTROLLER Web-based controller for UIMenu.

    properties
    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebMenuController( model, varargin  )
            obj = obj@matlab.ui.internal.componentframework.WebContainerController( model, varargin{:} );
        end

    end

    methods ( Access = 'protected' )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      postAdd
        %
        %  Description: Custom method for controllers which gets invoked after the
        %               addition of the web component into the view hierarchy.
        %
        %  Inputs :     None.
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function postAdd( obj )

            % Attach a listener for events
            obj.EventHandlingService.attachEventListener( @obj.handleEvent );

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       handleEvent
        %
        %  Description:  handle the MenuItemClicked event from the client
        %
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleEvent( obj, src, event )

            if( obj.EventHandlingService.isClientEvent( event ) )

                eventStructure = obj.EventHandlingService.getEventStructure( event );
                switch ( eventStructure.Name )
                    case 'MenuItemClicked'
                        obj.fireMenuSelectedEvent();
                    otherwise
                        % Now, defer to the base class for common event processing
                        handleEvent@matlab.ui.internal.componentframework.WebComponentController( obj, src, event );
                end

            end

        end

        function fireMenuSelectedEvent(obj)
            contextMenu = ancestor(obj.Model,'uicontextmenu');
            if ~isempty(contextMenu)
                % uimenu in a context menu
                contextMenuController = obj.getControllerFromModel(contextMenu);
                if ~isempty(contextMenuController.MenuSelectedData)
                    obj.Model.notify('MenuSelected',contextMenuController.MenuSelectedData);
                else
                    % If there is no MenuSelectedData, we're on a graphics
                    % canvas, which doesn't support the ContextObject and
                    % InteractionInformation
                    % Call a custom c++ method to fire action callback in GBT 
                    % event chain instead
                    obj.Model.handleActionEventFromClient();
                end
            else
                % Otherwise, uimenu in a menu bar
                % has no ContextObject or InteractionInformation
                % Call a custom c++ method to fire action callback in GBT 
                % event chain instead
                obj.Model.handleActionEventFromClient();
            end
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineViewProperties
        %
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to define which properties will be consumed by
        %               the web-based buser interface.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( obj )

            % Add model properties that concern the view.

            obj.PropertyManagementService.defineViewProperty( 'Label' );
            obj.PropertyManagementService.defineViewProperty( 'Checked' );
            obj.PropertyManagementService.defineViewProperty( 'Enable' );
            obj.PropertyManagementService.defineViewProperty( 'ForegroundColor' );
            obj.PropertyManagementService.defineViewProperty( 'Visible' );
            obj.PropertyManagementService.defineViewProperty( 'Separator' );
            obj.PropertyManagementService.defineViewProperty( 'Accelerator' );
            obj.PropertyManagementService.defineViewProperty( 'Tooltip' );
            obj.PropertyManagementService.defineViewProperty( 'Position' );
        end
    end
end


