classdef VEFactory < handle
    % VEFactory
    %   Factory responsible for keeping track of the existing Managers.
    %   Creates the managers and the appropriate providers to allow
    %   communication with the client

    % Copyright 2019-2021 The MathWorks, Inc.

    properties
        managers
    end

    % Events
    events
       ManagerFocusGained;  % Sent from the factory when a manager gains focus
       ManagerFocusLost;  % Sent from the factory when manager loses focus
       ManagerCreated; % Sent when a manager has been created on the factory
    end

    methods(Access='protected')
        function this = VEFactory()
        end
    end

    methods(Static, Access='public')
        function obj = getInstance(varargin)
            mlock; % Keep persistent variables until MATLAB exits
            persistent factoryInstance;
            if isempty(factoryInstance)% || ~isvalid(factoryInstance)
                % startup the Communication mechanism (in the current case MF0VMManagerFactory)
                % which can listen for create and delete Manager events from the client
                internal.matlab.variableeditor.peer.MF0VMManagerFactory.getRemoteInstance();
                factoryInstance = internal.matlab.variableeditor.peer.VEFactory();
            end
            obj = factoryInstance;
        end

        % Creates a new manager with the given Channel
        % if a manger with the given channel already exists then returns
        % the existing one
        function managerInstance = createManager(Channel, IgnoreUpdates, ActionManagerInfo)
            % Call into getInstance in case createManager is called before
            % factory is created to ensure that factory is started up.
            factoryInstance = internal.matlab.variableeditor.peer.VEFactory.getInstance();
            
            managerInstances = internal.matlab.variableeditor.peer.VEFactory.getManagerInstances();
            % calls createManager on RemoteManager class and passes in the
            % provider

            if ~exist('ActionManagerInfo', 'var')
                ActionManagerInfo = [];
            end

            mlock; % Keep persistent variables until MATLAB exits
            persistent deleteListeners; 

            if isempty(deleteListeners)
                deleteListeners = containers.Map();
            end

            if ~isKey(managerInstances, Channel)
                managerInstance = internal.matlab.variableeditor.peer.VEFactory.createNewManager(Channel, IgnoreUpdates, ActionManagerInfo);
                managerInstances(Channel) = managerInstance;
                deleteListeners(Channel) = event.listener(managerInstance,...
                    'ObjectBeingDestroyed',...
                    @(es,ed)internal.matlab.variableeditor.peer.VEFactory.removeInstance(Channel));

                internal.matlab.variableeditor.peer.VEFactory.getManagerInstances(managerInstances);

                eventdata = internal.matlab.variableeditor.ManagerEventData;
                eventdata.Manager = managerInstance;
                factoryInstance.notify('ManagerCreated', eventdata);
            end

            % Return the new manager instances
            managerInstance = managerInstances(Channel);
        end

        function removeInstance(Channel)
            mi = internal.matlab.variableeditor.peer.VEFactory.getManagerInstances;
            if isKey(mi, Channel)
                internal.matlab.variableeditor.peer.VEFactory.getManagerInstances(mi.remove(Channel));
            end
        end

        % deletes the manager with the given channel
        % Channel: channel of the manager to be deleted
        % serverOriginated: true if the delete is initiated on the server
        function deleteManager(Channel, serverOriginated)
            managerInstances = internal.matlab.variableeditor.peer.VEFactory.getManagerInstances();
            if isKey(managerInstances, Channel)
                managerInstances.remove(Channel);
                if serverOriginated
                    clientServerCommunicationHandler = internal.matlab.variableeditor.peer.VEFactory.getClientServerCommunicationHandler();
                    eventObj = struct();
                    eventObj.('type') = 'DeleteManager';
                    eventObj.('channel') = Channel;
                    clientServerCommunicationHandler.dispatchEventToClient(eventObj);
                end
            end
        end

        % returns the existing cache of managers if no arguments are passed
        % in
        % if newManagerInstances is not empty then resets the manager cache
        % to the value passed in
        function obj = getManagerInstances(newManagerInstances)
            mlock; % Keep persistent variables until MATLAB exits
            persistent managerInstances;

            if nargin > 0
                managerInstances = newManagerInstances;
            elseif isempty(managerInstances)
                managerInstances = containers.Map();
            end

            obj = managerInstances;
        end

        % Starts up itself by creating a singleton instance.
        function startup()
            % Makes sure the peer manager for the variable editor exists
            [~]=internal.matlab.variableeditor.peer.VEFactory.getInstance();
        end

        function logDebug(~, ~, ~, ~, varargin)
            % Arguments are this, class, method, message
        end

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

            if internal.matlab.variableeditor.peer.VEFactory.inFocusUpdate
                return;
            end

            if (~isempty(focusedManager) && ~isvalid(focusedManager))
                focusedManager = [];
            end
            obj = focusedManager;
            oldManager = focusedManager;

            % Short circuit if old value is same as new value or no value
            % passed in.  To prevent infinte loop.
            if nargin == 0 || ...
               isequal(focusedManager, varargin{1}) || ...
               (~isempty(varargin{1}) && ~isa(varargin{1}, 'internal.matlab.variableeditor.peer.RemoteManager'))
                return;
            end

            newManager = varargin{1};

            % Factory Instance
            factoryInstance = internal.matlab.variableeditor.peer.VEFactory.getInstance();

            % Fire event when manager loses focus
            if ~isempty(focusedManager)
                eventdata = internal.matlab.variableeditor.ManagerEventData;
                eventdata.Manager = focusedManager;
                factoryInstance.notify('ManagerFocusLost',eventdata);
            end

            focusedManager = varargin{1};
            channel = '';

            % Fire event when manager gainsfocus
            if ~isempty(newManager)
                eventdata = internal.matlab.variableeditor.ManagerEventData;
                eventdata.Manager = newManager;
                factoryInstance.notify('ManagerFocusGained',eventdata);
                channel = newManager.Channel;
            end

            % Notify the client regarding the focus change
            clientServerCommunicationHandler = internal.matlab.variableeditor.peer.VEFactory.getClientServerCommunicationHandler();
            clientServerCommunicationHandler.setProperty('FocusedManager', channel);

            % Setting these must happed at the end because they will call
            % back into this method but the short circuit at the beginning
            % should prevent an infinite loop
            if ~isempty(oldManager) && isvalid(oldManager)
                internal.matlab.variableeditor.peer.VEFactory.inFocusUpdate(true);
                oldManager.HasFocus = false;
                internal.matlab.variableeditor.peer.VEFactory.inFocusUpdate(false);
            end
            if ~isempty(newManager)
                internal.matlab.variableeditor.peer.VEFactory.inFocusUpdate(true);
                newManager.HasFocus = true;
                internal.matlab.variableeditor.peer.VEFactory.inFocusUpdate(false);
            end
        end

        function setFocusedManager(manager)
            internal.matlab.variableeditor.peer.VEFactory.getSetFocusedManager(manager);
        end

        function obj = getFocusedManager()
            % Get the currently focused manager
            obj = internal.matlab.variableeditor.peer.VEFactory.getSetFocusedManager();
        end

        % for testing only
        function obj = testGetClientServerCommunicationHandler()
            obj = internal.matlab.variableeditor.peer.VEFactory.getClientServerCommunicationHandler();
        end
    end

    methods(Static, Access='private')
        % Creates a new manager instance using the given channel name
        % Creates a peer provider and passes it into the manager
        function mgrInstance = createNewManager(Channel, IgnoreUpdates, ActionManagerInfo)
            managerInstances = internal.matlab.variableeditor.peer.VEFactory.getManagerInstances();
            provider = internal.matlab.variableeditor.peer.MF0ViewModelVEProvider(Channel);
            mgrInstance = internal.matlab.variableeditor.peer.RemoteManager(...
                                            provider, IgnoreUpdates, ActionManagerInfo);
            managerInstances(provider.Channel) = mgrInstance;
        end

        % TODO: Will be removed when the MF0VMManagerFactory functionality
        % is replaces with MessageService
        % Returns the PeerManager corresponding to the Factory which is
        % responsible for keeping track of the focusedManager communication
        % with the client
        function clientServerCommunicationHandler = getClientServerCommunicationHandler()
            clientServerCommunicationHandler = internal.matlab.variableeditor.peer.MF0VMManagerFactory.getRemoteInstance();
            clientServerCommunicationHandler = clientServerCommunicationHandler.PeerManager;
        end
    end
end
