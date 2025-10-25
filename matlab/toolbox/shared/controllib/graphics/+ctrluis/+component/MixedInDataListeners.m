classdef MixedInDataListeners < handle
% MixedIn class for data listener management.

    % Author(s): Rong Chen
    % Copyright 2014 The MathWorks, Inc.
    
    %% Private properties
    properties(Access = private, Transient)
        % stores event.listener objects in a cell array
        DataListeners
        % stores listener names in a cell array
        DataListenerNames
    end
    
    %% Protected methods
    methods
        
        function registerDataListeners(this, handles, varargin)
            % Example:
            %   lis1 = addlistener(dataobj,'Property','PostSet',@callback1);
            %   lis2 = addlistener(dataobj,'Event1',@callback2);
            %   lis3 = addlistener(dataobj,'Event2',@callback3);
            %   lis4 = addlistener(dataobj,'Event3',@callback4);
            %   registerDataListeners(this,lis1) % register a listener without a name
            %   registerDataListeners(this,lis2,'lis2') % register a listener with a name
            %   registerDataListeners(this,[lis3;lis4],{'lis3';'lis4'}) % register listeners with names
            % Note: register a listener only when you want to enable/disable it on the fly
            registerListeners(this, handles, varargin{:});
        end
        
        function unregisterDataListeners(this, varargin)
            % Example:
            %   unregisterDataListeners(this) % delete all listeners
            %   unregisterDataListeners(this,'lis1') % delete listener with a name
            %   unregisterDataListeners(this,{'lis2';'lis3'}) % delete listeners with names
            unregisterListeners(this, varargin{:});
        end
        
        function disableDataListeners(this, varargin)
            % Example:
            %   disableDataListeners(this) % disable all listeners
            %   disableDataListeners(this,'lis1') % disable listener with a name
            %   disableDataListeners(this,{'lis2';'lis3'}) % disable listeners with names
            onoffListeners(this, false, varargin{:});
        end
        
        function enableDataListeners(this, varargin)
            % Example:
            %   enableDataListeners(this) % enable all listeners
            %   enableDataListeners(this,'lis1') % enable listener with a name
            %   enableDataListeners(this,{'lis2';'lis3'}) % enable listeners with names
            onoffListeners(this, true, varargin{:});
        end
        
    end
    
    %% private methods
    methods (Access = private)
        
        function registerListeners(this, handles, names)
            % get # of handles
            num = numel(handles);
            % set default names to ''
            if nargin==2
                if num==1    
                    names = '';
                else
                    names = repmat({''},size(handles));
                end
            end
            % register listeners
            if num==1
                % scalar
                this.DataListeners = [this.DataListeners; handles];
                this.DataListenerNames = [this.DataListenerNames; {names}];                
            else                
                % vector
                for ct=1:num
                    this.DataListeners = [this.DataListeners; handles(ct)];
                    this.DataListenerNames = [this.DataListenerNames; names(ct)];                
                end
            end
        end
        
        function unregisterListeners(this, varargin)
            % locate listeners by names
            index = localFindIndex(this, varargin{:});
            % delete listeners
            delete(this.DataListeners(index));
            this.DataListeners(index) = [];
            this.DataListenerNames(index) = [];
        end
        
        function onoffListeners(this, value, varargin)
            % locate listeners by names
            index = localFindIndex(this, varargin{:});
            % enable/disable listeners
            for ct=1:length(index)
                this.DataListeners(index(ct)).Enabled = value;
            end
        end
        
        function index = localFindIndex(this, names)
            % default to selecting all listeners
            if nargin==1
                index = 1:length(this.DataListenerNames);
            else
                % find index
                if ischar(names)
                    % scalar: string
                    index = find(strcmp(this.DataListenerNames,names));
                else
                    % vector: cell array of strings
                    index = zeros(size(names));
                    for ct=1:length(names)
                        index(ct) = find(strcmp(this.DataListenerNames,names{ct}));
                    end
                    index = sort(index);
                end
            end
        end
        
    end
    
end