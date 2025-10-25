classdef PropertyInspectorManager < handle

    % PropertyInspectorManager: Corresponds to the property inspector.
    % This class takes care of inspecting the properties for the graphic
    % and non-graphics objects such as axes, figure, line, timer etc.

    % Copyright 2017-2025 The MathWorks, Inc.

    properties (Constant)
        % Used to set minimum height on the inspector window
        DEFAULT_FIGURE_SIZE = get(0,'defaultFigurePosition');
        DEFAULT_WINDOW_WIDTH = 350;
        MIN_WINDOW_HEIGHT = 300;
    end

    properties(SetAccess = private, GetAccess = public)
        % PropertyUndoRedoManager helps in performing undo/redo actions
        % for figure property changes.
        PropertyUndoRedoManager

        % Reference to the currently inspected figure
        CurrentFigure

        % Plot-Selection Change Listener
        PlotSelectListener

        % One-shot listener to listener to plot-edit mode being enabled
        PlotEditModeListener

        % Undo/Redo addCommand Listener
        PropertyChangedListener
        % Flag to not show the inspector window when closed manually by the
        % user
        IsInspectorClosedManually = false

        % g1694798: If OS is supported
        IsUnSupportedPlatform = false

        % Listener for current figure being destroyed
        FigureBeingDestroyedListener

        % URL string used for inspector
        URLString

        %Webwindow to host the inspector in JSD
        WebWindow matlab.internal.webwindow
    end

    properties(SetAccess = private, GetAccess = private)
        % Indicator of the Inspector window has been positioned - used for
        % uifigures only
        UIFigureInspectorPositioned = false;

        FigurePositionDefaultsRestored logical = false;

    end

    properties(SetAccess = protected, GetAccess = public)
        % Reference to the currently inspected object
        CurrentObject

        % Save the current variable name (if there is one)
        CurrentVarName string = strings(0);
        CurrentVarNameChange logical = false;
    end

    methods (Static)
        % PropertyInspectorManager class is a singleton
        function h = getInstance()
            mlock
            persistent hInspectorManager;
            if isempty(hInspectorManager)
                hInspectorManager = matlab.graphics.internal.propertyinspector.PropertyInspectorManager();
            end
            h = hInspectorManager;
        end

        % Supports Debugging workflows
        function debugInspectorFlag = setDebug(debugFlag)
            persistent enableDebugFlag;
            if nargin >=1
                enableDebugFlag = debugFlag;
            end

            if isempty(enableDebugFlag)
                debugInspectorFlag = false;
            else
                debugInspectorFlag = enableDebugFlag;
            end
        end

        % Forces to show Java property inspector
        function doShowJavaInspector = showJavaInspector(state)
            persistent showInspectorFlag;
            if nargin >=1
                showInspectorFlag = state;
            end

            if isempty(showInspectorFlag)
                doShowJavaInspector = false;
            else
                doShowJavaInspector = showInspectorFlag;
            end

            if ~isempty(doShowJavaInspector) && ~doShowJavaInspector
                munlock matlab.graphics.internal.propertyinspector.PropertyInspectorManager;
                clear matlab.graphics.internal.propertyinspector.PropertyInspectorManager;
            end
        end

        function removeFigureDTClientListenersIfNeeded()
            % Find any open figures in plotedit mode.
            % Remove figure desktop client listeners if there isn't any.
            allFigures=[];
            allFigures = findobj(0,'-depth',1,'type','figure',...
                '-function', @(x) ~isempty(x) && isprop(x,"ModeManager"));
            if ~isempty(allFigures)
                allFigures = findobj(allFigures,'-depth',1,'type','figure',...
                    '-function', @(x) ~isempty(x.ModeManager) && isprop(x.ModeManager,"CurrentMode"));
                if ~isempty(allFigures)
                    allFigures = findobj(allFigures,'-depth',1,'type','figure',...
                        '-function', @(x) ~isempty(x.ModeManager.CurrentMode) && isprop(x.ModeManager.CurrentMode,"Name"));
                    if ~isempty(allFigures)
                        allFigures = findobj(allFigures,'-depth',1,'type','figure',...
                            '-function', @(x) x.ModeManager.CurrentMode.Name == "Standard.EditPlot",...
                            '-and','BeingDeleted','off');
                    end
                end
            end
        end

        % Called from the Java Property Inspector to find out if the
        % different figure is selected, then show the property editor
        % alongside. Handler to figure gained focus/figure window activated.
        % This helps in moving the inspector window based on which figure window
        % in plot-edit mode gets focus
        function showPropertyInspectorIfNeeded(dtClient)
            this = matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance();
            hFig = getfigurefordesktopclient(dtClient);
            if ~isempty(hFig)
                % Early return if the figure is invalid or is being
                % deleted. This happens when figure gets activated
                % while clicking on Close Window button.
                if ~isvalid(hFig) || strcmpi(hFig.BeingDeleted,'on')
                    return;
                end

                % Don't show the inspector window if inspector is
                % closed manually
                if ~this.IsInspectorClosedManually
                    if ~isequal(hFig,this.CurrentFigure)
                        if isactiveuimode(hFig,'Standard.EditPlot')
                            hMode = getuimode(hFig,'Standard.EditPlot');
                            if ~isempty(hMode)
                                selectedObject = hMode.ModeStateData.PlotSelectMode.ModeStateData.SelectedObjects;
                                styleSelectionHandles(hFig);
                                this.showInspector(selectedObject);
                            end
                        else
                            % There are situations when figure window
                            % focus listener is fired but plot-edit
                            % mode has not yet enabled on the java
                            % figure. Add a one-shot listener to listen
                            % to plot-edit mode being enabled
                            if isempty(this.PlotEditModeListener)
                                this.addPlotEditModeListener(hFig);
                            end
                        end
                    elseif isequal(hFig,this.CurrentFigure) && isactiveuimode(hFig,'Standard.EditPlot')
                        % Bring the inspector window to front if the same
                        % figure gets focus again
                        this.bringInspectorToFrontIfNeeded();
                    end
                end
            end

        end

        % Called from the Java Property Inspector to find out if the
        % different figure is selected, then show the property editor
        % alongside. Handler to figure gained focus/figure window activated.
        % This helps in moving the inspector window based on which figure window
        % in plot-edit mode gets focus
        function showInspectorForDockedFigure(dtClient, figureFrame)
            this = matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance();
            hFig = getfigurefordesktopclient(dtClient);
            if ~isempty(hFig)
                % Early return if the figure is invalid or is being
                % deleted. This happens when figure gets activated
                % while clicking on Close Window button.
                if ~isvalid(hFig) || strcmpi(hFig.BeingDeleted,'on')
                    return;
                end

                % Don't show the inspector window if inspector is
                % closed manually
                if ~this.IsInspectorClosedManually
                    % There are situations when figure window
                    % focus listener is fired but plot-edit
                    % mode has not yet enabled on the java
                    % figure. Add a one-shot listener to listen
                    % to plot-edit mode being enabled
                    if ~isactiveuimode(hFig,'Standard.EditPlot') && isempty(this.PlotEditModeListener)
                        this.addPlotEditModeListener(hFig);
                    end
                    if ~isequal(hFig,this.CurrentFigure)
                        if isactiveuimode(hFig,'Standard.EditPlot')
                            this.setFigureWindowFrame(figureFrame);
                            hMode = getuimode(hFig,'Standard.EditPlot');
                            if ~isempty(hMode)
                                selectedObject = hMode.ModeStateData.PlotSelectMode.ModeStateData.SelectedObjects;
                                styleSelectionHandles(hFig);
                                this.showInspector(selectedObject);
                            end
                        end
                    elseif isequal(hFig,this.CurrentFigure) && isactiveuimode(hFig,'Standard.EditPlot')
                        % Bring the inspector window to front if the same
                        % figure gets focus again
                        this.setFigureWindowFrame(figureFrame);
                        this.bringInspectorToFrontIfNeeded();
                    end
                end
            end

        end

        function closeAllInspectorDropDowns()
            defaultInspectorInstance = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;

            if defaultInspectorInstance.isKey('/PropertyInspector')
                inspectorDocumentModel = defaultInspectorInstance('/PropertyInspector');
                if ~isempty(inspectorDocumentModel.Documents) && ~isempty(inspectorDocumentModel.Documents.ViewModel)
                    inspectorDocumentModel.Documents.ViewModel.handleFocusLost();
                end
            end
        end

        % If the property inspector window is closed manually,
        % inspector window will remain closed. Only context-menu or
        % inspect function or double-clicking or re-enabling plot-edit mode
        % can reopen the property inspector
        function setInspectorClosedManually(~)
            this = matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance();

            this.IsInspectorClosedManually = true;
            this.removeListenersAndRestoreSelection();
            inspectorMap = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;
            if isKey(inspectorMap, '/PropertyInspector')
                inspectorManager = inspectorMap('/PropertyInspector');

                if matlab.graphics.internal.propertyinspector.PropertyInspectorManager.isRemoteClientThatMirrorsSwingUIs()
                    % When the inspector is manually closed, close the inspector
                    % document, so it will get recreated if the inspector is opened
                    % again.  Without this, it will appear that the inspector is still
                    % active, and in Matlab Online it may result in the inspector
                    % reopening unexpectedly.  This should only be done for MOL,
                    % since the desktop has it's own window management.
                    inspectorManager.closeAllVariables;
                end

                if inspectorManager.clearObjectAfterClose()
                    % Clear the current object so we don't hold a refernce to it, if the
                    % clearObjectAfterClose returns true
                    this.CurrentObject = [];
                end
            end
        end

        % Remove plot-selection listener and restore selection handles on
        % all figures in plot-edit mode
        function removeListenersAndRestoreSelection(~)
            this = matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance();

            % Remove the plot selection change listener
            delete(this.PlotSelectListener);
            this.PlotSelectListener = [];

            % Remove the one-shot plot edit mode listener
            delete(this.PlotEditModeListener);
            this.PlotEditModeListener = [];

            % Remove the figure destroy listener
            delete(this.FigureBeingDestroyedListener);
            this.FigureBeingDestroyedListener = [];

            this.removeFigureDTClientListenersIfNeeded();

            % Need to delete the timer because we are only hiding the
            % inspector, and not deleting it (to help with performance).
            % The timer will be recreated when the inspector is opened
            % again.
            deleteTimer();

            % restore selection handles of all the figures in plot-edit
            % mode
            styleSelectionHandles();
        end

        % Returns true if we are in remote client supporting swing UIs and false otherwise.
        function isRemoteClient = isRemoteClientThatMirrorsSwingUIs()
            import matlab.internal.capability.Capability;
            isRemoteClient = ~Capability.isSupported(Capability.LocalClient) && ...
                Capability.isSupported(Capability.Swing);
        end
    end

    methods (Access = public,Hidden = true)
        % Show the inspector jFrame and position the window relative to the
        % figure
        function initInspector(this,hFig)
            if ~isempty(hFig) && any(isvalid(hFig))
                if ~isempty(this.CurrentFigure) && isvalid(this.CurrentFigure)
                    % Style the selection handles in the figure
                    styleSelectionHandles(hFig);
                end
            end

            this.CurrentFigure = hFig;

            if ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.isRemoteClientThatMirrorsSwingUIs
                if matlab.ui.internal.isUIFigure(hFig)
                    %For uifigures we dont need to install positioning
                    %listeners, just show the Inspector
                    this.showInspectorForUIFigure();
                elseif isempty(hFig) && this.useWebWindow()
                    if isempty(this.WebWindow) || ~isvalid(this.WebWindow) || ...
                            ~this.WebWindow.isWindowValid
                        this.initWebWindow();
                    end
                    if ~isempty(this.WebWindow)
                        this.WebWindow.show();
                    end
                else
                    this.initJavaPropertyInspectorManager();
                end
            end

            % Set the height of the inspector window
            this.setInspectorHeight();

            this.IsInspectorClosedManually = false;
            % Setup the plot selection change listener
            if isempty(this.PlotSelectListener)
                this.initPlotSelectListener();
            end

            % Delete the listener for the previous figure if existing so
            % that only one current figure destroy listener exists at any
            % time.
            if ~isempty(this.FigureBeingDestroyedListener)
                delete(this.FigureBeingDestroyedListener);
                this.FigureBeingDestroyedListener = [];
            end
            this.initFigureBeingDestroyedListener();
        end

        function temporarilyStopInspectorListeners(this)
            this.IsInspectorClosedManually = true;
            % Remove the plot selection change listener
            delete(this.PlotSelectListener);
            this.PlotSelectListener = [];

            % Remove the one-shot plot edit mode listener
            delete(this.PlotEditModeListener);
            this.PlotEditModeListener = [];
        end

        % Show the Inspector Window and inspect the currently selected
        % object.
        function showInspector(this,objToInspect)
            % g1711013 get the object handle from hObjs. In case hObjs passed is
            % double(figure) etc
            if isjava(objToInspect)
                % Don't bother with the parenting/figure logic for java objects,
                % just pass through to initialize the inspector
                obj = objToInspect;
                this.initInspector([]);
            else
                objToInspect = handle(objToInspect);
                % Avoid using parent indexing on scalar objects.  Some objects
                % error when trying to index on them.
                if isempty(objToInspect) || isscalar(objToInspect) || numel(objToInspect) == 1
                    obj = objToInspect;
                else
                    obj = objToInspect(1);
                end

                % Call the inspector helper method, as this not only checks
                % isgraphics(), but also handles objects like DataTipTemplate,
                % which isgraphics() is false, but is inspectable as part of the
                % figure hierarchy (and has an ancestor).
                if internal.matlab.inspector.Utils.isAllGraphics(obj)
                    hFig = ancestor(obj,'figure');
                else
                    hFig = [];
                end
                this.initInspector(hFig);
            end

            if ismethod(obj,'getObjectToInspect')
                objToInspect = obj.getObjectToInspect();
            end

            % Inspect the current object
            this.inspectObj(objToInspect);
        end

        % Add one-shot listener to listener to plot-edit mode being enabled
        function addPlotEditModeListener(this,hFig)
            % Get the modemanager and add a listener to respond to
            % plot-edit mode being enabled
            hManager = uigetmodemanager(hFig);
            this.PlotEditModeListener = event.proplistener(hManager,...
                findprop(hManager,'CurrentMode'),'PostSet',@(e,d)this.showWhenPlotEditEnabled(e,d,hFig));
        end

        % Dispose the InspectorFrame and the desktop client
        function closePropertyInspector(this)
            % Need to delete inspector manager, to make sure all timer
            % objects are deleted on closing the inspector window
            this.hideInspectorWindow();

            this.CurrentFigure = [];
            this.setInspectorClosedManually();
        end

        function setCurrentVarName(this, varName)
            % Save the current variable name and whether it was a change or not
            this.CurrentVarNameChange = ~isequal(varName, this.CurrentVarName);
            if isempty(varName)
                this.CurrentVarName = "";
            else
                this.CurrentVarName = varName;
            end
        end
    end

    methods (Access = private)
        % handler to show inspector when plot-edit mode is enabled
        function showWhenPlotEditEnabled(this,~,d,hFig)
            % Show inspector when plot-edit mode is enabled
            hMode = d.AffectedObject.CurrentMode;
            if ~isempty(hMode) && strcmpi(hMode.Name,'Standard.EditPlot')
                selectedObjects = hMode.ModeStateData.PlotSelectMode.ModeStateData.SelectedObjects;
                styleSelectionHandles(hFig);
                this.showInspector(selectedObjects);
            end

            % Remove the one-shot plot edit mode listener
            delete(this.PlotEditModeListener);
            this.PlotEditModeListener = [];
        end

        function initPlotSelectListener(this)
            % Get the plotmgr and add a listener to respond to clicks in
            % Plot Edit mode
            plotmgr = matlab.graphics.annotation.internal.getplotmanager;
            this.PlotSelectListener  = event.listener(plotmgr,'PlotSelectionChange',@this.localChangedSelectedObjectsCallback);
        end

        function initFigureBeingDestroyedListener(this)
            this.FigureBeingDestroyedListener  = event.listener(this.CurrentFigure, ...
                'ObjectBeingDestroyed',@(e,d) this.hideInspectorWindow());
        end

        % Plot Selection change event handler for the figure
        function localChangedSelectedObjectsCallback(this,~,eventData)
            % If current figure is not using side panel infrastructure,
            % then fire this callback. Else, not. Also, eventData.Figure is
            % pointing to the new figure being selected. If the newly
            % selected figure is undocked java figure or uifigure in MATLAB
            % Online, we should show standalone inspector
            if ~this.IsInspectorClosedManually && ...
                    ~matlab.graphics.internal.propertyinspector.shouldShowEmbeddedInspector(this.CurrentFigure) && ...
                    ~matlab.graphics.internal.propertyinspector.shouldShowEmbeddedInspector(eventData.Figure)
                this.showInspector(eventData.SelectedObjects);
            end
        end

        % Set the height of the inspector window. Default width set is 350
        function setInspectorHeight(this)
            figureToolBarHeight = 0;
            if ~isempty(this.CurrentFigure) && isvalid(this.CurrentFigure)
                figureToolBarHeight = this.CurrentFigure.OuterPosition(4) - this.CurrentFigure.Position(4);
            end
            defaultFigureHeight = this.DEFAULT_FIGURE_SIZE(4) + figureToolBarHeight;
            this.setInspectorWindowSize(defaultFigureHeight);
        end
    end

    methods(Access = protected)

        function showInspectorForUIFigure(this)

            if this.useWebWindow()
                this.showInspectorForUIFigureWebWindow();
                return
            end

            % The Inspector for uifigures is shown to the right of the
            % default position of the figure when it is opened for the
            % first time.

            % Add Inspector window listeners, needed for Undo/Redo
            if usejava('jvm')
            com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.setCurrentFigure(this.CurrentFigure);
            com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.showInspector();
            end

            if ~this.UIFigureInspectorPositioned
                % TODO: to replace this logic with a utility used for positioning
                % apps next to the figure
                screenSize =  get(0,'ScreenSize');
                figureFameBuffer = 25;

                x = screenSize(3) - this.DEFAULT_FIGURE_SIZE(1);
                y = screenSize(4)- (this.DEFAULT_FIGURE_SIZE(2) + this.DEFAULT_FIGURE_SIZE(4) + figureFameBuffer);

                if usejava('jvm')
                com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.moveInspectorTo(x,y);
                end
                this.UIFigureInspectorPositioned = true;
            end
        end

        function showInspectorForUIFigureWebWindow(this)

            % The Inspector for uifigures is shown to the right of the
            % default position of the figure when it is opened for the
            % first time.
            if isempty(this.WebWindow) || ~isvalid(this.WebWindow) || ...
                    ~this.WebWindow.isWindowValid
                this.initWebWindow();
            end

            if ~this.UIFigureInspectorPositioned
                % TODO: to replace this logic with a utility used for positioning
                % apps next to the figure
                screenSize =  get(0,'ScreenSize');
                figureFameBuffer = 25;
                horizontalBuffer = 5;

                x = screenSize(3) - this.DEFAULT_FIGURE_SIZE(1) + horizontalBuffer;

                % bottom left is the origin for webwindow
                y = this.DEFAULT_FIGURE_SIZE(2) + this.DEFAULT_FIGURE_SIZE(4) - this.WebWindow.Position(4) - figureFameBuffer;

                if ~isempty(this.WebWindow) % test
                    this.WebWindow.Position(1:2) = [x,y];
                    this.WebWindow.show();
                end

                this.UIFigureInspectorPositioned = true;
            elseif ~isempty(this.WebWindow)
                % When the inspector is re opened after manually closing
                if ~this.WebWindow.isVisible
                    this.WebWindow.show();
                end
            end
        end


        function initJavaPropertyInspectorManager(this)
            % Rapid focus changes can switch this.CurrentFigure to be a
            % non-java figure.
            % Also, check for condition when current figure can be empty
            % e.g. inspecting non-graphics objects
            if isempty(this.CurrentFigure) || ~isempty(matlab.graphics.internal.getFigureJavaFrame(this.CurrentFigure))

                % Current Figure's Window Frame is needed to add Window
                % Listeners onto the figure
                com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.setCurrentFigure(this.CurrentFigure,matlab.graphics.internal.getFigureJavaFrame(this.CurrentFigure));

                % Position the inspector window relative to the current figure
                javaMethodEDT('setInspectorWindowLocation', 'com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager');

                javaMethodEDT('showInspector', 'com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager');

                if ~this.FigurePositionDefaultsRestored
                    matlab.graphics.internal.drawnow.callback(@(e,d) com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.restoreToDefault());
                    this.FigurePositionDefaultsRestored = true;
                end

            end
        end

        % bring java inspector window to the front only when figure is
        % currently focused
        function bringInspectorToFrontIfNeeded(~)
            com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.bringInspectorToFrontIfNeeded();
        end

        % Hide Inspector Window
        function hideInspectorWindow(this)
            if ~isempty(this.WebWindow) && isvalid(this.WebWindow) && ...
                    this.WebWindow.isWindowValid
                this.WebWindow.hide();
            elseif usejava('jvm')
                com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.hideInspector();
            end

            this.removeListenersAndRestoreSelection();

            if matlab.graphics.internal.propertyinspector.PropertyInspectorManager.isRemoteClientThatMirrorsSwingUIs()
                % Call the forceCloseInspector method to close the MOL property
                % inspector, and set the current object to empty
                defaultInspectorInstance = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;
                inspectorManager = defaultInspectorInstance('/PropertyInspector');
                if ~isempty(inspectorManager.Documents)
                    inspectorManager.Documents.ViewModel.forceCloseInspector();
                    this.CurrentObject = [];
                end
            end
        end

        % Sets the size of the inspector window
        function setInspectorWindowSize(this,figureHeight)
            if ~isempty(this.WebWindow) && this.useWebWindow()
                this.WebWindow.Position(3) = this.DEFAULT_WINDOW_WIDTH;
                currHeight = this.WebWindow.Position(4);
                this.WebWindow.Position(4) = figureHeight;

                % Adjust the y position so it doesn't expand vertically offscreen
                this.WebWindow.Position(2) = this.WebWindow.Position(2) - currHeight;
                this.WebWindow.setMinSize([this.DEFAULT_WINDOW_WIDTH,this.MIN_WINDOW_HEIGHT]);
            else
                com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.setInspectorWindowSize(figureHeight);
            end
        end

        % Sets the figureFrame on the window
        function setFigureWindowFrame(~,figureFrame)
            com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.setFigureWindowFrame(figureFrame);
        end

        % Initial Setup. Happens only once when PropertyInspectorManager is
        % instantiated
        function this = PropertyInspectorManager(~)
            % If the platform is MATLAB Online, we should not instantiate
            % JxBrowser. MOL hosts inspector in mw-dialog.
            if ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.isRemoteClientThatMirrorsSwingUIs()
                % Starts the connector service and sets up the JxBrowser for the property inspector
                this.setupJXBrowserWindow();
            end
            % This is needed so that the server-side
            % DefaultPropertyInspector is ready to show. Inspector startup
            internal.matlab.inspector.peer.DefaultPropertyInspector.startup;


            % Register object selection callback to react to
            % selection change events in the figure
            hInspectorInstance = internal.matlab.inspector.peer.InspectorFactory.createInspector('default','/PropertyInspector');
            hInspectorInstance.registerObjectActionCallback(@internal.matlab.inspector.peer.InspectorActionHelper.actionEventHandler);

            % PropertyUndoRedoManager helps in performing undo/redo actions
            % for figure property changes.
            this.PropertyUndoRedoManager = matlab.graphics.internal.propertyinspector.PropertyUndoRedoManager.getInstance();
            sz = matlab.graphics.internal.propertyinspector.PropertyInspectorManager.DEFAULT_FIGURE_SIZE;
        end

        function setupJXBrowserWindow(this)
            % Ensure connector services are running.
            % It is important to call this in MATLAB because
            % of the changes in the implementation of this method which internally calls MATLAB.
            % This method will be called in the very beginning of starting
            % Inspector, and at that time connector probably would not be
            % fully on, related connector java class path not being set
            % correctly. Following call would be
            % no-op if connector already fully started, otherwise wait
            % until fully loaded
            connector.ensureServiceOn;
            % Get the path for the property inspector index page
            if this.setDebug()
                url = 'toolbox/matlab/datatools/inspector/js/peer/index-debug.html';
            else
                url = 'toolbox/matlab/datatools/inspector/js/peer/index.html';
            end

            % The desktop inspector should follow the desktop theme
            url = url + "?enableTheming=true";

            this.URLString = connector.getUrl(url);
            % Init the browser for the property inspector for supported
            % platforms
            if this.useWebWindow()
                this.initWebWindow();
            else
                javaMethodEDT('createPropertyInspectorManager', 'com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager', this.URLString);
            end
        end

        %Initialization of the web window
        function initWebWindow(this)
            this.WebWindow = matlab.internal.webwindow(this.URLString, matlab.internal.getDebugPort);
            this.WebWindow.CustomWindowClosingCallback = @(evt,src)this.closeWebWindowImpl();
        end

        % Inspect the selected object
        function inspectObj(this,obj)
            % Call DefaultPropertyInspector's inspect method
            defaultInspectorInstance = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;

            if defaultInspectorInstance.isKey('/PropertyInspector')
                inspectorDocumentModel = defaultInspectorInstance('/PropertyInspector');
                % Close the error dialog if showing previously. Make sure,
                % Documents and ViewModel exists since they can empty
                % before calling inspect
                if ~isempty(inspectorDocumentModel.Documents) && ~isempty(inspectorDocumentModel.Documents.ViewModel)
                    inspectorDocumentModel.Documents.ViewModel.handleSelectChange();
                end

                if this.needToInspect(obj, inspectorDocumentModel)
                    % Pass in the current variable name and workspace. workspace
                    % can be empty.  Once workspace handles (or better access to
                    % the 'caller') is supported this can be updated.
                    ws = "";
                    inspectorDocument = inspectorDocumentModel.inspect(obj,...
                        internal.matlab.inspector.MultiplePropertyCombinationMode.INTERSECTION,...
                        internal.matlab.inspector.MultipleValueCombinationMode.LAST, ...
                        ws, this.CurrentVarName);

                    this.CurrentObject = obj;
                    this.CurrentVarNameChange = false;

                    % ViewModel changes when we change the selection. Need to listen to
                    % the new view everytime
                    % DataChange event is thrown from PeerInspectorViewModel and
                    % PropertyUndoRedoManager needs the eventdata to add the
                    % undoredo command onto the figure uiundo stack

                    %  uifigures property editing is not currently undoable
                    if isNOTUIFigure(obj) && ~isjava(obj)
                        % add undo/redo listener only for graphics objects since we are using the figure's stack.
                        this.PropertyChangedListener = event.listener(inspectorDocument.ViewModel, 'DataChange', ...
                            @(e,d)this.PropertyUndoRedoManager.addCommandToUiUndo(e,d,this.CurrentFigure));
                    end
                else
                    inspectorDocumentModel.reinspect(obj,...
                        internal.matlab.inspector.MultiplePropertyCombinationMode.INTERSECTION,...
                        internal.matlab.inspector.MultipleValueCombinationMode.LAST, ...
                        "", this.CurrentVarName);
                end
                if ~this.useWebWindow()
                    com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.bringInspectorToFrontIfNeededWithFocus();
                    matlab.graphics.internal.drawnow.callback(@(e,d) javaMethodEDT('requestFocus', 'com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager'));
                end
            end
        end

        function b = needToInspect(this, obj, inspector)
            % inspect needs to be called if the CurrentObject is empty, if the
            % CurrentObject is different than the obj being inspected, if the
            % inspector documents are empty (so it hasn't been opened
            % previously), or if the name of the current variable has changed.
            % Otherwise, reinspect can be called.
            b = isempty(this.CurrentObject) || ...
                ~isequal(obj,this.CurrentObject) || ...
                isempty(inspector.Documents) || ...
                this.CurrentVarNameChange;
        end


        function ret = useWebWindow(this)
            ret = ~matlab.graphics.internal.propertyinspector.shouldShowEmbeddedInspector(this.CurrentFigure) && feature('webui');
        end

        function closeWebWindowImpl(this)
            this.WebWindow.close();
            this.WebWindow = matlab.internal.webwindow.empty;
            % Need to delete the timer because we are only hiding the
            % inspector, and not deleting it (to help with performance).
            % The timer will be recreated when the inspector is opened
            % again.
            deleteTimer();
        end
    end
end

% helper function to delete the timer
% Need to delete the timer because we are only hiding the
% inspector, and not deleting it (to help with performance).
% The timer will be recreated when the inspector is opened
% again.
function deleteTimer()
% Stop the timer from starting up again
defaultInspectorInstance = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;
if defaultInspectorInstance.isKey('/PropertyInspector')
    inspectorDocumentModel = defaultInspectorInstance('/PropertyInspector');
    if ~isempty(inspectorDocumentModel.Documents) && ~isempty(inspectorDocumentModel.Documents.ViewModel)
        inspectorDocumentModel.Documents.ViewModel.DataModel.stopTimer();
    end
end

% Forcibly stop the timer if it is currently running
t = timerfindall('Name', 'veHandleObj_inspector');
if ~isempty(t)
    stop(t);
    delete(t);
end
end

function ret = isNOTUIFigure(hObj)
if isjava(hObj)
    % Java objects are not in a uifigure
    ret = true;
elseif isscalar(hObj) || numel(hObj) == 1
    ret = isgraphics(hObj) && ~checkFigureType(hObj);
else
    ret = all(arrayfun(@(x) isgraphics(x) && ~checkFigureType(x), hObj));
end

    function result = checkFigureType(h)
        hFig = ancestor(h,'figure');
        result = ~isempty(hFig) && matlab.ui.internal.FigureServices.isUIFigure(hFig);
    end
end



