classdef CEFFigurePlatformHost < matlab.ui.internal.controller.platformhost.FigurePlatformHost

    % FigurePlatformHost class containing the CEF platform-specific functions for
    % the matlab.ui.internal.controller.FigureController object

    % Copyright 2016-2023 The MathWorks, Inc.
   
    properties (Access = protected)
        ReleaseHTMLFile = 'cefComponentContainer.html';
    end
    
    properties (Hidden, Access = {?matlab.ui.control.internal.HTMLComponentDebugUtils, ?matlab.ui.internal.FigureImageCaptureService})
        CEF;            % CEF webwindow
    end    
    
    properties (Hidden, Access = private)
        hasCEF = false; % indicates whether or not the CEF webwindow has been created
    end 
    
    % Hidden properties with private access
    properties (Hidden, Access = {?tCEFFigurePlatformHost, ?tFigureController})
        currentWindowState; % local copy of WindowState value from model
        currentWindowStyle; % lcoal copy of WindowStyle value from model
        currentTitle; % local copy of Title value from model
    end
    
    properties (Hidden, Dependent)
        FigureUUID;
        CEFWindowState;
        CEFWindowStyle;
    end
    
    properties (Access = public)
        AppCaptureClientDone = false;
        AppCaptureCleanupDone = false;
    end
    
    methods (Access = public)

        % constructor
        function this = CEFFigurePlatformHost(updatesFromClientImpl)                        
            this = this@matlab.ui.internal.controller.platformhost.FigurePlatformHost(updatesFromClientImpl);

            % This ID is used by WindowIdentificationServiceFactory.js in
            % the client
            this.WindowUUID = "windowUUID" + updatesFromClientImpl.getUuid();                                  
      end 

        % destructor
        function delete(this)
            notifyWindowUUIDClosed(this.UpdatesFromClientImpl)            

            figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
            figureLifecycleController.removeFigure(this.FigureUUID);
                                      
            % delete CEF window object if it was ever created
            if this.hasCEF && isvalid(this.CEF)
                this.CEF.FocusGained = [];
                this.CEF.FocusLost = [];
                delete(this.CEF);
            end
        end 
        
        %
        % methods delegated to by FigureController and implemented by this FigurePlatformHost child class
        %

        % createView() - perform platform-specific view creation operations
        function createView(this, peerModelInfo, position, title, visible, ~, windowState, windowStyle, ~)
            if this.viewCreationDisabled()
                % There is no display connected to the MATLAB session, or
                % MATLAB was started with the -nodisplay flag
                % Create an invisible view.
                visible = false;
            end

            this.createView@matlab.ui.internal.controller.platformhost.FigurePlatformHost(peerModelInfo, visible);
            figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
            figureLifecycleController.addFigure(this.FigureUUID, this);

            if this.disableWindowCreation() 
                % we only create and set up the CEF webwindow if creation
                % has not been disabled, so if it is disabled, skip CEF
                % webwindow creation
                return;
            end

            % create the CEF webwindow
            this.CEF = this.createCEFWindow(peerModelInfo.URL, peerModelInfo.DebugPort, position);
            this.hasCEF = true;

            this.currentWindowState = windowState;
            this.currentWindowStyle = windowStyle;
            this.currentTitle = title;

            % add view killed callback
            this.CEF.MATLABWindowExitedCallback = @(event, data) this.onViewKilled();

            % Window activation/deactivation callbacks
            this.CEF.FocusGained = @(event, data)this.onFigureActivated(event, data);
            this.CEF.FocusLost = @(event, data)this.onFigureDeactivated(event, data);
        end             

        % isDrawnowSyncSupported() - platform-specific function to return whether or not drawnow synchronization is supported
        function status = isDrawnowSyncSupported(this)
            status = ~this.disableWindowCreation() && ~this.viewCreationDisabled();
        end

        function status = viewCreationDisabled(~)
            status = ~(matlab.ui.internal.hasDisplay() && matlab.ui.internal.isFigureShowEnabled);
        end
        
        % isFullScreenModeSupported() - whether the specific platform supports full-screen windows
        function isSupported = isFullScreenModeSupported(~)
            isSupported = true;
        end
        
        % overrideClose() - platform-specific function to wire up the close callback on the Figure to a handler function
        function overrideClose(this, fcn)
        % NOTE: This prevents the CEF window from being closed when the 'x' 
        % is clicked. It is up to the handler to delete the CEF window.
            if this.hasCEF
                this.CEF.CustomWindowClosingCallback = fcn;
            end
        end % overrideClose()
        
        % updateResize() - platform-specific supplement to FigureController.updateResize()
        function updateResize(this, newResizable)
            if this.hasCEF
                this.CEF.setResizable(newResizable);
            end
        end % updateResize()

        % updateTitle () - platform-specific supplement to FigureController.updateTitle()
        function updateTitle(this, newTitle)
            this.currentTitle = newTitle;
            if this.hasCEF
                % we need to check for the empty condition
                % and set the title on the CEF window otherwise
                % we do see the url on the title section
                if (isempty(this.CEF.Title) || ~isequal(this.currentTitle, this.CEF.Title))
                    this.CEF.Title = this.currentTitle;
                end
            end
        end % updateTitle()

        % updateVisible() - platform-specific supplement to FigureController.updateVisible()
        function updateVisible(this, newVisible)
            if feature("noFigureWindows")
                return;
            end
            
            if this.hasCEF && ~this.disableWindowCreation()
                % Prevent updates that make the CEF window visible until the
                % viewReady message is received, however, cache this value
                % by calling the base class because we will need it once 
                % the view is ready.
                this.updateVisible@matlab.ui.internal.controller.platformhost.FigurePlatformHost(newVisible);
                if this.ViewReadyReceived
                    if newVisible
                        if (~strcmp(this.currentWindowState, 'fullscreen') || ~ismac)
                            % bring the figure to the front as well as show it, but not
                            % if full-screen on Mac (because it would case a callback of
                            % 'WindowRestored' which would transition us to normal state)
                            % g2285339 - if figure is minimized and not visible
                            % then while making it visible bring it to front
                            % and that will change the WindowState to normal
                            this.CEF.bringToFront();
                        end
                        % Make sure any window style set while hidden is applied
                        if ~isempty(this.currentWindowStyle)
                            this.applyWindowStyleOnVisible(this.currentWindowStyle)
                        end    
                    else
                        % Manually set the modal window to normal.
                        % WindowStayle is honored only when window is visible. 
                        % fix to g2684539 setting the window modal to
                        % false if the window is current modal if not doing so results in other windows not
                        % accessible. Consider reverting this change once
                        % the g2685347 is fixed 
                        if(this.CEF.isModal)
                            this.CEF.setWindowAsModal(false);
                        end
                        this.CEF.hide();
                    end
                end
            end
        end % updateVisible()

        % updateWindowState() - save the state
        function updateWindowState(this, newWindowState)
            this.currentWindowState = newWindowState;
        end % updateWindowState()
        
         % updateWindowStyle() - save the windowstyle
        function updateWindowStyle(this, newWindowStyle)
            if this.hasCEF            
                this.currentWindowStyle = newWindowStyle;
                this.applyWindowStyleOnVisible(this.currentWindowStyle);
            end
        end % updateWindowStyle()

        % updateWindiwIconPNG() - set the window Icon using PNG file format (required)
        function updateWindowIconPNG(this, newIcon)
            
            % Window icons are not supported on Mac
            if ismac
                return;
            end
            
            if this.hasCEF
                 this.CEF.Icon = newIcon;
            end
        end % updateIcon()
        
        % toFront() - request that the CEF window be brought to the front
        function toFront(this)
            bringToFront(this.CEF);
        end
        
        function hostType = getHostType(this)
            if(this.disableWindowCreation())
                hostType = this.DefaultHostType;
            else
                hostType = 'cefclient';
            end
        end
        
        function onBeingDeleted(this)
            % Don't let the base class hide the window on deletion as it
            % will impact the stacking order of windows w.r.t to MATLAB
            % desktop on windows platform. g2225860
        end
        
        % exportToPDF() - Export a PDF image of the figure
        function exportToPDF(this, fileName, includeFigureTools, channel)
            % Initiate the client to setup the DOM appropriately before exporting
            setupSubscription = message.subscribe([channel '/setupAppCaptureDone'], @(msg) onSetupAppCaptureDone(msg));
            message.publish([channel '/setupAppCapture'], struct("includeFigureTools", includeFigureTools));
            
            % Block MATLAB execution until the export has finished and cleaned up. 
            exportSuccessful = false;
            waitfor(this, 'AppCaptureClientDone', true);
            
            % Clear flags
            this.AppCaptureClientDone = false;
            this.AppCaptureCleanupDone = false;

            if ~exportSuccessful
                throwAsCaller(MException('MATLAB:ui:figure:ExportUnsuccessful', 'Export unsuccessful'));
            end
            
            % After the setup is done, execute the CEF print to PDF functionality
            % Then tell the client to cleanup the DOM to it's previous state
            function onSetupAppCaptureDone(~)
                message.unsubscribe(setupSubscription);

                % Ensure figure has not been destroyed.
                if ~isvalid(this)
                    this.AppCaptureClientDone = true;
                    return;
                end
                
                % Execute the export
                exportSuccessful = this.CEF.printToPDF(fileName);

                % Return the client back to it's original state
                cleanupSubscription = message.subscribe([channel '/cleanupAppCaptureDone'], @(msg) onCleanupAppCaptureDone(msg));
                message.publish([channel '/cleanupAppCapture'], []);
                
                % Execute cleanup callback
                function onCleanupAppCaptureDone(~)
                    message.unsubscribe(cleanupSubscription);
                    this.AppCaptureCleanupDone = true;
                end
                
                % Block MATLAB execution until the cleanup is finished.
                waitfor(this, 'AppCaptureCleanupDone', true);

                this.AppCaptureClientDone = true;
            end
        end

        function setViewReady(this)
            this.setViewReady@matlab.ui.internal.controller.platformhost.FigurePlatformHost();
            % Now that viewReady is recieved, update the state of visibilty
            % of the CEF window.
            this.updateVisible(this.Visible);
        end
    
    end % public methods
    
    methods (Access = private)
        
        function onFigureActivated(this, ~, ~)
            this.UpdatesFromClientImpl.figureActivated();
        end

        function onFigureDeactivated(this, ~, ~)
            this.UpdatesFromClientImpl.figureDeactivated();
        end
        
        function applyWindowStyleOnVisible(this, windowStyle)
            if strcmp(this.CEFWindowStyle, windowStyle)
                % If the CEF window is already in the requested style, do nothing
                return;
            end
            
            %g2404608 Fix to the modality in existance of 
            %other figure with alwaysontop
            if strcmp(windowStyle, 'normal')
                if (this.CEF.isWindowModal) 
                    this.CEF.setWindowAsModal(false);
                end
                if (this.CEF.isAlwaysOnTop)
                    this.CEF.setAlwaysOnTop(false);
                end
            end

            %g2286380 Set the Window to modal only when its Visible.
            if (strcmp(windowStyle, 'modal') && this.Visible)
                % g3283936 set title if the window title is not
                % set by the time window is set to modal. We get into 
                % this scenario where the window is rendered soon that the
                % content is ready showing the url at the window title
                % section. 
                this.updateTitle(this.currentTitle);
                % bring the window to the front
                this.CEF.bringToFront();
                this.CEF.setWindowAsModal(true);
            elseif strcmp(windowStyle, 'alwaysontop')
                this.CEF.setAlwaysOnTop(true);
            end    
            
        end    
    end % private methods
    
    methods (Static=true, Access={?matlab.ui.internal.controller.FigureController, ?tFigureController})

        % disableWindowCreation() - used by FigureControllerTestHelper to enable and disable window creation
        %                           used by FigurePlatformHost child classes to detect enabled versus disabled state
        function status = disableWindowCreation(dohide)
            persistent hidewindow;
            if isempty(hidewindow)
                hidewindow = false;
            end

            if nargin >= 1
                if ~islogical(dohide)
                    error('MATLAB:ui:internal:controller:FigureController:incorrectLogicalInput', 'Incorrect input. Expected a logical value of true or false');
                end
                hidewindow = dohide;
            end
            status = hidewindow;
        end % disableWindowCreation()

    end % static limited access methods
    
    methods
        function uuid = get.FigureUUID(this)
            uuid = this.UpdatesFromClientImpl.getUuid();
        end

        function windowState = get.CEFWindowState(this)
            if this.CEF.isMaximized
                windowState = 'maximized';
            elseif this.CEF.isMinimized
                windowState = 'minimized';
            elseif this.CEF.isFullscreen
                windowState = 'fullscreen';
            else
                windowState = 'normal';
            end
        end
        
        function windowStyle = get.CEFWindowStyle(this)
            if this.CEF.isWindowModal
                windowStyle = 'modal';
            elseif this.CEF.isAlwaysOnTop
                windowStyle = 'alwaysontop';
            else
                windowStyle = 'normal';
            end
        end
    end % property get methods

    methods (Access = protected)
        function updatePositionImpl(this, adjPosition)
            if (this.Visible == false)
                % send the position directly to it
                this.CEF.Position = adjPosition;
            end
        end
    end

    methods (Static = true, Access = private)

        function CEFWindow = createCEFWindow(URL, debugPort, position)
            if feature('webui')
                % matlab.internal.cef.webwindow() ignores capabilities -- we want to use this
                % entrypoint when in -webui to support environments where
                % certain Capabilities are not supported and will cause the
                % failure of CEF window creation if the
                % matlab.internal.webwindow() entry point is used
                CEFWindow = matlab.internal.cef.webwindow(URL, debugPort, position);
            else
                % webwindow will error unless Capabilities.WebWindow is
                % available
                CEFWindow = matlab.internal.webwindow(URL, debugPort, position);
            end
        end
    end % static private methods
end
