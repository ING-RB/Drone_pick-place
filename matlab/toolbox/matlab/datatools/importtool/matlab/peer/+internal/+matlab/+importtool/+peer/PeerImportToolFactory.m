% This class is unsupported and might change or be removed without notice
% in a future version.

classdef PeerImportToolFactory < handle
    % A class defining MATLAB PeerModel ImportTool Manager
    %

    % Copyright 2018-2024 The MathWorks, Inc.

    % Property Definitions:

    % Events
    events
        ManagerFocusGained;  % Sent from the factory when a manager gains focus
        ManagerFocusLost;  % Sent from the factory when manager loses focus
    end

    properties (Constant)
        % PeerModelChannel
        PeerModelChannel = '/ImportToolManager';

        % Force New Instance
        % Used to force creation of a new instance for testing purposes
        ForceNewInstance = 'force_new_instance';
    end

    properties (SetObservable = false, SetAccess = protected, GetAccess = public)
        Root;
        Channel = internal.matlab.importtool.peer.PeerImportToolFactory.PeerModelChannel;
        Initialized = false;
    end

    % Peer Listener Properties
    properties (SetObservable = false, SetAccess = protected, GetAccess = public)
        PeerEventListener;
        PropertySetListener;
        ImportDataPrefListener = [];
        ViewModelManager;
    end

    properties (Hidden = true)
        ManagerInstances;
        DeleteListeners;
        CreateActionsSynchronous logical = false;
    end

    % Constructor
    methods(Access='protected')
        function this = PeerImportToolFactory(appChannel)
            factory = viewmodel.internal.ViewModelManagerFactory;
            % made this local variable into a class property instead
            % because the manager was getting destroyed when it went out of
            % scope at the end of this method
            this.ViewModelManager = factory.getViewModelManager(appChannel);

            if ismethod(this.ViewModelManager, "setCallbackDebugFlag")
                % Set stop at breakpoints behavior
                this.ViewModelManager.setCallbackDebugFlag(~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            end

            this.Channel = appChannel;
            RootType = internal.matlab.importtool.peer.PeerImportToolFactory.PeerModelChannel;
            if isempty(this.ViewModelManager.getRoot()) || ~isvalid(this.ViewModelManager.getRoot())
                this.Root = this.ViewModelManager.setRoot(RootType);
                % Set Channel as a root property on the Manager
                this.Root.setProperty('Channel', appChannel);
            else
                this.Root = this.ViewModelManager.getRoot();
            end

            % Add peer event listener
            this.Root.addEventListener('peerEvent', @this.handlePeerEvent);
            this.Root.addEventListener('propertySet',@this.handlePropertySet);

            this.ManagerInstances = containers.Map;
            this.DeleteListeners = containers.Map();

            % Set the Initialized property
            formattedProp = internal.matlab.importtool.peer.PeerImportToolFactory.formatPropertyForRoot('Initialized', true);
            this.Root.setProperty('Initialized', formattedProp);

            % Send event for the factory ready
            root = this.Root;
            root.dispatchEvent('FactoryInitialized', struct);

            this.Initialized = true;
            message.subscribe(this.Channel + "/queryInitStatus", ...
                @(x) this.sendInitializedMessage(),...
                'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);

            this.sendInitializedMessage();

            if isempty(this.ImportDataPrefListener)
                s = settings;
                if hasSetting(s.matlab.confirmationdialogs, "ImportDataShowDialog")
                    this.ImportDataPrefListener = addlistener(...
                        s.matlab.confirmationdialogs, "ImportDataShowDialog", "PostSet", ...
                        @this.handleImportDataPrefChange);
                end
            end
        end

        function sendInitializedMessage(this)
            message.publish(this.Channel + "/importToolServerInitialized",...
                struct('initialized', true));
        end

        function handleImportDataPrefChange(~, ~, ed)
            enabled = ed.AffectedObject.ImportDataShowDialog.ActiveValue;
            s = matlab.internal.importdata.ImportProviderFactory.getAllProviderTypes;
            for idx = 1:length(s)
                p = feval(s(idx), "");
                p.updateShowDialogPref(enabled);
            end
        end
    end

    % Public methods
    methods
        % Handles all peer events from the client
        function handlePeerEvent(this, ~, ed)
            if isfield(ed.data, 'source') && strcmp('server', ed.data.source)
                return;
            end

            if isfield(ed.data, 'type')
                try
                    switch ed.data.type
                        case 'CreateManager' % Fired to start a server peer manager
                            this.logDebug('PeerImportToolFactory', 'handlePeerEvent', 'CreateManager');

                            if isfield(ed.data, 'fileType')
                                fileType = ed.data.fileType;
                            else
                                fileType = 'spreadsheet';
                            end

                            this.createManagerInstance(ed.data.channel, ...
                                struct(...
                                "FileName", ed.data.DataSource, ...
                                "Importer", internal.matlab.importtool.server.ImporterFactory.getImporter(ed.data.DataSource, fileType), ...
                                "ImportType", fileType));

                        case 'DeleteManager' % Fired to remove a server peer manager
                            this.logDebug('PeerImportToolFactory', 'handlePeerEvent', 'DeleteManager');

                            if this.getManagerInstances.isKey(ed.data.channel)
                                manager = this.createManagerInstance(ed.data.channel, '');
                                delete(manager);
                            end
                    end
                catch e
                    this.Root.dispatchEvent(struct(...
                        "type", "error", ...
                        "message", e.message, ...
                        "source", "server"));
                end
            end
        end

        function status = handlePropertySet(~, ~, ed)
            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.EventData.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            status = '';

            if isfield(ed.data.newValue, 'Source') && strcmp(ed.data.newValue.Source, 'server')
                return;
            end

        end

        function handlePropertyDeleted(this, ~, ~)
            m = getString(message(...
                'MATLAB:codetools:variableeditor:NoPropertiesShouldBeRemoved'));
            this.Root.dispatchEvent(struct('type','error','message',m,'source','server'))
        end

        function logDebug(~, class, method, message, varargin)
            % log using the standard logging
            internal.matlab.datatoolsservices.logDebug("import", class + ": " + method + ": " + message);
        end

        function obj = getManagerInstances(this, newManagerInstances)
            if nargin > 1
                this.ManagerInstances = newManagerInstances;
                this.logDebug('PeerImportToolFactory', 'getManagerInstances', 'set');
                keyVals = this.ManagerInstances.keys();
                managerJSON = ['[' sprintf('"%s",',keyVals{:})];
                managerJSON(end) = ']';

                % Set the Managers property
                formattedProp = internal.matlab.importtool.peer.PeerImportToolFactory.formatPropertyForRoot('Managers', managerJSON);
                this.Root.setProperty('Managers', formattedProp);
                this.logDebug('PeerImportToolFactory', 'getManagerInstances', 'set - done');
            else
                this.logDebug('PeerImportToolFactory', 'getManagerInstances', 'get');
            end

            obj = this.ManagerInstances;
        end

        function obj = createManagerInstance(this, channel, dataSource)
            import internal.matlab.importtool.peer.PeerImportToolFactory;
            import internal.matlab.importtool.server.ImportUtils;
            import internal.matlab.variableeditor.peer.PeerUtils

            managerInstances = this.getManagerInstances();
            managerInstance = [];

            if ~isempty(dataSource) && exist(dataSource.FileName, 'file')
                if ~isKey(managerInstances, channel)
                    this.logDebug('PeerImportToolFactory','createManagerInstance - key not set', channel);
                    provider = internal.matlab.variableeditor.peer.MF0ViewModelVEProvider(channel);

                    % Add in the CreateActionsSynchronous flag to the
                    % dataSource struct before manager creation
                    dataSource.CreateActionsSynchronous = this.CreateActionsSynchronous;
                    managerInstance = internal.matlab.importtool.peer.RemoteImportToolManager( ...
                        provider, dataSource);
                    if isempty(managerInstance.Documents)
                        % No document was created, so there was either an error
                        % when detectImportOptions was called, or after reading
                        % in the file, it was empty.  Either way, just return
                        % the managerInstance as is (without adding it to the
                        % managerInstances), and it will be handled as an error
                        % condition.
                        obj = managerInstance;
                        return;
                    else
                        this.logDebug('PeerImportToolFactory', 'createManagerInstance - setManagerInstances', channel);
                        managerInstances(channel) = managerInstance;
                        this.DeleteListeners(channel) = event.listener(managerInstance,...
                            'ObjectBeingDestroyed',...
                            @(es,ed) (this.getManagerInstances(managerInstances.remove(channel))));

                        this.getManagerInstances(managerInstances);
                        % Send event for the manager creation
                        tableList = managerInstance.getDocumentList();
                        [~, fname, ext] = fileparts(char(dataSource.FileName));

                        initialSheet = '';
                        if isfield(dataSource, "InitialSheet")
                            initialSheet = char(dataSource.InitialSheet);
                        end

                        payload = struct( ...
                            'type', 'ManagerCreated', ...
                            'Channel', channel, ...
                            'fileType', managerInstance.DataSource.ImportType, ...
                            'SheetNames', tableList, ...
                            'InitialSheet', initialSheet, ...
                            'HasMultipleTables', managerInstance.Documents.ViewModel.DataModel.FileImporter.HasMultipleTables, ...
                            'TableList', tableList, ...
                            'FullFileName', dataSource.FileName, ...
                            'DataSource', [fname ext]);

                        s = this.Root.getProperty('Managers');
                        payload.Managers = s.Managers;
                        payload.Source = 'server';
                        this.Root.setProperty('Managers', payload);
                        pause(0.1);
                        this.Root.dispatchEvent('peerEvent', payload);
                    end
                else
                    this.logDebug('PeerImportToolFactory', 'createManagerInstance - managerExists', channel);
                    managerInstance = managerInstances(channel);
                    payload = struct( ...
                        'type', 'ManagerExists', ...
                        'Channel', channel, ...
                        'fileType', managerInstance.DataSource.ImportType);
                    this.Root.dispatchEvent('peerEvent', payload);
                end

                % Close any progressMessages that are open
                ImportUtils.closeImportProgressWindow();

                % Send event for manager focus
                this.logDebug('PeerImportToolFactory','createManagerInstance - setFocusedManager', channel);
                PeerImportToolFactory.setFocusedManager(managerInstance);
            end

            % Return the new manager instances
            obj = managerInstance;
        end
    end

    % Protected Static methods
    methods(Static, Access='public')
        function inupdate = inFocusUpdate(varargin)
            persistent inUpdateChain;
            if isempty(inUpdateChain)
                inUpdateChain = false;
            end

            if (nargin > 0)
                inUpdateChain = varargin{1};
            end

            inupdate = inUpdateChain;
        end

        function obj = getSetFocusedManager(varargin)
            mlock; % Keep persistent variables until MATLAB exits
            persistent focusedManager;

            if internal.matlab.importtool.peer.PeerImportToolFactory.inFocusUpdate
                return;
            end

            obj = focusedManager;
            oldManager = focusedManager;

            % Short circuit if old value is same as new value or no value
            % passed in.  To prevent infinite loop.
            if nargin == 0 || ...
                    isequal(focusedManager, varargin{1}) || ...
                    (~isempty(varargin{1}) && ~isa(varargin{1}, 'internal.matlab.importtool.peer.RemoteImportToolManager')) || ...
                    (~isempty(varargin{1}) && strcmp(varargin{1}.Channel,internal.matlab.importtool.peer.PeerImportToolFactory.PeerModelChannel))
                return;
            end

            newManager = varargin{1};

            % Factory Instance
            factoryInstance = internal.matlab.importtool.peer.PeerImportToolFactory.getInstance();

            % Fire event when manager loses focus
            if ~isempty(focusedManager)
                eventdata = internal.matlab.variableeditor.ManagerEventData;
                eventdata.Manager = focusedManager;
                factoryInstance.notify('ManagerFocusLost',eventdata);
            end

            focusedManager = varargin{1};
            channel = '';

            % Fire event when manager gains focus
            if ~isempty(newManager)
                eventdata = internal.matlab.variableeditor.ManagerEventData;
                eventdata.Manager = newManager;
                factoryInstance.notify('ManagerFocusGained',eventdata);
                channel = newManager.Channel;
            end

            % Send a peer event with the new manager channel
            formattedProp = internal.matlab.importtool.peer.PeerImportToolFactory.formatPropertyForRoot('FocusedManager', channel);
            factoryInstance.Root.setProperty('FocusedManager', formattedProp);

            % Setting these must happen at the end because they will call
            % back into this method but the short circuit at the beginning
            % should prevent an infinite loop
            if ~isempty(oldManager) && isvalid(oldManager)
                internal.matlab.importtool.peer.PeerImportToolFactory.inFocusUpdate(true);
                oldManager.HasFocus = false;
                internal.matlab.importtool.peer.PeerImportToolFactory.inFocusUpdate(false);
            end
            if ~isempty(newManager)
                internal.matlab.importtool.peer.PeerImportToolFactory.inFocusUpdate(true);
                newManager.HasFocus = true;
                internal.matlab.importtool.peer.PeerImportToolFactory.inFocusUpdate(false);
            end
        end

        function setFocusedManager(manager)
            if isvalid(manager)
                internal.matlab.importtool.peer.PeerImportToolFactory.getSetFocusedManager(manager);
            end
        end
    end

    % Public Static Methods
    methods(Static, Access='public')
        % getInstance
        function obj = getInstance(appChannel, createIfNotInitialized)
            arguments
                appChannel char = internal.matlab.importtool.peer.PeerImportToolFactory.PeerModelChannel;

                % By default a factory will be created for the channel if
                % it hasn't been created already.  Set to false to return
                % [] if the factory for the channel hasn't been created.
                createIfNotInitialized (1,1) logical = true;
            end

            obj = [];
            if ~startsWith(appChannel, internal.matlab.importtool.peer.PeerImportToolFactory.PeerModelChannel)
                appChannel = [internal.matlab.importtool.peer.PeerImportToolFactory.PeerModelChannel appChannel];
            end

            mlock; % Keep persistent variables until MATLAB exits
            persistent factoryInstance;
            if isempty(factoryInstance)
                factoryInstance = containers.Map;
            end

            if createIfNotInitialized && ~isKey(factoryInstance, appChannel)
                managerInstance = internal.matlab.importtool.peer.PeerImportToolFactory(appChannel);

                factoryInstance(appChannel) = managerInstance;
                obj = managerInstance;
            elseif isKey(factoryInstance, appChannel)
                obj = factoryInstance(appChannel);
            end

            if createIfNotInitialized && ~isvalid(obj)
                managerInstance = internal.matlab.importtool.peer.PeerImportToolFactory(appChannel);
                factoryInstance(appChannel) = managerInstance;
                obj = managerInstance;
            end
        end

        function obj = createManager(Channel, IgnoreUpdates, fileName, fileType)
            import internal.matlab.importtool.peer.PeerImportToolFactory;

            factoryInstance = PeerImportToolFactory.getInstance();
            factoryInstance.logDebug('PeerImportToolFactory', 'createManager', '', 'channel', Channel, 'IgnoreUpdate', IgnoreUpdates);

            dataSource = struct(...
                "FileName", fileName, ...
                "Importer", internal.matlab.importtool.server.ImporterFactory.getImporter(fileName, fileType), ...
                "ImportType", fileType);
            obj = factoryInstance.createManagerInstance(Channel, dataSource);
        end

        function startup()
            % Makes sure the peer manager for the variable editor exists
            [~]=internal.matlab.importtool.peer.PeerImportToolFactory.getInstance();
        end

        function obj = getFocusedManager()
            % Get the currently focused manager
            obj = internal.matlab.importtool.peer.PeerImportToolFactory.getSetFocusedManager();
        end

        function resetAllOpenFiles(channel)
            arguments
                % for the desktop could be: PeerImportToolFactory.DesktopImportChannel
                channel string = internal.matlab.importtool.peer.PeerImportToolFactory.PeerModelChannel;
            end

            import internal.matlab.importtool.peer.PeerImportToolFactory;
            import internal.matlab.importtool.peer.DesktopImportTool;

            % Get the factory instance, specifying false to not create it
            % if it hasn't been created yet.
            f = PeerImportToolFactory.getInstance(channel, false);
            if ~isempty(f)
                mgrs = f.getManagerInstances;
                if ~isempty(mgrs)
                    mgrKeys = keys(mgrs);
                    for idx = 1:length(mgrKeys)
                        key = mgrKeys{idx};
                        mgr = mgrs(key);

                        try
                            % call reset() on its viewmodel
                            mgr.Documents.ViewModel.reset();
                        catch
                            % Ignore errors.  This shouldn't fail, but
                            % worst case the reset doesn't happen and the
                            % Import Tool remains in its current state.
                        end
                    end
                end
            end
        end

        function closeAllImportToolManagers(~)
            % No-op
        end

        function testCloseAllImportToolManagers(appChannel, count)
            arguments
                appChannel = ''

                % Provide the option to just close a specific number of managers (typically just 1)
                count = [];
            end

            internal.matlab.datatoolsservices.logDebug("import", "PeerImportToolFactory: testCloseAllImportToolManagers");

            % Closes all of the Import Tool managers
            if isempty(appChannel)
                f = internal.matlab.importtool.peer.PeerImportToolFactory.getInstance('', false);
            else
                f = internal.matlab.importtool.peer.PeerImportToolFactory.getInstance(appChannel, false);
            end

            if ~isempty(f)
                m = f.getManagerInstances;
                k = keys(f.getManagerInstances);
                if isempty(count)
                    % If not specified, delete all manager instances
                    count = length(k);
                end
                for idx = 1:count
                    mgr = m(k{idx});
                    delete(mgr);
                    pause(0.1);
                end
            end
        end

        function property = formatPropertyForRoot(propName, propValue)
            property = struct(propName, propValue, 'Source', 'server');
        end
    end
end
