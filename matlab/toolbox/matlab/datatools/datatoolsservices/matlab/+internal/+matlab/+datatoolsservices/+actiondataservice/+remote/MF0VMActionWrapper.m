classdef MF0VMActionWrapper < internal.matlab.datatoolsservices.actiondataservice.RemoteActionWrapper
    %MF0ActionWrapper class has an Action class instance.
    
    % This class takes care of synchronizing actions with it's node such
    % that the client and server remain in sync. This class responds to
    % changes made to properties of the Actions and updates it's corresponding peernode properties. 
    % It also listens for changes on the peernode and updates the
    % corresponding action's properties.
    
    % Copyright 2017-2024 The MathWorks, Inc.
    
    properties (Access = 'private')
        PeerNode viewmodel.internal.ViewModel = viewmodel.internal.ViewModel.empty
        ParentNode viewmodel.internal.ViewModel = viewmodel.internal.ViewModel.empty
    end   
    
    properties (Access = 'private')
        DefaultEventType = 'peerEvent'
    end   
    
    properties (Constant)
        SRC_LANG_SERVER = "CPP";
        SRC_LANG_CLIENT = "JS" 
    end
    
    
    methods
        % Creates a PeerAction from properties provided as struct. A
        % node of type 'Action' is created and added on parentNode.        
        function this = MF0VMActionWrapper(action, parentNode)
            arguments
                action
                parentNode (1,1) viewmodel.internal.ViewModel
            end
            this@internal.matlab.datatoolsservices.actiondataservice.RemoteActionWrapper(action, parentNode);
            this.initListeners();            
        end 
        
        function initListeners(this)
            this.initListeners@internal.matlab.datatoolsservices.actiondataservice.RemoteActionWrapper();
            this.PeerNode.addEventListener('propertySet', @this.handleRemotePropertySet);
            this.PeerNode.addEventListener(this.DefaultEventType, @(es, ed) executeCallBack(this, es, ed));
        end
        
        function addChild(this, ActionType, ActionProps, parentNode)
            arguments
                this
                ActionType
                ActionProps
                parentNode (1,1) viewmodel.internal.ViewModel
            end
            childNode = parentNode.addChild(ActionType,ActionProps);
            this.PeerNode = childNode;
        end        
        
        % executes the callback for an action and reports back on the
        % status of an action as a PeerEvent.
        function executeCallBack(this, ~, ed)
            isSourceServer = nargin > 2 && ~isempty(ed.data) && isfield(ed, 'srcLang') && strcmp(ed.srcLang, this.SRC_LANG_SERVER);
            if ~isSourceServer 
                actionCallbackParams = [];    
                if exist('ed', 'var') && ~isempty(fieldnames(ed.data))
                    actionCallbackParams = ed.data;
                end
                this.executeCallBack@internal.matlab.datatoolsservices.actiondataservice.RemoteActionWrapper(actionCallbackParams);                                
            end
        end       
        
        function delete(this)
            if isvalid(this.PeerNode)
                delete(this.PeerNode);
            end
        end       
    end
    
    methods (Access='protected')
        
        function executionStatus = updateExecutionStatus(this, status, statusMessage)
            executionStatus = this.updateExecutionStatus@internal.matlab.datatoolsservices.actiondataservice.RemoteActionWrapper(status, statusMessage);
            executionStatus.source = 'server';
            if isvalid(this.PeerNode)
                this.PeerNode.dispatchEvent('peerEvent', executionStatus);
            end
        end
        
        % Sets Action's property values on the PeerNode.
        function setRemoteProperty(this, name, newValue)            
            [name, newValue] = this.setRemoteProperty@internal.matlab.datatoolsservices.actiondataservice.RemoteActionWrapper(name, newValue);                        
            if ~strcmpi(name, 'Callback')
                this.PeerNode.setProperty(name ,newValue);            
            end
        end
        
        % Sets PeerNode's property values on the Action.
        function handleRemotePropertySet(this, ~, ed)            
            name = ed.data.key;                        
            eventDataVal = ed.data.newValue;
            % When we set too many properties consecutively from the server, model gets into a state where it sends back
            % out of sync properties and this triggers an infinite update.
            % Forcing all legit property sets from client to send 'source' payload to correctly detect originator. 
            if ~strcmp(ed.srcLang, this.SRC_LANG_CLIENT)
                return;
            end
            newValue = eventDataVal.value;
            this.handleRemotePropertySet@internal.matlab.datatoolsservices.actiondataservice.RemoteActionWrapper(name, newValue);
        end
    end
end

