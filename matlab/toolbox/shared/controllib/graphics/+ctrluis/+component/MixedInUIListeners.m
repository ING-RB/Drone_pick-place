classdef MixedInUIListeners < handle
    % MixedIn class for UI listener management.
    
    % Author(s): Rong Chen
    % Copyright 2014 The MathWorks, Inc.
    
    %% Protected properties
    properties(Access = private, Transient)
        % stores handle.listener or event.listener objects in a cell array
        UIListeners         
        % stores listener names in a cell array
        UIListenerNames
    end
    
    %% Protected methods
    methods
        
        function registerUIListeners(this, handles, varargin)
            % Example:
            %   lis1 = addlistener(widget1,'Event1',@callback1);
            %   lis2 = addlistener(widget2,'Event2',@callback2);
            %   lis3 = addlistener(widget3,'Event3',@callback3);
            %   lis4 = addlistener(widget4,'Event4',@callback4);
            %   registerUIListeners(this,lis1) % register a listener without a name
            %   registerUIListeners(this,lis2,'lis2') % register a listener with a name
            %   registerUIListeners(this,[lis3;lis4],{'lis3';'lis4'}) % register listeners with names
            % Note 1: register a listener only when you want to enable/disable it on the fly
            % Note 2: widget can be either a MCOS object or Java Swing object
            registerListeners(this, handles, varargin{:});
        end
        
        function unregisterUIListeners(this, varargin)
            % Example:
            %   unregisterUIListeners(this) % delete all listeners
            %   unregisterUIListeners(this,'lis1') % delete listener with a name
            %   unregisterUIListeners(this,{'lis2';'lis3'}) % delete listeners with names
            unregisterListeners(this, varargin{:});
        end
        
        function disableUIListeners(this, varargin)
            % Example:
            %   disableUIListeners(this) % disable all listeners
            %   disableUIListeners(this,'lis1') % disable listener with a name
            %   disableUIListeners(this,{'lis2';'lis3'}) % disable listeners with names
            onoffListeners(this, false, varargin{:});
        end
        
        function enableUIListeners(this, varargin)
            % Example:
            %   enableUIListeners(this) % enable all listeners
            %   enableUIListeners(this,'lis1') % enable listener with a name
            %   enableUIListeners(this,{'lis2';'lis3'}) % enable listeners with names
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
                this.UIListeners = [this.UIListeners; {handles}];
                this.UIListenerNames = [this.UIListenerNames; {names}];                
            else                
                % vector
                for ct=1:num
                    this.UIListeners = [this.UIListeners; {handles(ct)}];
                    this.UIListenerNames = [this.UIListenerNames; names(ct)];                
                end
            end
        end
        
        function unregisterListeners(this, varargin)
            % locate listeners by names
            index = localFindIndex(this, varargin{:});
            % delete listeners
            for ct=1:length(index)
                delete(this.UIListeners{index(ct)});
            end
            this.UIListeners(index) = [];
            this.UIListenerNames(index) = [];
        end
        
        function onoffListeners(this, value, varargin)
            % locate listeners by names
            index = localFindIndex(this, varargin{:});
            % enable/disable listeners
            for ct=1:length(index)
                lis = this.UIListeners{index(ct)};
                if isa(lis,'handle.listener')
                    if value
                        lis.Enabled = 'on';
                    else
                        lis.Enabled = 'off';
                    end
                else
                    lis.Enabled = value;
                end
            end                        
        end
        
        function index = localFindIndex(this, names)
            % default to selecting all listeners
            if nargin==1
                index = 1:length(this.UIListenerNames);
            else
                % find index
                if ischar(names)
                    % scalar: string
                    index = find(strcmp(this.UIListenerNames,names));
                else
                    % vector: cell array of strings
                    index = zeros(size(names));
                    for ct=1:length(names)
                        index(ct) = find(strcmp(this.UIListenerNames,names{ct}));
                    end
                    index = sort(index);
                end
            end
        end
        
    end
    
end

