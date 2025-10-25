classdef DivFigurePlatformHost < matlab.ui.internal.controller.platformhost.FigurePlatformHost

    % FigurePlatformHost class containing the platform-specific functions that will eventually
    % replace all others for the matlab.ui.internal.controller.FigureController object

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Access = protected)
        % this will be obsolete once DivFigure replaces all other PlatformHosts
        ReleaseHTMLFile = 'webAppsComponentContainer.html';
    end

    properties (Access = private)
        isDrawnowSyncEnabled = false;   % drawnow synchronizarion is initially disabled
        SubscriptionId  % message subscription ID, for receipt of messages from client
        CtsChannel = '/cts';    % client to server channel, initialized for testing purposes
        StcChannel = '/stc';    % server to client channel, initialized for testing purposes
        figUuid;
        hasDesktopDocument = false;
        desktopDocument = [];
    end % private properties

    methods (Access = public)

        % constructor
        function this = DivFigurePlatformHost(updatesFromClientImpl)
            this = this@matlab.ui.internal.controller.platformhost.FigurePlatformHost(updatesFromClientImpl);
        end % constructor

        % destructor
        function delete(this)
            if (~isempty(this.SubscriptionId))
                figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
                figureLifecycleController.removeFigure(this.figUuid);
                message.unsubscribe(this.SubscriptionId);
                % don't do the following during response to a viewDestroyed msg from the client
                if (this.hasDesktopDocument)
                    close(this.desktopDocument);
                    this.desktopDocument = [];
                else
                    message.publish(this.StcChannel, struct('eventType', 'windowClosed'));
                end
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
        function createView(this, cvStruct)

            % Save the peerModelInfo element for multiple uses below
            peerModelInfo = cvStruct.peerModelInfo;

            %delegate common processing to base class
            if isfield(cvStruct, 'dfPacket')
                visible = cvStruct.dfPacket.Visible;
                % When the cvStruct has a divFigure packet, the view is
                % being constructed immediately, so enable drawnow sync.
                this.isDrawnowSyncEnabled = true;
                this.UpdatesFromClientImpl.updateDrawnowSyncReady(this.isDrawnowSyncSupported());
            elseif peerModelInfo.FigurePeerNode.hasProperty('Visible')
                visible = peerModelInfo.FigurePeerNode.getProperty('Visible');
            else
                visible = true;
            end
            this.createView@matlab.ui.internal.controller.platformhost.FigurePlatformHost(peerModelInfo, visible);

            % get the packet containing information for setting up client-server communications
            differentiators = matlab.ui.internal.FigureServices.getChannelDifferentiators();

            % extract the MessageService channel Ids, making them unique by appending the peerModel Channel
            this.CtsChannel = strcat(differentiators.ClientToServer, peerModelInfo.PeerModelChannel);
            this.StcChannel = strcat(differentiators.ServerToClient, peerModelInfo.PeerModelChannel);

            % subscribe on the channel to handle messages coming from the client
            this.SubscriptionId = message.subscribe(this.CtsChannel, @(data)this.handleMessage(data));
            % N.B. subscription id is documented to be a String but is actually a uint64 as of Feb 2018

            this.figUuid = cvStruct.uuid;
            figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
            figureLifecycleController.addFigure(cvStruct.uuid, this);

            isLiveEditorInvisible =  feature('LiveEditorRunning') && ~visible;
            if isLiveEditorInvisible
                % Most likely the figure is animating in the Live Editor
                % using a Graphicsview. No need to create a view for that
                % figure.
                % TODO: this code should be removed when the Live Editor
                % stops using standalone GraphicsViews for anmimations
                return
            end
         
            % This function sends the DivFigure packet to the client for "immediate" View creation
            % when the DivFigure is generated by the figure or uifigure function.
            % The packet for a DivFigure created by the divfigure function will be fetched by
            % the calling application and used to create the View when it suits the application.
            % The FigureController passes the packet to this function if this function should send it
            % to the client.
            %
            % When MATLAB is started with the -noFigureWindows startup switch,
            % we do not publish the figureCreated message, which prevents creation
            % of Figure documents in the MATLAB desktop. As of right now, this
            % message is only published in the MATLAB desktop document use case.
            if isfield(cvStruct, 'dfPacket') && ~feature('noFigureWindows')
                windowStyle = cvStruct.dfPacket.WindowStyle;

                % send a message with the packet to the client code so it displays the DivFigure
                if (feature('FigureServerSideDocumentCreation')) 
                    figLaunchFunction = @()(this.createDesktopDocument(cvStruct.dfPacket));
                else
                    figLaunchFunction = @()(message.publish('/gbtweb/divfigure/figureCreated', cvStruct.dfPacket));
                end

                if ~feature('DivFigureEarlyLaunch') && (strcmpi(windowStyle,'normal') || strcmpi(windowStyle,'alwaysontop'))
                    % If the Figure will be undocked (but not modal),
                    % launch the view in a throttled manner using the
                    % Figure LifecycleController
                    figureLifecycleController.throttledFigureViewLaunch(cvStruct.uuid, figLaunchFunction);
                else
                    % otherwise launch the view immediately
                    figLaunchFunction();
                end
            end

        end % createView()

        % getHostType() - return platform-specific host type
        function hostType = getHostType(~)
            hostType = 'divclient';
        end

        % toFront() - platform-specific supplement to FigureController.toFront()
        % ### this message is used only by the old MO-specific code now
        % ### we may need to implement this for the general DivFigure case as well
        function toFront(this)
            if ~isempty(this.SubscriptionId)
                message.publish(this.StcChannel, struct('eventType', 'windowToFront'));
            end
        end

        function rebuildView(this, packet)         
            if (this.hasDesktopDocument)
                if ~isempty(this.desktopDocument)
                    close(this.desktopDocument);
                    this.desktopDocument = [];
                end

                this.createDesktopDocument(packet);
            else
                rebuildView@matlab.ui.internal.controller.platformhost.FigurePlatformHost(this, packet);
            end

        end

    end % public methods

    methods (Access = private)

        function name = getDocumentGroupName(~, packet)
            if strcmp(packet.DefaultTools,"toolstrip")
                name = "defaultfigure";
            else
                name = "legacyfigure";
            end
        end

    end

    methods (Access = { ?matlab.ui.internal.controller.FigureLifecycleController, ?tDivFigurePlatformHost }) % ToDo: Remove code smell: Test code in production

        % handleMessage() - handle messages sent by client
        function handleMessage(this, data)
            if strcmpi(data.eventType, 'clientReady')
                this.isDrawnowSyncEnabled = true;
                this.UpdatesFromClientImpl.updateDrawnowSyncReady(this.isDrawnowSyncSupported());
            elseif strcmpi(data.eventType, 'figureActivated')
                this.UpdatesFromClientImpl.figureActivated(); % react to window activation on client
            elseif strcmpi(data.eventType, 'figureDeactivated')
                this.UpdatesFromClientImpl.figureDeactivated(); % react to window deactivation on client
            elseif strcmpi(data.eventType, 'windowClosed')
                this.UpdatesFromClientImpl.windowClosed(); % execute CloseRequestFcn on Model

            elseif strcmpi(data.eventType, 'windowClosingRequest')
                this.UpdatesFromClientImpl.windowClosed(); % execute CloseRequestFcn on Model

                % check if the figure is deleted
                % if it is NOT, then we should send an event that
                % window closing was rejected, we send the msg to
                % client to reject closing the window
                if isvalid(this) && isvalid(this.UpdatesFromClientImpl)
                    message.publish(this.StcChannel, struct(...
                        'eventType', 'windowClosingRejected', ...
                        'value', data.eventId));
                end

            elseif strcmpi(data.eventType, 'viewDestroyed')
                this.onViewDestroyed();
                this.UpdatesFromClientImpl.onViewDestroyed();

            elseif strcmpi(data.eventType, 'viewRebuilding')
                % Nothing needs to be done, but we dont want to print the warning below

            else
                % Downstream team clients may send us messages we do not
                % respond to, and that is okay, so this is an intentional
                % no-op.
            end
        end % handleMessage()

        function createDesktopDocument(this, packet)
            % Get the appropriate Figure document group
            rootApp = matlab.ui.container.internal.RootApp.getInstance();
            if isempty(rootApp)
                % TODO add to Message Catalog
                error("PLACEHOLDER: Internal error: Could not get RootApp instance.");
            end
            if rootApp.State ~= "RUNNING"
                % TODO add to Message Catalog
                error("PLACEHOLDER: Internal error: RootApp not running.");
            end

            documentGroupName = getDocumentGroupName(this, packet);
            docGroup = rootApp.getDocumentGroup(documentGroupName);
            if isempty(docGroup)
                % TODO add to Message Catalog
                error("PLACEHOLDER: Internal error: Failed to get Figure document group");
            end

            this.hasDesktopDocument = true;

            this.desktopDocument = matlab.ui.container.internal.appcontainer.Document;
            this.desktopDocument.DocumentGroupTag = documentGroupName;
            this.desktopDocument.Content = packet;

            if strcmp(packet.WindowStyle,"docked")
                this.desktopDocument.Docked = true;
            else
                this.desktopDocument.Docked = false;
            end

            rootApp.add(this.desktopDocument);
        end

    end % limited access methods

end
