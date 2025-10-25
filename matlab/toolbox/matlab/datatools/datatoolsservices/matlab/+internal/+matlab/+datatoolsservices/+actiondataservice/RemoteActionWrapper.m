classdef RemoteActionWrapper < handle
    %REMOTEACTION is a wrapper around the action to allow synchronization
    % with the client remotely. The class maintains the action and deals
    % with any notifications on the action like callback/property updates.
    % Abstract class that defines an addChild fn, implementing class should
    % add a remote connection on addChild.
    
    % Copyright 2019-2024 The MathWorks, Inc.    
    
   properties (SetAccess='private', WeakHandle)
        Action internal.matlab.datatoolsservices.actiondataservice.Action
   end
    
   %Listener Properties
    properties (SetObservable=false, Access='public', Dependent=false, Hidden=false)        
        ActionStateChangedListener; % Listents to Enabled state change in Actions.
        CallbackChangedListener; % Listens to Callback change in Actions.       
        PropertyValueChangedListener; % Listens to changes in property values on the Action.
    end 
    
    methods
        function this = RemoteActionWrapper(action, RemoteView)                    
             if ~isa(action, 'internal.matlab.datatoolsservices.actiondataservice.Action')
                error(message('MATLAB:codetools:datatoolsservices:InvalidAction'))
            end
            this.Action = action;            
            remoteActionProps = struct;
            fns = properties(this.Action);
            for i=1:length(fns)
                key = fns{i};
                if strcmpi(key, 'ID')
                    remoteActionProps.id = this.Action.(key);
                elseif strcmpi(key, 'Enabled')
                    remoteActionProps.enabled = this.Action.(key);
                    % Do not add 'Callback' as a peernode property.
                elseif strcmpi(key, 'Callback')
                    % Do not add object properties on the RemoteActionProps
                elseif ~(isobject(this.Action.(key)))
                    remoteActionProps.(key) = this.Action.(key);
                end
            end
            this.addChild('Action', remoteActionProps, RemoteView)
        end
      
        
        function initListeners(this)
            this.ActionStateChangedListener = event.listener(this.Action, 'ActionStateChanged', @(es, ed)this.setRemoteProperty('Enabled',this.Action.Enabled));
            this.CallbackChangedListener = event.listener(this.Action, 'CallbackChanged', @(es, ed)this.addActionCallBack(this.Action.Callback));
            this.PropertyValueChangedListener = event.listener(this.Action, 'PropertyValueChanged', @(es, ed)this.setRemoteProperty(ed.Property, ed.NewValue));                      
        end
        
        function addActionCallBack(this, callBack)
            this.Action.Callback = callBack;
        end        
        
        function setActionProperty(this, name, newValue, doNotify)
            this.Action.setProperty(name, newValue, doNotify);
        end 
        
         % Iterate through name-value pairs provided as Action properties
        % and set them on the Action.
        function this = updateActionProperty(this, args)
            props = args;
            % For name value args
            for index = 1:2:length(props)
                propName = props{index};
                propVal = props{index+1};
                if (strcmpi(propName, 'ID'))
                   error(message('MATLAB:codetools:datatoolsservices:ActionIDUpdate'));                     
                end
                this.setActionProperty(propName, propVal, true);
            end
        end
        
        % executes the callback for an action and reports back on the
        % status of an action as a PeerEvent.
        function executeCallBack(this, actionCallbackParams)
            if ~isempty(this.Action.Callback) && isa(this.Action.Callback, 'function_handle')
                try
                    status = '';
                    try
                        % Try calling the function with an output argument.
                        % (You can't use nargout on callback functions, so we
                        % need to use try/catch).
                        if isempty(actionCallbackParams)
                            status = this.Action.Callback();
                        else
                            status = this.Action.Callback(actionCallbackParams);
                        end
                    catch ex
                        if strcmp(ex.identifier, 'MATLAB:TooManyOutputs')
                            % If the exception is too many outputs, try calling
                            % again with no outputs
                            if isempty(actionCallbackParams)
                                this.Action.Callback();
                            else
                                this.Action.Callback(actionCallbackParams);
                            end
                        else
                            % If it were some other exception, just rethrow it.
                            rethrow(ex)
                        end
                    end
                    this.updateExecutionStatus('success', status);
                catch e
                    this.updateExecutionStatus('error', e.message);
                end       
            end
        end     
        
        function delete(this)
            this.deleteListener('ActionStateChangedListener');
            this.deleteListener('CallbackChangedListener');
            this.deleteListener('PropertyValueChangedListener');
            if isvalid(this.Action)
                delete(this.Action);
            end
        end
    end
    
   methods (Access='protected')
       function executionStatus = updateExecutionStatus(~, status, statusMessage)
            executionStatus = struct('type', 'executionStatus', 'status', status, ...
                'message', statusMessage);
       end
        
       function [name, newValue] = setRemoteProperty(this, name, newValue)
            if strcmpi(name, 'ID')
                name = 'id';
            end
            if strcmpi(name, 'Callback')
                this.addActionCallBack(newValue);
                return;
            end
            if strcmpi(name, 'Enabled')
                name = 'enabled';
            end            
        end
        
        function handleRemotePropertySet(this, name, newValue)
            if ~isempty(name) && ~isempty(newValue)                
                if strcmpi(name, 'id')
                    name = 'ID';
                elseif strcmpi(name, 'callback')
                    name = 'Callback';
                elseif strcmpi(name, 'enabled')
                    name = 'Enabled';
                end
                % This could be getting logicals, function handles or chars
                if isprop(this.Action, name) && (isequal(newValue , this.Action.(name)))
                    return;
                end
                this.updateActionProperty({name, newValue});
            end
        end       
        
        function deleteListener(this, listener)
            if ~isempty(this.(listener)) && isvalid(this.(listener))
                delete(this.(listener));
            end
        end
   end     
     
    methods (Access='public',Abstract=true)
        addChild(this, ActionType, RemoteActionProps, remoteViewModel);        
    end
end

