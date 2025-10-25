classdef MOFigurePlatformHost < matlab.ui.internal.controller.platformhost.FigurePlatformHost

    % FigurePlatformHost class containing the MATLAB Online platform-specific functions for
    % the matlab.ui.internal.controller.FigureController object

    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties (Access = protected)
        % ReleaseHTMLFile = 'moComponentContainer-debug.html'; 
        ReleaseHTMLFile = 'moComponentContainer.html'; 
    end 
    
    properties (Access = private)
        MOSubscriptionId % message subscription for MATLAB Online
        SubscriptionId  % message subscription ID for specific app/uifigure
        MOChannelId = '/mlapp/figure' % Channel on which messages exchanged between Server and Client 
        MOChannelIdForApp %Channel id specific to the Figure based on the peerNodeId
        Position
        Title
        Resizable
        WindowStyle

        RefreshTitleOnViewReady = false;
        RefreshVisibleOnViewReady = false;
        RefreshResizeOnViewReady = false;
        RefreshWindowStyleOnViewReady = false;
        RefreshPositionOnViewReady = false;
        RefreshToFrontOnViewReady = false;
    end % private properties
    
    methods (Access = public)

        % constructor
        function this = MOFigurePlatformHost(updatesFromClientImpl)            
            this = this@matlab.ui.internal.controller.platformhost.FigurePlatformHost(updatesFromClientImpl);
           
            % subscribe on the general channel to handle Messages for MO
            % refresh
            this.MOSubscriptionId = message.subscribe(this.MOChannelId, @(data)this.handleMOMessage(data));
            
            this.WindowUUID = "windowUUID" + updatesFromClientImpl.getUuid();
            
        end % constructor

        % destructor
        function delete(this)
            notifyWindowUUIDClosed(this.UpdatesFromClientImpl);

            if(~isempty(this.MOChannelIdForApp) && ~isempty(this.SubscriptionId)) 
                %Publish the close message to the Client to Close the mlapp
                message.publish(this.MOChannelIdForApp, struct('peerNodeId', this.PeerModelInfo.Id, 'eventType', 'windowClosed'));
                %unsubscribe on specific figure channel;
                message.unsubscribe(this.SubscriptionId);
                %unsubscribe on the general channel;
                message.unsubscribe(this.MOSubscriptionId);
            end    

            figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
            figureLifecycleController.removeFigure(this.UpdatesFromClientImpl.getUuid());
        end % destructor
       
        %
        % methods delegated to by FigureController and implemented by this FigurePlatformHost child class
        %

        % createView() - perform platform-specific view creation operations
        function createView(this, peerModelInfo, pos, title, visible, resizable, ~, windowStyle, ~)
            
            %defer to base class for common information 
            this.createView@matlab.ui.internal.controller.platformhost.FigurePlatformHost(peerModelInfo, visible);

            % This ID is used by WindowIdentificationServiceFactory.js in
            % the client
            this.WindowUUID = "windowUUID" + this.UpdatesFromClientImpl.getUuid();
            
            % update the properties for the initial creation
            this.Position = pos;
            this.Title = title;
            this.Visible = visible;
            this.Resizable = resizable;
            this.WindowStyle = windowStyle;                        
                       
            %create the channel id based on the peerNodeId for particular
            % figure, so that communication happens to particular figure
            this.MOChannelIdForApp = this.createMOChannelIdForApp(this.PeerModelInfo.Id);
                        
            %post msg to client to show figure in iframe
            this.sendOpenMessage();
                        
            % subscribe on the channel with peerNodeId to handle Messages
            % for specific Figure
            this.SubscriptionId = message.subscribe(this.MOChannelIdForApp, @(data)this.handleMessage(data));

            figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
            figureLifecycleController.addFigure(this.UpdatesFromClientImpl.getUuid(), this);
        end % createView()
        
        function sendOpenMessage(this)
            
            % publish the URL so MO can show the figure
            message.publish(this.MOChannelId, struct('host', this.PeerModelInfo.URL, 'peerNodeId', this.PeerModelInfo.Id, ...
                            'position', this.Position, 'name', this.Title, 'visibility', this.Visible, ...
                            'resizable', this.Resizable, 'windowStyle', this.WindowStyle, 'eventType', 'windowOpen'));
            
        end    
            
        % updateTitle() - platform-specific supplement to FigureController.updateTitle()
        function updateTitle(this, newTitle)

            if (isequal(this.Title, newTitle)) 
                return;
            end            

            % save the title, until MO doesn't lose it when visibility is turned off
            this.Title = newTitle;

            if (this.ViewReadyReceived)
                this.sendPropertyChangedMsg('name', newTitle);
            else
                % Delay publishing until handshake is complete with view
                this.RefreshTitleOnViewReady = true;
            end
        end % updateTitle()

        % updateVisible() - platform-specific supplement to FigureController.updateVisible()
        function updateVisible(this, newVisible)

            % ignore if value is not changed 
            if (isequal(this.Visible, newVisible)) 
                return;
            end

            % update the cache value 
            this.Visible = newVisible;
            
            % publish the property as view is ready to receive mesaages 
            if (this.ViewReadyReceived)
                this.sendPropertyChangedMsg('visibility', newVisible);
            else
                % Delay publishing until handshake is complete with view
                this.RefreshVisibleOnViewReady = true;
            end
        end % updateVisible()
        
          % updateResize() - platform-specific supplement to FigureController.updateTitle()
        function updateResize(this, newResizable)

            if (isequal(this.Resizable, newResizable)) 
                return;
            end
            
            % save the resize, until MO doesn't lose it when visibility is turned off
            this.Resizable = newResizable;

             % publish the property as view is ready to receive mesaages 
            if (this.ViewReadyReceived)
                this.sendPropertyChangedMsg('resizable', newResizable);
            else
                % Delay publishing until handshake is complete with view
                this.RefreshResizeOnViewReady = true;
            end
        end % updateResize()

        % updateWindowStyle() - platform-specific supplement to FigureController.updateWindowStyle()
        function updateWindowStyle(this, newWindowStyle)

            if (isequal(this.WindowStyle, newWindowStyle)) 
                return;
            end
            
            this.WindowStyle = newWindowStyle;
            
             % publish the property as view is ready to receive mesaages 
            if (this.ViewReadyReceived)
                this.sendPropertyChangedMsg('windowStyle', newWindowStyle);
            else
                % Delay publishing until handshake is complete with view
                this.RefreshWindowStyleOnViewReady = true;
            end
        end % updateWindowStyle()

        % toFront() - request that the MO virtual window be brought to the front
        function toFront(this)

             % publish the property as view is ready to receive mesaages 
            if (this.ViewReadyReceived)
                message.publish(this.MOChannelIdForApp, struct('peerNodeId', this.PeerModelInfo.Id, ...
                                                               'eventType', 'windowToFront'));
            else
                % Delay publishing until handshake is complete with view
                this.RefreshToFrontOnViewReady = true;
            end
        end
        
         % publish the property with value to the client 
        function sendPropertyChangedMsg (this, propertyName, value) 

            message.publish(this.MOChannelIdForApp, struct('peerNodeId', this.PeerModelInfo.Id, ...
                                                               propertyName, value, 'eventType', 'windowPropertyChanged'));
        end

        function hostType = getHostType(this)
            hostType = 'moclient';
        end
        
        function setViewReady(this)
            setViewReady@matlab.ui.internal.controller.platformhost.FigurePlatformHost(this);

            % Update the view with any changes that have come in since channel creation.
            if (this.RefreshTitleOnViewReady)
                this.sendPropertyChangedMsg('name', this.Title);
            end
            if (this.RefreshVisibleOnViewReady)
                this.sendPropertyChangedMsg('visibility', this.Visible);
            end
            if (this.RefreshResizeOnViewReady)
                this.sendPropertyChangedMsg('resizable', this.Resizable);
            end
            if (this.RefreshWindowStyleOnViewReady)
                this.sendPropertyChangedMsg('windowStyle', this.WindowStyle);
            end
            if (this.RefreshPositionOnViewReady)
                this.sendPropertyChangedMsg('position', this.Position);
            end
            if (this.RefreshToFrontOnViewReady)
                this.toFront;
            end
        end        
    end % public methods
    
    methods (Access = protected)
        % updatePositionImpl() - platform-specific supplement to FigureController.updatePosition()
        function updatePositionImpl(this, newPos)

            if (isequal(this.Position, newPos)) 
                return;
            end
            
            % save the position, until MO doesn't lose it when visibility is turned off
            this.Position = newPos;
    
            % publish the property as view is ready to receive mesaages 
            if (this.ViewReadyReceived)
                  this.sendPropertyChangedMsg('position', newPos);
            else
                % Delay publishing until handshake is complete with view
                this.RefreshPositionOnViewReady = true;
            end
        end % updatePositionImpl()
    end % protected methods
    
    methods (Access = { ?tMOFigurePlatformHost }) % ToDo: Remove code smell: Test code in production
        
        % create the MOChannelId based on the peerNodeId
        function id = createMOChannelIdForApp(this, peerNodeID) 
            id = strcat(this.MOChannelId, '/', peerNodeID);
        end
        
        % handleMessage() - handle messages sent by client
        function handleMessage(this, data)
            try
                if strcmpi(data.eventType, 'windowClosed')
                    this.onAppFigureWindowClosed();
                elseif strcmpi(data.eventType, 'windowPropertyChanged')
                    if (isnumeric(data.data.position))
                        % save the position, until MO doesn't lose it when visibility is turned off
                        this.Position = data.data.position';
                        % @TODO This call can probably be removed, because 
                        % the MO client side resizable strategy notifies
                        % the client side controller on resize, which in
                        % turn notifies the server side figure controller
                        % @TODO Shouldn't the height and maybe even the Y
                        % be adjusted to remove the Menubar height?
                        this.UpdatesFromClientImpl.updatePositionFromClient(this.Position, this.Position);
                    end
                elseif strcmpi(data.eventType, 'figureActivated')
                    this.UpdatesFromClientImpl.figureActivated();
                elseif strcmpi(data.eventType, 'figureDeactivated')
                    this.UpdatesFromClientImpl.figureDeactivated();
                end
            catch e %#ok<NASGU>
            end    
            
        end % handleMessage()
        
         function handleMOMessage(this, data)
            try
                if strcmpi(data.eventType, 'moRefreshed')
                    %resend the msg to open the figure 
                    this.sendOpenMessage();
                end
            catch e %#ok<NASGU>
            end                
        end         
        
        function onAppFigureWindowClosed(this)
            
            % call to Figure Contoller window close 
            % which will execute the CloseRequestFcn on Model
            this.UpdatesFromClientImpl.windowClosed();
        end
        
    end    

end
