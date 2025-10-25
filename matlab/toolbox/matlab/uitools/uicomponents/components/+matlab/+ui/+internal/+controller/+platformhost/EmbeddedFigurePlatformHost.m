classdef EmbeddedFigurePlatformHost < matlab.ui.internal.controller.platformhost.FigurePlatformHost

    % FigurePlatformHost class containing the Embedded platform-specific functions for
    % the matlab.ui.internal.controller.FigureController object

    % Copyright 2018-2020 The MathWorks, Inc.

    properties (Access = protected)
        ReleaseHTMLFile = 'webAppsComponentContainer.html';
    end

    properties (Access = private)
        isDrawnowSyncEnabled = false;   % drawnow synchronizarion is initially disabled
        SubscriptionId  % message subscription ID, for receipt of messages from client
        CtsChannel = '/cts';    % client to server channel, initialized for testing purposes
        StcChannel = '/stc';    % server to client channel, initialized for testing purposes
        Position = [1 1 0 0];    % figure Position, to help prevent repeated updates of equal sizes (only w & h used)
		Resizable	% is Figure resizable? needed to help prevent circular/superfluous setting
        Title       % Figure Title/Name needed to help prevent circular/superfluous setting
        figUuid              

    end % private properties

    methods (Access = public)

        % constructor
        function this = EmbeddedFigurePlatformHost(updatesFromClientImpl)
            this = this@matlab.ui.internal.controller.platformhost.FigurePlatformHost(updatesFromClientImpl);
        end % constructor

        % destructor
        function delete(this)            

            if (~isempty(this.SubscriptionId))
                figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
                figureLifecycleController.removeFigure(this.figUuid);
                message.unsubscribe(this.SubscriptionId);
                % don't do the following during response to a viewKilled msg from the client
                message.publish(this.StcChannel, struct('eventType', 'windowClosed'));
            end
        end % delete()

        % isDrawnowSyncSupported() - platform-specific function to return whether or not
        % drawnow synchronization is currently supported
        function status = isDrawnowSyncSupported(this)
            status = this.isDrawnowSyncEnabled && this.Visible;
        end

        %
        % methods delegated to by FigureController and implemented by this FigurePlatformHost child class
        %

        % createView() - perform platform-specific view creation operations
        function createView(this, peerModelInfo, pos, title, visible, resizable, ~, ~, figUuid)

            %delegate common processing to base class
            this.createView@matlab.ui.internal.controller.platformhost.FigurePlatformHost(peerModelInfo, visible);

            % store initial property values
			this.Position = pos;
            this.Resizable = resizable;
            this.Title = title;
            this.Visible = visible;            

            % get the packet containing information for setting up client-server communications
            differentiators = matlab.ui.internal.FigureServices.getChannelDifferentiators();

            % extract the MessageService channel Ids, making them unique by appending the peerModel Channel
            this.CtsChannel = strcat(differentiators.ClientToServer, peerModelInfo.PeerModelChannel);
            this.StcChannel = strcat(differentiators.ServerToClient, peerModelInfo.PeerModelChannel);

			% subscribe on the channel to handle messages coming from the client
			this.SubscriptionId = message.subscribe(this.CtsChannel, @(data)this.handleMessage(data));
			% N.B. subscription id is documented to be a String but is actually a uint64 as of Feb 2018

            this.figUuid = figUuid;
            figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
            figureLifecycleController.addFigure(figUuid, this);
        end % createView()

        % getHostType() - return platform-specific host type
        function hostType = getHostType(~)
            hostType = 'embeddedclient';
        end

        % updateResize() - platform-specific supplement to FigureController.updateResize()
        function updateResize(this, newResizable)
            if ~isempty(this.SubscriptionId)
                if ~isequal(this.Resizable, newResizable)
                    this.Resizable = newResizable;
                    message.publish(this.StcChannel, struct('eventType', 'Resize', 'value', newResizable));
                end
            end
        end % updateResize()

        % updateTitle() - platform-specific supplement to FigureController.updateTitle()
        function updateTitle(this, newTitle)
            if ~isempty(this.SubscriptionId)
                if ~isequal(this.Title, newTitle)
                    this.Title = newTitle;
                    message.publish(this.StcChannel, struct('eventType', 'Title', 'value', newTitle));
                end
            end
        end % updateTitle()

        % updateVisible() - platform-specific supplement to FigureController.updateVisible()
        function updateVisible(this, newVisible)
            if ~isempty(this.SubscriptionId)
                if ~isequal(this.Visible, newVisible)
                    this.Visible = newVisible;
                    message.publish(this.StcChannel, struct('eventType', 'Visible', 'value', newVisible));
                end
            end
        end % updateVisible()

        % toFront() - platform-specific supplement to FigureController.toFront()
        function toFront(this)
            if ~isempty(this.SubscriptionId)
                message.publish(this.StcChannel, struct('eventType', 'windowToFront'));
            end
        end        
    end % public methods

    methods (Access = protected)
        % updatePositionImpl() - platform-specific supplement to FigureController.updatePosition()
        function updatePositionImpl(this, newPos)
            if ~isempty(this.SubscriptionId)
                % Set Position only if it differs from current Position (g1429917)
                % Only deal with width and height, as we do not yet support undocked figures
                if ~isequal(this.Position(3), newPos(3)) || ~isequal(this.Position(4), newPos(4))
                    this.Position(3) = newPos(3);
                    this.Position(4) = newPos(4);
                    message.publish(this.StcChannel, struct('eventType', 'Position', 'value', this.Position));
                end
            end
        end % updatePositionImpl()
    end % protected methods

    methods (Access = { ?matlab.ui.internal.controller.FigureLifecycleController, ?tEmbeddedFigurePlatformHost }) % ToDo: Remove code smell: Test code in production

        % handleMessage() - handle messages sent by client
        function handleMessage(this, data)
            try
                if strcmpi(data.eventType, 'clientReady')
                    this.isDrawnowSyncEnabled = true;
                    this.UpdatesFromClientImpl.updateDrawnowSyncReady(this.isDrawnowSyncSupported());
                    % send windowOpen message if widget has not already been added to the DOM
                    if ~strcmpi(data.value, 'added')
                        message.publish(this.StcChannel, struct('Position', this.Position, ...
                        'Resize', this.Resizable, 'Title', this.Title, 'Visible', this.Visible, 'eventType', 'windowOpen'));
                    end
                elseif strcmpi(data.eventType, 'figureActivated')
					this.UpdatesFromClientImpl.figureActivated(); % react to window activation on client
                elseif strcmpi(data.eventType, 'figureDeactivated')
					this.UpdatesFromClientImpl.figureDeactivated(); % react to window deactivation on client
                elseif strcmpi(data.eventType, 'windowClosed')
					this.UpdatesFromClientImpl.windowClosed(); % execute CloseRequestFcn on Model
                elseif strcmpi(data.eventType, 'viewKilled')
                    message.unsubscribe(this.SubscriptionId); % unsubscribe from the figure-specific channel
					this.UpdatesFromClientImpl.onViewKilled(); % delete the Model
                elseif strcmpi(data.eventType, 'Position')
                    this.Position([1 2]) = [1 1];	% x,y always 1,1 until undocking enabled
                    this.Position(3) = data.value(3);
                    innerheight = data.value(4) - this.MenuToolBarHeight;
                    if( innerheight < 0)
                        this.Position(4) = 0;
                    else
                        this.Position(4) = innerheight;
                    end


                    % set up the Position value to update the peer node
                    peerNode.Value = this.Position;
                    peerNode.fromClient = true;
                    this.UpdatesFromClientImpl.updatePositionFromClient(this.Position, peerNode);

                elseif strcmpi(data.eventType, 'Size')
                    this.Position([1 2]) = [1 1];	% x,y always 1,1 until undocking enabled
                    this.Position(3) = data.value(3);
                    this.Position(4) = data.value(4);
                    this.UpdatesFromClientImpl.updatePositionFromClient(this.Position, this.Position);
                elseif strcmpi(data.eventType, 'Title')
                    this.Title = data.value;
					this.UpdatesFromClientImpl.updateTitleFromClient(data.value);
                elseif strcmpi(data.eventType, 'Visible')
                    this.Visible = data.value;
					this.UpdatesFromClientImpl.updateVisibleFromClient(data.value);
                elseif strcmpi(data.eventType, 'Resize')
                    this.Resizable = data.value;
					this.UpdatesFromClientImpl.updateResizeFromClient(data.value);
                else
                    disp(['### unhandled message type ' data.eventType ' received from client ###']);
                end
            catch e %#ok<NASGU>
            end

        end % handleMessage()

    end % private methods

end
