classdef FigurePlatformHost < handle
    % PlatformHost base class defining the set of platform-specific functions performed
    % by its child classes for the matlab.ui.internal.controller.FigureController object

    % Copyright 2016-2022 The MathWorks, Inc.        
    properties (Abstract, Access = protected)
        ReleaseHTMLFile;
    end    
    
    properties (Access = protected)
        DebugHTMLFile = 'componentContainer-debug.html'; % ### this is obsolete for DivFigures
        PeerModelInfo           % PeerModelInfo used by the figure
        UpdatesFromClientImpl   % implementation of FigureUpdatesFromClient interface
        
        % g2275393 - work-around to set default hostType to a non-empty value.
        DefaultHostType = 'browser'
        
        MenuToolBarHeight = 0;
        ViewReadyReceived = false;

        % g2274298 - workaround to add visible property
        Visible = false;   

        WindowUUID = '';
    end

    methods (Access = public)
        
        function this = FigurePlatformHost(updatesFromClientImpl)
            this.UpdatesFromClientImpl = updatesFromClientImpl;
        end 
        
        function delete(~)            
        end 

        % Public methods delegated to by FigureController and implemented by FigurePlatformHost child classes
        % Most of these methods are empty and none are abstract, so they can serve as stubs for all
        % child classes that have no need to implement platform-specific functionality for them.
        %

        % createView() - perform platform-specific view creation operations
        function createView(this, peerModelInfo, visible, ~, ~, ~, ~, ~, ~)
            this.PeerModelInfo = peerModelInfo;
            this.Visible = visible;
        end 

        % isDrawnowSyncSupported() - platform-specific function to return whether or not drawnow synchronization is supported
        function status = isDrawnowSyncSupported(this)
            status = this.Visible;
        end
        
        % isFullScreenModeSupported() - whether the specific platform supports full-screen windows
        function isSupported = isFullScreenModeSupported(~)
            isSupported = false;
        end
        
        % onViewKilled() - function to delete the figure when the View has been destroyed
        function onViewKilled(this)
            this.UpdatesFromClientImpl.onViewKilled();
        end 
        
        % overrideClose() - platform-specific function to wire up the close callback on the Figure to a handler function
        function overrideClose(~, ~)
        end 
        
        % updatePosition() - platform-specific supplement to FigureController.updatePosition()
        function updatePosition(this, newPos)
            % As Figure tools area is not part of Figure client area 
            % we append the height of Figure tools to the window height
            figToolsPosition = [0 0 0 this.MenuToolBarHeight]; 
            adjPos = newPos + figToolsPosition;
            this.updatePositionImpl(adjPos);
        end 
        
        % updateResize() - platform-specific supplement to FigureController.updateResize()
        function updateResize(~, ~)
        end 

        % updateTitle() - platform-specific supplement to FigureController.updateTitle()
        function updateTitle(~, ~)
        end 

        % updateVisible() - platform-specific supplement to FigureController.updateVisible()
        function updateVisible(this, newVisible)
            this.Visible = newVisible;
        end 

        % updateWindowState() - platform-specific supplement to FigureController.updateWindowState()
        function updateWindowState(~, ~)
        end 
        
        % updateWindowStyle() - platform-specific supplement to FigureController.updateWindowStyle()
        function updateWindowStyle(~, ~)            
        end 
        
        % updateWindowIconPNG() - platform-specific supplement to FigureController.updateIconView()
        function updateWindowIconPNG(~, ~)
        end 
        
        % updateToolMenuBarHeight() - store the height of the tools/menubar
        function updateToolMenuBarHeight(this, toolbarHeight)
            this.MenuToolBarHeight = toolbarHeight;
        end 
        
        % toFront() - platform-specific supplement to FigureController.toFront()
        function toFront(this)
        end

        % Return the html File based on the status of the DebugMode of the
        % Application
        function htmlFile = getHTMLFile(this)
            s = settings;
            htmlFile = this.ReleaseHTMLFile;
            
            if s.matlab.ui.UIFigureDebugModeEnabled.ActiveValue
                htmlFile = this.DebugHTMLFile;
            end
        end 

        function hostType = getHostType(this)
            hostType = this.DefaultHostType;        
        end
        
        function onBeingDeleted(this)
            % When the figure is about to be deleted hide the figure so users don't see
            % components being deleted one at a time (g1496493).
            this.updateVisible(false);
        end

        function onViewDestroyed(this)
            this.ViewReadyReceived = false;
        end

        function setViewReady(this)
            this.ViewReadyReceived = true;
        end
        
        % exportToPDF() - Export a PDF image of the figure
        function exportToPDF(~, ~, ~, ~)
            % By defualt, error out that this is not supported.
            % Each PlatformHost can override this to support this API.
            error('MATLAB:ui:uifigure:EnvironmentNotSupported', 'Functionality not supported in this environment');
        end
         
        function notifyWindowUUIDClosed(this)            
            notifyWindowUUIDClosed(this.UpdatesFromClientImpl)
        end

        function id = getWindowUUID(this)
            % All PlatformHosts must provide a unique UUID for their "Host Window"
            %
            % A "Host Window" can mean many things
            %
            % - a stand alone CEF window
            % - the overall JSD window when docked
            % - A MATLAB online browser tab in Chrome
            %
            %
            id = this.WindowUUID;
        end

        function setWindowUUID(this, windowUUID)
            this.WindowUUID = windowUUID;
            this.UpdatesFromClientImpl.notifyWindowUUIDChanged();
        end

        function rebuildView(~, packet)
            message.publish('/gbtweb/divfigure/rebuildView',packet);
        end

    end 

   
    methods (Access = protected)
        function updatePositionImpl(~, ~)
        end
    end    
end
