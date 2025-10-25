classdef PlotsTabListeners < handle
    % Adds Listeners to the variable editor and workspace browser selection
    % events so that the appropriate plots in the plots gallery can be
    % enabled.
    
    % Copyright 2013-2025 The MathWorks, Inc.
    properties
        % factory objects gets instances of the variable editor and
        % workspace browser managers
        
        % PlotsTabListeners for non-mgg VE integration
        desktopVEFactory;
        desktopVEmanagerFocusGainedListener;
        
        % variable editor listeners
        ManagerCreatedListener;
        desktopVEManager;
        desktopVEManagerFocusGainedListener;
        desktopVEDocumentFocusGainedListener;        
        desktopVEDocumentClosedListener;
        desktopVEDocumentTypeChangedListener;
        desktopVESelectionChangeListener;
        
        % workspace browser listeners
        wbManager;
        wbSelectionChangedListener;
        
        % timers for variable editor and workspace browser
        %selectionVETimer;
        %selectionWBTimer;
        
        % cache to store the previous selection to allow swapping
        prevSelectedFieldsWB;
        prevSelectedFieldsVE;
        
        % subscribing for events on the client side
        plotsChannelSubscription;     
    end

    properties(Access= ?matlab.unittest.TestCase)
        % Temp: Initialized settings for workspacebrowser
        PlotSettingsForWsb
        plotsMapBuiltListener
    end
    
    methods(Access='private')
        
        % This function adds the workspace browser and variable editor selection listeners
        function addPlotsGalleryListeners(this)
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::addPlotsGalleryListeners", "");
            if ~isvalid(this)
                % Because this can be called asynchronously there is a
                % chance that the this object is no longer valid
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::addPlotsGalleryListeners", "invalid listeners");
                return;
            end

            %------------- Variable Editor Listeners ---------------------%

            % instantiate a factory object to keep track of which manager has focus
            this.desktopVEFactory = internal.matlab.variableeditor.peer.VEFactory.getInstance; 

            % If Desktop VE instance is not yet created, wait for
            % ManagerCreated. Else, call addVariableEditorListeners directly.
            if ~internal.matlab.desktop_variableeditor.DesktopVariableEditor.getSetIsVariableEditorInitialized()
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::addPlotsGalleryListeners", "Adding listener for VE manager creation");
                this.ManagerCreatedListener = event.listener(this.desktopVEFactory, 'ManagerCreated',...
                @(es, ed)this.addVariableEditorListeners(ed));
            else
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::addPlotsGalleryListeners", "Adding VE listeners");
                dve = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance();
                ed.Manager = dve.PeerManager;
                this.addVariableEditorListeners(ed);
            end

            %------------- Workspace Browser Listeners -------------------%
            
            % create workspace manager
            % listen to the wb manager focus gained events
            % when the workspace gains focus, listen to selection changed
            % events
            % we also need a listener to the dataChanged event in the
            % workspace so that the selected variable can be updated in the
            % plots gallery
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::addPlotsGalleryListeners", "Adding WSB listeners");
            this.wbManager = internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.getInstance.Manager;
            this.wbSelectionChangedListener = event.listener(this.wbManager.Documents.ViewModel, 'SelectionChanged',...
                @(es, ed) internal.matlab.plotstab.PlotsTabListeners.handleWBSelectionChange(ed.EventName, false));
            
            %------------Listener for variables swapped event and Reuse figure state change-------------%
            
            this.plotsChannelSubscription = message.subscribe('/PlotsChannel', @(es)this.handleMessageFromClient(es), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.initPlotSettingsForWSB();
        end

        % Add VariableEditor listeners only when VEManager is created. 
        % Until then, PlotsGallery will respond to workspace selection
        % changes.
        function addVariableEditorListeners(this, eventData)
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::addVariableEditorListeners", "");
              %------------ Variable Editor Listeners ----------------------%
            mgr = eventData.Manager;
            if strcmp(mgr.Channel, '/VariableEditorMOTW')
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::addVariableEditorListeners", "Channel Match: " + mgr.Channel);
                % create a variable editor manager
                % listen to manager focus gained events
                % if manager gains focus, add a document focus gained listener
                this.desktopVEManager = mgr;
                
                % the veManager and document may gain focus at the same time.
                % Hence the document focus listener is added simultaneously.
                this.desktopVEDocumentFocusGainedListener = event.listener(this.desktopVEManager, 'DocumentFocusGained',...
                    @(es, ed) this.handleVEDocumentFocus(es, ed));
                
                % Document closed listener so that when the last tab is closed,
                % the plots gallery reacts to ve collapse
                this.desktopVEDocumentClosedListener = event.listener(this.desktopVEManager, 'DocumentClosed',...
                    @(es, ed) this.handleDocumentClosed());
    
                % One shot listener
                if ~isempty(this.ManagerCreatedListener)
                    delete(this.ManagerCreatedListener);
                    this.ManagerCreatedListener =[];
                end
                
                % Add MgrFocusGained Listener
                this.desktopVEManagerFocusGainedListener = event.listener(this.desktopVEFactory, 'ManagerFocusGained',...
                    @(es, ed)this.handleManagerFocusEvents(ed)); 
            end
        end

        function handleMessageFromClient(this, es)
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::handleMessageFromClient", "message: " + es.eventType);
            switch es.eventType
                case 'variablesSwapped'
                    this.swap(es);
                case 'updateGallery'
                    this.updateGallery(es);
                case {'plotExecuted', 'plotCommandShow'}
                    this.handlePlotExecution(es);
            end
        end

        function handlePlotExecution(this, es)
            % Create a cell array containing a string representation of the
            % selected data as a cell array e.g. '{data.Age(1:100);data.Weight(1:100)}'
            actionType = "execute";
            if strcmp(es.eventType, "plotCommandShow")
                actionType = "show";
            end
            name = '';
            if strcmp(es.selectionSrc,'variable')
                mgr = this.getCurrentFocusedVEManager(this);
                name = mgr.FocusedDocument.Name;
                s = settings;
                settingObj = s.matlab.desktop.variables.plotting;
            elseif strcmp(es.selectionSrc, 'workspace')
                settingObj = this.PlotSettingsForWsb;
            end
            pt = internal.matlab.plotstab.PlotsTabState.getInstance();
            pt.AutoLinkData = settingObj.LinkData.ActiveValue;
            internal.matlab.plotstab.PlotsTabUtils.handleExecution(es.itemTag, es.selectedVariables, name, es.isPrivateWorkspace, actionType, settingObj);                 
        end

        % For now, set all the auto codegen settings to be false for workpacebrowser
        % Except for Focus and Docking which we always want on. see g3019094
        % Future: Enhance this to define separate settings for
        % workspacebrowser or shared settings with the VE Gallery.
        function initPlotSettingsForWSB(this)
            this.PlotSettingsForWsb.GenerateTitle.ActiveValue = false;
            this.PlotSettingsForWsb.DockFigure.ActiveValue = true;
            this.PlotSettingsForWsb.FocusFigure.ActiveValue = true;
            this.PlotSettingsForWsb.LinkData.ActiveValue = false;
            this.PlotSettingsForWsb.GenerateLabels.ActiveValue = false;
            this.PlotSettingsForWsb.GenerateLegend.ActiveValue = false;
        end
        
        function updateGallery(~, es)
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::updateGallery", "message: " + es.operation);
            adaptor = internal.matlab.plotstab.PlotsTabAdapter.getInstance();
            adaptor.updatePlotsMap(es.data, es.operation);
        end
        
        % This function to call the method which swaps the currently selected
        % variables in the workspace browser
        function swap(this, es)
            if this.isVECurrentManagerForPlotsTab()
                this.handleVESelectionChange(es.eventType, false);
            else
                this.handleWBSelectionChange(es.eventType, false);
            end
        end
        
        function isCurrentManager = isVECurrentManagerForPlotsTab(this)
            plotsTabInstance = internal.matlab.plotstab.PlotsTabState.getInstance();
            if isempty(this.desktopVEManager)
                isCurrentManager = false;
            else
                isCurrentManager = strcmp(plotsTabInstance.currentManagerForPlotsTab, this.desktopVEManager.Channel);
            end
        end

        % This function adds a listener to listen to selection change events.
        % This listener is added when the variable editor gains focus.
        function handleVEDocumentFocus(this, es, ed)
            plotsTabInstance = internal.matlab.plotstab.PlotsTabState.getInstance(); 
            plotsTabInstance.currentManagerForPlotsTab = char(es.Channel);           
            
            % Call the selectionChange method to update the plots gallery.
            % This allows the plots gallery to reflect the correct
            % selection while switching between different document tabs
            internal.matlab.plotstab.PlotsTabListeners.handleVESelectionChange(ed.EventName, false);
            
            % event.listener ensures that when this document view model
            % goes out of scope, the listener tied to it no longer exists
            if this.isaVESelectionModel(es.FocusedDocument.ViewModel)
                if ~isempty(this.desktopVEDocumentTypeChangedListener)
                    delete(this.desktopVEDocumentTypeChangedListener);
                end
                if ~isempty(this.desktopVESelectionChangeListener)
                    delete(this.desktopVESelectionChangeListener);
                end
                this.desktopVEDocumentTypeChangedListener = event.listener(es.FocusedDocument, 'DocumentTypeChanged',...
                    @(es, ed) this.handleDocTypeChanged(ed.EventName));
                this.desktopVESelectionChangeListener = event.listener(es.FocusedDocument.ViewModel,...
                    'SelectionChanged', @(es, ed) internal.matlab.plotstab.PlotsTabListeners.handleVESelectionChange(ed.EventName, false));
            end
        end
        
        function isVESelectionModel = isaVESelectionModel(~, viewModel)
            isVESelectionModel = (isa(viewModel,'internal.matlab.legacyvariableeditor.SelectionModel') || ...
                isa(viewModel,'internal.matlab.variableeditor.SelectionModel'));
        end
        
        function handleDocumentClosed(this)
            event = 'selectionChanged';
            filteredData = struct('eventType',char(event));
            varsSelectedArray = cell(1,0);
            filteredData.items = [];
            filteredData.variables = varsSelectedArray;            
            if isempty(this.desktopVEManager.Documents)
                message.publish('/PlotsChannel', filteredData);
            end           
        end
        
        function handleManagerFocusEvents(this, ed)
            plotsTabStateInstance = internal.matlab.plotstab.PlotsTabState.getInstance();
            if strcmp(ed.Manager.Channel, '/WorkspaceBrowser') && ...
                    ~isempty(this.wbManager) && ...
                    ~isempty(this.wbManager.Channel)
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::handleManagerFocusEvents", "WSB");
                % check if the currently active manager cached in the PlotsTabState(plotsTabStateInstance.currentManagerForPlotsTab)
                % and the new manager(this.wbManager.Channel) are the same. If not then
                % execute selection changed call back
                if ~isequal(plotsTabStateInstance.currentManagerForPlotsTab, char(this.wbManager.Channel))
                    plotsTabStateInstance.currentManagerForPlotsTab = char(this.wbManager.Channel);
                    this.wbSelectionChangedListener.Enabled = true;
                    this.handleWBSelectionChange(ed.EventName, false);
                end
            elseif strcmp(ed.Manager.Channel, '/VariableEditorMOTW') && ...
                    ~isempty(this.desktopVEManager) && ...
                    ~isempty(this.desktopVEManager.Channel)
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::handleManagerFocusEvents", "VE");
                % check if the currently active manager cached in the PlotsTabState(plotsTabStateInstance.currentManagerForPlotsTab)
                % and the new manager(this.veManager.Channel) are the same. If not then
                % execute selection changed call back
                if ~isequal(plotsTabStateInstance.currentManagerForPlotsTab, char(this.desktopVEManager.Channel))
                    plotsTabStateInstance.currentManagerForPlotsTab = char(this.desktopVEManager.Channel);
                    this.wbSelectionChangedListener.Enabled = false;
                    this.handleVESelectionChange(ed.EventName, false);
                end
            end            
        end     
        
        function isMLWorkspace = isaVEMLWorkspace(~, workspace)
             isMLWorkspace = isa(workspace, 'internal.matlab.variableeditor.MLWorkspace');
        end
        
        % This is sensitive to whether focused document has updated when
        % doc type changes. Check for valid focusedDocument before adding
        % listeners
        function handleDocTypeChanged(this, eventname)
            if ~isempty(this.desktopVEManager.FocusedDocument) && this.isaVESelectionModel(this.desktopVEManager.FocusedDocument.ViewModel)
                this.desktopVESelectionChangeListener = event.listener(this.desktopVEManager.FocusedDocument.ViewModel,...
                    'SelectionChanged', @(es, ed) internal.matlab.plotstab.PlotsTabListeners.handleVESelectionChange(ed.EventName, false));
            end
            internal.matlab.plotstab.PlotsTabListeners.handleVESelectionChange(eventname, false);           
        end

        % Plots Adapter listener to track when plots map is built to
        % refresh selection on the Workspacebrowser. 
        % This is done once on cold start alone due to async workflows. 
        function createPlotsMapBuiltListener(this, plotsTabAdapter)
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::createPlotsMapBuiltListener", "");
            this.plotsMapBuiltListener = event.listener(plotsTabAdapter,...
                        'PlotsMapBuilt',...
                        @(es,ed)this.handlePlotsMapBuilt());
        end

        % On PlotsMap built by the PlotsTabAdapter, publish
        % 'SelectionChanged' in WSB and remove the one-shot listener.
        function handlePlotsMapBuilt(this)
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::handlePlotsMapBuilt", "");
            this.prevSelectedFieldsWB = [];
            internal.matlab.plotstab.PlotsTabListeners.handleWBSelectionChange('SelectionChanged', false);
            if ~isempty(this.plotsMapBuiltListener)
                delete(this.plotsMapBuiltListener);
                this.plotsMapBuiltListener = [];
            end
        end
    end
    
    methods(Access='public')
        % For testing purpose only
        function callHandleManagerFocusEvents(this, ed)
            this.handleManagerFocusEvents(ed);
        end
    end
    
    methods(Static=true)
        function init(forceNewInstance)
            arguments
                forceNewInstance (1,1) logical = false;
            end
            persistent initialized;

            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::init", "");
            message.publish('/plotsModuleStarted', true);
            if isempty(initialized) || forceNewInstance
                initialized = true;

                t = internal.matlab.plotstab.PlotsTabListeners.getInstance(true);
                % It's possible the WSB already has a selection.  Once the
                % plots have been initialized, call the event listeners so
                % the plots are updated (this only happens in tests)               
                plotsTabAdapter = internal.matlab.plotstab.PlotsTabAdapter.getInstance;
                
                if isempty(plotsTabAdapter.getPlotsMap)
                    t.createPlotsMapBuiltListener(plotsTabAdapter);                   
                else
                    t.handlePlotsMapBuilt();
                end
            end
        end

        % This function ensures that the state of the listeners is a
        % singleton.
        function out = getInstance(createListenersSynchronously, resetSelection)
            arguments
                createListenersSynchronously (1,1) logical = false

                % When true, resets the WSB selection.  Does not create an instance
                % if one is not already created.
                resetSelection (1,1) logical = false;
            end
            persistent sInstance;
            mlock;

            if resetSelection
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::getInstance", "resetSelection = true");
                if ~isempty(sInstance) && isvalid(sInstance)
                    sInstance.prevSelectedFieldsWB = [];
                end
            elseif isempty(sInstance) || ~isvalid(sInstance)
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::getInstance", "resetSelection = false");
                sInstance = internal.matlab.plotstab.PlotsTabListeners;
                if createListenersSynchronously
                    sInstance.addPlotsGalleryListeners();
                else
                    % Defer startup cost by initializing actions when MATLAB
                    % is idle g2427655
                    builtin('_dtcallback', @()sInstance.addPlotsGalleryListeners(),...
                        internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle);
                end
            end
            out = sInstance;
        end

        function focusedVEManager = getCurrentFocusedVEManager(this)
            plotsTabInstance = internal.matlab.plotstab.PlotsTabState.getInstance(); 
            focusedManagerChannel = plotsTabInstance.currentManagerForPlotsTab;          
            if (strcmp(focusedManagerChannel, this.desktopVEManager.Channel))
                focusedVEManager = this.desktopVEManager;
            else
                focusedVEManager = [];
            end
        end

        % Takes in selectionVarNames cell array {'a', 'b', ..} and returns a
        % formattedStr '{'a','b',...}'
        function formattedStr = getFormattedSelectionVarNames(selectionVarNames)
            if ~isempty(selectionVarNames)
                formattedStr = ['{''' selectionVarNames{1} ''''];
                for k=2:length(selectionVarNames)
                    formattedStr = [formattedStr ,',''',selectionVarNames{k} '''']; %#ok<AGROW>
                end
                formattedStr = [formattedStr,'}'];
            else
                formattedStr = '{}';
            end
        end
        
        
        % This function gets the formatted string for the selected cells, and
        % calls the event which sends this data to the client. Since the
        % current workspace at this instant is not the base workspace, this
        % call is executed using a web worker.
        function formattedSelection = handleVESelectionChange(eventName, usePrevious)
            arguments
                eventName
                usePrevious
            end
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::handleVESelectionChange", "");
            this = internal.matlab.plotstab.PlotsTabListeners.getInstance();
            formattedSelection = ''; 
            focusedManager = this.getCurrentFocusedVEManager(this);
            if strcmp(eventName, 'variablesSwapped')
                fieldsSelected = strsplit(this.prevSelectedFieldsVE, ';');
                if length(fieldsSelected) == 2
                    temp = fieldsSelected(1);
                    fieldsSelected(1) = fieldsSelected(2);
                    fieldsSelected(2) = temp;
                end
                formattedSelection = [fieldsSelected(1) ';' fieldsSelected(2)];
            elseif ~isempty(focusedManager) && ~isempty(focusedManager.FocusedDocument) && this.isaVESelectionModel(focusedManager.FocusedDocument.ViewModel)
                if this.isaVEMLWorkspace(focusedManager.FocusedDocument.ViewModel.DataModel.Workspace) && ...
                        ~focusedManager.FocusedDocument.ViewModel.DataModel.Workspace.supportsPlotGallery
                    this.handlePrivateWorkspaceSelection(focusedManager.FocusedDocument.ViewModel.DataModel.Workspace,{},eventName, 'variable');
                    return
                end
                
                % I need to use the previous selection if I get into this
                % function from the selection of the new figure or reuse
                % figure buttons
                if ~usePrevious
                    formattedSelection = focusedManager.FocusedDocument.ViewModel.getFormattedSelection();
                else
                    formattedSelection = this.prevSelectedFieldsVE;
                end
            end

            % Escape any single quotes
            formattedSelection = char(strrep(formattedSelection, "'", "''"));
            
            % Create a cell array containing a string representation of the
            % selected data as a cell array e.g. '{data.Age(1:100);data.Weight(1:100)}'
            selectionRange = {strcat('{',formattedSelection,'}')};

            % to allow swapping
            this.prevSelectedFieldsVE = formattedSelection;
            
            % The call to handle selection method (which evaluates the execution
            % strings of the selected data) needs to be called using a web
            % worker since we will not be in the same workspace as the
            % variables at this instant of execution
            % Here we build a string which represents the call to
            % handleSelection and pass it to the web worker for evaluation.
            % Create a string literal representation of the selected
            % variables, e.g., '{'data.Column1(1:100)','data.Column2(1:100)'}'
            if ~isempty(formattedSelection)
                selectionVarNames = internal.matlab.plotstab.PlotsTabUtils.getSelectionVarNamesForVariableEditor(formattedSelection, focusedManager.FocusedDocument);
                selectionVarNamesLiteral = internal.matlab.plotstab.PlotsTabListeners.getFormattedSelectionVarNames(selectionVarNames);
            else
                selectionVarNamesLiteral = '{}';
                selectionVarNames = {};
            end

            % For private workspaces which support the Plot Gallery,
            % internal.matlab.plotstab.PlotsTabUtils.handleSelection
            % should be called directly since the selected
            % variables can be derived from a call to the MLWorkspace
            % evalin() method
            try
                if ~isempty(focusedManager.FocusedDocument)
                    vm = focusedManager.FocusedDocument.ViewModel;
                    if isfield(vm, "DataModel") && isfield(vm.DataModel, "Workspace") && (this.isaVEMLWorkspace(vm.DataModel.Workspace))
                        this.handlePrivateWorkspaceSelection(vm.DataModel.Workspace,selectionVarNames,eventName);
                    else
                        execCommandString = strcat('[~] = internal.matlab.plotstab.PlotsTabUtils.handleSelection(',selectionRange, ...
                            ',', selectionVarNamesLiteral , ',''', eventName , ''',false,''variable'')');
                        internal.matlab.datatoolsservices.executeCmd(execCommandString);
                    end
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::handleVESelectionChange", "Error: " + e.message);
            end
        end
       
        % This function constructs the string with the information about the
        % currently selected workspace variables and calls the function
        % which communicates this data to the client
        function handleWBSelectionChange(eventName, usePrevious)
            internal.matlab.datatoolsservices.logDebug("PlotsTabListeners::handleWBSelectionChange", "");
            this = internal.matlab.plotstab.PlotsTabListeners.getInstance();
            selectedFields = [];
            if strcmp(eventName, 'variablesSwapped')
                % the 2 variables in the cached selection are swapped
                if length(this.prevSelectedFieldsWB) == 2
                    temp = this.prevSelectedFieldsWB(1);
                    this.prevSelectedFieldsWB(1) = this.prevSelectedFieldsWB(2);
                    this.prevSelectedFieldsWB(2) = temp;
                end
                selectedFields = this.prevSelectedFieldsWB;
            else
                mgr = this.wbManager;
                doc = mgr.FocusedDocument;
                if ~isempty(doc) && ~isempty(doc.ViewModel.SelectedRowIntervals)
                    % I need to use the previous selection if I get into this
                    % function from the selection of the new figure or reuse
                    % figure buttons
                    if ~usePrevious
                        try
                            selectedFields = this.wbManager.FocusedDocument.ViewModel.SelectedFields;
                            if isequal(selectedFields, this.prevSelectedFieldsWB)
                                % If the selected fields hasn't changed, just
                                % return.  The selectionChanged event may be fired
                                % because it refers to the row selection changing,
                                % which can happen when sorting or new variables
                                % being added, but the result may still be the same
                                % field being selected.
                                return
                            end
                        catch ex
                            % Ignore exceptions here
                        end
                    else
                        selectedFields = this.prevSelectedFieldsWB;
                    end
                end
            end
            % selectedFields is a string array containing the names of
            % selected variables
            selectedFieldsString = this.getSelectedFieldsString(selectedFields);
            
            % the previous selection is remembered to allow swapping
            this.prevSelectedFieldsWB = selectedFields;
            
            % Create a string literal representation of the selected
            % variables, e.g., '{'a','b'}'
            if ~isempty(selectedFieldsString)
                selectionNames = strsplit(selectedFieldsString,',');
                selectionVarNamesLiteral = ['{''' selectionNames{1} ''''];
                for k=2:length(selectionNames)
                    selectionVarNamesLiteral = [selectionVarNamesLiteral ,',''',selectionNames{k} '''']; %#ok<AGROW>
                end
                selectionVarNamesLiteral = [selectionVarNamesLiteral,'}'];
            else
                selectionVarNamesLiteral = '{}';
            end
            
            % For private workspaces which support the Plot Gallery,
            % internal.matlab.plotstab.PlotsTabUtils.handleSelection
            % should be called directly since the selected
            % variables can be derived from a call to the MLWorkspace
            % evalin() method
            % WSB has only one document, access document directly for cases
            % when focus might not be set.
            if isa(this.wbManager.Documents(1).ViewModel.DataModel.Workspace,'internal.matlab.variableeditor.MLWorkspace')
                this.handlePrivateWorkspaceSelection(this.wbManager.FocusedDocument.ViewModel.DataModel.Workspace,selectionNames,eventName, 'workspace');
            else
                % The string containing the current selection is passed to the
                % function which communicates this data to the client. This is
                % done via a web worker since we are not in the base workspace
                % at this instant

                execCommandString = strcat('[~] = internal.matlab.plotstab.PlotsTabUtils.handleSelection(','{',selectedFieldsString,'},', selectionVarNamesLiteral , ',''',eventName,''',false, ''workspace'')');

                execImmediately = internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle;
                if execImmediately
                    % This is used in test environments so this call happens
                    % synchronously and not after the test completes
                    execCommandString = strrep(execCommandString, "[~]", "eventData");
                    evalin("base", execCommandString);
                else
                    internal.matlab.datatoolsservices.executeCmd(execCommandString);
                end
            end
        end
        
        function selectedFieldsString = getSelectedFieldsString(selectedFields)
            % SelectedFields is a string array of selected variables
            selectedFieldsString = [];
            if ~isempty(selectedFields)
                selectedFieldsString = strjoin(selectedFields, ",");
            end
        end
        
        function publishData = handlePrivateWorkspaceSelection(ws,selectionNames,eventName, selectionSrc)
            if ws.supportsPlotGallery
                % Create a length(selectionVarNames)-by-1 cell array
                % containing the actual selected data
                selectedData = cell(length(selectionNames),1);
                for k=1:length(selectedData)
                    selectedData{k} = ws.evalin(selectionNames{k});
                end
                % Selection in private workspace with no execution
                % strings
                publishData = internal.matlab.plotstab.PlotsTabUtils.handleSelection(...
                    selectedData,selectionNames,eventName,true, selectionSrc);
            else
                publishData = internal.matlab.plotstab.PlotsTabUtils.handleSelection(...
                    {},{},eventName,true, selectionSrc);
            end
        end
    end
end
