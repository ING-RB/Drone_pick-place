classdef MixInListeners < handle
    % MixIn class for listener management.

    % Copyright 2021 The MathWorks, Inc.
    
    %% Private properties
    properties (Access = private, Transient, NonCopyable)
        % stores listener objects in an array
        Listeners (:,1)
        % stores listener names in an array
        ListenerNames (:,1) string
    end

    %% Destructor
    methods
        function delete(this)
            delete(this.Listeners);
        end
    end
    
    %% Hidden methods
    methods (Hidden)        
        function registerListeners(this, handles, names)
            % Method "registerListeners": 
            %
            % Example:
            %   lis1 = addlistener(dataobj,'Property','PostSet',@callback1);
            %   lis2 = addlistener(dataobj,'Event1',@callback2);
            %   lis3 = addlistener(dataobj,'Event2',@callback3);
            %   lis4 = addlistener(dataobj,'Event3',@callback4);
            %   registerListeners(this,lis1)                            % register a listener without a name
            %   registerListeners(this,lis2,'lis2')                     % register a listener with a name
            %   registerListeners(this,[lis3;lis4],{'lis3';'lis4'})     % register listeners with names
            % 
            % Register a listener only when you want to enable/disable it on the fly

            arguments
                this (1,1) controllib.chart.internal.foundation.MixInListeners
                handles (:,1) handle
                names (:,1) string {localMustBeEqualSize(handles,names)} = matlab.lang.internal.uuid(numel(handles),1)
            end
            registerListeners_(this, handles, names);
        end
        
        function unregisterListeners(this,names)
            % Method "unregisterListeners": 
            %
            % Example:
            %   unregisterListeners(this)                   % delete all listeners
            %   unregisterListeners(this,'lis1')            % delete listener with a name
            %   unregisterListeners(this,{'lis2';'lis3'})   % delete listeners with names
            %
            %   any unregistered listener is deleted.

            arguments
                this (1,1) controllib.chart.internal.foundation.MixInListeners
                names (:,1) string = this.ListenerNames
            end
            unregisterListeners_(this,names);
        end

        function varargout = disableListeners(this,names,optionalArguments)
            % Method "disableListeners": 
            %
            % Example:
            %   disableListeners(this)                      % disable all listeners
            %   disableListeners(this,'lis1')               % disable listener with a name
            %   disableListeners(this,{'lis2';'lis3'})      % disable listeners with names

            arguments
                this (1,1) controllib.chart.internal.foundation.MixInListeners
                names (:,1) string = this.ListenerNames
                optionalArguments.EnableOnCleanUp (1,1) logical = false;
            end
            onoffListeners(this,false,names);
            
            varargout = {};
            if optionalArguments.EnableOnCleanUp
                varargout{1} = onCleanup(@() onoffListeners(this,true,names));
            end
        end
        
        function enableListeners(this,names)
            % Method "enableListeners": 
            %
            % Example:
            %   enableListeners(this)                       % enable all listeners
            %   enableListeners(this,'lis1')                % enable listener with a name
            %   enableListeners(this,{'lis2';'lis3'})       % enable listeners with names
            
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInListeners
                names (:,1) string = this.ListenerNames
            end
            onoffListeners(this,true,names);
        end

        function isEnabled = isListenerEnabled(this,name)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInListeners
                name (1,1) string
            end
            index = find(contains(this.ListenerNames,name));
            if isempty(index)
                isEnabled = false;
            else
                isEnabled = [this.Listeners(index).Enabled];
            end
        end
        
        function isListener = hasListener(this,name)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInListeners
                name (1,1) string
            end
            index = find(contains(this.ListenerNames,name),1);
            isListener = ~isempty(index);
        end

        function sources = getSourceForListener(this,name)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInListeners
                name (1,1) string
            end
            index = find(contains(this.ListenerNames,name),1);
            if ~isempty(index)
                hListener = this.Listeners(index(1));
                sources = hListener.Source;
            else
                sources = [];
            end
        end
    end

    %% private methods
    methods (Access = private)        
        function registerListeners_(this,handles,names)
            % register listeners
            this.Listeners = [this.Listeners; handles];
            this.ListenerNames = [this.ListenerNames; names];
        end
        
        function unregisterListeners_(this,names)
            % locate listeners by names
            index = find(contains(this.ListenerNames,names));
            % delete listeners
            if ~isempty(index)
                delete(this.Listeners(index));
                this.Listeners(index) = [];
                this.ListenerNames(index) = [];
            end
        end
        
        function onoffListeners(this,value,names)
            % locate listeners by names
            index = find(contains(this.ListenerNames,names));
            % enable/disable listeners
            if ~isempty(index)
                if ~ishandle(this.Listeners)
                    % MCOS Listeners
                    for ii = 1:length(index)
                        this.Listeners(index(ii)).Enabled=value;
                    end
                else
                    % UDD Listeners
                    if value
                        set(this.Listeners(index),Enabled='on');
                    else
                        set(this.Listeners(index),Enabled='off');
                    end
                end
            end
        end
    end    
end

% Custom validation function
function localMustBeEqualSize(a,b)
% Test for equal size
if ~isequal(size(a),size(b))
    eid = 'Size:notEqual';
    msg = 'Size of second input must equal size of third input.';
    throwAsCaller(MException(eid,msg))
end
end