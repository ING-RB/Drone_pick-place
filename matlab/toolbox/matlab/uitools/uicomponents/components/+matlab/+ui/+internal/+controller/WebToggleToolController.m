classdef WebToggleToolController < matlab.ui.internal.controller.WebToolMixinController
    % WebToggleToolController Web-based controller for
    % matlab.ui.container.toolbar.ToggleTool object.

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebToggleToolController(model, varargin )
            %WebToggleToolController Construct an instance of this class
            obj = obj@matlab.ui.internal.controller.WebToolMixinController( model, varargin{:} );
        end

    end

    methods (Access = 'protected')


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       handleEvent
        %
        %  Description:  handle the ToggleToolClicked event from the client
        %
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleEvent( obj, src, event )

            if( obj.EventHandlingService.isClientEvent( event ) )

                eventStructure = obj.EventHandlingService.getEventStructure( event );
                switch ( eventStructure.Name )
                    case 'ToolClicked'
                        obj.fireActionEvent();
                    otherwise
                        % Now, defer to the base class for common event processing
                        handleEvent@matlab.ui.internal.controller.WebToolMixinController( obj, src, event );
                end

            end

        end


        % Call a custom c++ method to fire action callback in GBT event chain
        function fireActionEvent(obj)
            % Update the state in the model accordingly
            % Clicking on the toggle tool switches the State to its
            % opposite value. We need to handle this logic on the server
            % side since relying on a client-side update can result in
            % timing issues.
            if strcmp(obj.Model.State, 'off')
                obj.Model.State = 'on';
            else
                obj.Model.State = 'off';
            end

            % Use startUpdate to push the state change to the view
            matlab.graphics.internal.drawnow.startUpdate;

            % Fire ToolClicked event
            obj.Model.handleToggleToolClickedFromClient();
        end

        % Call a custom c++ method to fire stateChanged in GBT event chain,
        % which handles OnCallback and OffCallback
        function fireStateChanged(obj)
            obj.Model.handleStateChangedFromClient();
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
            defineViewProperties@matlab.ui.internal.controller.WebToolMixinController(obj);
            % Add model properties for the view, specific to the uiToggletool,
            obj.PropertyManagementService.defineViewProperty('State');
        end
    end
end

