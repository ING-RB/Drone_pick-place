classdef DesktopVariableEditor < handle
    % A class defining MATLAB Peer Variable Editor
    %

    % Copyright 2013-2025 The MathWorks, Inc.

    % Property Definitions:

    properties(Constant)
        PeerModelChannel = '/VariableEditorMOTW';
        ActionManagerNamespace = '/VEMOTWActionManager';
        startPath = 'internal.matlab.variableeditor.Actions'; 
        ContextMenuManagerNamespace = '/VEMOTWContextMenuManager';
        % This file contains the Variable Editor actions. If it doesn't exist, this condition is handled and no actions are created
        VEContextMenuActionsFile = fullfile(matlabroot,'toolbox','matlab','datatools','variableeditor','matlab','resources','VEActionGroupings.xml'); 
        UserContext = 'MOTW';
        messageServiceChannel = '/VariableEditorMOTW/MsgService'; 
    end

    properties (SetAccess = 'protected')
        VEActionManager;
        CodePublishingEnabledListener = [];
        ContextMenuProvider;
    end

    properties (SetAccess='private', GetAccess = 'public')
        VariableEditorInitialized
        ActionsInitialized (1,1) logical = false;
    end

    properties (SetObservable=false, SetAccess='protected', GetAccess='protected', Dependent=false, Hidden=false)
        PeerManager_I;
    end

    properties (SetObservable=false, SetAccess='protected', GetAccess='public', Dependent=true, Hidden=false)
        PeerManager;
    end

    methods
        function storedValue = get.PeerManager(this)
            if isempty(this.PeerManager_I) || ~isvalid(this.PeerManager_I)
                channel = internal.matlab.desktop_variableeditor.DesktopVariableEditor.PeerModelChannel;
                this.PeerManager_I = internal.matlab.variableeditor.peer.VEFactory.getInstance.createManager(channel, false);
            end
            storedValue = this.PeerManager_I;
        end

        function set.PeerManager(this, newValue)
            reallyDoCopy = ~isequal(this.PeerManager_I, newValue);
            if reallyDoCopy
                this.PeerManager_I = newValue;
            end
        end
    end

    properties (SetObservable=false, GetAccess='public', Dependent=true, Hidden=false)
        Documents;
    end
    methods
        function storedValue = get.Documents(this)
            storedValue = this.PeerManager.Documents;
        end
    end

    methods(Access='protected')
        % Constructor
        function this = DesktopVariableEditor(initializeSynchronously)
            arguments
                initializeSynchronously (1,1) logical = false
            end
            import internal.matlab.desktop_variableeditor.DesktopVariableEditor;

            message.subscribe(this.messageServiceChannel, @(evtData)this.handleEventFromClientVEFactory(evtData), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            veFactory = internal.matlab.variableeditor.peer.VEFactory.getInstance();
            this.PeerManager_I = veFactory.createManager(DesktopVariableEditor.PeerModelChannel, false);

            % % Defer startup cost by initializing actions when MATLAB
            % % is idle g2427655
            % if initializeSynchronously
            %     deferedInitialization;
            % else
            %     builtin('_dtcallback', @deferedInitialization,...
            %         internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle);
            % end
            
            % Initialize struct view to restore metadata from settings
            internal.matlab.variableeditor.ArrayViewModel.useSettingForContext(DesktopVariableEditor.UserContext, true);
        end

        % handle message from client to create a new manager for undocked window
        function handleEventFromClientVEFactory(this, eventData)	
            if strcmp(eventData.eventType, 'StartupServices')
                this.initializeServices();
            end           
        end

        function initializeServices(this)
            if ~isvalid(this)
                % Because this can be called asynchronously there is a
                % chance that the this object is no longer valid
                return;
            end
            if ~this.ActionsInitialized
                this.initCodePublishing();
                this.initActions();
                this.initContextMenu();
            end

            this.ActionsInitialized = true;
            % Post message for client-side to know that the services on the server side have been started
            message.publish(this.messageServiceChannel, "ServicesInitialized");
        end
        
        % Sets up code publishing by enabling
        function initCodePublishing(this)
            if isempty(this.CodePublishingEnabledListener)
                s = settings;
                this.CodePublishingEnabledListener = addlistener(...
                    s.matlab.desktop.arrayeditor, ...
                    'VECmdLineCodeGenEnabled', 'PostSet', ...
                    @this.handleCmdLineCodeGenEnabled);
                this.PeerManager_I.CodePublishing = s.matlab.desktop.arrayeditor.VECmdLineCodeGenEnabled.ActiveValue;
            end
        end

        function handleCmdLineCodeGenEnabled(this, ~, ed)
            enabled = ed.AffectedObject.VECmdLineCodeGenEnabled.ActiveValue;
            this.PeerManager_I.setProperty('VECmdLineCodeGenEnabled', enabled);
            this.PeerManager_I.CodePublishing = enabled;
            % Iterate on all the currently open documents and update CodePublishing Property.
            docs = this.PeerManager_I.Documents;
            for i=1:length(docs)
                dm = docs(i).DataModel;
                if isprop(dm, 'CodePublishing')
                    dm.CodePublishing = enabled;
                end
            end
        end
        
        % Starts up the Desktop VariableEditor's ActionDataService using
        % ActionManager that instantiates all the VEActions.
        function initActions(this)
            internal.matlab.datatoolsservices.logDebug("DesktopVariableEditor", "initActions");
            actionNamespace = internal.matlab.desktop_variableeditor.DesktopVariableEditor.ActionManagerNamespace;            
            pathToScan = internal.matlab.desktop_variableeditor.DesktopVariableEditor.startPath;
            this.VEActionManager = this.PeerManager_I.initActions(actionNamespace, pathToScan, ...
                'internal.matlab.datatoolsservices.actiondataservice.Action', true);   
        end   

        % Starts up the Desktop VariableEditor's ContextMenuManager Service by passing in 
        % ContextNamespace, queryString (target node for the context menus) and path of the XML file containing the Contextmenu options.
        function initContextMenu(this)            
            contextNamespace = internal.matlab.desktop_variableeditor.DesktopVariableEditor.ContextMenuManagerNamespace;            
            pathToXMLFile = internal.matlab.desktop_variableeditor.DesktopVariableEditor.VEContextMenuActionsFile;
            this.ContextMenuProvider = this.PeerManager_I.initContextMenu('.DesktopVariableEditor.focused', pathToXMLFile, contextNamespace);           
        end        
    end

    % Public Static Methods
    methods(Static, Access='public')
        % getInstance
        function obj = getInstance(forceNewInstance, syncInit)
            arguments
                forceNewInstance (1,1) logical = false;
                syncInit (1,1) logical = false;
            end
            mlock; % Keep persistent variables until MATLAB exits
            persistent managerInstance;
            if isempty(managerInstance) || forceNewInstance
                managerInstance = internal.matlab.desktop_variableeditor.DesktopVariableEditor(syncInit);
                internal.matlab.desktop_variableeditor.DesktopVariableEditor.getSetIsVariableEditorInitialized(true);
            end
            obj = managerInstance;
        end

        function isStarted = getSetIsVariableEditorInitialized(isInitialized)
            arguments
                isInitialized (1,1) logical = false;
            end
            mlock; % Keep persistent variables until MATLAB exits
            persistent variableEditorIntialized;
            if isempty(variableEditorIntialized) && (nargin > 0)
                variableEditorIntialized = isInitialized;
            end
            isStarted = variableEditorIntialized;
            if isempty(isStarted)
                isStarted = false;
            end
            internal.matlab.datatoolsservices.logDebug('DesktopVariableEditor::isVEInitialized::', string(isStarted));
        end
        

        function startup()
            % Makes sure the peer manager for the variable editor exists
            [~] = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance;
        end

        % Passthrough convenience methods
        function varDocument = openvar(name, workspace, data, userContext)
            if nargin < 2 || isempty(workspace)
                workspace = 'debug';
            end

            % NullValueObject - signals that we have to ask MATLAB for the
            % data
            if nargin<=2 || isa(data,'internal.matlab.variableeditor.NullValueObject')
                try
                    data = evalin(workspace, name);
                catch
                    data = internal.matlab.variableeditor.NullValueObject(name);
                end
            end

            if nargin<=3 || isempty(userContext)
                userContext = '';
            end

            varDocument = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.openvar(name, workspace, data, UserContext = userContext);
        end
        
        % If the document with oldName is currently open in desktop VE,
        % rename to newName
        function renamevar(oldName, newName)
            arguments
                oldName char
                newName char
            end
            internal.matlab.datatoolsservices.logDebug("DesktopVariableEditor", "renamevar from " + oldName + " to " + newName);
            desktop_ve = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance;
            docIndex = desktop_ve.PeerManager.documentIndex(oldName, 'debug');
            docIndexOfRenamedVar = desktop_ve.PeerManager.documentIndex(newName, 'debug');
            if ~isempty(docIndexOfRenamedVar)
                % if the new name being renamed already exists as a
                % document, we ignore the rename operation.
                return;
            end
            if (~isempty(docIndex))
                doc = desktop_ve.PeerManager.Documents(docIndex);
                doc.Name = newName;
                vm = doc.ViewModel;
                dm = vm.DataModel;
                s = vm.getSize();
                try
                    internal.matlab.datatoolsservices.logDebug("DesktopVariableEditor", "renamevar forcing data changed event");
                    eventData = internal.matlab.datatoolsservices.data.DataChangeEventData;
                    eventData.SizeChanged = false;
                    eventData.StartRow = 1;
                    eventData.EndRow = s(1);
                    eventData.StartColumn = 1;
                    eventData.EndColumn = s(2);
                    notify(dm, "DataChange", eventData);
                catch e
                    internal.matlab.datatoolsservices.logDebug("DesktopVariableEditor", "renamevar error forcing data changed event: " + e.message);
                end
            end

            % Find children matches
            beginingNameMatch = "^" + oldName + "\.*";
            childIndices = desktop_ve.PeerManager.documentRegexMatches(beginingNameMatch, 'debug');
            if ~isempty(childIndices)
                for i = 1:length(childIndices)
                    if childIndices(i) ~= docIndex % Rename already applied to parent document
                        doc = desktop_ve.PeerManager.Documents(childIndices(i));
                        doc.Name = regexprep(doc.Name, beginingNameMatch, newName + ".");
                        vm = doc.ViewModel;
                        dm = vm.DataModel;
                        s = vm.getSize();
                        try
                            internal.matlab.datatoolsservices.logDebug("DesktopVariableEditor", "renamevar forcing data changed event");
                            eventData = internal.matlab.datatoolsservices.data.DataChangeEventData;
                            eventData.SizeChanged = false;
                            eventData.StartRow = 1;
                            eventData.EndRow = s(1);
                            eventData.StartColumn = 1;
                            eventData.EndColumn = s(2);
                            notify(dm, "DataChange", eventData);
                        catch e
                            internal.matlab.datatoolsservices.logDebug("DesktopVariableEditor", "renamevar error forcing data changed event: " + e.message);
                        end
                    end
                end
            end

            datamanager.renameArrayEditorVariable(oldName, newName);
        end

        function closevar(name, workspace)
            if nargin < 2 || isempty(workspace)
                workspace = 'debug';
            end
            internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.closevar(name, workspace);
        end

        function closeAllVariables()
            internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.closeAllVariables();
        end

        function hasDoc = containsDocument(doc)
            hasDoc = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.containsDocument(doc);
        end

        function index = documentIndex(name, workspace)
            if nargin < 2 || isempty(workspace)
                workspace = 'debug';
            end
            index = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.documentIndex(name, workspace);
        end

        function index = docIdIndex(docID)
            index = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance.PeerManager.docIdIndex(docID);
        end
    end

    methods(Static, Hidden)
        function initializeAllServices()
            dve = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance();
            dve.initializeServices();
        end
    end
end

