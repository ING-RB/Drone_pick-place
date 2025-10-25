classdef (Abstract) FigureUpdatesFromClient < handle

    % abstract base class defining an interface that must be implemented in order for 
    % the figure to receive notification of property changes made by the client

    % Copyright 2016-2020 The MathWorks, Inc.

    methods (Access = public)

        % onViewKilled() - function to delete the figure when the View has been destroyed
        onViewKilled(this)
        
        % updateDrawnowSyncReadyFromClient() - update the model DrawNowSyncReady value
        updateDrawnowSyncReady(this, syncReady)

        % updatePositionFromClient() - update the figure Position
        updatePositionFromClient(this, Position, peerNodeData)

        % updateTitleFromClient() - update the figure Title/Name
        updateTitleFromClient(this, Title)

        % updateVisibleFromClient() - update the figure Visibility
        updateVisibleFromClient(this, Visible)

        % updateWindowStateFromClient() - update the window state when maximized, etc.
        updateWindowStateFromClient(this, NewWindowState, ForcedByPositionChange)
        
        % updateWindowStyleFromClient() - update the window style when docked/undocked.
        updateWindowStyleFromClient(this, newWindowStyle)
        
        % figureActivated() - notification that the figure window has been activated
        figureActivated(this)
        
        % figureDeactivated() - notification that the figure window has been deactivated
        figureDeactivated(this)
        
        % windowClosed() - notification that the figure window has been closed
        windowClosed(this)            

        % getUuid - gets a unique ID for this Figure
        getUuid(this)
         
    end 
    
   methods (Access = {....
            ?matlab.ui.internal.controller.platformhost.FigurePlatformHost, ...
            ?matlab.ui.internal.controller.FigureUpdatesFromClient ...
            })
        % These methods should only be triggered by the FigurePlatformHost
        %
        % Ideally, other public methods on this class should become access
        % restrcted to ensure property encapsulation
        
        % Tells this to fire events when the hosting
        % window (a browser tab, an App Container CEF window, etc...) has
        % closed
        notifyWindowUUIDClosed(this)
    end

    events
        % Fired when the Window ID changes
        WindowUUIDChanged

        % Fired when the overall Window is closed
        WindowUUIDClosed;
    end

end
