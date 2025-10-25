classdef GridPickerButton < matlab.ui.internal.toolstrip.base.Control ...
        & matlab.ui.internal.toolstrip.mixin.ActionBehavior_Text ...
        & matlab.ui.internal.toolstrip.mixin.WidgetBehavior_TextOverride ...
        & matlab.ui.internal.toolstrip.mixin.ActionBehavior_Icon ...
        & matlab.ui.internal.toolstrip.mixin.WidgetBehavior_IconOverride ...
        & matlab.ui.internal.toolstrip.mixin.WidgetBehavior_DescriptionOverride ...
        & matlab.ui.internal.toolstrip.mixin.ActionBehavior_QuickAccessIcon ...
        & matlab.ui.internal.toolstrip.mixin.ActionBehavior_IsInQuickAccess

    % Grid Picker Button
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.GridPickerButton">GridPickerButton</a>
    %
    % Properties:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Control.Description">Description</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Control.Enabled">Enabled</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.ActionBehavior_Icon.Icon">Icon</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Component.Tag">Tag</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.ActionBehavior_Text.Text">Text</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.GridPickerButton.MaxRows">MaxRows</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.GridPickerButton.MaxColumns">MaxColumns</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.GridPickerButton.Occupancy">Occupancy</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.GridPickerButton.Selection">Selection</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.GridPickerButton.ValueChangedFcn">ValueChangedFcn</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.WidgetBehavior_DescriptionOverride.DescriptionOverride">DescriptionOverride</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.WidgetBehavior_IconOverride.IconOverride">IconOverride</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.WidgetBehavior_TextOverride.TextOverride">TextOverride</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.ActionBehavior_IsInQuickAccess.IsInQuickAccess">IsInQuickAccess</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.ActionBehavior_QuickAccessIcon.QuickAccessIcon">QuickAccessIcon</a>
    %   
    % Methods:
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.ActionBehavior_IsInQuickAccess.addToQuickAccess">addToQuickAccess</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.mixin.ActionBehavior_IsInQuickAccess.removeFromQuickAccess">removeFromQuickAccess</a>
    %   <a href="matlab:help matlab.ui.internal.toolstrip.base.Control.shareWith">shareWith</a>
    % Events:
    %   N/A
    % -----------------------------------------------------------------------------------------

    % ----------------------------------------------------------------------------
    
    properties (Dependent, Access = public)
        % Property "MaxRows": 
        %
        %   MaxRows takes a number. The maximum number of rows that the 
        %   GridPickerButton menu will show. Its value can only be set 
        %   at construction time. Default is 5.
        %
        %   Example:
        %       gridPickerBtn = matlab.ui.internal.toolstrip.GridPickerButton('GridPicker', 4);
        MaxRows (1,1) {mustBeInteger, mustBePositive, mustBeNonzero}
        % Property "MaxColumns": 
        %
        %   MaxColumns takes a number. The maximum number of columns that 
        %   the GridPickerButton menu will show. Its value can only be set 
        %   at construction time. Default is 5.
        %
        %   Example:
        %       gridPickerBtn = matlab.ui.internal.toolstrip.GridPickerButton('GridPicker', 4);
        MaxColumns (1,1) {mustBeInteger, mustBePositive, mustBeNonzero}
        % Property "Occupancy": 
        %
        %   Occupancy takes a number. The total number of items(document/plot/graphs/etc.) 
        %   whose layout will be affected by a selection from the GridPickerButton menu. 
        %   Default value is 0.
        %
        %   Example:
        %       gridPickerBtn = matlab.ui.internal.toolstrip.GridPickerButton();
        %       gridPickerBtn.Occupancy = 2;
        Occupancy (1,1) {mustBeInteger, mustBePositive, mustBeNonzero}
        % Property "Selection": 
        %
        %   This property is an object that consists of the row and column of the last 
        %   selected gridPicker cell. This property is set each time a gridPicker cell 
        %   is selected.
        %
        %   Example:
        %       gridPickerBtn = matlab.ui.internal.toolstrip.GridPickerButton();
        %       gridPickerBtn.Selection = struct('row', 4, 'column', 4);
        Selection (1,1) struct
        % Property "ResetAfterSelection": 
        %
        %   When true, resets the value of the GridPicker after each selection, to allow
        %   subsequent selections to trigger watchers regardless of the selection value.
        %   When false, new selections that match the previous selection value will not
        %   trigger a property changed watcher.
        %
        %   Example:
        %       gridPickerBtn = matlab.ui.internal.toolstrip.GridPickerButton();
        %       gridPickerBtn.ResetAfterSelection = true;
        ResetAfterSelection (1,1) logical
    end
    
    properties (Access = public)
        % Property "ValueChangedFcn": 
        %
        %   This callback function executes when the selection is updated in the
        %   gridpicker dropdown.
        %   
        %   Valid callback types are:
        %       * a function handle
        %       * a string
        %       * a 1xN cell array where the first element is either a function handle or a string
        %       * [], representing no callback
        %
        %   EventData looks like:
        %       * struct with fields:
        %           Property: 'Value'
        %           NewValue: [1×1 struct]
        %           OldValue: [1×1 struct]
        %
        %       * Both NewValue and OldValue are the new and old selected gridPicker cell respectively. 
        %         Both look like:
        %           struct with fields:
        %           column: 2
        %           row: 4
        %
        %   Example:
        %       gridPickerBtn.ValueChangedFcn = @(x,y) disp('Callback fired!');
        ValueChangedFcn
    end
    
     properties (Access = private, Hidden)
        ConstructorDoneFlag (1,1) logical = false
    end
    
    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        MaxRowsPrivate = 5
        MaxColumnsPrivate = 5
        OccupancyPrivate = 0
        SelectionPrivate = struct.empty
        ResetAfterSelectionPrivate = false;
    end
    
    events (Hidden)
        % Event triggered by clicking the button in the UI.
        DropDownPerformed
    end
    
    % ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Constructor
        function this = GridPickerButton(varargin)
            % Constructor "GridPickerButton": 
            %
            %   Create a grid picker button.
            %
            %   Examples:
            %       text = 'Open';
            %       icon = matlab.ui.internal.toolstrip.Icon.OPEN_24;
            %       btn = matlab.ui.internal.toolstrip.GridPickerButton
            %       btn = matlab.ui.internal.toolstrip.GridPickerButton(text)
            %       btn = matlab.ui.internal.toolstrip.GridPickerButton(icon)
            %       btn = matlab.ui.internal.toolstrip.GridPickerButton(text,icon)
            %       btn = matlab.ui.internal.toolstrip.GridPickerButton(text, maxRows, maxColumns)
            %       btn = matlab.ui.internal.toolstrip.GridPickerButton(text,icon, maxRows, maxColumns)

            % super
            
            this = this@matlab.ui.internal.toolstrip.base.Control('GridPickerButton');
            % process custom property
            this.processCustomProperties(varargin{:});
            
            this.ConstructorDoneFlag = true;
        end
        
        %% Public API: Get/Set
        function value = get.MaxRows(this)
            % GET function
            value = this.MaxRowsPrivate;
        end
        
        function set.MaxRows(this, value)
            % SET function
            if this.ConstructorDoneFlag
                error(message('MATLAB:toolstrip:control:noChangeMaxRows'));
            end
                        
            this.MaxRowsPrivate = value;
            this.setPeerProperty('maxRows',value);
        end
        
        function value = get.MaxColumns(this)
            % GET function
            value = this.MaxColumnsPrivate;
        end
        
        function set.MaxColumns(this, value)
            % SET function
            if this.ConstructorDoneFlag
                error(message('MATLAB:toolstrip:control:noChangeMaxColumns'));
            end
            
            this.MaxColumnsPrivate = value;
            this.setPeerProperty('maxColumns',value);
        end
        
        function value = get.Occupancy(this)
            % GET function
            value = this.OccupancyPrivate;
        end
        
        function set.Occupancy(this, value)
            % SET function
            this.OccupancyPrivate = value;
            this.setPeerProperty('occupancy',value);
        end
        
        function value = get.Selection(this)
            % GET function
            value = this.SelectionPrivate;
        end
        
        function set.Selection(this, value)
            % SET function
            this.SelectionPrivate = value;
            this.setPeerProperty('selection',value);
        end
        
        function value = get.ResetAfterSelection(this)
            % GET function
            value = this.ResetAfterSelectionPrivate;
        end
        
        function set.ResetAfterSelection(this, value)
            % SET function
            this.ResetAfterSelectionPrivate = value;
            this.setPeerProperty('resetAfterSelection',value);
        end
        
        function value = get.ValueChangedFcn(this)
            % GET function
            value = this.ValueChangedFcn;
        end
        
        function set.ValueChangedFcn(this, value)
            % SET function
            this.ValueChangedFcn = value;
        end
        
    end
    
    %% You must initialize all the abstract methods here
    methods (Access = protected)
        
        function [mcos, peer] = getWidgetPropertyNames_MaxRows(this)
            mcos = {'MaxRowsPrivate'};
            peer = {'maxRows'};
        end
        
        function [mcos, peer] = getWidgetPropertyNames_MaxColumns(this)
            mcos = {'MaxColumnsPrivate'};
            peer = {'maxColumns'};
        end
        
        function [mcos, peer] = getWidgetPropertyNames_Occupancy(this)
            mcos = {'OccupancyPrivate'};
            peer = {'occupancy'};
        end
        
        function [mcos, peer] = getWidgetPropertyNames_Selection(this)
            mcos = {'SelectionPrivate'};
            peer = {'selection'};
        end
        
        function rules = getInputArgumentRules(this) %#ok<MANU>
            % Abstract method defined in @component
            %
            % specify the rules for constructor syntax without using PV
            % pairs.  For constructor using PV pairs such as column, you
            % still need to create a dummy function though.
            rules.properties.Text = struct('type','string','isAction',true);
            rules.properties.Icon = struct('type','Icon','isAction',true);
            rules.properties.MaxRows = struct('type', 'integer', 'isAction', false);
            rules.properties.MaxColumns = struct('type', 'integer', 'isAction', false);
            rules.input0 = true;
            rules.input1 = {{'Text'};{'Icon'};{'MaxRows'};{'MaxColumns'}};
            rules.input2 = {{'Text';'Icon'}};
            rules.input3 = {{'Text';'MaxRows';'MaxColumns'}};
            rules.input4 = {{'Text';'Icon';'MaxRows';'MaxColumns'}};
        end
        
        function buildWidgetPropertyMaps(this)
            % Abstract method defined in @component
            %
            % build maps between private MCOS property names and peer node
            % property names for widget properties.  The map for action
            % properties are automatically built when creating Action
            % object.
            [mcos1, peer1] = this.getWidgetPropertyNames_Control();
            [mcos2, peer2] = this.getWidgetPropertyNames_TextOverride();
            [mcos3, peer3] = this.getWidgetPropertyNames_IconOverride();
            [mcos4, peer4] = this.getWidgetPropertyNames_DescriptionOverride();
            [mcos5, peer5] = this.getWidgetPropertyNames_MaxRows();
            [mcos6, peer6] = this.getWidgetPropertyNames_MaxColumns();
            [mcos7, peer7] = this.getWidgetPropertyNames_Occupancy();
            [mcos8, peer8] = this.getWidgetPropertyNames_Selection();
            mcos = [mcos1;mcos2;mcos3;mcos4;mcos5;mcos6;mcos7; mcos8];
            peer = [peer1;peer2;peer3;peer4;peer5;peer6;peer7; peer8];
            this.WidgetPropertyMap_FromMCOSToPeer = containers.Map(mcos, peer);
            this.WidgetPropertyMap_FromPeerToMCOS = containers.Map(peer, mcos);
        end
        
        function addActionProperties(this)
            % Abstract method defined in @control
            %
            % add action properties to Action object as dynamic properties.
            this.Action.addProperty('Text');
            this.Action.addProperty('Icon');
            this.Action.addProperty('QuickAccessIcon');
            this.Action.addProperty('IsInQuickAccess');
        end
        
        function result = checkAction(this, control) %#ok<INUSL>
            % Abstract method defined in @control
            %
            % specify all the objects that can share action with this one.
            result = isa(control, 'matlab.ui.internal.toolstrip.GridPickerButton');
        end
        
    end
    
    %% You must put all the overloaded methods here
    methods (Access = protected)
        
        function PropertySetCallback(this, ~, data)
        % overload the method in peer interface
            if viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(this.Peer)
                if (strcmp(data.srcLang, 'JS') && strcmp(data.data.key, 'selection'))
                    % update property
                    this.SelectionPrivate = data.data.newValue;
                    % get event data
                    eventdata.EventData.OldValue = data.data.oldValue;
                    eventdata.EventData.NewValue = data.data.newValue;
                    % force to be Value
                    eventdata.EventData.Property = 'Value';
                    % run callback fcn
                    if ~isempty(findprop(this,'ValueChangedFcn'))
                        internal.Callback.execute(this.ValueChangedFcn, this, eventdata);
                    end
                end
            else
                originator = data.getOriginator();
                if ~(isa(originator, 'java.util.HashMap') && strcmp(originator.get('source'),'MCOS'))
                    % get event data
                    eventdata = matlab.ui.internal.toolstrip.base.Utility.processPropertySetData(data);

                    if strcmp(eventdata.EventData.Property,'selection')
                        % update property
                        this.SelectionPrivate = eventdata.EventData.NewValue;
                        % force to be Value
                        eventdata.EventData.Property = 'Value';
                        % run callback fcn
                        if ~isempty(findprop(this,'ValueChangedFcn'))
                            internal.Callback.execute(this.ValueChangedFcn, this, eventdata);
                        end

                    end
                end
            end
        end
        
    end
    
    %% QE methods
    methods (Hidden)
        
        function qeDropDownPushed(this)
            % qeDropDownPushed(this) mimics user pushes the
            % drop down button in the UI without displaying the popup
            
            % send out QE event
            this.notify('DropDownPerformed');
        end
        
    end
    
end
