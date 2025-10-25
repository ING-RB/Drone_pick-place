classdef UIVariableEditor < matlab.ui.componentcontainer.ComponentContainer
    % UIVariableEditor a Component Container with a UIHTML containing a
    % Variable Editor.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties(Access = {?UIVariableEditor, ?matlab.unittest.TestCase }, Constant)
        DEFAULT_POSITION            = [20 20 300 400]
        HTMLSource                  = 'toolbox/matlab/datatools/variableeditor/js/peer/VariableEditorPopoutHandler.html';
        DEBUGHTMLSource             = 'toolbox/matlab/datatools/variableeditor/js/peer/VariableEditorPopoutHandler-debug.html';
        VEManagerKey                = '/UIVariableEditor';

        PluginList                  = ["DataSortable", "DataFilterable", "DataEditable", ...
                                          "CategoricalColumnCleanable", "DataTypeChangeable", ...
                                          "DataSelectable", "RowHeadersVisible", ...
                                          "ContextMenusVisible", "InfiniteGrid", "PadDataRequests", "DataSearchable"];
        PluginListI                 = ["SORT", "COLUMN_FILTER", "DataEditable", ...
                                          "CLEAN_CATEGORIES", "DATA_TYPE_CONVERSION", ...
                                          "PEER_PLAID_SELECTION", "ROW_HEADERS", ...
                                          "ARRAY_VIEW_CONTEXT_HANDLER", "INFINITE_GRID", "DATA_PADDING", "SEARCHABLE"];

        DependantPluginsI           = {struct('HEADER_MENU', {'SORT', 'COLUMN_FILTER'}), ...
                                          struct('ARRAY_VIEW_CONTEXT_HANDLER', 'PEER_PLAID_SELECTION'), ...           % Disable table context menus if DataSelectable is off
                                          struct('TABLE_CONTEXT_BASED_PLAID_SELECTION', 'PEER_PLAID_SELECTION'), ...  % Disable table context menus if DataSelectable is off
                                          struct('CORNER_SPACER_TEXT', 'ROW_HEADERS'), ...                            % Disable corner spacer selection if RowHeadersVisible is off
                                          struct('COLUMN_SORT', 'SORT'), ...                                          % Disable struct sorting if DataSortable is off
                                          struct('REMOTE_MULTI_ROW_SELECTION', 'PEER_PLAID_SELECTION'), ...           % Disable struct selection if DataSelectable is off
                                          struct('CONTEXT_BASED_SELECTION', 'PEER_PLAID_SELECTION'), ...              % Disable struct selection if DataSelectable is off
                                          struct('VIEW_CONTEXT_HANDLER', 'ARRAY_VIEW_CONTEXT_HANDLER'), ...           % Disable struct context menus if ContextMenusVisible is off
                                          struct('INFINITE_GRID', 'PEER_PLAID_SELECTION'), ...                        % Disable infinite grid if DataSelectable is off
                                          struct('INFINITE_GRID', 'DataEditable')};                                   % Disable infinite grid if DataEditable is off
                                      
        DEFAULT_VISIBLE_COLS        = ["Name", "Value", "Size", "Class"];                                             % The default columns visible for scalar structs

    end

    properties (Access = {?UIVariableEditor, ?matlab.unittest.TestCase }, Transient, NonCopyable, Hidden)
        GridLayout                  matlab.ui.container.GridLayout
        UIHTML                      matlab.ui.control.HTML
        Button                      matlab.ui.control.Button
        Document                    internal.matlab.variableeditor.peer.RemoteDocument
        Channel
    end

    properties (Access = {?UIVariableEditor, ?matlab.unittest.TestCase }, Transient, NonCopyable, Hidden)
        VariableI;
        WorkspaceI;
        DisabledPluginsI;
        VisibleColumnsI;
        ParentDocument;
        IsTimetable;

        SelectionChangedListener;
        ScrollPositionChangedListener;
        UserDataInteractionListener;
        DataEditListener;
        DataChangeListener;
        DocumentOpenedListener;
        DocumentTypeChangedListener;
        PropertySetListener;
    end

    properties (Dependent = true)
        Variable;
        Workspace;
        Selection;
        ScrollPosition;
    end

    properties (GetAccess='public', SetAccess='private')
        FeatureConfig;
    end
    
    properties (Hidden)
        Debug                         (1,1) logical = false
        SummaryBarVisible             (1,1) logical = false
        VisibleColumns
        SparkLinesVisible             matlab.lang.OnOffSwitchState = 'off'
        StatisticsVisible             matlab.lang.OnOffSwitchState = 'off'
    end
    
    properties (Access='public')
        % Features
        DataSortable                  matlab.lang.OnOffSwitchState = 'off'
        DataFilterable                matlab.lang.OnOffSwitchState = 'off'
        DataEditable                  matlab.lang.OnOffSwitchState = 'off'
        CategoricalColumnCleanable    matlab.lang.OnOffSwitchState = 'off'
        DataTypeChangeable            matlab.lang.OnOffSwitchState = 'off'
        DataSelectable                matlab.lang.OnOffSwitchState = 'off'
        ContextMenusVisible           matlab.lang.OnOffSwitchState = 'off'
        RowHeadersVisible             matlab.lang.OnOffSwitchState = 'off'
        InfiniteGrid                  matlab.lang.OnOffSwitchState = 'on'
        PadDataRequests               matlab.lang.OnOffSwitchState = 'off'
        DataSearchable                matlab.lang.OnOffSwitchState = 'off'

        % Callback Functions
        SelectionChangedCallbackFcn;
        ScrollPositionChangedCallbackFcn;
        UserDataInteractionCallbackFcn;
        DataEditCallbackFcn;

        % Configuration
        UUID
    end

    methods
        function val = get.Variable(obj)
            val = obj.VariableI;
        end
        function set.Variable(obj, val)
            obj.VariableI = val;
        end

        function val = get.Workspace(obj)
            val = obj.WorkspaceI;
        end
        function set.Workspace(obj, val)
            obj.WorkspaceI = val;
        end

        function val = get.Selection(obj)
            rows = obj.Document.ViewModel.SelectedRowIntervals;
            columns = obj.Document.ViewModel.SelectedColumnIntervals;
            val = struct('Rows', rows, 'Columns', columns);
        end
        function set.Selection(obj, selectionObj)
            obj.SelectionChangedListener.Enabled = false;
            obj.setSelection(selectionObj.Rows, selectionObj.Columns);
            obj.SelectionChangedListener.Enabled = true;
        end

        function val = get.ScrollPosition(obj)
            row = obj.Document.ViewModel.ViewportStartRow;
            if (row <= 4)
                row = row + 4;
            end
            column = obj.Document.ViewModel.ViewportStartColumn;
            val = struct('Row', row, 'Column', column);
        end
        function set.ScrollPosition(obj, scrollPositonObj)
            obj.ScrollPositionChangedListener.Enabled = false;
            obj.scrollTo(scrollPositonObj.Row, scrollPositonObj.Column);
            obj.ScrollPositionChangedListener.Enabled = true;
        end

        %% Feature Configuration
        function val = get.DisabledPluginsI(obj)
            fconfig = obj.FeatureConfig;
            features = fieldnames(fconfig);
            % Do not use the struct2array function directly since it will
            % fail on component install.
            % Convert structure to cell
            tempC = struct2cell(fconfig);
            % Construct an array
            userSelection = [tempC{:}];

            pluginConfig = containers.Map(obj.PluginList, obj.PluginListI);
            tempVal = values(pluginConfig, features(~userSelection));
            val = unique(obj.addDependantPlugins(tempVal));
        end
        

        %% Feature List
        function val = get.DataSortable(obj)
            val = obj.DataSortable;
        end
        function set.DataSortable(obj, val)
            obj.DataSortable = val;
            obj.refresh;
        end

        function val = get.DataFilterable(obj)
            val = obj.DataFilterable;
        end
        function set.DataFilterable(obj, val)
            obj.DataFilterable = val;
            obj.refresh;
        end

        function val = get.CategoricalColumnCleanable(obj)
            val = obj.CategoricalColumnCleanable;
        end
        function set.CategoricalColumnCleanable(obj, val)
            obj.CategoricalColumnCleanable = val;
            obj.refresh;
        end

        function val = get.DataTypeChangeable(obj)
            val = obj.DataTypeChangeable;
        end
        function set.DataTypeChangeable(obj, val)
            obj.DataTypeChangeable = val;
            obj.refresh;
        end

        function val = get.DataSelectable(obj)
            val = obj.DataSelectable;
        end
        function set.DataSelectable(obj, val)
            obj.DataSelectable = val;
            obj.refresh;
        end
        
        function val = get.ContextMenusVisible(obj)
            val = obj.ContextMenusVisible;
        end
        function set.ContextMenusVisible(obj, val)
            obj.ContextMenusVisible = val;
            obj.refresh;
        end

        function val = get.RowHeadersVisible(obj)
            val = obj.RowHeadersVisible;
        end
        function set.RowHeadersVisible(obj, val)
            obj.RowHeadersVisible = val;
            obj.refresh;
        end

        function val = get.InfiniteGrid(obj)
            val = obj.InfiniteGrid;
        end
        function set.InfiniteGrid(obj, val)
            obj.InfiniteGrid = val;
            obj.refresh;
        end

        function val = get.PadDataRequests(obj)
            val = obj.PadDataRequests;
        end
        function set.PadDataRequests(obj, val)
            obj.PadDataRequests = val;
            obj.refresh;
        end

        function val = get.DataSearchable(obj)
            val = obj.DataSearchable;
        end
        function set.DataSearchable(obj, val)
            obj.DataSearchable = val;
            obj.refresh;
            if (val)
                obj.bindFindKeys;
            end
        end

        % Initialize Non-Plugin Display Properties
        function val = get.DataEditable(obj)
            % TODO/To consider: If a user tries to set an uneditable variable
            % as editable, let them know through some way.
            % The uncommented code block is here in case the determined
            % method of notifying users requires it.

            %{
            val = matlab.lang.OnOffSwitchState('off');
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'getTableModelProperty')
                logicalVal = obj.Document.ViewModel.getTableModelProperty('editable');
                if ~isempty(logicalVal) && logicalVal
                    val = matlab.lang.OnOffSwitchState('on');
                else
                    val = matlab.lang.OnOffSwitchState('off');
                end
            end
            %}

            val = obj.DataEditable;
        end
        
        function set.DataEditable(obj, val)
            arguments
                obj
                val  (1,1) matlab.lang.OnOffSwitchState = 'off'
            end

            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty') %#ok<*MCSUP> 
                isOn = (val == true);
                obj.Document.ViewModel.setTableModelProperties('editable', isOn);
            end

            obj.DataEditable = val;
        end
        
        function val = get.SparkLinesVisible(obj)
            % TODO: See "get.DataEditable".
            %{
            val = matlab.lang.OnOffSwitchState('off');
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'getTableModelProperty')
                logicalVal = obj.Document.ViewModel.getTableModelProperty('ShowSparkLines');
                if ~isempty(logicalVal) && logicalVal
                    val = matlab.lang.OnOffSwitchState('on');
                else
                    val = matlab.lang.OnOffSwitchState('off');
                end
            end
            %}

            val = obj.SparkLinesVisible;
        end
        
        function set.SparkLinesVisible(obj, val)
            arguments
                obj
                val  (1,1) matlab.lang.OnOffSwitchState = 'off'
            end
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty')
                isOn = (val == true);
                obj.Document.ViewModel.setTableModelProperty('ShowSparkLines', isOn);
            end

            obj.SparkLinesVisible = val;
        end

        function val = get.StatisticsVisible(obj)
            % TODO: See "get.DataEditable".
            %{
            val = matlab.lang.OnOffSwitchState('off');
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'getTableModelProperty')
                logicalVal = obj.Document.ViewModel.getTableModelProperty('ShowStatistics');
                if ~isempty(logicalVal) && logicalVal
                    val = matlab.lang.OnOffSwitchState('on');
                else
                    val = matlab.lang.OnOffSwitchState('off');
                end
            end
            %}

            val = obj.StatisticsVisible;
        end
        
        function set.StatisticsVisible(obj, val)
            arguments
                obj
                val  (1,1) matlab.lang.OnOffSwitchState = 'off'
            end
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty')
                isOn = (val == true);
                obj.Document.ViewModel.setTableModelProperty('ShowStatistics', isOn);
            end

            obj.StatisticsVisible = val;
        end

        function val = get.VisibleColumns(obj)
            val = obj.VisibleColumnsI;
        end
        
        % Iterate through the FieldColumns and update Visible property on
        % the columns.
        function set.VisibleColumns(obj, val)
            arguments
                obj matlab.internal.datatools.uicomponents.uivariableeditor.UIVariableEditor
                val string
            end
            if ~isempty(obj.Document)
                view = obj.Document.ViewModel;
                if isprop(view, 'FieldColumnList')
                    fieldColumns = view.FieldColumnList;
                    for i=keys(fieldColumns)
                        isVisible = false;
                        headerName = fieldColumns(i{:}).HeaderName;
                        if matches(headerName, val)
                            isVisible = true;
                        end
                        view.setColumnVisible(headerName, isVisible);
                    end
                end
            end
            obj.VisibleColumnsI = val;
        end
    end

    methods
        function obj = UIVariableEditor(NameValueArgs)
            arguments
                NameValueArgs.?matlab.ui.componentcontainer.ComponentContainer

                % UIVariableEditor Appearence
                NameValueArgs.Parent                                                                 = uifigure
                NameValueArgs.BackgroundColor                                                        = 'white'

                % UIVariableEditor Config.
                NameValueArgs.Workspace                                                              = 'base'
                NameValueArgs.Variable                          (1,:) char
                NameValueArgs.UUID                              (1,:) char                           = matlab.lang.internal.uuid

                % UIVariableEditor Interaction Plugins
                NameValueArgs.DataSortable                      matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataFilterable                    matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataEditable                      matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.CategoricalColumnCleanable        matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataTypeChangeable                matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataSelectable                    matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.ContextMenusVisible               matlab.lang.OnOffSwitchState         = 'off'

                % UIVariableEditor Display Plugins
                NameValueArgs.RowHeadersVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.SparkLinesVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.StatisticsVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.SummaryBarVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.InfiniteGrid                      matlab.lang.OnOffSwitchState         = 'on'
                NameValueArgs.PadDataRequests                   matlab.lang.OnOffSwitchState         = 'off'  % TODO: Remove once https://jira.mathworks.com/browse/MLFA-3641 has been submitted.
                NameValueArgs.DataSearchable                    matlab.lang.OnOffSwitchState         = 'off'

                % Default Columns Visible for Scalar Structs
                NameValueArgs.VisibleColumns                    string                               = matlab.internal.datatools.uicomponents.uivariableeditor.UIVariableEditor.DEFAULT_VISIBLE_COLS

                % Debug Flag
                NameValueArgs.Debug                             (1,1) logical                        = false

            end

            % Initialize the parent class
            obj@matlab.ui.componentcontainer.ComponentContainer(NameValueArgs);
            if ~isa(NameValueArgs.Parent, "matlab.ui.container.GridLayout") && ~isfield(NameValueArgs, "Position")
                obj.Position = matlab.internal.datatools.uicomponents.uivariableeditor.UIVariableEditor.DEFAULT_POSITION;
            end

            % Wrap LXE Workspace in common interface
            if (isa(NameValueArgs.Workspace, 'matlab.lang.internal.Workspace'))
                obj.Workspace = matlab.internal.datatoolsservices.AppWorkspace(NameValueArgs.Workspace, CloneWorkspace=false);
            end
            
            obj.Channel = [obj.VEManagerKey '_' NameValueArgs.UUID];

            obj.Debug = NameValueArgs.Debug;
            obj.SummaryBarVisible = NameValueArgs.SummaryBarVisible;

            % Configure the feature that are enabled based on the user
            % input
            obj.FeatureConfig = cell2struct((arrayfun(@(x)({NameValueArgs.(x)}), obj.PluginList)), cellstr(obj.PluginList), 2);

            % Initialize the UIVariableEditor
            obj.setupUIHTML;

            % Initialize Non-Plugin Display Properties
            obj.SparkLinesVisible = NameValueArgs.SparkLinesVisible;
            obj.StatisticsVisible = NameValueArgs.StatisticsVisible;
            obj.DataEditable = NameValueArgs.DataEditable;
            obj.VisibleColumns = NameValueArgs.VisibleColumns;
            
            % Make the UUID public
            obj.UUID = NameValueArgs.UUID;
        end
        
        % Create a unique channel name so that each instance of the
        % UIVariableEditor has its own manager
        function channel = getUniqueChannel(obj)
            mlock; % Keep persistent variables until MATLAB exits
            persistent channelCounter;
            if isempty(channelCounter)
                channelCounter = 0;
            end
            channelCounter = channelCounter+1;
            channel = [obj.VEManagerKey '_' num2str(channelCounter)];
        end

        function delete(obj)
            obj.deleteListeners;
            
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(obj.Channel,false);
            % Close the document assicated with the UIVariable Instance.
            if ~isempty(obj.Document) && ~isempty(obj.Document.Name)
                docID = obj.Document.DocID;
                channel = strcat('/VE/filter',docID);
                filtMgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
                filtMgr.delete();
                mgr.closevar(obj.Document.Name, obj.Workspace);
            end

            % Delete the manager if all its documents are closed.
            if isempty(mgr.Documents)
                mgr.delete();
            end
        end

        %-----TODO: Refactor. Temporary APIs for setting model properties -----%

        function setTableColumnWidth(obj, width)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty')
                obj.Document.ViewModel.setTableModelProperty('ColumnWidth', width);
            end
        end

        function setCellColor(obj, row, col, color)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setCellModelProperty')
                obj.Document.ViewModel.setCellModelProperty(row, col, 'style', struct('backgroundColor', color));
            end
        end

        function clearCellColors(obj)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setCellModelProperty')
                obj.Document.ViewModel.CellModelProperties = [];
                obj.Document.ViewModel.setCellModelProperty(1,1,'dummy','force update');
            end
        end
        
        function clearCodeBuffer(obj)
            obj.Document.ViewModel.ActionStateHandler.CommandArray = [];
            obj.Document.ViewModel.ActionStateHandler.CodeArray = [];
        end
        
        function disableEditing(obj)
            vm = obj.Document.ViewModel;
            vm.setTableModelProperties('editable', false);
        end

        function showFindDialog(obj)
            sa = obj.Document.Manager.ActionManager.ActionDataService.getAction('SearchAction');
            obj.Document.Manager.FocusedDocument = obj.Document;
            sa.Action.Search(struct('open', true));
        end

        function bindFindKeys(obj)
            if ~isempty(obj.Document)
                sa = obj.Document.Manager.ActionManager.ActionDataService.getAction('SearchAction');
                obj.Document.Manager.FocusedDocument = obj.Document;
                sa.Action.Search(struct('bindKeys', obj.DataSearchable));
            end
        end
    end

    methods (Access = 'protected')
        function setup(obj)
            % Sets up the Gird with UIHTML and UIButton.
            obj.GridLayout = uigridlayout(obj, [2, 2]);
            obj.GridLayout.RowHeight{1} = 0;

            obj.GridLayout.ColumnSpacing = 0;
            obj.GridLayout.RowSpacing = 0;
            obj.GridLayout.Padding = [0 0 0 0];
            obj.GridLayout.BackgroundColor = [1 1 1];
            
            % Position the UIHTML
            obj.UIHTML = uihtml(obj.GridLayout);
            obj.UIHTML.Layout.Row = 2;
            obj.UIHTML.Layout.Column = [1 2];
            
            % Position the GoBack Button
            obj.Button = uibutton(obj.GridLayout, 'push');
            obj.Button.IconAlignment = 'center';
            obj.Button.BackgroundColor = [1 1 1];
            obj.Button.Layout.Row = 1;
            obj.Button.Layout.Column = 2;
            obj.Button.Text = 'GoUp';
            obj.Button.ButtonPushedFcn =  @(btn, event) obj.goUp();
            obj.Button.Enable = 0;
        end

        function update(~)
        end
    end

    methods (Access = {?UIVariableEditor, ?matlab.unittest.TestCase })
        function refresh(obj)
            % Save the current Non-Plugin Diplay Properties so that they 
            % may be set again.
            sparkLinesVisible = obj.SparkLinesVisible;
            statisticsVisible = obj.StatisticsVisible;
            dataEditable = obj.DataEditable;
            visibleColumns = obj.VisibleColumns;
            
            % Refresh the view on the client with the new features
            if ~isempty(obj.Document)
                featureConfig = {
                    obj.DataSortable, ...
                    obj.DataFilterable, ...
                    dataEditable, ...
                    obj.CategoricalColumnCleanable, ...
                    obj.DataTypeChangeable, ...
                    obj.DataSelectable, ...
                    obj.RowHeadersVisible, ...
                    obj.ContextMenusVisible, ...
                    obj.InfiniteGrid, ...
                    obj.PadDataRequests, ...
                    obj.DataSearchable
                };
                obj.FeatureConfig = cell2struct(featureConfig, cellstr(obj.PluginList), 2);
                obj.deleteListeners;
                
                mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(obj.Channel,false);
                mgr.closevar(obj.Document.Name, obj.Workspace);
                obj.setupUIHTML;
                
                % g2474447: Non-Plugin Diplay Properties need to be updated
                % each time the view is setup.
                obj.SparkLinesVisible = sparkLinesVisible;
                obj.StatisticsVisible = statisticsVisible;
                obj.DataEditable = dataEditable;
                obj.VisibleColumns = visibleColumns;
            end
        end
        
        function val = addDependantPlugins(obj, plugins)
            % Convienience method to disable plugins that cannot be toggeled by the user
            % directly but need to be disabled if all their consumers are disabled
            for i = 1:length(obj.DependantPluginsI)
                dependantPluginName = fieldnames(obj.DependantPluginsI{i});
                dependsOn = {obj.DependantPluginsI{i}.(dependantPluginName{:})};
                if ismember(dependsOn, plugins)
                    plugins{end+1} = dependantPluginName{:}; %#ok<AGROW> 
                end
                
            end
            val = plugins;
        end

        function setupUIHTML(obj)
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(obj.Channel,false);
            
            if isempty(obj.Document) || ~isvalid(obj.Document)
                try
                    tVar = evalin(obj.Workspace, obj.Variable);
                    obj.IsTimetable = istimetable(tVar);
                catch 
                    tVar = internal.matlab.variableeditor.NullValueObject(obj.Variable);
                end
                
                obj.Document = mgr.openvar(obj.Variable, obj.Workspace, tVar, UserContext='UIVariableEditor');
            end
            
            % Check if the doc has a parent and show the go-up affordance
            % ortherwise hide it.
            parentDoc = obj.Document.getProperty('parentName');
            if ~isempty(parentDoc)
                obj.showGoUpBtn();
                obj.ParentDocument = parentDoc;
            else
                obj.hideGoUpBtn();
            end 

            if ~isempty(obj.DisabledPluginsI)
                obj.Document.setProperty('DisabledPlugins', obj.DisabledPluginsI);
            end
            docId = obj.Document.DocID;
            if obj.Debug
                s = connector.getUrl(obj.DEBUGHTMLSource);
            else
                s = connector.getUrl(obj.HTMLSource);
            end
            url = sprintf('%s&channel=%s&docId=%s&summaryBarVisible=%s',s,obj.Channel,docId,obj.SummaryBarVisible);
            obj.UIHTML.HTMLSource =  url;

            % Add SelectionChanged listener
            if ismember('SelectionChanged', events(obj.Document.ViewModel))
                obj.SelectionChangedListener = addlistener(obj.Document.ViewModel,'SelectionChanged',@(e,d)obj.handleSelectionChanged(d));
            end
            % Add ScrollPositionChanged listener
            if ismember('ViewportPositionChanged', events(obj.Document.ViewModel))
                obj.ScrollPositionChangedListener = addlistener(obj.Document.ViewModel,'ViewportPositionChanged',@(e,d)obj.handleScrollPositionChanged(d));
            end
            % Add UserDataInteraction listener
            if ismember('UserDataInteraction', events(obj.Document.ViewModel))
                obj.UserDataInteractionListener = addlistener(obj.Document.ViewModel, 'UserDataInteraction', @(es,ed) obj.handleUserDataInteraction(ed));
            end
            % Add DataEdit listener
            if ismember('DataEditFromClient', events(obj.Document.ViewModel))
                obj.DataEditListener = addlistener(obj.Document.ViewModel, 'DataEditFromClient', @(es,ed) obj.handleDataEdit(ed));
            end
            % Listen to DataChange events on the viewmodel
            if ismember('DataChange', events(obj.Document.ViewModel))
                obj.DataChangeListener = addlistener(obj.Document.ViewModel, 'DataChange', @(es,ed)obj.handleDataChange(ed));
            end
            % Listen to PropertySet events on the viewmodel
            if ismember('PropertySet', events(obj.Document.ViewModel))
                obj.PropertySetListener = addlistener(obj.Document.ViewModel, 'PropertySet', @(es,ed)obj.handleViewPropertySet(ed));
            end
            % Listen to DataChange events on the viewmodel
            obj.DocumentOpenedListener = addlistener(mgr, 'Documents', 'PostSet', @(es,ed)obj.handleDocumentPropertyChange(ed));

            % Listen to data type change events on the document (where the
            % current view model is replaced, requiring a refresh).
            obj.DocumentTypeChangedListener = addlistener(obj.Document, 'DocumentTypeChanged', ...
                @(~,~)obj.handleDocumentTypeChanged());
            
            % Initialize the action manager
            ActionManagerNamespace = [obj.Channel 'ActionManager'];
            startPath = 'internal.matlab.variableeditor.Actions';
            mgr.initActions(ActionManagerNamespace, startPath);
            
            % Initialize the context menu manager
            contextMenuManagerNamespace = [obj.Channel '/VEContextMenuManager'];
            veContextMenuActionsFile = fullfile(matlabroot,'toolbox','matlab','datatools','variableeditor','matlab','resources','UIVEActionGroupings.xml');
            mgr.initContextMenu('.popoutWrapper', veContextMenuActionsFile, contextMenuManagerNamespace);
        end

        % API To set a selection on the client.
        function setSelection(obj, selectedRows, selectedColumns)
            %{
                selectedRows (:,2)
                selectedRows (n,:) A discrete selection
                selectedRows (n,1) StartRow of the discrete selection
                selectedRows (n,2) EndRow of the discrete selection

                selectedColumns (:,2)
                selectedColumns (n,:) A discrete selection
                selectedColumns (n,1) StartCol of the discrete selection
                selectedColumns (n,2) EndCol of the discrete selection
            %}
            arguments
                obj matlab.internal.datatools.uicomponents.uivariableeditor.UIVariableEditor
                selectedRows (:,2) double {mustBeReal, mustBePositive}
                selectedColumns (:,2) double {mustBeReal, mustBePositive}
            end
            view = obj.Document.ViewModel;
            view.setSelection(selectedRows, selectedColumns);
        end

        function handleSelectionChanged(obj, eventData)
            % This is the property callback that needs to be implemented by
            % consumers of the UIVariableEditor in order to react to
            % selection changes by the user
            selectionObj = struct('Rows', eventData.Selection{1}, ...
                'Columns', eventData.Selection{2});
            if ~isempty(obj.SelectionChangedCallbackFcn)
                try
                    obj.SelectionChangedCallbackFcn(selectionObj);
                catch e
                    disp(e);
                end
            end
        end

        % API to scroll the view on the client.
        function scrollTo(obj, row, column)
            %{
                row (1,1) The row to scroll the viewport to
                column (1,1) The column to scroll the viewport to
            %}
            arguments
                obj matlab.internal.datatools.uicomponents.uivariableeditor.UIVariableEditor
                row (1,1) double {mustBeReal, mustBePositive}
                column (1,1) double {mustBeReal, mustBePositive}
            end
            view = obj.Document.ViewModel;
            view.scrollViewOnClient(row, column);
        end

        function handleScrollPositionChanged(obj, eventData)
            % This is the property callback that needs to be implemented by
            % consumers of the UIVariableEditor in order to react to
            % selection changes by the user
            scrollPositionObj = struct('Row', eventData.StartRow, ...
                'Column', eventData.StartColumn);
            if ~isempty(obj.ScrollPositionChangedCallbackFcn)
                try
                    obj.ScrollPositionChangedCallbackFcn(scrollPositionObj);
                catch e
                    disp(e);
                end
            end
        end
        
        function handleUserDataInteraction(this, eventData)
            % This is the property callback that needs to be implemented by
            % consumers of the UIVariableEditor in order to react to
            % user data interactions like sorting and filtering.
            
            % Disable the editing listeners to prevent double updates
            if ~isempty(this.DataChangeListener)
                this.DataChangeListener.Enabled = false;
            end
            
            docID = this.Document.DocID;
            channel = strcat('/VE/filter',docID);
            filtMgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            if ~isempty(filtMgr.Workspaces)
                % Get the filteredTable prop. from the FilterWorkspace so that
                % we do not loose prior user interactions.
                ws = filtMgr.Workspaces('filterWorkspace');
                filtData = ws.FilteredTable;
            
                % Assign the mutated data to the variable in the
                % UIVariableEditor Workspace.
                if (this.IsTimetable)
                    filtData = table2timetable(filtData);
                end
                assignin(this.Workspace, this.Variable, filtData);
            end
            
            % Evaluate the new action code to reflect the latest changes
            codeToExecute = eventData.Code;
            if iscell(codeToExecute)
                codeToExecute = codeToExecute{end};
            end
            evalin(this.Workspace, codeToExecute);
            
            if ~isempty(this.UserDataInteractionCallbackFcn)
                try
                    this.UserDataInteractionCallbackFcn(eventData);
                catch e
                    disp(e);
                end
            end
            
            % Re-enable the editing listeners
            if ~isempty(this.DataChangeListener)
                this.DataChangeListener.Enabled = true;
            end
        end

        function handleDataEdit(this, eventData)
            % This method is called in response to a single cell edit. 
            try
                code = eventData.Code;
                % Evaluate the code in the UIVariableEditor Workspace to
                % reflect the edit action
                evalin(this.Workspace, code);
                
                % g2457036: If the workspace is private, force a variableChanged event
                %% TODO: Remove this once appWorkspace can detect changes in handle objects.
                if isobject(this.Workspace)
                    % g2505927: If the VariablesChanged event does not
                    % exist on the private workspace, call the update APIs
                    % on the Document and DataModel directly. 
                    if ismember('VariablesChanged', events(this.Workspace))
                        wce = matlab.internal.datatoolsservices.AppWorkspaceChangeEvent;
                        wce.Type = 'VariablesChanged';
                        wce.Workspace = this.Workspace;
                        wce.Variables = {this.Variable};
                        this.Workspace.notify('VariablesChanged', wce);
                    else
                        this.Document.workspaceUpdated(this.Variable, internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_CHANGED);
                        this.Document.DataModel.workspaceUpdated(this.Variable, internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_CHANGED);
                    end
                end
            catch e
                % g2651217: Temp. fix to ensure all errors are handled
                % similarly. 
                %% TODO: Remove the manual event dispatch and provide downstream consumers a way to 
                %% override the default error handling.
                s = struct;
                s.type = 'dataChangeStatus';  
                s.status = 'error';
                s.message = e.message;
                s.eventType = 9;
                s.source = 'server';
                s.row = [];
                s.column = [];
                s.newValue = [];
                
                message.publish(this.Document.ViewModel.Channel, s);
            end
            
            % This is the property callback that needs to be implemented by
            % consumers of the UIVariableEditor in order to react to
            % user data interactions like sorting and filtering.
            % evalin(this.Workspace,
            if ~isempty(this.DataEditCallbackFcn)
                try
                    this.DataEditCallbackFcn(eventData);
                catch e
                    disp(e);
                end
            end
        end
        
        % This method is called when the workspace variable is changed via
        % an edit from the UIVariableEditor OR some external action. In
        % this case, the Filtering Workspace needs to be updated to reflect
        % the mutated data.
        function handleDataChange(obj, eventData)
            tVar = eventData.Source.DataModel.Data;
            obj.IsTimetable = strcmp(eventData.Source.DataModel.ClassType, 'timetable');
            docID = obj.Document.DocID;
            channel = strcat('/VE/filter',docID);
            filtMgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            if ~isempty(filtMgr.Workspaces)
                tws = filtMgr.Workspaces('filterWorkspace');
                % Add this check to prevent resetting of the cache if the
                % change was caused by filtering the data.
                if ~isequaln(sortrows(tws.FilteredTable), sortrows(tVar))
                    tws.updateTableAndResetCache(tVar, docID);
                end
            end
        end

        % This method is called when a property is set on the view model
        % from the client-side
        % We're looking for SearchPluginInitialized property to make sure
        % to set the key bindings on the client-side
        function handleViewPropertySet(obj, eventData)
            if ~isempty (eventData) && isprop(eventData, 'Properties') && strcmp(eventData.Properties, 'SearchPluginInitialized')
                obj.bindFindKeys;
            end
        end
        
        % This method is called in respose to a change in the Manager's
        % "Documents" property. 
        % It is used to handle addition of new documents when the user
        % drills into cells in the UIVariableEditor
        %% TODO: Try to use the DocumentAdded event on the Manager instead
        function handleDocumentPropertyChange(obj, eventData)
            % Save the current Non-Plugin Diplay Properties so that they 
            % may be set again.
            sparkLinesVisible = obj.SparkLinesVisible;
            statisticsVisible = obj.StatisticsVisible;
            dataEditable = obj.DataEditable;
            visibleColumns = obj.VisibleColumns;
            
            % Delete all existing listeners on the document
            obj.deleteListeners;
            
            % Setup the HTML page with the new document
            % g2346688: Close the variable using the Document's workspace
            mgr = eventData.AffectedObject;
            mgr.closevar(obj.Document.Name, obj.Document.Workspace);
                        
            obj.Document = mgr.Documents;
            obj.Variable = obj.Document.Name;
            obj.IsTimetable = istimetable(evalin(obj.Workspace, obj.Variable));
            obj.setupUIHTML;
            
            % Set the Non-Plugin Display Properties Again.
            obj.SparkLinesVisible = sparkLinesVisible;
            obj.StatisticsVisible = statisticsVisible;
            obj.DataEditable = dataEditable;
            obj.VisibleColumns = visibleColumns;
        end

        % Handle document type change when the data type is changed from
        % an external source (i.e., not through the UIVariableEditor).
        function handleDocumentTypeChanged(obj)
            obj.refresh;
        end
        
        % Call this method to add the Go-Up affordance.
        % It is called in responce to a document change which can
        % occur via a drill down into a nested view OR if the user launches
        % the UIVariableEditor with a nested view directly.
        function showGoUpBtn(obj)
            % Move the UIHTML one row lower
            obj.GridLayout.RowHeight{1} = 20;
            obj.GridLayout.ColumnWidth{2} = 40;
            
            % Enable the GoUp Button
            obj.Button.Enable = 1;
        end  
        
        % Call this method to remove the Go-Up affordance.
        % It is called when the user toggles the GoUp affordance to replace
        % the current document with it's parent.
        function hideGoUpBtn(obj)
            obj.GridLayout.RowHeight{1} = 0;
            obj.Button.Enable = 0;
        end
        
        % This method is called in reponse to the GO-UP Button being
        % pushed. This method handles reverting to the parent document and
        % hiding the UIButton if the user is at the top-most level.
        function goUp(obj)
            % Disable the Button
            obj.Button.Enable = 0;
            
            obj.deleteListeners;
            
            % Save the current Non-Plugin Diplay Properties so that they 
            % may be set again.
            sparkLinesVisible = obj.SparkLinesVisible;
            statisticsVisible = obj.StatisticsVisible;
            dataEditable = obj.DataEditable;
            visibleColumns = obj.VisibleColumns;
            
            obj.Variable = char(obj.ParentDocument);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(obj.Channel,false);
            mgr.closevar(obj.Document.Name, obj.Workspace);
            delete(obj.Document);

            obj.setupUIHTML;
            
            % Set the Non-Plugin Display Properties again.
            obj.SparkLinesVisible = sparkLinesVisible;
            obj.StatisticsVisible = statisticsVisible;
            obj.DataEditable = dataEditable;
            obj.VisibleColumns = visibleColumns;
        end
                
        % Delete all existing listeners on the document
        function deleteListeners(obj)
            if ~isempty(obj.SelectionChangedListener)
                delete(obj.SelectionChangedListener);
                obj.SelectionChangedListener = [];
            end

            if ~isempty(obj.ScrollPositionChangedListener)
                delete(obj.ScrollPositionChangedListener);
                obj.ScrollPositionChangedListener = [];
            end

            if ~isempty(obj.UserDataInteractionListener)
                delete(obj.UserDataInteractionListener);
                obj.UserDataInteractionListener = [];
            end

            if ~isempty(obj.DataEditListener)
                delete(obj.DataEditListener);
                obj.DataEditListener = [];
            end

            if ~isempty(obj.DataChangeListener)
                delete(obj.DataChangeListener);
                obj.DataChangeListener = [];
            end
            
            if ~isempty(obj.DocumentOpenedListener)
                delete(obj.DocumentOpenedListener);
                obj.DocumentOpenedListener = [];
            end

            if ~isempty(obj.DocumentTypeChangedListener)
                delete(obj.DocumentTypeChangedListener);
                obj.DocumentTypeChangedListener = [];
            end
        end
    end
end
