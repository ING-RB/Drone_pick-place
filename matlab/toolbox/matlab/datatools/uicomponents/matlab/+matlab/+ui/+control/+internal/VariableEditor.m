classdef (ConstructOnLoad=true) VariableEditor < ...        
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent  & ...
        matlab.ui.control.internal.model.mixin.Layoutable
    %
    
    % Do not remove above white space
    % Copyright 2020-2024 The MathWorks, Inc.
 
   
    properties(Access = {?VariableEditor, ?matlab.unittest.TestCase }, Constant)
        DEFAULT_POSITION            = [100 100 300 300]
        VEManagerKey                = '/UIVariableEditor';

        PluginList                  = ["DataSortable", "DataFilterable", "DataEditable", ...
                                          "CategoricalColumnCleanable", "DataTypeChangeable", ...
                                          "DataSelectable", "RowHeadersVisible", ...
                                          "ContextMenusVisible", "InfiniteGrid", "PadDataRequests", "DataSearchable", ...
                                          "DrilldownEnabled", "LightWeightViewEnabled"];
        PluginListI                 = ["SORT", "COLUMN_FILTER", "DataEditable", ...
                                          "CLEAN_CATEGORIES", "DATA_TYPE_CONVERSION", ...
                                          "PEER_PLAID_SELECTION", "ROW_HEADERS", ...
                                          "ARRAY_VIEW_CONTEXT_HANDLER", "INFINITE_GRID", "DATA_PADDING", "SEARCHABLE", ...
                                          "DOUBLE_CLICK_HANDLER", "LIGHT_WEIGHT_VIEW"];

        DependantPluginsI           = {struct('HEADER_MENU', {'SORT', 'COLUMN_FILTER'}), ...
                                          struct('ARRAY_VIEW_CONTEXT_HANDLER', 'PEER_PLAID_SELECTION'), ...           % Disable table context menus if DataSelectable is off
                                          struct('TABLE_CONTEXT_BASED_PLAID_SELECTION', 'PEER_PLAID_SELECTION'), ...  % Disable table context menus if DataSelectable is off
                                          struct('CORNER_SPACER_TEXT', 'ROW_HEADERS'), ...                            % Disable corner spacer selection if RowHeadersVisible is off
                                          struct('COLUMN_SORT', 'SORT'), ...                                          % Disable struct sorting if DataSortable is off
                                          struct('REMOTE_MULTI_ROW_SELECTION', 'PEER_PLAID_SELECTION'), ...           % Disable struct selection if DataSelectable is off
                                          struct('REMOTE_MULTI_ROW_TREE_SELECTION', 'PEER_PLAID_SELECTION'), ...      % Disable struct selection if DataSelectable is off
                                          struct('CONTEXT_BASED_SELECTION', 'PEER_PLAID_SELECTION'), ...              % Disable struct selection if DataSelectable is off
                                          struct('CONTEXT_BASED_TREETABLE_SELECTION', 'PEER_PLAID_SELECTION'), ...    % Disable struct tree selection if DataSelectable is off g3223263
                                          struct('VIEW_CONTEXT_HANDLER', 'ARRAY_VIEW_CONTEXT_HANDLER'), ...           % Disable struct context menus if ContextMenusVisible is off
                                          struct('INFINITE_GRID', 'PEER_PLAID_SELECTION'), ...                        % Disable infinite grid if DataSelectable is off
                                          struct('INFINITE_GRID', 'DataEditable'), ...                                % Disable infinite grid if DataEditable is off
                                          struct('TREE_TABLE_DOUBLE_CLICK_HANDLER', 'DOUBLE_CLICK_HANDLER')};         % Disable tree table double click if double click is off

        DEFAULT_VISIBLE_COLS        = ["Name", "Value", "Size", "Class"];                                             % The default columns visible for scalar structs

        FILTER_CHANNEL              = '/VE/filter';
    end

    properties (Access = {?VariableEditor, ?matlab.unittest.TestCase }, Transient, NonCopyable, Hidden)
        GridLayout                  matlab.ui.container.GridLayout
        Button                      matlab.ui.control.Button
        Document                    internal.matlab.variableeditor.peer.RemoteDocument
        Channel
    end

    properties (Access = {?VariableEditor, ?matlab.unittest.TestCase }, Transient, NonCopyable, Hidden)
        VariableI;
        WorkspaceI;
        DisabledPluginsI;
        VisibleColumnsI;
        ParentDocument;
        IsTimetable;

        SparkLinesVisibleI          matlab.lang.OnOffSwitchState = 'off'
        StatisticsVisibleI          matlab.lang.OnOffSwitchState = 'off'
        DataEditableI               matlab.lang.OnOffSwitchState = 'off'
        SearchLintbarsVisibleI      matlab.lang.OnOffSwitchState = 'off'
        BackgroundColorI;

        SelectionChangedListener;
        ScrollPositionChangedListener;
        UserDataInteractionListener;
        DataEditListener;
        DataChangeListener;
        DocClosedListener;
        PropertySetListener;
        DoubleClickListener;
    end

    properties (Dependent = true)
        Variable;
        Workspace;
        Selection;
        ScrollPosition;
        SparkLinesVisible
        StatisticsVisible
        SearchLintbarsVisible
        DataEditable
        BackgroundColor
    end

    properties (GetAccess='public', SetAccess='private')
        FeatureConfig;
    end
    
    properties (Hidden)
        VisibleColumns
    end
    
    properties (Access='public')
        % Features
        DataSortable                  matlab.lang.OnOffSwitchState = 'off'
        DataFilterable                matlab.lang.OnOffSwitchState = 'off'
        CategoricalColumnCleanable    matlab.lang.OnOffSwitchState = 'off'
        DataTypeChangeable            matlab.lang.OnOffSwitchState = 'off'
        DataSelectable                matlab.lang.OnOffSwitchState = 'off'
        ContextMenusVisible           matlab.lang.OnOffSwitchState = 'off'
        RowHeadersVisible             matlab.lang.OnOffSwitchState = 'off'
        InfiniteGrid                  matlab.lang.OnOffSwitchState = 'on'
        PadDataRequests               matlab.lang.OnOffSwitchState = 'off'
        DataSearchable                matlab.lang.OnOffSwitchState = 'off'
        DrilldownEnabled              matlab.lang.OnOffSwitchState = 'on'
        LightWeightViewEnabled        matlab.lang.OnOffSwitchState = 'off'

        % Callback Functions
        SelectionChangedCallbackFcn;
        ScrollPositionChangedCallbackFcn;
        UserDataInteractionCallbackFcn;
        DataEditCallbackFcn;
        DrillDownRequestCallbackFcn;
        SearchStateChangedCallbackFcn;
    end

    properties(GetAccess=public, SetAccess=private, Hidden, Transient)
        % Configuration
        UUID                            = matlab.lang.internal.uuid
        DocID
        ParentName
    end

    properties(GetAccess=public, SetAccess=private)
        SummaryBarVisible               (1,1) logical = false
        SearchState = struct;
    end

    % Getters/Setters
    methods
        function val = get.Variable(obj)
            val = obj.VariableI;
        end
        function set.Variable(obj, val)
            if ~strcmp(val, obj.VariableI)
                obj.VariableI = val;
                obj.setupDocument;
            end
        end

        function val = get.Workspace(obj)
            val = obj.WorkspaceI;
        end
        function set.Workspace(obj, val)
            obj.WorkspaceI = val;
        end

        function val = get.Selection(obj)
            rows = [];
            columns = [];
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel) && isprop(obj.Document.ViewModel, 'SelectedRowIntervals')
                rows = obj.Document.ViewModel.SelectedRowIntervals;
                columns = obj.Document.ViewModel.SelectedColumnIntervals;
            end
            val = struct('Rows', rows, 'Columns', columns);
        end
        function set.Selection(obj, selectionObj)
            obj.SelectionChangedListener.Enabled = false;
            if ~isfield(selectionObj, 'UpdateFocus')
                selectionObj.UpdateFocus = true;
            end
            obj.setSelection(selectionObj.Rows, selectionObj.Columns, selectionObj.UpdateFocus);
            obj.SelectionChangedListener.Enabled = true;
        end

        function val = get.ScrollPosition(obj)
            row = 0;
            column = 0;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel) && isprop(obj.Document.ViewModel, 'ViewportStartRow')
                row = obj.Document.ViewModel.ViewportStartRow;
                if (row <= 4)
                    row = row + 4;
                end
                column = obj.Document.ViewModel.ViewportStartColumn;
            end
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

        function val = get.LightWeightViewEnabled(obj)
            val = obj.LightWeightViewEnabled;
        end
        function set.LightWeightViewEnabled(obj, val)
            obj.LightWeightViewEnabled = val;
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
            val = obj.DataEditableI;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'getTableModelProperty')
                logicalVal = obj.Document.ViewModel.getTableModelProperty('editable');
                if ~isempty(logicalVal) && logicalVal
                    val = matlab.lang.OnOffSwitchState('on');
                else
                    val = matlab.lang.OnOffSwitchState('off');
                end
            end
        end
        
        function set.DataEditable(obj, val)
            arguments
                obj
                val  (1,1) matlab.lang.OnOffSwitchState = 'off'
            end
            obj.DataEditableI = val;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty') %#ok<*MCSUP> 
                isOn = (val == true);
                obj.Document.ViewModel.setTableModelProperties('editable', isOn);
            end
        end
        
        function val = get.SparkLinesVisible(obj)
            val = obj.SparkLinesVisibleI;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'getTableModelProperty')
                logicalVal = obj.Document.ViewModel.getTableModelProperty('ShowSparkLines');
                if ~isempty(logicalVal) && logicalVal
                    val = matlab.lang.OnOffSwitchState('on');
                else
                    val = matlab.lang.OnOffSwitchState('off');
                end
            end
        end
        
        function set.SparkLinesVisible(obj, val)
            arguments
                obj
                val  (1,1) matlab.lang.OnOffSwitchState = 'off'
            end
            obj.SparkLinesVisibleI = val;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty')
                isOn = (val == true);
                obj.Document.ViewModel.setTableModelProperty('ShowSparkLines', isOn);
            end
        end

        function val = get.StatisticsVisible(obj)
            val = obj.StatisticsVisibleI;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'getTableModelProperty')
                logicalVal = obj.Document.ViewModel.getTableModelProperty('ShowStatistics');
                if ~isempty(logicalVal) && logicalVal
                    val = matlab.lang.OnOffSwitchState('on');
                else
                    val = matlab.lang.OnOffSwitchState('off');
                end
            end
        end
        
        function set.StatisticsVisible(obj, val)
            arguments
                obj
                val  (1,1) matlab.lang.OnOffSwitchState = 'off'
            end
            obj.StatisticsVisibleI = val;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty')
                isOn = (val == true);
                obj.Document.ViewModel.setTableModelProperty('ShowStatistics', isOn);
            end
        end

        function val = get.SearchLintbarsVisible(obj)
            val = obj.SearchLintbarsVisibleI;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'getProperty')
                logicalVal = obj.Document.ViewModel.getProperty('ShowSearchLintbars');
                if ~isempty(logicalVal) && logicalVal
                    val = matlab.lang.OnOffSwitchState('on');
                else
                    val = matlab.lang.OnOffSwitchState('off');
                end
            end
        end
        
        function set.SearchLintbarsVisible(obj, val)
            arguments
                obj
                val  (1,1) matlab.lang.OnOffSwitchState = 'off'
            end
            obj.SearchLintbarsVisibleI = val;
            if ~isempty(obj.Document) && ~isempty(obj.Document.ViewModel)...
                    && ismethod(obj.Document.ViewModel, 'setProperty')
                isOn = (val == true);
                obj.Document.ViewModel.setProperty('ShowSearchLintbars', isOn);
            end
        end

        function val = get.VisibleColumns(obj)
            val = obj.VisibleColumnsI;
        end
        
        % Iterate through the FieldColumns and update Visible property on
        % the columns.
        function set.VisibleColumns(obj, val)
            arguments
                obj matlab.ui.control.internal.VariableEditor
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

        function val = get.DrilldownEnabled(obj)
            val = obj.DrilldownEnabled;
        end

        function set.DrilldownEnabled(obj, val)
            obj.DrilldownEnabled = val;
            obj.refresh;
        end

        function val = get.BackgroundColor(obj)
            val = obj.BackgroundColorI;
        end

        function set.BackgroundColor(obj, newColor)
            obj.BackgroundColorI = newColor;
            % Update Model
            % obj.BackgroundColor = newColor;

            % Update View
            markPropertiesDirty(obj, {'BackgroundColor'});

            obj.setTableBackgroundColor(newColor);
        end
    end

    % Public Methods
    methods
        % ---------------------------------------------------------------------
        % Constructor
        % ---------------------------------------------------------------------
        function obj = VariableEditor(NameValueArgs)
            arguments
                NameValueArgs.Parent                                                                 = uifigure
                % Donot assign default color to Background color, it can
                % break Desktop theming
                NameValueArgs.BackgroundColor
                NameValueArgs.Position                                                               = matlab.ui.control.internal.VariableEditor.DEFAULT_POSITION

                % UIVariableEditor Config.
                NameValueArgs.Workspace                                                              = 'base'
                NameValueArgs.Variable                          (1,:) char                           = ''
                NameValueArgs.UUID                              (1,:) char                           = matlab.lang.internal.uuid

                % UIVariableEditor Interaction Plugins
                NameValueArgs.DataSortable                      matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataFilterable                    matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataEditable                      matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.CategoricalColumnCleanable        matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataTypeChangeable                matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataSelectable                    matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.ContextMenusVisible               matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DrilldownEnabled                  matlab.lang.OnOffSwitchState         = 'on'

                % UIVariableEditor Display Plugins
                NameValueArgs.RowHeadersVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.SparkLinesVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.StatisticsVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.SummaryBarVisible                 matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.SearchLintbarsVisible             matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.InfiniteGrid                      matlab.lang.OnOffSwitchState         = 'on'
                NameValueArgs.PadDataRequests                   matlab.lang.OnOffSwitchState         = 'off'  % TODO: Remove once https://jira.mathworks.com/browse/MLFA-3641 has been submitted.
                NameValueArgs.DataSearchable                    matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.LightWeightViewEnabled            matlab.lang.OnOffSwitchState         = 'off'

                % Default Columns Visible for Scalar Structs
                NameValueArgs.VisibleColumns                    string                               = matlab.ui.control.internal.VariableEditor.DEFAULT_VISIBLE_COLS
            end

            %

            % Do not remove above white space
            % Override the default values

            obj.Type = 'uivariableditor';

            % Wrap LXE Workspace in common interface
            if (isa(NameValueArgs.Workspace, 'matlab.lang.internal.Workspace'))
                obj.Workspace = matlab.internal.datatoolsservices.AppWorkspace(NameValueArgs.Workspace, CloneWorkspace=false);
            else
                obj.Workspace = NameValueArgs.Workspace;
            end
            obj.VariableI = NameValueArgs.Variable;

            % Initialize Layout Properties
            obj.Position = NameValueArgs.Position;
            obj.PrivateInnerPosition = NameValueArgs.Position;
            obj.PrivateOuterPosition = NameValueArgs.Position;
            obj.AspectRatioLimits = [1 1];

            obj.SummaryBarVisible = NameValueArgs.SummaryBarVisible;
            
            % Make the UUID public
            obj.UUID = NameValueArgs.UUID;

            obj.Channel = [obj.VEManagerKey '_' char(obj.UUID)];
            obj.markPropertiesDirty({'UUID', 'Channel', 'SummaryBarVisible'});

            % Mark properties dirty so that component infrastructure knows to sync them
            % to the client-side.  We need UUID and Channel in order to make sure we sync
            % the correct client and server models.
            obj.markPropertiesDirty({'UUID', 'Channel'});

            % Configure the feature that are enabled based on the user
            % input
            obj.FeatureConfig = cell2struct((arrayfun(@(x)({obj.(x)}), obj.PluginList)), cellstr(obj.PluginList), 2);

            % Call superclass parsePVPairs for all GBT component level
            % properties
            parsePVPairs(obj,  {'Parent'}, {NameValueArgs.Parent}, {'Position'}, {NameValueArgs.Position});

            % Initialize the UIVariableEditor
            obj.setupDocument;

            % Initialize Non-Plugin Display Properties for VariableEditor
            % specific properties
            obj.setFromNVPairs(NameValueArgs);
            % obj.SparkLinesVisible = NameValueArgs.SparkLinesVisible;
            % obj.StatisticsVisible = NameValueArgs.StatisticsVisible;
            % obj.DataEditable = NameValueArgs.DataEditable;
            % obj.VisibleColumns = NameValueArgs.VisibleColumns;
        end

        function delete(obj)
            obj.deleteListeners;
            
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(obj.Channel,false);
            % Close the document assicated with the UIVariable Instance.
            if ~isempty(obj.Document) && isvalid(obj.Document) && ~isempty(obj.Document.Name)
                docID = obj.Document.DocID;
                channel = strcat(matlab.ui.control.internal.VariableEditor.FILTER_CHANNEL,docID);
                filtMgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
                filtMgr.delete();
                mgr.closevar(obj.Document.Name, obj.Workspace);
            end

            % Delete the manager if all its documents are closed.
            mgr.delete();
        end

        % Rename the specified column (using its HeaderName property) to a new name.
        % For example, the "Name" header name is "Field". If you want to
        % rename the header name to "VariableName", you would run:
        % >> VariableEditor.renameColumn("Name", "VariableName");
        function renameColumn(obj, columnHeaderName, newName)
            documentExists = ~isempty(obj.Document) && isvalid(obj.Document);
            viewModelExists = ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel);

            if documentExists && viewModelExists
                column = obj.Document.ViewModel.findFieldByHeaderName(columnHeaderName);
                column.setHeaderTagName(newName);
            end
        end

        function setTableColumnWidth(obj, width)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty')
                obj.Document.ViewModel.setTableModelProperty('ColumnWidth', width);
            end
        end

        function setCellBackgroundColor(obj, row, col, newColor)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setCellModelProperty')

                    viewModel = obj.Document.ViewModel;
                    s = viewModel.getSize();
                    l = zeros(s);
                    l(row, col) = 1;
                    obj.setCellBackgroundColorForIndices(l, newColor);
            end
        end

        % API to set background color for cells in the Variable Editor
        % indexArr is a logical array with same size as that of the current
        % slice of the dataset
        % newColor is a 1x3 array representing (r,g,b)
        function setCellBackgroundColorForIndices(obj, indexArr, newColor)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setCellModelProperty')

                viewModel = obj.Document.ViewModel;
                bgcolorPlugin = viewModel.getPluginByName('BACKGROUND_COLOR_PLUGIN');
                if isempty(bgcolorPlugin)
                    viewModel.addToPlugins('BACKGROUND_COLOR_PLUGIN');
                    bgcolorPlugin = viewModel.getPluginByName('BACKGROUND_COLOR_PLUGIN');
                end
                jsColor = obj.getJSRGBColorStyle(newColor);
                bgcolorPlugin.setColorIndices(indexArr, jsColor);
            end
        end

        function setRowBackgroundColor(obj, row, newColor)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setRowModelProperty')
                jsColor = obj.getJSRGBColorStyle(newColor);
                currentStyle = obj.Document.ViewModel.getRowModelProperty(row, 'style');
                jsStyle = obj.getModifiedStyle(currentStyle, jsColor);
                obj.Document.ViewModel.setRowModelProperty(row, 'style', jsStyle);
            end
        end

        function setColumnBackgroundColor(obj, col, newColor)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setColumnModelProperty')

                jsColor = obj.getJSRGBColorStyle(newColor);
                currentStyle = obj.Document.ViewModel.getColumnModelProperty(col, 'style');
                jsStyle = obj.getModifiedStyle(currentStyle, jsColor);
                obj.Document.ViewModel.setColumnModelProperty(col, 'style', jsStyle);
            end
        end

        function setTableBackgroundColor(obj, newColor)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setTableModelProperty')

                jsColor = obj.getJSRGBColorStyle(newColor);
                currentStyle = obj.Document.ViewModel.getTableModelProperty('style');
                jsStyle = obj.getModifiedStyle(currentStyle, jsColor);
                obj.Document.ViewModel.setTableModelProperty('style', jsStyle);
            end
        end

        function clearCellColors(obj)
            if ~isempty(obj.Document) && isvalid(obj.Document) ...
                    && ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel) ...
                    && ismethod(obj.Document.ViewModel, 'setCellModelProperty')
                viewModel = obj.Document.ViewModel;
                bgcolorPlugin = viewModel.getPluginByName('BACKGROUND_COLOR_PLUGIN');
                if isempty(bgcolorPlugin)
                    viewModel.addToPlugins('BACKGROUND_COLOR_PLUGIN');
                    bgcolorPlugin = viewModel.getPluginByName('BACKGROUND_COLOR_PLUGIN');
                end
                bgcolorPlugin.clearColors();

                viewModel.CellModelProperties = [];
                s = viewModel.getSize();
    
                eventdata = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                eventdata.Row = 1:s(1);
                eventdata.Column = 1:s(2);
                viewModel.notify('CellMetaDataChanged', eventdata);  
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

        function goToFindDialogMatch(obj, index)
            arguments
                obj
                index (1,1) {mustPositiveNumericOrIn(index, ["next", "previous"])}
            end
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(obj.Channel,false);
            if ~isempty(mgr.ActionManager)
                sa = mgr.ActionManager.ActionDataService.getAction('SearchAction');
                if ~isempty(sa)
                    sa.Action.goToMatch(index);
                end
            end
        end

        function bindFindKeys(obj)
            if ~isempty(obj.Document)
                obj.Document.Manager.FocusedDocument = obj.Document;
                sa = obj.Document.Manager.ActionManager.ActionDataService.getAction('SearchAction');
                if ~isempty(sa)
                    sa.Action.Search(struct('bindKeys', obj.DataSearchable));
                end
            end
        end

        function state = getFilterState(this)
            state = struct.empty;

            data = this.Document.DataModel.getData();
            if ~istabular(data)
                return;
            end

            ws = this.getFilterWorkspace;
            if ~isempty(ws)
                state = ws.serializeFilters;
            end
        end

        function setFilterState(this, state, triggerCallbacks)
            arguments
                this
                state
                triggerCallbacks (1,1) logical = false
            end

            data = this.Document.DataModel.getData();
            if ~istabular(data)
                return;
            end
            ws = this.getFilterWorkspace;
            if ~isempty(ws)
                ws.deserializeFilters(state);
                filtData = ws.FilteredTable;
            
                % Assign the mutated data to the variable in the
                % UIVariableEditor Workspace.
                if (this.IsTimetable)
                    filtData = table2timetable(filtData);
                end
                assignin(this.Workspace, this.Variable, filtData);

                % Set UI Filtered State
                vars = data.Properties.VariableNames;
                this.Document.ViewModel.setColumnModelProperty(1:length(vars),'IsFiltered', false);
                [~,fi] = ws.getFilteredColumns();
                this.Document.ViewModel.setColumnModelProperty(fi,'IsFiltered', true);

                % Need to trigger individual callbacks for each filtering
                % Firing of events used for testing purposes mostly
                if triggerCallbacks && ~isempty(this.UserDataInteractionCallbackFcn)
                    if isfield(state, 'CategoricalFilters')
                        fns = fields(state.CategoricalFilters);
                        for i=1:length(fns)
                            fieldName = fns{i};
                            varNames = data.Properties.VariableNames;
                            index = find(strcmp(varNames, fieldName)) - 1; % Expects 0-based indexing
                            if (index >= 0)
                                actionInfo = struct('index', index, 'userAction', 'SingleCheckbox');
                                editInfo = struct('actionInfo', actionInfo, 'docID', this.Document.DocID);
                                editTextboxAction = internal.matlab.variableeditor.Actions.EditCheckboxAction(struct(), this.Document.Manager);
                                editTextboxAction.EditCheckbox(editInfo);
                            else
                                disp("Bad index(" + index + ") for " + fieldName)
                            end
                        end
                    end

                    if isfield(state, 'NumericFilters')
                        fns = fields(state.NumericFilters);
                        for i=1:length(fns)
                            fieldName = fns{i};
                            varNames = data.Properties.VariableNames;
                            index = find(strcmp(varNames, fieldName)) - 1; % Expects 0-based indexing
                            if (index >= 0)
                                actionInfo = struct('index', index);
                                editInfo = struct('actionInfo', actionInfo, 'docID', this.Document.DocID);
                                editTextboxAction = internal.matlab.variableeditor.Actions.EditTextboxAction(struct(), this.Document.Manager);
                                editTextboxAction.EditTextbox(editInfo);
                            else
                                disp("Bad index(" + index + ") for " + fieldName)
                            end
                        end
                    end
                end
            end
        end

        function resetFilters(this)
            this.setFilterState(struct.empty);
        end

        % Getter to fetch current ND Array slice being viewed as a string
        % array
        function slice = getDimensionSliceForNDArray(obj)
            documentExists = ~isempty(obj.Document) && isvalid(obj.Document);
            if (documentExists) && isprop(obj.Document.DataModel, 'Slice')
                slice = obj.Document.DataModel.Slice;
            else
                slice = [];
            end
        end

        % Setter to programatically set current ND Array slice
        function slice = setDimensionSliceForNDArray(obj, slice)
            arguments
                obj
                slice (1,:) string
            end
            documentExists = ~isempty(obj.Document) && isvalid(obj.Document);
            if (documentExists) && isprop(obj.Document.DataModel, 'Slice')
                obj.Document.DataModel.Slice = string(slice);
            end
        end

        function view = getVariableViewmodel(obj)
            view = obj.Document.ViewModel;
        end
    end

    methods (Access = {?VariableEditor, ?matlab.unittest.TestCase })
        function setFromNVPairs(obj, NVPairs)
            arguments
                obj
                NVPairs (1,1) struct
            end

            fn = fieldnames(NVPairs);
            for i=1:length(fn)
                if isprop(obj, fn{i})
                    obj.(fn{i}) = NVPairs.(fn{i});
                end
            end
        end

        function refresh(obj)
            featureConfig = {
                obj.DataSortable, ...
                obj.DataFilterable, ...
                obj.DataEditable, ...
                obj.CategoricalColumnCleanable, ...
                obj.DataTypeChangeable, ...
                obj.DataSelectable, ...
                obj.RowHeadersVisible, ...
                obj.ContextMenusVisible, ...
                obj.InfiniteGrid, ...
                obj.PadDataRequests, ...
                obj.DataSearchable, ...
                obj.DrilldownEnabled ...
                obj.LightWeightViewEnabled ...
            };
            obj.FeatureConfig = cell2struct(featureConfig, cellstr(obj.PluginList), 2);

            if ~isempty(obj.DisabledPluginsI)
                obj.Document.setProperty('DisabledPlugins', obj.DisabledPluginsI);
            else
                obj.Document.setProperty('DisabledPlugins', []);
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

        function setupDocument(obj)
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(obj.Channel,false);

            % Save the current Non-Plugin Display Properties so that they 
            % may be set again.
            sparkLinesVisible = obj.SparkLinesVisible;
            statisticsVisible = obj.StatisticsVisible;
            dataSortable = obj.DataSortable;
            infiniteGrid = obj.InfiniteGrid;
            dataSearchable = obj.DataSearchable;
            dataFilterable = obj.DataFilterable;
            dataSelectable = obj.DataSelectable;
            dataEditable = obj.DataEditable;
            visibleColumns = obj.VisibleColumns;
            drilldownEnabled = obj.DrilldownEnabled;
            bgColor = obj.BackgroundColor;
            lightWeightViewEnabled = obj.LightWeightViewEnabled;
            searchLintbarsVisible = obj.SearchLintbarsVisible;

            % Close the current document to reopen child document
            if ~isempty(obj.Document) && isvalid(obj.Document)
                mgr.closevar(obj.Document.Name, obj.Workspace);
                obj.deleteListeners;
                delete(obj.Document);
            end

            if isempty(obj.Document) || ~isvalid(obj.Document)
                try
                    tVar = evalin(obj.Workspace, obj.Variable);
                    obj.IsTimetable = istimetable(tVar);
                catch
                    tVar = internal.matlab.variableeditor.NullValueObject(obj.Variable);
                end

                % Check if someone else called openvar and the doc is
                % already opened (double click for drill down workflows
                % calls openvar on manager directly)
                docIndex = obj.findDoc(mgr, obj.Variable);

                if isempty(docIndex)
                    % call openvar on manager if doc is not opened
                    obj.Document = mgr.openvar(obj.Variable, obj.Workspace, tVar, UserContext = 'UIVariableEditor');
                else
                    % Fetch the document from manager using docIndex if the
                    % document is already opened
                    obj.Document = mgr.Documents(docIndex);
                end
            end

            % Check if the doc has a parent and show the go-up affordance
            % ortherwise hide it.
            parentDoc = obj.Document.getProperty('parentName');
            obj.ParentName = parentDoc;

            docId = obj.Document.DocID;
            obj.DocID = docId;
            obj.markPropertiesDirty({'DocID', 'ParentName', 'SummaryBarVisible'});
            % drawnow nocallbacks;

            % g2474447: Non-Plugin Diplay Properties need to be updated
            % each time the view is setup.
            obj.SparkLinesVisible = sparkLinesVisible;
            obj.StatisticsVisible = statisticsVisible;
            obj.DataEditable = dataEditable;
            obj.VisibleColumns = visibleColumns;
            obj.DataSortable = dataSortable;
            obj.InfiniteGrid = infiniteGrid;
            obj.DataSearchable = dataSearchable;
            obj.DataFilterable = dataFilterable;
            obj.DataSelectable = dataSelectable;
            obj.DrilldownEnabled = drilldownEnabled;
            obj.LightWeightViewEnabled = lightWeightViewEnabled;
            obj.SearchLintbarsVisible = searchLintbarsVisible;
            % Reset the background color in drill-down workflow
            % g3128855
            if ~isempty(obj.BackgroundColor)
                obj.BackgroundColor = bgColor;
            end


            if ~isempty(obj.DisabledPluginsI)
                obj.Document.setProperty('DisabledPlugins', obj.DisabledPluginsI);
            end

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

            % listen to double click events on the document
            obj.DoubleClickListener = addlistener(obj.Document, 'DoubleClickOnVariable', @(es,ed) obj.handleDoubleClickOnCell(ed));

            % Listen to Document Closed events on the manager
            obj.DocClosedListener = addlistener(mgr, 'DocumentClosed', @(es, ed) obj.handleDocumentClosed(ed));
            
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
        function setSelection(obj, selectedRows, selectedColumns, setFocus)
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
                obj matlab.ui.control.internal.VariableEditor
                selectedRows (:,2) double {mustBeReal, mustBePositive}
                selectedColumns (:,2) double {mustBeReal, mustBePositive}
                setFocus (1,1) logical = true
            end
            view = obj.Document.ViewModel;
            view.setSelection(selectedRows, selectedColumns, 'server', updateFocus=setFocus);
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
                    internal.matlab.datatoolsservices.logDebug("uicomponents::variableeditor", "Error executing SelectionChangedCallbackFcn: " + e.message);
                end
            end
        end

        % This is the callback that needs to be implemented by
        % consumers of the UIVariableEditor in order to react to
        % double click on a metadata cell by user.
        function handleDoubleClickOnCell(obj, eventData)
           % If Drilldown is enabled, proceed to call DrillDownRequestCallbackFcn
            if obj.DrilldownEnabled
                drillDownToOpenvar = true;
                if ~isempty(obj.DrillDownRequestCallbackFcn)
                    drillDownToOpenvar = obj.DrillDownRequestCallbackFcn(eventData);
                end
                if drillDownToOpenvar
                    newVarName = eventData.variableName;
                    % Rename the Variable name property with an incoming change if the name is different.
                    if ~strcmp(obj.Variable, newVarName)
                        obj.Variable = newVarName;
                    end
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
                obj matlab.ui.control.internal.VariableEditor
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
                    internal.matlab.datatoolsservices.logDebug("uicomponents::variableeditor::handleScrollPositionChanged", "Error executing ScrollPositionChangedCallbackFcn: " + e.message);
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
            channel = strcat(matlab.ui.control.internal.VariableEditor.FILTER_CHANNEL,docID);
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

            % g3000498: The event data "Code" field likely contains code only for the most
            % recently changed table variable. We must include _all_ generated code for the
            % table---if we don't, the user will only see generated code for their most
            % recent modification, such as filtering a table variable.
            %
            % g3146097: There are some situations where "CodeArray" (containing all the generated
            % code) is empty. This occurs, for example, when the data interaction was kicked off
            % by a Variable Editor Action, such as "DeleteAction.m".
            if ~isempty(eventData.Source.ActionStateHandler.CodeArray)
                eventData.Code = eventData.Source.ActionStateHandler.CodeArray(1:end-1);
            end

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
                % g3181569:
                % If we have a public workspace ('base', 'caller', or 'debug'),
                % we need to execute the event data code.
                %
                % If we have a private workspace instead, it's likely the code has
                % already been executed elsewhere (e.g., MLArrayDataModel.m); in this
                % case, we don't execute the code.
                % - g3146097: When the user clicks on a single cell to toggle the table variable's
                %   visibility (see this file's "addStructTablesWithColumnVisibility" function), the
                %   generated code will not execute. We must execute this code, even if we are
                %   using a private workspace.
                %   The visibility change can be refactored to act like the "rename" action; the code
                %   generated when the user renames a variable name gets executed within the view model.
                % - TODO: Is there a better way to determine if the event data code has already
                %   been executed?
                executeEventDataCode = ischar(this.Workspace) || strcmp(eventData.UserAction, 'SingleCellClick');

                if executeEventDataCode
                    code = eventData.Code;
                    % Evaluate the code in the UIVariableEditor Workspace to
                    % reflect the edit action
                    evalin(this.Workspace, code);
                else % Private workspace, like "matlab.internal.datatoolsservices.AppWorkspace"
                    % g2457036: If the workspace is private, force a variableChanged event.
                    %% TODO: Remove this once appWorkspace can detect changes in handle objects.

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
            channel = strcat(matlab.ui.control.internal.VariableEditor.FILTER_CHANNEL,docID);
            filtMgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            if ~isempty(filtMgr.Workspaces)
                tws = filtMgr.Workspaces('filterWorkspace');
                % Add this check to prevent resetting of the cache if the
                % change was caused by filtering the data.
                try
                    if ~isequaln(sortrows(tws.FilteredTable), sortrows(tVar))
                        tws.updateTableAndResetCache(tVar, docID);
                    end
                catch
                    % If the data is not sortable force the update
                    tws.updateTableAndResetCache(tVar, docID);
                end
            end
            if isprop(eventData, 'Slice') && ~isempty(eventData.Slice) && ~isempty(obj.UserDataInteractionCallbackFcn)
                try
                    obj.UserDataInteractionCallbackFcn(eventData);
                catch e
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
            elseif ~isempty (eventData) && isprop(eventData, 'Properties') && strcmp(eventData.Properties, 'SearchInfo')
                if ~isempty(obj.SearchStateChangedCallbackFcn)
                    try
                        obj.SearchStateChangedCallbackFcn(eventData.Values(1));
                    catch e
                        internal.matlab.datatoolsservices.logDebug("uicomponents::variableeditor::handlePropertyChanged", "Error executing SearchStateChangedCallbackFcn: " + e.message);
                    end
                    obj.SearchState = eventData.Values(1);
                end
            end
        end

        % This method is called when a document is deleted.
        % It is used to ensure any filtering managers that are associated
        % with the document are also cleaned up
        %% TODO: Try to use the DocumentAdded event on the Manager instead
        function handleDocumentClosed(~, eventData)
            if ~isempty(eventData.Document) && ~isempty(eventData.Document.Name)
                docID = eventData.Document.DocID;
                channel = strcat(matlab.ui.control.internal.VariableEditor.FILTER_CHANNEL, docID);
                filtMgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
                filtMgr.delete();
            end
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
            
            if ~isempty(obj.DocClosedListener)
                delete(obj.DocClosedListener);
                obj.DocClosedListener = [];
            end

            if ~isempty(obj.DoubleClickListener)
                delete(obj.DoubleClickListener);
                obj.DoubleClickListener = [];
            end

            if ~isempty(obj.PropertySetListener)
                delete(obj.PropertySetListener);
                obj.PropertySetListener = [];
            end
        end

        function jsRGB = getJSRGBColorStyle(obj, color)
            jsRGB = struct('backgroundColor', []);
            if isnumeric(color)
                jsColor = "rgb(" + color(1)*255 + "," + color(2)*255 + "," + color(3)*255 + ")";
                jsRGB = struct('backgroundColor', jsColor);
            elseif isstring(color) || ischar(color)
                if ~strcmp(color, "none")
                    jsRGB = struct('backgroundColor', color);
                end
            end
        end

        function newStyle = getModifiedStyle(~, currentStyle, delta)
            newStyle = struct;
            if isstruct(delta)
                deltaFields = fieldnames(delta);
                for i=1:length(deltaFields)
                    fieldName = deltaFields{i};
                    fieldValue = delta.(fieldName);
                    if ~isempty(fieldValue)
                        newStyle.(fieldName) = fieldValue;
                    end
                end

                if isstruct(currentStyle)
                    currFields = fieldnames(currentStyle);
                    for i=1:length(currFields)
                        fieldName = currFields{i};
                        fieldValue = currentStyle.(fieldName);
                        if ~isempty(fieldValue) && ~ismember(fieldName, deltaFields)
                            newStyle.(fieldName) = fieldValue;
                        end
                    end
                end
            end
        end

        function ws = getFilterWorkspace(this)
            ws = [];
            docID = this.Document.DocID;
            channel = strcat(matlab.ui.control.internal.VariableEditor.FILTER_CHANNEL,docID);
            filtMgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            if isempty(filtMgr.Workspaces) || ~isKey(filtMgr.Workspaces, 'filterWorkspace')
                filtAction = this.Document.Manager.ActionManager.ActionDataService.getAction('InitializeFilterAction');
                if ~isempty(filtAction)
                    try
                        % There are use cases for the Live Editor where
                        % they may be switching Variables and then
                        % requesting the filter state, this could lead to
                        % some synchronization issues which automatically
                        % get resolved once the new variable has fully
                        % opened g3206106
                        filtAction = filtAction.Action;
                        filtAction.InitFilter(struct('actionInfo', struct('index',0),'docID',docID));
                    catch e
                        internal.matlab.datatoolsservices.logDebug("uicomponents::variableeditor", "Error getting filter WS: " + e.message);
                    end
                    ws = filtMgr.Workspaces('filterWorkspace');
                end
            else
                ws = filtMgr.Workspaces('filterWorkspace');
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {...
                };
                
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = '';
            
        end
    end

    % ---------------------------------------------------------------------
    % Table Column Visibility Methods
    % ---------------------------------------------------------------------
    % These methods are responsible for showing eye icons for each table
    % and its columns.
    %
    % Example:
    % t
    % |- Col1 <o> % Open eye, signaling "Col1" is visible
    % |- Col2 < > % Shut eye, signaling "Col2" is not visible
    methods(Hidden = true)
        % Adds the given tables to the workspace with functioning eye icons.
        %
        % "visibilityData" is an array containing whether the respective
        % column is visible (1) or not visible (0). It should match the
        % number of columns a table has, plus 1 if the table is a time
        % table.
        function addStructTablesWithColumnVisibility(obj, tables, tableNames, visibilityData)
            arguments
                obj
                tables (1,:) cell
                tableNames (1,:) cell
                visibilityData (1,:) cell
            end

            if length(tables) ~= length(visibilityData) && length(tables) ~= length(tableNames)
                return;
            end

            ws = obj.Workspace;
            % For all tables, attach visibility data, then add table as a
            % child to the parent struct.
            for i = 1:length(tables)
                % Add visibility metadata to the table.
                curTable = tables{i};
                curTableName = tableNames{i};
                curVisData = visibilityData{i};
                newTable = obj.addVisibilityMetadataToTable(obj.Variable, curTableName, curTable, curVisData);

                % Assign the table as a child to the workspace parent struct.
                structParent = ws.evalin(obj.Variable);
                structParent.(curTableName) = newTable;
                ws.assignin(obj.Variable, structParent);
            end

            documentExists = ~isempty(obj.Document) && isvalid(obj.Document);
            viewModelExists = ~isempty(obj.Document.ViewModel) && isvalid(obj.Document.ViewModel);

            if documentExists && viewModelExists
                % Finally, set the "Visible" column to true...
                obj.Document.ViewModel.setColumnVisible("Visible", true);
                obj.renameColumn('Visible', ...
                    getString(message('MATLAB:datatools:preprocessing:app:VISIBLE_COLUMN_NAME')));

                % ...and expand the newly-added table.
                fieldIds = keys(newTable.Properties.CustomProperties.VisibilityFlags);
                tableFieldId = fieldIds(1);

                % Force the view model to update its field IDs. Without it,
                % the view model may not recognize the newly-added table's
                % field ID, causing an error.

                % TODO: Pass in the exact variable names that have changed
                % as the first argument to "workspaceUpdated()" for performance
                % gains. See MLNamedVariableObserver.m.
                %
                % Make sure to see what varNames (first argument) should
                % be formatted through the DataTools debugging tool/disp().
                obj.Document.DataModel.workspaceUpdated();
                obj.Document.ViewModel.expandFields(tableFieldId);
            end
        end

        % For each table in the tree struct workspace, get a list of all
        % their visible column names.
        function visibleColumns = getVisibleStructTableColumns(this)
            parentStruct = evalin(this.Workspace, this.Variable);
            tableNameList = fields(parentStruct);
            visibleColumns = dictionary;

            for i = 1:length(tableNameList)
                curTable = parentStruct.(tableNameList{i});
                visibilityFlags = curTable.Properties.CustomProperties.VisibilityFlags;

                % Get a list of all currently visible table columns.
                curTableVisibleColumns = [];
                visKeys = keys(visibilityFlags);
                visVals = values(visibilityFlags);
                len = length(keys(visibilityFlags));

                for j = 2:len % Skip the first entry, the table
                    if visVals(j) == 1
                        visKeySplit = internal.matlab.variableeditor.VEUtils.splitRowId(visKeys(j));
                        colName = visKeySplit(end);
                        curTableVisibleColumns = [curTableVisibleColumns colName]; %#ok<AGROW>
                    end
                end
                visibleColumns(tableNameList{i}) = {curTableVisibleColumns};
            end
        end

        % Set a table's column's visibility (1 = visible, 0 = hidden, -1 = no eye icon).
        %
        % This currently does not have an associated unit test in "tVariableEditor.m", but it
        % is tested in "tVariableBrowser.m" (part of the Data Cleaner/Preprocessing app).
        function setVisibilityForTableColumns(this, tableName, colNames, visVals, structName)
            arguments
                this
                tableName (1,1) string
                colNames (1,:) string {mustBeVector(colNames)}
                visVals (1,:) double {mustBeVector(visVals)}
                % visVals: An array containing values -1 (no eye icon),
                %          0 (closed eye icon), and 1 (open eye icon)
                structName (1,1) string % The name of the struct holding the table
            end

            % Generate code to set the visibility for every column specified in "colNames".
            setVisCode = strings(1, length(colNames));

            for i = 1:length(colNames)
                codeId = internal.matlab.variableeditor.VEUtils.joinRowId([structName tableName colNames(i)]);
                additionalVisCode = sprintf("%s.%s.Properties.CustomProperties.VisibilityFlags('%s') = %d;", ...
                    structName, tableName, codeId, visVals(i));
                setVisCode(i) = additionalVisCode;
            end

            % In the case we're setting visibility for more than one table
            % column, we must join all the code into one string.
            setVisCode = strjoin(setVisCode, "");
            evalin(this.Workspace, setVisCode);
        end
    end

    methods(Access = {?VariableEditor, ?matlab.unittest.TestCase}, Hidden = true)
        function colId = createColId(~, structName, tableName, colName)
            colId = internal.matlab.variableeditor.VEUtils.joinRowId([structName tableName colName]);
        end

        % Create "visibility metadata" for the imported table.
        % This metadata is used by the client Variable Editor to display
        % open/closed eye icons in the "Visible" column.
        % If a table column is not visible, no plot is generated and vice
        % versa.
        function tableData = addVisibilityMetadataToTable(this, structName, tableName, tableData, visibilityData)
            arguments
                this
                structName (1,1) string
                tableName (1,1) string
                tableData tabular
                visibilityData (1,:) double
            end

            % Set up variables for generating IDs.
            numOfCols = length(tableData.Properties.VariableNames);
            idListLen = numOfCols + 1;
            idList = strings(1, idListLen);
            idList(1) = internal.matlab.variableeditor.VEUtils.joinRowId([structName tableName]);

            % Generate IDs for all table columns.
            colNames = string(tableData.Properties.VariableNames);
            for i = 1:numOfCols
                idList(i+1) = this.createColId(structName, tableName, colNames(i));
            end

            % If this is a timetable, we must insert an extra ID for the
            % "Time" column.
            if istimetable(tableData)
                timeFieldName = tableData.Properties.DimensionNames{1};
                timeId = this.createColId(structName, tableName, timeFieldName);
                idList = [idList(1), timeId, idList(2:end)];
            end

            % Generate a dictionary using IDs as keys with default values 1.
            % The Visibility column will expect the data to be of type dictionary.
            metadata = dictionary(idList, visibilityData);

            % Add the metadata to the tableData.
            tableData = addprop(tableData, {'VisibilityFlags'}, {'table'});
            tableData.Properties.CustomProperties.VisibilityFlags = metadata;
        end

        % Returns the docIndex of a document if it is already created and
        % is available in Manager's list
        function index = findDoc(~, mgr, docName)
            index = [];

            for i=1:length(mgr.Documents)
                doc = mgr.Documents(i);
                if strcmp(doc.Name,docName)
                    index = i;
                    return;
                end
            end
        end
    end
end

function mustPositiveNumericOrIn(var, stringList)
    if (isnumeric(var) && var <= 0) || (~isnumeric(var) && ~ismember(var, stringList))
        error("Not positive number or in [" + strjoin(stringList,",") + "]");
    end
end
