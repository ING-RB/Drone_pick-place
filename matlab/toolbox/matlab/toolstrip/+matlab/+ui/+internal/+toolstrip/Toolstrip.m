classdef Toolstrip < matlab.ui.internal.toolstrip.base.Container
    % Layout Container (Toolstrip)
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.Toolstrip">Toolstrip</a>    
    %
    % Properties:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.DisplayState">DisplayState</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.SelectedTab">SelectedTab</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Component.Tag">Tag</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.DisplayStateChangedFcn">DisplayStateChangedFcn</a>            
    %
    % Methods:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.add">add</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.addTabGroup">addTabGroup</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.disableAll">disableAll</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.enableAll">enableAll</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.find">find</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.findAll">findAll</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.get">get</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.remove">remove</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.render">render</a>
    %
    % Events:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.DisplayStateChanged">DisplayStateChanged</a>        
    %   <a href="matlab:help matlab.ui.internal.toolstrip.Toolstrip.SelectedTabChanged">SelectedTabChanged</a>    
    %
    % See also matlab.ui.internal.toolstrip.TabGroup, matlab.ui.internal.toolstrip.Tab
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties (Dependent, GetAccess = public, SetAccess = private)
        % Property "SelectedTab": 
        %
        %   The currently selected Tab 
        %   It is a reference to the Tab object and the default value is [].
        %   It is read-only.
        %
        %   Example:
        %       tabgroup = matlab.ui.internal.toolstrip.TabGroup()
        %       tab1 = matlab.ui.internal.toolstrip.Tab('title1')
        %       tab2 = matlab.ui.internal.toolstrip.Tab('title2')
        %       tabgroup.add(tab1)
        %       tabgroup.add(tab2)
        %       tabgroup.SelectedTab = tab1 % select tab1 as current
        SelectedTab
    end
    
    properties (Dependent, Access = public)
        % Property "DisplayState": 
        %
        %   It takes one of the following strings: "expanded" (default),
        %   "collapsed" and "expanded_on_top".  The property is writable.
        %   Use this property to change the toolstrip display state.
        %
        %   Example:
        %       ts = matlab.ui.internal.toolstrip.Toolstrip()
        %       ts.DisplayState = 'collpased' % initialize toolstrip to be collapsed 
        DisplayState
        % Property "DisplayStateChangedFcn": 
        %
        %  Function Handle
        %   It is called when DisplayState property of Toolstrip is changed.
        DisplayStateChangedFcn
    end
    
    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        DisplayStatePrivate = 'expanded'
        QABIdPrivate = ''
    end
    
    properties (SetAccess = private, Hidden)
        % For swing rendering, a "***.swing.ToolstripSwingService" object
        % must be created externally and assigned via constructor
        % For JS rendering, it is left empty.
        ToolstripSwingService = []
    end
    
    % ----------------------------------------------------------------------------
    properties (Access = private)
        QuickAccessBarPrivate = []
        DisplayStateChangedFcnPrivate = []
        SelectedTabChangedListeners = []
        ToolstripModelManager
    end
    
    % ----------------------------------------------------------------------------
    events
        % Event "DisplayStateChanged": 
        %
        %   Fires toolstrip is collapsed or expanded
        %
        %   Example:
        %       ts = matlab.ui.internal.toolstrip.Toolstrip()
        %       listener = ts.addlistener('DisplayStateChanged',@YourCallback)
        DisplayStateChanged
        % Event "SelectedTabChanged": 
        %
        %   Fires when a new tab is selected from GUI
        %
        %   Example:
        %       tabgroup = matlab.ui.internal.toolstrip.TabGroup()
        %       tab1 = matlab.ui.internal.toolstrip.Tab('title1')
        %       tab2 = matlab.ui.internal.toolstrip.Tab('title2')
        %       tabgroup.add(tab1)
        %       tabgroup.add(tab2)
        %       listener = tabgroup.addlistener('SelectedTabChanged',@YourCallback)
        SelectedTabChanged
    end
    
    %% ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Constructor
        function this = Toolstrip(varargin)
            % Constructor "Toolstrip": 
            %
            %   Create a toolstrip.
            %
            %   Examples:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip();
            
            % super
            this = this@matlab.ui.internal.toolstrip.base.Container('Toolstrip');
            % create QAB
            this.QuickAccessBarPrivate = matlab.ui.internal.toolstrip.impl.QuickAccessBar();
            % passing in swing service only for swing rendering
            if nargin==1
                this.ToolstripSwingService = varargin{1};
            end
        end
        
        %% Get/Set Properties
        % DisplayState
        function value = get.DisplayState(this)
            % GET function for DisplayState property.
            value = this.DisplayStatePrivate;
        end
        function set.DisplayState(this, value)
            % SET function for DisplayState property.
            OK = matlab.ui.internal.toolstrip.base.Utility.validate(value, 'DisplayState');
            if OK
                this.DisplayStatePrivate = lower(value);
                this.setPeerProperty('displayState',lower(value));
            else
                error(message('MATLAB:toolstrip:container:invalidDisplayState'))
            end
        end
        % DisplayStateChangedFcn
        function value = get.DisplayStateChangedFcn(this)
            % GET function for DisplayStateChangedFcn property.
            value = this.DisplayStateChangedFcnPrivate;
        end
        function set.DisplayStateChangedFcn(this, value)
            % SET function for DisplayStateChangedFcn property.
            if internal.Callback.validate(value)
                this.DisplayStateChangedFcnPrivate = value;
            else
                error(message('MATLAB:toolstrip:general:invalidFunctionHandle', 'DisplayStateChanged'))
            end
        end
        % SelectedTab
        function obj = get.SelectedTab(this)
            % GET function for SelectedTab property.
            obj = [];
            for ct=1:length(this.Children)
                obj = this.Children(ct).SelectedTab;
                if ~isempty(obj)
                    break;
                end
            end
        end
        
        %% Overload delete
        function delete(this)
            this.SelectedTabChangedListeners = [];
            if ~isempty(this.ToolstripSwingService)
                % swing rendering only
                if isvalid(this.ToolstripSwingService)
                    this.ToolstripSwingService.cleanup();
                end
            end
        end
        
        %% Add/Remove
        function add(this, tabgroup, varargin)
            % Method "add":
            %
            %   "add(ts, tabgroup)": add a TabGroup object at the end of the toolstrip.
            %   Example:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip()
            %       tabgroup = matlab.ui.internal.toolstrip.TabGroup()
            %       ts.add(tabgroup)
            %
            %   "add(ts, tabgroup, index)": insert a TabGroup at a specified location in the toolstrip.
            %   Example:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip()
            %       tabgroup1 = matlab.ui.internal.toolstrip.TabGroup()
            %       ts.add(tabgroup1)
            %       tabgroup2 = matlab.ui.internal.toolstrip.TabGroup()
            %       ts.add(tabgroup2,1) % insert tabgroup2 as the first tab group
            if isa(tabgroup, 'matlab.ui.internal.toolstrip.TabGroup')
                add@matlab.ui.internal.toolstrip.base.Container(this, tabgroup, varargin{:});
                if nargin==2
                    % append
                    add(this.QuickAccessBarPrivate, tabgroup.getQuickAccessGroup(), 1);
                else
                    % insert
                    index = length(this.Children)+2-varargin{1};
                    add(this.QuickAccessBarPrivate, tabgroup.getQuickAccessGroup(), index);
                end
                this.SelectedTabChangedListeners = [this.SelectedTabChangedListeners; addlistener(tabgroup, 'SelectedTabChanged', @(src, event) SelectedTabChangedCallback(this, src, event))];
            else
                error(message('MATLAB:toolstrip:container:invalidObjectAddedToParent', class(tabgroup), class(this)));
            end
        end
        
        function remove(this, tabgroup)
            % Method "remove":
            %
            %   "remove(ts, tabgroup)": remove a TabGroup object from the toolstrip.
            %   Example:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip()
            %       tabgroup1 = matlab.ui.internal.toolstrip.TabGroup()
            %       tabgroup2 = matlab.ui.internal.toolstrip.TabGroup()
            %       ts.add(tabgroup1)
            %       ts.add(tabgroup2)
            %       ts.remove(tabgroup1) % now only tabgroup2 displayed
            if isa(tabgroup, 'matlab.ui.internal.toolstrip.TabGroup')
                if this.isChild(tabgroup)
                    remove@matlab.ui.internal.toolstrip.base.Container(this, tabgroup);
                    remove(this.QuickAccessBarPrivate, tabgroup.getQuickAccessGroup());
                    for ct=1:length(this.SelectedTabChangedListeners)
                        if this.SelectedTabChangedListeners(ct).Source{1}==tabgroup
                            this.SelectedTabChangedListeners(ct) = [];
                            break;
                        end
                    end
                %else
                %    error(message('MATLAB:toolstrip:container:invalidChild'));
                end
            else
                error(message('MATLAB:toolstrip:container:invalidObjectRemovedFromParent', class(tabgroup), class(this)));
            end
        end
        
        function tabgroup = addTabGroup(this)
            % Method "addTabGroup":
            %
            %   "tabgroup = addTabGroup(ts)": create a TabGroup object at
            %   the end of the toolstrip and returns its handle. Example:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip()
            %       tabgroup = ts.addTabGroup()
            tabgroup = matlab.ui.internal.toolstrip.TabGroup();
            this.add(tabgroup);
        end
        
        %% render
        function render(this, varargin)
            % Method "render" (Overloaded):
            %
            %   "render(ts, channel)": render toolstrip in the given peer
            %   model channel.  Initialize the peer model channel if it is
            %   not already initialized.
            %
            %   Example:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip()
            %       tabgroup = ts.addTabGroup()
            %       tab = tabgroup.addTab('title1')
            %       ts.render('/ToolstripShowcaseChannel')
            
            % get peer model channel name
            if nargin == 1
                % default channel
                channel = '/DefaultUIBuilderPeerModelChannel';
            else
                channel = varargin{1};
            end
            % initialize peer model channel if necessary
            this.ToolstripModelManager = matlab.ui.internal.toolstrip.base.ToolstripService.initialize(channel);
            % initialize action channel if necessary
            matlab.ui.internal.toolstrip.base.ActionService.initialize([channel '_Action']);
            % create QAB peer node and its children recursively
            this.QuickAccessBarPrivate.render(channel,'QuickAccessBar');
            % TODO: Remove this temp workaround, which ensures the peer model is updated before get call
            this.QuickAccessBarPrivate.dispatchEvent(struct);
            % get QAB peer node id
            this.QABIdPrivate = this.QuickAccessBarPrivate.getId();
            % create toolstrip peer node and its children recursively
            render@matlab.ui.internal.toolstrip.base.Container(this, channel, 'Toolstrip');
        end

        function varargout = attach(this, channel)
            % Method "attach" (Overloaded):
            %
            %   "attach(ts, channel)": attach toolstrip in the given peer
            %   model channel.  Initialize the peer model channel if it is
            %   not already initialized.
            %
            %   Example:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip()
            %       tabgroup = ts.addTabGroup()
            %       tab = tabgroup.addTab('title1')
            %       success = ts.attach('/ToolstripShowcaseChannel')
            
            nargoutchk(0,1);
            success = false;
            
            % get peer model channel name
            if nargin < 2
                % default channel
                channel = '/DefaultUIBuilderPeerModelChannel';
            end

            % initialize peer model channel if necessary
            this.ToolstripModelManager = matlab.ui.internal.toolstrip.base.ToolstripService.initialize(channel);
            % initialize action channel if necessary
            matlab.ui.internal.toolstrip.base.ActionService.initialize([channel '_Action']);

            % attach to toolstrip peer node and its children recursively
            this.ToolstripModelManager = matlab.ui.internal.toolstrip.base.ToolstripService.get(channel);
            ts = this.ToolstripModelManager.getByType('Toolstrip');
            if matlab.ui.internal.toolstrip.base.ViewModelUtilities.isViewModelChannel(channel)
                if ~isempty(ts) && isvalid(ts)
                    tsId = ts.getId(); % There shouldn't be more than one Toolstrip
                    attach@matlab.ui.internal.toolstrip.base.Container(this, channel, tsId);

                    % TODO: Remove this temp workaround, which ensures the peer model is updated before get call
                    this.dispatchEvent(struct);
                    % get QAB peer node id
                    this.QABIdPrivate = this.ToolstripModelManager.getByType('QuickAccessBar').getId();
                    % attach QAB peer node and its children recursively
                    attach@matlab.ui.internal.toolstrip.base.Container(this.QuickAccessBarPrivate, channel, this.QABIdPrivate);
                    success = true;
                end
            else
                if ~ts.isEmpty()
                    tsId = ts.get(0).getId(); % There shouldn't be more than one Toolstrip
                    attach@matlab.ui.internal.toolstrip.base.Container(this, channel, tsId);

                    % TODO: Remove this temp workaround, which ensures the peer model is updated before get call
                    this.dispatchEvent(struct);
                    % get QAB peer node id
                    this.QABIdPrivate = this.ToolstripModelManager.getByType('QuickAccessBar').get(0).getId();
                    % attach QAB peer node and its children recursively
                    attach@matlab.ui.internal.toolstrip.base.Container(this.QuickAccessBarPrivate, channel, this.QABIdPrivate);
                    success = true;
                end
            end
            
            if isequal(nargout, 1)
                varargout = {success};
            else
                varargout = {};
            end
        end

        %% AddToHost
        function addToHost(this, host)
            % Method "addToHost":
            %
            %   "addToHost(ts, div)": display toolstrip in the "div" dom
            %   node in the host container.
            %
            %   "addToHost(ts, java_comp)": display toolstrip in
            %   the "java_comp" component in the host container.
            %
            %   Example:
            %     Render in JavaScript:
            %       ts = matlab.ui.internal.toolstrip.Toolstrip()
            %       tabgroup = ts.addTabGroup()
            %       tab = tabgroup.addTab('title1')
            %       ts.render('/ToolstripShowcaseChannel')
            %       ts.addToHost('myDIV')
            % 
            %     Render in Swing:
            %       jf = javaObjectEDT('com.mathworks.mwswing.MJFrame');
            %       service = matlab.ui.internal.toolstrip.swing.ToolstripSwingService('/ToolstripShowcaseChannel');
            %       ts = matlab.ui.internal.toolstrip.Toolstrip(service);
            %       tabgroup = ts.addTabGroup()
            %       tab = tabgroup.addTab('title1')
            %       ts.render('/ToolstripShowcaseChannel')
            %       ts.addToHost(jf.getContentPane)
           
            % display toolstrip
            host = matlab.ui.internal.toolstrip.base.Utility.hString2Char(host);
            if ischar(host)
                % specify the DOM node
                this.setPeerProperty('hostId',host);
                % display
                this.dispatchEvent(struct('eventType','placeToolStrip','id',this.getId(),'hostId',host));
            elseif isjava(host)
                drawnow;
                jtoolstrip = this.ToolstripSwingService.Registry.getWidgetById(this.getId());
                javaMethodEDT('add',host,jtoolstrip.getComponent());
            else                
                error(message('MATLAB:toolstrip:container:invalidHostId'));
            end
        end
        
    end
    
    %% You must initialize all the abstract methods here
    methods (Access = protected)

        function rules = getInputArgumentRules(this) %#ok<MANU>
            % Abstract method defined in @component
            %
            % specify the rules for constructor syntax without using PV
            % pairs.  For constructor using PV pairs such as column, you
            % still need to create a dummy function though.
            rules.input0 = true;
        end
        
        function buildWidgetPropertyMaps(this)
            % Abstract method defined in @component
            %
            % build maps between private MCOS property names and peer node
            % property names for widget properties.  The map for action
            % properties are automatically built when creating Action
            % object.
            [mcos1, peer1] = this.getWidgetPropertyNames_Container();
            mcos = [mcos1;{'DisplayStatePrivate';'QABIdPrivate'}];
            peer = [peer1;{'displayState';'QABId'}];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end
        
    end
    
    %% You must put all the overloaded methods here
    methods (Access = protected)
        
        function PropertySetCallback(this,~,data)
            % overload the method in peer interface
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                if isfield(data, 'srcLang') && isfield(data, 'data')
                    srcLangField = 'srcLang';
                    dataField = 'data';
                else
                    srcLangField = 'SrcLang';
                    dataField = 'Data';
                end
                if (strcmp(data.(srcLangField), 'JS') && strcmp(data.(dataField).key, 'displayState'))
                    this.DisplayStatePrivate = data.(dataField).newValue;
                        % send out event
                        new_eventdata = matlab.ui.internal.toolstrip.base.ToolstripEventData(struct(...
                            'Property','DisplayState','OldValue',data.(dataField).oldValue,'NewValue',data.(dataField).newValue));
                        internal.Callback.execute(this.DisplayStateChangedFcnPrivate, this, new_eventdata);
                        this.notify('DisplayStateChanged',new_eventdata);
                end
            else
                originator = data.getOriginator();
                if ~(isa(originator, 'java.util.HashMap') && strcmp(originator.get('source'),'MCOS'))
                    % client side event
                    if strcmp(data.getData.get('key'),'displayState')
                        % update property
                        this.DisplayStatePrivate = data.getData.get('newValue');
                        % send out event
                        new_eventdata = matlab.ui.internal.toolstrip.base.ToolstripEventData(struct(...
                            'Property','DisplayState','OldValue',data.getData.get('oldValue'),'NewValue',data.getData.get('newValue')));
                        internal.Callback.execute(this.DisplayStateChangedFcnPrivate, this, new_eventdata);
                        this.notify('DisplayStateChanged',new_eventdata);
                    end
                end
            end
        end
    end
    
    %% Other methods
    methods (Access = private)
        
        function SelectedTabChangedCallback(this, ~, event)
            eventdata = matlab.ui.internal.toolstrip.base.ToolstripEventData(struct(...
                'Property','SelectedTab','TabGroup',event.Source,...
                'OldValue',event.EventData.OldValue,'NewValue',event.EventData.NewValue));
            if isvalid(this)
                this.notify('SelectedTabChanged',eventdata);
            end
        end
        
    end
    
    methods (Hidden)
        
        function value = getQuickAccessBar(this)
            value = this.QuickAccessBarPrivate;
        end
        
    end
    
end
