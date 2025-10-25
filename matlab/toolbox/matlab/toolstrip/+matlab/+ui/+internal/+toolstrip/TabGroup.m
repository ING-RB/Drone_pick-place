classdef TabGroup < matlab.ui.internal.toolstrip.base.Container
    % Layout Container (Tab Group)
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.TabGroup.TabGroup">TabGroup</a>    
    %
    % Properties:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.TabGroup.SelectedTab">SelectedTab</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Component.Tag">Tag</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.TabGroup.SelectedTabChangedFcn">SelectedTabChangedFcn</a>            
    %
    % Methods:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.TabGroup.add">add</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.TabGroup.addTab">addTab</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.TabGroup.remove">remove</a>    
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.disableAll">disableAll</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.enableAll">enableAll</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.find">find</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.findAll">findAll</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Container.get">get</a>
    %
    % Events:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.TabGroup.SelectedTabChanged">SelectedTabChanged</a>    
    %
    % See also matlab.ui.internal.toolstrip.Toolstrip, matlab.ui.internal.toolstrip.Tab
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties (Dependent, Access = public, SetObservable, AbortSet)
        % Property "SelectedTab": 
        %
        %   The currently selected Tab 
        %   It is a reference to the Tab object and the default value is [].
        %   It is writable.
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
        % Property "SelectedTabChangedFcn":
        %
        %   Function Handle
        %   It is called when the SelectedTab property of TabGroup is changed.
        SelectedTabChangedFcn
        
        % Property "Contextual"
        %
        %   true if the tab group is contextual, i.e. if it is to be displayed only when
        %   a certain context or contexts are active.
        Contextual
    end
    
    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        SelectedTabId = ''
        QAGroupIdPrivate = ''
    end
    
    % ----------------------------------------------------------------------------
    properties (Access = private)
        SelectedTabPrivate = []
        ContextualPrivate = false;
        SelectedTabChangedFcnPrivate = []
        QuickAccessGroupPrivate = []   
    end
    
    % ----------------------------------------------------------------------------
    events
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
        function this = TabGroup()
            % Constructor "TabGroup": 
            %
            %   Create a tab group.
            %
            %   Examples:
            %       tabgroup = matlab.ui.internal.toolstrip.TabGroup();
            
            % super
            this = this@matlab.ui.internal.toolstrip.base.Container('TabGroup');
            % create QAB group
            this.QuickAccessGroupPrivate = matlab.ui.internal.toolstrip.impl.QuickAccessGroup();
        end
        
        %% Get/Set Properties
        % SelectedTab
        function obj = get.SelectedTab(this)
            % GET function for SelectedTab property.
            obj = this.SelectedTabPrivate;            
        end
        function set.SelectedTab(this, obj)
            % SET function for SelectedTab property.
            if isempty(obj)
                %error(message('MATLAB:toolstrip:container:invalidSelectedTab'));
                this.SelectedTabPrivate = [];
                if hasPeerNode(this)
                    this.SelectedTabId = '';
                    this.setPeerProperty('selectedTab','');
                end
            else
                if ~isa(obj, 'matlab.ui.internal.toolstrip.Tab')
                    error(message('MATLAB:toolstrip:container:invalidSelectedTab'));
                elseif ~this.isChild(obj)
                    error(message('MATLAB:toolstrip:container:invalidChild'));
                end
                % PostSet event will be sent over to the view adapter
                this.SelectedTabPrivate = obj;
                if hasPeerNode(this)
                    this.SelectedTabId = obj.getId();
                    this.setPeerProperty('selectedTab',this.SelectedTabId);
                    if ~isempty(this.Parent) && strcmp(this.Parent.Tag,'ToolGroupToolstrip')
                        % force immediate synchronization by triggering
                        % selected tab changed swing event and fire the
                        % "cbSwingSelectedTabChanged" callback in toolgroup
                        drawnow;
                    end
                end
            end
        end
        % SelectedTabChangedFcn
        function value = get.SelectedTabChangedFcn(this)
            % GET function for SelectedTabChangedFcn property.
            value = this.SelectedTabChangedFcnPrivate;
        end
        function set.SelectedTabChangedFcn(this, value)
            % SET function for SelectedTabChangedFcn property.
            if internal.Callback.validate(value)
                this.SelectedTabChangedFcnPrivate = value;
            else
                error(message('MATLAB:toolstrip:general:invalidFunctionHandle', 'SelectedTabChangedFcn'))
            end
        end
        
        function result = get.Contextual(this)
            % GET function for Contextual property.
            result = this.ContextualPrivate;            
        end
        
        function set.Contextual(this, value)
            % SET function for Contextual property.
            this.ContextualPrivate = value;
            if hasPeerNode(this)
                this.setPeerProperty('contextual', value);
            end
        end
        
        %% Add/Remove
        function add(this, tab, varargin)
            % Method "add":
            %
            %   "add(tabgroup, tab)": add a tab object at the end of the tab group.
            %   Example:
            %       tabgroup = matlab.ui.internal.toolstrip.TabGroup()
            %       tab1 = matlab.ui.internal.toolstrip.Tab('title1')
            %       tabgroup.add(tab1)
            %
            %   "add(tabgroup, tab, index)": insert a tab at a specified location in the tab group.
            %   Example:
            %       tabgroup = matlab.ui.internal.toolstrip.TabGroup()
            %       tab1 = matlab.ui.internal.toolstrip.Tab('title1')
            %       tabgroup.add(tab1)
            %       tab2 = matlab.ui.internal.toolstrip.Tab('title2')
            %       tabgroup.add(tab2,1) % insert tab2 as the first tab
            if isa(tab, 'matlab.ui.internal.toolstrip.Tab')
                add@matlab.ui.internal.toolstrip.base.Container(this, tab, varargin{:});
            else
                error(message('MATLAB:toolstrip:container:invalidObjectAddedToParent', class(tab), class(this)));
            end
        end
        
        function remove(this, tab)
            % Method "remove":
            %
            %   "remove(tabgroup, tab)": remove a tab object from the tab group.
            %   Example:
            %       tabgroup = matlab.ui.internal.toolstrip.TabGroup()
            %       tab1 = matlab.ui.internal.toolstrip.Tab('title1')
            %       tab2 = matlab.ui.internal.toolstrip.Tab('title2')
            %       tabgroup.add(tab1)
            %       tabgroup.add(tab2)
            %       tabgroup.remove(tab1) % now tab2 becomes the only tab
            if isa(tab, 'matlab.ui.internal.toolstrip.Tab')
                if this.isChild(tab)
                    remove@matlab.ui.internal.toolstrip.base.Container(this, tab);
                    
                    if isvalid(tab)
                        % The drawnow call within this if block was only
                        % meant for ToolGroup based apps. Adding this
                        % condition to ensure drawnow does not get called
                        % for AppContainer based apps since they are not
                        % hooked into the drawnow life cycle.
                        if ~viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                            % g1943886: Flush the event queue to prevent a race condition
                            drawnow;
                        end
                        
                        if isvalid(tab)
                            if this.SelectedTabPrivate == tab
                                this.SelectedTabPrivate = [];
                                if hasPeerNode(this)
                                    this.SelectedTabId = '';
                                    this.setPeerProperty('selectedTab','');
                                end
                            end
                        end
                    end
                else
                    error(message('MATLAB:toolstrip:container:invalidChild'));
                end
            else
                error(message('MATLAB:toolstrip:container:invalidObjectRemovedFromParent', class(tab), class(this)));
            end
        end
        
        function tab = addTab(this, varargin)
            % Method "addTab":
            %
            %   "tab1 = addTab(tabgroup, 'title1')": create a tab object at the end
            %   of the toolstrip and returns its handle. 
            %   Example:
            %       tabgroup = matlab.ui.internal.toolstrip.TabGroup()
            %       tab1 = tabgroup.addTab('tab1')
            try
                tab = matlab.ui.internal.toolstrip.Tab(varargin{:});
            catch E
                throw(E)
            end
            this.add(tab);
        end
        
    end
    
    methods (Hidden)
        
        %% render
        function render(this, channel, parent, varargin)
            % Method "render" (Overloaded):
            % 
            % "parent" can be a MCOS toolstrip object: toolstrip is created using MCOS API 
            % "parent" can be a string "TabGroup": toolstrip is created without using MCOS API 
            
            parent = matlab.ui.internal.toolstrip.base.Utility.hString2Char(parent);
            if ischar(parent)
                % create QAGroup peer node and its children recursively
                this.QuickAccessGroupPrivate.render(channel, 'QuickAccessGroup');
            else
                % create QAGroup peer node and its children recursively
                this.QuickAccessGroupPrivate.render(channel, parent.getQuickAccessBar());
            end
            % Rong: this is a temp workaround. to be removed in the future.
            this.QuickAccessGroupPrivate.dispatchEvent(struct);
            % get QAB peer node id
            this.QAGroupIdPrivate = this.QuickAccessGroupPrivate.getId();
            % create toolstrip peer node and its children recursively
            render@matlab.ui.internal.toolstrip.base.Container(this, channel, parent, varargin{:});
            % ensure correct tab is selected during rendering
            if ~isempty(this.SelectedTab)
                this.SelectedTabId = this.SelectedTab.getId();
                this.setPeerProperty('selectedTab',this.SelectedTabId);
            end
            if this.Contextual
                this.setPeerProperty('contextual', this.Contextual);
            end
        end
        
        function sendSelectedTabChangedEvent(this,oldtab,newtab)
            if ~isvalid(this)
                return;
            end
            % send out event                    
            data = matlab.ui.internal.toolstrip.base.ToolstripEventData(...
                struct('Property','SelectedTab','OldValue',oldtab,'NewValue',newtab));
            internal.Callback.execute(this.SelectedTabChangedFcnPrivate, this, data);
            this.notify('SelectedTabChanged',data);
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
            mcos = [mcos1;{'SelectedTabId';'QAGroupIdPrivate'; 'Contextual'}];
            peer = [peer1;{'selectedTab';'QAGroupId'; 'contextual'}];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end
        
    end
    
    %% You must put all the overloaded methods here
    methods (Access = protected)
        
        function PropertySetCallback(this,~,data)
            % overload the method in peer interface
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                if (strcmp(data.srcLang, 'JS') && strcmp(data.data.key, 'selectedTab'))
                    old_id = data.data.oldValue;
                    new_id = data.data.newValue;
                    old_tab = this.findChildByID(old_id);
                    new_tab = this.findChildByID(new_id);
                    this.SelectedTabPrivate = new_tab;
                    if ~isempty(new_tab)
                        % only set SelectedTabId when tab is not empty
                        this.SelectedTabId = new_tab.getId();
                    end
                    % send SelectedTabChanged event
                    sendSelectedTabChangedEvent(this,old_tab,new_tab);
                end
            else
                originator = data.getOriginator();
                if ~(isa(originator, 'java.util.HashMap') && strcmp(originator.get('source'),'MCOS'))
                    % client side event
                    if strcmp(data.getData.get('key'),'selectedTab')
                        old_id = data.getData.get('oldValue');
                        new_id = data.getData.get('newValue');
                        old_tab = this.findChildByID(old_id);
                        new_tab = this.findChildByID(new_id);
                        % update property
                        this.SelectedTabPrivate = new_tab;
                        if ~isempty(new_tab)
                            % only set SelectedTabId when tab is not empty
                            this.SelectedTabId = new_tab.getId();
                        end
                        % send SelectedTabChanged event
                        sendSelectedTabChangedEvent(this,old_tab,new_tab);
                    end
                end
            end
        end
        
    end
    
    %% Other methods
    methods (Access = {?matlab.ui.internal.toolstrip.mixin.ActionBehavior_IsInQuickAccess, ?matlab.ui.internal.toolstrip.Toolstrip, ?matlab.unittest.TestCase})
        
        function value = getQuickAccessGroup(this)
            value = this.QuickAccessGroupPrivate;
        end
        
    end
    
end
