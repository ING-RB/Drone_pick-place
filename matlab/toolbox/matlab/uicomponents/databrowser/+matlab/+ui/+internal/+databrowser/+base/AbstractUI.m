classdef AbstractUI < handle & matlab.mixin.Heterogeneous
    % Master super class for AbstractDataBrowser.
    
    % Copyright 2020 The MathWorks, Inc.
    
    %% Private properties
    properties(Access = private, Transient)
        % stores event.listener objects in a cell array
        DataListeners
        % stores listener names in a cell array
        DataListenerNames
        % stores handle.listener or event.listener objects in a cell array
        UIListeners         
        % stores listener names in a cell array
        UIListenerNames
    end
    
    %% Public methods (UI life cycle management)
    methods
        
        function updateUI(this)
            % Method "updateUI": 
            %
            %   Programmatically refresh data browser based on the truth. 
            %
            %       updateUI(this)
            % 
            %   To be overloaded by subclass.
        end
    
        function delete(this)
            % delete all the data and UI listeners
            unregisterDataListeners(this);
            unregisterUIListeners(this);
            % force to clean up UI
            cleanupUI(this)
        end
        
    end
        
    %% Public methods (Data nd UI listener management)
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
    
    %% Protected methods (UI life cycle management)
    methods(Access = protected)
        
        function buildUI(this)  %#ok<*MANU>
            % Method "buildUI": 
            %
            %   Build layout and widgets used by the data browser. Expected
            %   to be called by the sub-class constructor.
            %
            %       updateUI(this)
            % 
            %   To be overloaded by subclass.
        end
        
        function connectUI(this)
            % Method "connectUI": 
            %
            %   Add listeners to data events and UI events. Expected to be
            %   called by the sub-class constructor.
            %
            %       connectUI(this)
            % 
            %   To be overloaded by subclass.
        end
        
        function cleanupUI(this)
            % Method "cleanupUI": 
            %
            %   Use it to destroy any orphan widgets when data browser is
            %   being delted. Expected to be called by the sub-class
            %   destructor.
            %
            %       cleanupUI(this)
            % 
            %   To be overloaded by subclass.
        end
        
    end
    
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
    
    %% Below this line are properties and methods for QE use only
    methods (Hidden)
       
        function widgets = getWidgets(this)
            % return UI widget references for QE tests
            % To be overloaded by sub-class.
            widgets = [];
        end
        
    end
        
end
    
