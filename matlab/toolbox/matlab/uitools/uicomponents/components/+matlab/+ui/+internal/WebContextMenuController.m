classdef WebContextMenuController < matlab.ui.internal.componentframework.WebContainerController
    % WEBCONTEXTMENUCONTROLLER Web-based controller for UIContextMenu.

    %   Copyright 2019-2023 The MathWorks, Inc.

    properties (Access = 'private')
        % Counter for showContextMenu function
        showContextMenuCallCount = 0;
    end

    properties
        % Store ContextObject and InteractionInformation for child menu
        % events
        MenuSelectedData
    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebContextMenuController( model, varargin )
            % Constructor
            obj = obj@matlab.ui.internal.componentframework.WebContainerController( model, varargin{:} );
        end

    end

    methods(Access={?matlab.ui.container.ContextMenu})

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      showContextMenu
        %
        %  Description: Show the context menu at the given location
        %
        %  Inputs :     mousePt: the click location in figure device coordinates
        %               target: reference to the element that was right-clicked
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function showContextMenu(obj, mousePt)
            if(~isempty(mousePt))

                % g2504637 - The add child of the view model occurs during the drawnow.
                % We need the add child to occur first on the client side before
                % any dispatch events.
                drawnow nocallbacks;

                % dispatch 'showContextMenu' peerevent
                pvPairs = {'type', 'showContextMenu', 'x', mousePt(1), 'y', mousePt(2)};

                func = @() obj.EventHandlingService.dispatchEvent('peerEvent', pvPairs);
                matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);



                % increment showContextMenuCallCount
                obj.showContextMenuCallCount = obj.showContextMenuCallCount + 1;
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      hideContextMenu
        %
        %  Description: Hide the context menu
        %
        %  Inputs :     None.
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function hideContextMenu(obj)
            % check if Visible property is 'off'
            if (isequal(obj.Model.Visible, 'off'))
                pvPairs = {'type', 'hideContextMenu'};

                func = @() obj.EventHandlingService.dispatchEvent('peerEvent', pvPairs);
                matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);

            end
        end

    end

    methods( Access = 'protected' )

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

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( obj )
            obj.PropertyManagementService.defineViewProperty( 'ObjectID' );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       handleEvent
        %
        %  Description:  handle the Callback event from the client
        %
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleEvent( obj, src, event )

            if( obj.EventHandlingService.isClientEvent( event ) )

                eventStructure = obj.EventHandlingService.getEventStructure( event );
                switch ( eventStructure.Name )
                    case 'ContextMenuOpeningFcn'
                        % The 'ContextMenuOpening' event was already
                        % processed via the context menu target object in 
                        % the mixin, but we need to finish processing it
                        % here to finish up behavior specific to the
                        % context menu itself

                        % The add child of the view model occurs during the drawnow.
                        % We need the add child to occur first on the client side before
                        % any dispatch events.
                        drawnow nocallbacks;

                        % send a peerEvent to the client to confirm that the
                        % callback execution is complete
                        pvPairs = {'type', 'finishedCMOpeningFcnCallback',...
                            'x', eventStructure.ContextMenuPosition.x,...
                            'y', eventStructure.ContextMenuPosition.y};
                        obj.EventHandlingService.dispatchEvent('peerEvent', pvPairs);
                    case 'ContextMenuClosed'
                        if obj.showContextMenuCallCount >= 1
                            % set Visible property to 'off' only when
                            % no additional showContextMenu() calls are
                            % made - g2151721
                            if obj.Model.Visible && obj.showContextMenuCallCount == 1
                                obj.Model.Visible = 'off';
                            end
                            % decrement showContextMenuCallCount
                            obj.showContextMenuCallCount = obj.showContextMenuCallCount - 1;
                            % Clear the stored data
                            obj.MenuSelectedData = [];
                        end
                    otherwise
                        % Now, defer to the base class for common event processing
                        handleEvent@matlab.ui.internal.componentframework.WebComponentController( obj, src, event );
                end
            end

        end

    end

end
