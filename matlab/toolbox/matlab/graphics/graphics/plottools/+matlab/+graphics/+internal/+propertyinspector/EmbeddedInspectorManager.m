classdef EmbeddedInspectorManager < handle

    % EmbeddedInspectorManager: Corresponds to the property inspector.
    % This class takes care of inspecting the properties for the graphic
    % objects such as axes, figure, line etc. integrated in a side panel

    % Copyright 2021-2024 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        DockedEmbeddedInspector;

        % Plot-Selection Change Listener
        PlotSelectListener;

        CurrentFigureListener;
    end

    properties(SetAccess = protected)
        PropertyChangedListener;
    end

    properties (Constant)
        INSPECTOR_PANELID = 'inspector'
        INSPECTOR_TITLE = getString(message('MATLAB:propertyinspector:InspectorTitle'))
        INSPECTOR_REGION = 'right'
        INSPECTOR_CREATE_PANEL_COLLAPSED = false
        INSPECTOR_CLOSEABLE = false
        INSPECTOR_DOM_NODE_ID = 'propertyInspectorDiv'
        INSPECTOR_SIDEBAR_ICON = 'propertyInspectorSB';
    end

    properties(SetAccess = protected, GetAccess = public)
        CurrentObject
        % Save the current variable name (if there is one)
        CurrentVarName string = strings(0);
        CurrentVarNameChange logical = false;
        PropertyChangedCodeGenListener;
    end

    methods (Static, Hidden)
        % EmbeddedInspectorManager class is a singleton
        function h = getInstance()
            mlock
            persistent hInspectorManager;
            if isempty(hInspectorManager)
                hInspectorManager = matlab.graphics.internal.propertyinspector.EmbeddedInspectorManager();
            end
            h = hInspectorManager;
        end

        % Returns true if we are in remote client supporting swing UIs and false otherwise.
        function isRemoteClient = isRemoteClientThatMirrorsSwingUIs()
            import matlab.internal.capability.Capability;
            isRemoteClient = ~Capability.isSupported(Capability.LocalClient) && ...
                Capability.isSupported(Capability.Swing);
        end

        function channelID = getFigureId(hFig)
            if isprop(hFig, 'MOLToolstripMggId')
                channelID = get(hFig, 'MOLToolstripMggId');
            else
                channelID = matlab.ui.internal.FigureServices.getUniqueChannelIdImpl(hFig);
            end
        end

        function isDockedOrWillBeDocked = isDockedFigure(hFig)
            isDockedOrWillBeDocked = strcmp(hFig.WindowStyle,'docked') ...
                  || matlab.graphics.internal.PlotEditModeUtils.willFigureBeDockedIntoContainer(hFig);
        end
		
        % When figure is destroyed
        function deleteInspector(hFig)                       
            figId = matlab.graphics.internal.propertyinspector.EmbeddedInspectorManager.getFigureId(hFig);

            cg = matlab.graphics.internal.propertyinspector.PropertyEditingCodeGenerator.getInstance();
            cg.removeFigureInfo(figId);

            % Forcibly stop the timer if it is currently running
            t = timerfindall('Name', 'veHandleObj_inspector');
            if ~isempty(t)
                stop(t);
                delete(t);
            end
			
			if isprop(hFig, 'EmbeddedInspector') && ~isempty(hFig.EmbeddedInspector)
				delete(hFig.EmbeddedInspector);
			end
			
        end
    end

    methods (Access = public, Hidden = true)
        % Show the Inspector Window and inspect the currently selected
        % object.
        function showInspector(this,objToInspect)
            for i=1:numel(objToInspect)

                hFig = ancestor(objToInspect(i),'figure');
                isDocked = this.isDockedFigure(hFig);

                this.initInspector(hFig);

                if ~isDocked || isempty(this.DockedEmbeddedInspector)
                    % Defer inspectObject() until "ViewReady" which guarantees
                    % that required subscription to inspector events is fully established
                    % in InspectorManager.js (g2988515)
                     this.createViewReadyCallback(hFig, objToInspect(i));
                end
            end
        end

        function temporarilyStopInspectorListeners(this)
            % Remove the plot selection change listener
            delete(this.PlotSelectListener);
            this.PlotSelectListener = [];

            delete(this.CurrentFigureListener);
            this.CurrentFigureListener = [];
        end

        function togglePlotSelectListeners(this, value)
            % Remove the plot selection change listener
            if ~isempty(this.PlotSelectListener)
                this.PlotSelectListener.Enabled = value;
            end

            if ~isempty(this.CurrentFigureListener)
                this.CurrentFigureListener.Enabled = value;
            end
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
		
        function obj = getCurrentInspector(this, hFig)
            obj = [];
            
            if ~this.isDockedFigure(hFig)
                if isprop(hFig, 'EmbeddedInspector')
                    obj = hFig.EmbeddedInspector;
                end
            else
                obj = this.DockedEmbeddedInspector;
            end
        end		
		
    end

    methods (Access = protected)

        function createViewReadyCallback(this, hFig, objToInspect)
            curInspector = this.getCurrentInspector(hFig);
            if ~isempty(curInspector) && isvalid(curInspector)
                curInspector.addViewReadyListener(@(h, ~) viewReadyCallback(this, hFig, objToInspect));
            end
        end

        function viewReadyCallback(this, hFig, objToInspect)
            % Set the current object to empty so we can inspect it
            % properly on startup
            this.CurrentObject = [];

            this.inspectObject(hFig, objToInspect);
        end

        % Show the inspector jFrame and position the window relative to the
        % figure
        function initInspector(this, hFig)
            if ~isempty(hFig) && isvalid(hFig)
                % Create a inspector for showing in a side panel
                this.createUIInspector(hFig);
            end

            % Setup the plot selection change listener
            if isempty(this.PlotSelectListener)
                this.initPlotSelectListener();
            end

            if isempty(this.CurrentFigureListener)
                this.CurrentFigureListener = event.proplistener(groot,...
                    findprop(groot,'CurrentFigure'),'PostSet',@this.updateOnSelectionChange);
            end

            this.initFigureBeingDestroyedListener(hFig);
        end

        % Creates inspector and publishes the message to show it in a
        % side panel
        function createUIInspector(this, hFig)

            if ~isempty(hFig) && isvalid(hFig)

                if ~this.isDockedFigure(hFig)

                    if ~isprop(hFig, 'EmbeddedInspector')
                        p = addprop(hFig, 'EmbeddedInspector');
                        p.Transient = true;
                        p.Hidden = true;
                    end

                    % For undocked figures create a unique instance of the
                    % Inspector g3239970
                    if isempty(hFig.EmbeddedInspector)
                        channelID = this.getFigureId(hFig);
						app = char(strcat('StandAloneFigure', channelID));
                        channel = char(strcat(channelID, '/inspector'));
                        hFig.EmbeddedInspector = internal.matlab.inspector.peer.InspectorFactory.createInspector(app,channel);
                        hFig.EmbeddedInspector.ShowObjectBrowser = true;

                        addlistener(hFig.EmbeddedInspector, 'PropertyEdited', @(e,d)this.updatePropertyEditingCode(e,d));                       

                        hFig.EmbeddedInspector.registerObjectActionCallback(@internal.matlab.inspector.peer.InspectorActionHelper.actionEventHandler);
                    end

                    inspectorId = hFig.EmbeddedInspector.InspectorID;                
                else
                    if isempty(this.DockedEmbeddedInspector) || ~isvalid(this.DockedEmbeddedInspector)
                        % Figures in a docked figure container can share an
                        % Inspector instance
                        this.DockedEmbeddedInspector = internal.matlab.inspector.peer.InspectorFactory.createInspector('default');
                        this.DockedEmbeddedInspector.ShowObjectBrowser = true;

                        this.PropertyChangedCodeGenListener = event.listener(this.DockedEmbeddedInspector, 'PropertyEdited', @(e,d)this.updatePropertyEditingCode(e,d));
                        % Listen to BreadCrumbs/Object Browser selection
                        this.DockedEmbeddedInspector.registerObjectActionCallback(@internal.matlab.inspector.peer.InspectorActionHelper.actionEventHandler);
                    end

                    inspectorId = this.DockedEmbeddedInspector.InspectorID;
                end

                % Track the first time the inspector is called for the figure to
                % allow initialization in cases like inspect(gca)
                if ~isprop(hFig, 'InitialInspect')
                    p = addprop(hFig, 'InitialInspect');
                    p.Transient = true;
                    p.Hidden = true;
                    hFig.InitialInspect = true;
                end

                matlab.graphics.internal.toolstrip.FigureToolstripManager.getInspectorState(hFig, true);

                matlab.graphics.internal.sidepanel.showSidePanel([], ...
                    this.INSPECTOR_PANELID, ...
                    this.INSPECTOR_TITLE, ...
                    this.INSPECTOR_REGION, ...
                    this.INSPECTOR_CREATE_PANEL_COLLAPSED, ...
                    this.INSPECTOR_CLOSEABLE, ...
                    hFig, ...
                    this.INSPECTOR_DOM_NODE_ID, ...
                    this.INSPECTOR_SIDEBAR_ICON, ...
                    true, ...
                    inspectorId);
            end
        end

        function inspectObject(this,hFig,objToInspect)
            import matlab.graphics.internal.toolstrip.FigureToolstripManager;

            % Short circuit in case the figure is deleted while this is
            % executing
            ShouldShowEmbeddedInspector = matlab.graphics.internal.propertyinspector.shouldShowEmbeddedInspector(hFig);
            if isempty(hFig) || ~isvalid(hFig) || strcmpi(hFig.BeingDeleted, 'on') ||  ~ShouldShowEmbeddedInspector
                return;
            end

            % If I am inspecting an object the state should be true
            if FigureToolstripManager.getInspectorState(hFig)

                % g1711013 get the object handle from hObjs. In case hObjs passed is
                % double(figure) etc
                objToInspect = handle(objToInspect);

                % Avoid using parent indexing on scalar objects.  Some objects
                % error when trying to index on them.
                if isempty(objToInspect) || isscalar(objToInspect)
                    obj = objToInspect;
                else
                    obj = objToInspect(1);
                end

                if ismethod(obj,'getObjectToInspect')
                    objToInspect = obj.getObjectToInspect();
                end

                if isempty(objToInspect)
                    objToInspect = hFig;
                end

                % Inspect the current object
                if all(isgraphics(objToInspect)) || isa(objToInspect,...
                        'matlab.graphics.datatip.DataTipTemplate') || isa(objToInspect,...
                        'matlab.graphics.internal.propertyinspector.views.DataTipTemplatePropertyView')
                    this.reinspectIfNeeded(hFig, objToInspect);

                    currInspector = this.getCurrentInspector(hFig);

                    if isempty(this.PropertyChangedListener) && ~isempty(currInspector)
                        % Register property sets with undo stack
                        propertyUndoRedoManager = matlab.graphics.internal.propertyinspector.PropertyUndoRedoManager.getInstance();
                        this.PropertyChangedListener = event.listener(currInspector.Documents.ViewModel,...
                            'DataChange',  @(e,d) propertyUndoRedoManager.addCommandToUiUndo(e,d,hFig));
                    end
                end
            end
        end

        function updatePropertyEditingCode(~,e,d)
            cg = matlab.graphics.internal.propertyinspector.PropertyEditingCodeGenerator.getInstance();
            cg.propertyChanged(e,d)
        end

        %This function created the initial inspector and calls inspect on the object if 
        % the object is not current
        function reinspectIfNeeded(this, hFig, obj)            
            currInspector = this.getCurrentInspector(hFig);
 
            if isempty(currInspector) || ~isvalid(currInspector)
                this.createUIInspector(hFig);

                this.createViewReadyCallback(hFig, obj);
            elseif this.needToInspect(obj, currInspector)
                currInspector.inspect(obj);  
                
                if isprop(hFig, 'InitialInspect') && hFig.InitialInspect
                    this.CurrentObject = [];
                    hFig.InitialInspect = false;
                else
                    this.CurrentObject = obj;
                end
            end
        end

        function b = needToInspect(this, obj, inspector)
            % inspect needs to be called if the CurrentObject is empty, if the
            % CurrentObject is different than the obj being inspected, if the
            % inspector documents are empty (so it hasn't been opened
            % previously), or if the name of the current variable has changed.
            % Otherwise, reinspect can be called.
            b = all(isempty(this.CurrentObject)) ||... 
                all(~isvalid(this.CurrentObject)) ||...
                all(~isequal(obj, this.CurrentObject)) || ...
                isempty(inspector.Documents) || ...
                this.CurrentVarNameChange;
        end
    end

    methods (Access = private)

        function initPlotSelectListener(this)
            % Get the plotmgr and add a listener to respond to clicks in
            % Plot Edit mode
            if isempty(this.PlotSelectListener)
                plotmgr = matlab.graphics.annotation.internal.getplotmanager;
                this.PlotSelectListener = event.listener(plotmgr,'PlotSelectionChange',@this.localChangedSelectedObjectsCallback);
            end
        end

        function updateOnSelectionChange(this,~,~)
            import matlab.graphics.internal.toolstrip.FigureToolstripManager;

            currentFigure = get(groot,'CurrentFigure');
            if ~isempty(currentFigure) && isvalid(currentFigure)                
                if FigureToolstripManager.getPlotEditState(currentFigure)
                    FigureToolstripManager.updatePlotEditState(currentFigure);
                    
                    modeManager = uigetmodemanager(currentFigure);
                    
					if ~isempty(modeManager) && ~isempty(modeManager.CurrentMode) &&...
                            ~isempty(modeManager.CurrentMode.ModeStateData.PlotSelectMode)
                        selectedObjects = modeManager.CurrentMode.ModeStateData.PlotSelectMode.ModeStateData.SelectedObjects;
                    else
                        selectedObjects = currentFigure;
                    end
					
                    this.inspectObject(currentFigure,selectedObjects);
                end
            else
                % Remove the plot selection change listener
                delete(this.PlotSelectListener);
                this.PlotSelectListener = [];

                delete(this.CurrentFigureListener);
                this.CurrentFigureListener = [];
            end
        end

        function initFigureBeingDestroyedListener(this, hFig)
            addlistener(hFig, ...
                'ObjectBeingDestroyed',@(e,d) this.deleteInspector(hFig));
        end

        % Plot Selection change event handler for the figure
        function localChangedSelectedObjectsCallback(this,~,eventData)
            this.inspectObject(eventData.Figure, eventData.SelectedObjects);
        end
    end
end

