classdef RemoteWorkspaceListener < handle & internal.matlab.datatoolsservices.WorkspaceListener
    % This undocumented function may be removed in a future release.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Hidden = true)
        % Keep track of the last value of 'ans', to prevent unnecessary updates
        % to the client
        LastAns = [];
        
        % Store the listeners which are added
        ListenerChannels string = strings(0);
        
        % Whether the listeners are enabled or not
        Enabled logical = true;
    end

    methods(Access='private')
        function obj = RemoteWorkspaceListener()
            obj@internal.matlab.datatoolsservices.WorkspaceListener(false);
        end
    end
    
    methods (Static)
        function observer = getInstance()
            % Get an instance of the RemoteWorkspaceListener
            mlock;
            persistent remoteListener;
            if isempty(remoteListener)
                remoteListener = matlab.internal.datatoolsservices.RemoteWorkspaceListener;
            end
            observer = remoteListener;
        end
        
        function addWorkspaceListener(channel)
            % Add a workspace listener for the given channel.  Lazily creates
            % the actual listener for MVM events when the first listener is
            % added here.
            
            arguments
                % The channel used for listening to the workspace events
                channel string
            end
            
            rwl = matlab.internal.datatoolsservices.RemoteWorkspaceListener.getInstance();
            rwl.addListener(channel);
        end
        
        function removeWorkspaceListener(channel)
            % Removes the workspace listener for the given channel.  When all
            % listeners are removed, the actual listener for MVM events is
            % disabled.
            
            arguments
                % The channel used for listening to the workspace events
                channel string
            end
            
            rwl = matlab.internal.datatoolsservices.RemoteWorkspaceListener.getInstance();
            rwl.removeListener(channel);
        end
        
        function enableListeners()
            % Called to enable all listeners
            rwl = matlab.internal.datatoolsservices.RemoteWorkspaceListener.getInstance();
            rwl.Enabled = true;
            if ~isempty(rwl.ListenerChannels)
                rwl.activate();
            end
        end
        
        function disableListeners()
            % Called dto disable the listeners.  This can be used when there is
            % an intensive operation going on, to prevent listeners from slowing
            % things down.
            rwl = matlab.internal.datatoolsservices.RemoteWorkspaceListener.getInstance();
            rwl.Enabled = false;
            rwl.deactivate();
        end
    end
    
    methods
        function workspaceUpdated(this, varNames, eventType)
            % Called when the workspace is updated.
            
            arguments
                this matlab.internal.datatoolsservices.RemoteWorkspaceListener
                varNames cell
                eventType internal.matlab.datatoolsservices.WorkspaceEventType
            end
            
            ed = this.getEventData(varNames, eventType);
            if ~isempty(ed)
                message.publish("/datatools/RemoteWorkspaceListener", ed);
            end
        end
        
        function delete(this)
            % Destructor, deactivates the listeners
            
            arguments
                this matlab.internal.datatoolsservices.RemoteWorkspaceListener
            end
            this.deactivate;
        end
    end
    
    methods(Hidden = true)
        function ed = getEventData(this, varNames, eventType)
            % Abort if this is an update to "ans" only and its value has
            % not changed.
            
            arguments
                this matlab.internal.datatoolsservices.RemoteWorkspaceListener
                varNames cell
                eventType internal.matlab.datatoolsservices.WorkspaceEventType
            end
            
            ed = [];
            if eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_CHANGED && ...
                    isequal(varNames,{'ans'})

                if evalin("debug", 'exist("ans", "var")')
                    % Some datetime comparisons with other types can throw warnings (about
                    % conversion to text, for example).  It's quicker to just always turn off
                    % these warnings than to check to see if they could happen.
                    w = warning("off", "MATLAB:datetime:AutoConvertStrings");
                    c = onCleanup(@() warning(w));

                    currentAns = evalin("debug", 'ans');
                    if isequal(this.LastAns, currentAns)                        
                        return;
                    end
                else
                    return;
                end
            end
            
            if evalin("debug", 'exist("ans","var")')
                this.LastAns = evalin("debug",'ans');
            end
            ed = struct(...
                "eventType", string(eventType), ...
                "varNames", varNames, ...
                "listeners", this.ListenerChannels);
        end
    end
    
    methods(Access = protected)
        function addListener(this, channel)
            
            arguments
                this matlab.internal.datatoolsservices.RemoteWorkspaceListener
                channel string
            end
            
            if isempty(this.ListenerChannels)
                this.activate();
            end
            this.ListenerChannels(end + 1) = channel;
            this.ListenerChannels = unique(this.ListenerChannels);
        end
        
        function removeListener(this, channel)
            arguments
                this matlab.internal.datatoolsservices.RemoteWorkspaceListener
                channel string
            end
            
            this.ListenerChannels(this.ListenerChannels == channel) = [];
            
            if isempty(this.ListenerChannels)
                this.deactivate();
            end
        end
        
        function activate(this)
            arguments
                this matlab.internal.datatoolsservices.RemoteWorkspaceListener
            end
            
            if this.Enabled
                internal.matlab.datatoolsservices.WorkspaceListener.enableLXEListeners
                % WorkspaceListener will add listener only if listener is not
                % already added
                this.addListeners();
            end
        end
        
        function deactivate(this)
            arguments
                this matlab.internal.datatoolsservices.RemoteWorkspaceListener
            end
        
            this.removeListeners();
        end
    end
end
