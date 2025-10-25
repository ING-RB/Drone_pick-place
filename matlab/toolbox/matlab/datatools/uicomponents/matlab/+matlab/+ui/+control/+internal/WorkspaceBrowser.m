classdef (ConstructOnLoad=true) WorkspaceBrowser < ...        
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent  & ...
        matlab.ui.control.internal.model.mixin.Layoutable
    %
    
    % Do not remove above white space
    % Copyright 2021-2025 The MathWorks, Inc.

    properties(Access = {?WorkspaceBrowser, ?matlab.unittest.TestCase }, Constant)
        DEFAULT_POSITION            = [20 20 300 400]
        Context                     = 'WorkspaceBrowser';
        PluginList                  = ["DataSortable", "DataEditable", ...
            "DataSingleSelectable", "DataSelectable", "DataResizable", "DefaultContextMenus", "DataDraggable"];
        PluginListMap               = ["COLUMN_SORT", "DataEditable", ...
            "REMOTE_SINGLE_ROW_SELECTION", "REMOTE_MULTI_ROW_SELECTION", "COLUMN_RESIZE_PAGED", "VIEW_CONTEXT_HANDLER", "DRAG_AND_DROP"];
        DependantPluginsI           = struct('REMOTE_SINGLE_ROW_SELECTION', {'CELL_FOCUS'}, 'REMOTE_MULTI_ROW_SELECTION', {'CELL_FOCUS'}, 'VIEW_CONTEXT_HANDLER', {'CONTEXT_BASED_SELECTION'});
        WSBContextMenuActionsFile = fullfile(matlabroot,'toolbox','matlab','datatools','widgets','matlab','resources','UIWSBActionGroupings.xml');
        DEFAULT_VISIBLE_COLS = ["Name", "Value", "Size", "Class"];
        DEFAULT_AVAILABLE_COLS = ["Name", "Value", "Size", "Class", "Min", "Max", "Range", "Mean", "Median", "Mode", "Var", "Std", "Bytes"];
    end
   
    properties (Access = {?WorkspaceBrowser, ?matlab.unittest.TestCase }, Transient, NonCopyable, Hidden)
        WorkspaceManager            internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowserManager
        ChannelBase char = '/WorkspaceBrowser'
    end

    properties(GetAccess=public, SetAccess=private, Hidden, Transient)
        % Configuration
        UUID                            = matlab.lang.internal.uuid
    end

    properties (Access = 'protected', Transient, NonCopyable, Hidden)
        DisabledPluginsI;
        DynamicPluginsI;
        WorkspaceI = 'base';
        VisibleColumnsI;
        AvailableColumnsI;
        WSBActionManager;
        WSBContextMenuProvider;
        
        SelectionChangedListener;
        DataEditListener;
        DoubleClickListener;
        OpenSelectionListener;
        DropListener;
    end

    properties (Dependent = true)
        Workspace
        SelectedRows double;
        VisibleColumns string
        AvailableColumns string
    end
    
    properties (Dependent = true, SetAccess=protected)
        SelectedVariables string;
    end
    
    properties (GetAccess='public', SetAccess='private')
        FeatureConfig;
    end
    
    properties (Access = 'public')
        DataEditable                  matlab.lang.OnOffSwitchState = 'off'
        DataSelectable                matlab.lang.OnOffSwitchState = 'on'
        DataSingleSelectable          matlab.lang.OnOffSwitchState = 'off'
        DataSortable                  matlab.lang.OnOffSwitchState = 'off'
        DataResizable                 matlab.lang.OnOffSwitchState = 'on'
        DefaultContextMenus           matlab.lang.OnOffSwitchState = 'on'      
        DataDraggable                 matlab.lang.OnOffSwitchState = 'off'

        SelectionChangedCallbackFcn;
        DataEditCallbackFcn;
        DoubleClickCallbackFcn;
        OpenSelectionCallbackFcn;
        DropCallbackFcn;

        BackgroundColor               matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = 'white';
    end
    
    methods
        function obj = WorkspaceBrowser(NameValueArgs)
            arguments
                NameValueArgs.Parent                                                      = uifigure
                NameValueArgs.BackgroundColor                                             = 'white'
                NameValueArgs.Position                                                    = matlab.ui.control.internal.WorkspaceBrowser.DEFAULT_POSITION

                % WorkspaceBrowser configuration
                NameValueArgs.Workspace                                                   = 'base'
                NameValueArgs.UUID                   (1,:) char                           = matlab.lang.internal.uuid

                % WorkspaceBrowser Interactions
                NameValueArgs.DataEditable           matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataSelectable         matlab.lang.OnOffSwitchState         = 'on'
                NameValueArgs.DataSingleSelectable   matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataSortable           matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataResizable          matlab.lang.OnOffSwitchState         = 'on'
                NameValueArgs.DefaultContextMenus    matlab.lang.OnOffSwitchState         = 'off'
                NameValueArgs.DataDraggable          matlab.lang.OnOffSwitchState         = 'off'

                NameValueArgs.VisibleColumns string = matlab.ui.control.internal.WorkspaceBrowser.DEFAULT_VISIBLE_COLS
                NameValueArgs.AvailableColumns string = matlab.ui.control.internal.WorkspaceBrowser.DEFAULT_AVAILABLE_COLS
            end

            % Make the UUID public
            obj.UUID = NameValueArgs.UUID;
            obj.markPropertiesDirty({'UUID'});

            % Wrap LXE Workspace in common interface
            if (isa(NameValueArgs.Workspace, 'matlab.lang.internal.Workspace'))
                obj.Workspace = matlab.internal.datatoolsservices.AppWorkspace(NameValueArgs.Workspace, CloneWorkspace=false);
            else
                obj.Workspace = NameValueArgs.Workspace;
            end

            obj.DataEditable = NameValueArgs.DataEditable;
            obj.DataSelectable = NameValueArgs.DataSelectable;
            obj.DataSingleSelectable = NameValueArgs.DataSingleSelectable;
            obj.DataSortable = NameValueArgs.DataSortable;
            obj.DataResizable = NameValueArgs.DataResizable;
            obj.DefaultContextMenus = NameValueArgs.DefaultContextMenus;
            obj.DataDraggable = NameValueArgs.DataDraggable;

            markPropertiesDirty(obj, {'DataEditable', 'DataSelectable', 'DataSingleSelectable', 'DataSortable', 'DataResizable', 'DefaultContextMenus', 'DataDraggable'});

            % Configure the feature that are enabled based on the user
            % input
            if (obj.DataSingleSelectable)
                NameValueArgs.DataSelectable = matlab.lang.OnOffSwitchState.off;
            end
            obj.FeatureConfig = cell2struct((arrayfun(@(x)({NameValueArgs.(x)}), obj.PluginList)), cellstr(obj.PluginList), 2);

            % Call superclass parsePVPairs for all GBT component level
            % properties
            if ~isa(NameValueArgs.Parent, "matlab.ui.container.GridLayout")
                parsePVPairs(obj,  {'Parent'}, {NameValueArgs.Parent}, {'BackgroundColor'}, {NameValueArgs.BackgroundColor}, {'Position'}, {NameValueArgs.Position});
            else
                parsePVPairs(obj,  {'Parent'}, {NameValueArgs.Parent}, {'BackgroundColor'}, {NameValueArgs.BackgroundColor});
            end
            obj.BackgroundColor = NameValueArgs.BackgroundColor;

            % Initialize the WorkspaceBrowser
            obj.setupDocument;

            obj.DataEditable = NameValueArgs.DataEditable;
            
            % Call initFieldColumns to create any field columns that might
            % not exist before we set Available and Visible Columns
            obj.initFieldColumns;
            obj.VisibleColumns = NameValueArgs.VisibleColumns;
            obj.AvailableColumns = NameValueArgs.AvailableColumns;
        end

        function val = get.Workspace(obj)
            val = obj.WorkspaceI;
        end
        function set.Workspace(obj, val)
            obj.WorkspaceI = val;
        end
        
        function val = get.VisibleColumns(obj)
            val = obj.VisibleColumnsI;
        end
        
        function set.DataEditable(obj, val)
            arguments
                obj
                val logical;
            end
            obj.DataEditable = val;
            if ~isempty(obj.WorkspaceManager) %#ok<*MCSUP> 
                workspaceDoc = obj.WorkspaceManager.Documents(1);
                workspaceDoc.ViewModel.setTableModelProperty('editable', logical(val));
            end
            obj.markPropertiesDirty({'DataEditable'});
            
        end
        
        % Iterate through the FieldColumns and update Visible property on
        % the columns.
        function set.VisibleColumns(obj, val)
            arguments
                obj matlab.ui.control.internal.WorkspaceBrowser
                val string
            end
            if ~isempty(obj.WorkspaceManager)
                view = obj.WorkspaceManager.Documents(1).ViewModel;
                fieldColumns = view.FieldColumnList;
                for colName=keys(fieldColumns)
                    isVisible = false;
                    headerName = fieldColumns(colName{:}).HeaderName;
                    if matches(headerName, val)
                        isVisible = true;
                    end
                    view.setColumnVisible(headerName, isVisible);
                end
            end
            obj.VisibleColumnsI = val;
        end
        
        % Add getter to Available columns as we need to access this
        % internal prop from the dependent prop setter.
        function val = get.AvailableColumns(obj)
            val = obj.AvailableColumnsI;
        end
        
        % Returns the range of selected row intervals in the Workspacebrowser.
        % For e.g if rows 1 and 3-5 are selected, val = [1 1; 3 5]
        function val = get.SelectedRows(obj)
            vm = obj.WorkspaceManager.Documents.ViewModel;
            val = vm.SelectedRowIntervals;
        end
        
        % Set SelectedRows as a scalar or array of ranges to select rows in
        % the workspacebrowser.
        function set.SelectedRows(obj, selectedRows)
            arguments
                obj
                selectedRows double
            end
            obj.SelectionChangedListener.Enabled = false;
            vm = obj.WorkspaceManager.Documents.ViewModel;
            sz = vm.getTabularDataSize();
            if isscalar(selectedRows)
                selectedRows = [selectedRows selectedRows];
            end
            % Set selection with all columns selected by default.
            vm.setSelection(min(selectedRows, sz(1)), [1 sz(2)]);
            obj.SelectionChangedListener.Enabled = true;
        end
        
        % Returns all the variables selected in the workspacebrowser as a
        % string array.
        function val = get.SelectedVariables(obj)
            vm = obj.WorkspaceManager.Documents.ViewModel;     
            val = vm.SelectedFields;
        end
        
        % Iterate through the FieldColumns and update available columns in
        % the view. AvailableColumnsI internal prop state is updated from
        % here as we need to set both internal prop (AvailableColumnsI) as
        % well as dependent prop (VisibleColumns)
        function set.AvailableColumns(obj, val)
            arguments
                obj matlab.ui.control.internal.WorkspaceBrowser
                val string
            end
            if ~isempty(obj.WorkspaceManager)
                if isequal(obj.AvailableColumns, val)
                    return;
                end
                if isempty(val)
                    error('Provide a non-empty value for AvailableColumns');
                end
                view = obj.WorkspaceManager.Documents(1).ViewModel;
                fieldColumns = view.FieldColumnList; 
                % Remove any fieldColumns that are not in the
                % AvailableColumns List
                fCols = [];
                for i=keys(fieldColumns)
                    fCol = fieldColumns(i{:});
                    if ~ismember(fCol.HeaderName, val)
                        view.removeFieldColumn(fCol.ColumnIndex);
                    else
                        % Add any AvailableColumns not in the FieldColumns list
                        fCols = [fCols fCol.HeaderName]; %#ok<AGROW> 
                    end
                end               
                columnsToAdd = val(~matches(val, fCols));
                for i=1:length(columnsToAdd)
                    % Adding by HeaderName will add the column back from
                    % the buffer.
                    fcol = view.fetchRemovedFieldColumn(columnsToAdd(i));
                    if ~isempty(fcol)
                        view.addFieldColumn(fcol);
                    end
                end
                % Update Available state on the HeaderAction
                if ~isempty(obj.WorkspaceManager.ActionManager)
                    actionDataService = obj.WorkspaceManager.ActionManager.ActionDataService;
                    headerAction = actionDataService.getAction('HeaderAction');
                    if ~isempty(headerAction)
                        headerAction.Action.UpdateVisibleState(obj.WorkspaceManager.Documents(1));
                    end
                end
                % Refresh VisibleColumns if they are unavailable.
                visibleColumnMatchIndices = matches(obj.VisibleColumns, val);
                obj.VisibleColumns = obj.VisibleColumns(visibleColumnMatchIndices);
                view.refreshColumnRange(1, view.VisibleFieldColumnList.Count, true);
                obj.AvailableColumnsI = val;
            end
        end
        
        
        %% Feature List
        
        function set.DataSortable(obj, val)
            if isequal(val, obj.DataSortable)
                return;
            end
            obj.DataSortable = val;
            obj.refresh;
        end
        
        function set.DataResizable(obj, val)
            if isequal(val, obj.DataResizable)
                return;
            end
            obj.DataResizable = val;
            obj.refresh;
        end
        
        function set.DataSelectable(obj, val)
            if isequal(val, obj.DataSelectable)
                return;
            end
            obj.DataSelectable = val;
            obj.refresh;
        end
        
        function set.DataSingleSelectable(obj, val)
            if isequal(val, obj.DataSingleSelectable)
                return;
            end
            if (val)
                obj.DataSelectable = matlab.lang.OnOffSwitchState.off;
            end
            obj.DataSingleSelectable = val;
            obj.refresh;
        end
        
        function set.DefaultContextMenus(obj, val)
            if isequal(val, obj.DefaultContextMenus)
                return;
            end
            obj.DefaultContextMenus = val;
            obj.refresh;
        end
        
        function set.DataDraggable(obj, val)
            if isequal(val, obj.DataDraggable)
                return;
            end
            obj.DataDraggable = val;
            obj.refresh;
        end
        
        function delete(obj)
            delete(obj.WorkspaceManager);
            if ~isempty(obj.WSBActionManager)
                delete(obj.WSBActionManager);
            end
            if ~isempty(obj.WSBContextMenuProvider)
                delete(obj.WSBContextMenuProvider);
            end
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
            
            pluginConfig = containers.Map(obj.PluginList, obj.PluginListMap);
            tempVal = values(pluginConfig, features(~userSelection));
            val = obj.addDependantPlugins(tempVal);
        end
        
        %% Update DynamicPlugins correctly for DataSingleSelectable.
        function val = get.DynamicPluginsI(obj)
            val= {};
            if obj.DataSingleSelectable
                k = find(strcmp(obj.PluginList, 'DataSingleSelectable'));
                val = cellstr(obj.PluginListMap(k));
            end
        end
    end
    
    methods(Access='protected')
        % Create Field Columns that are available by default but do not
        % exist on the view.
        function initFieldColumns(obj)
            commonCols = ismember(obj.DEFAULT_AVAILABLE_COLS, obj.DEFAULT_VISIBLE_COLS);
            colsToInit = obj.DEFAULT_AVAILABLE_COLS(~commonCols);
            view = obj.WorkspaceManager.Documents(1).ViewModel;
            for col=colsToInit
                % This check loops through all fieldCols, investigate if
                % this can be removed in the future.
                 if isempty(view.findFieldByHeaderName(col))
                    view.createFieldColumn(col);
                end
            end
        end

        function setupDocument(obj)
            channel = [obj.ChannelBase '_' char(obj.UUID)];
            obj.WorkspaceManager = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.createWorkspaceBrowser(obj.Workspace,channel, obj.Context);
            
            % Set App Context on Manager
            obj.WorkspaceManager.setProperty('AppContext', true);
            
            % Update Disabled Plugins
            disabledPlugins = obj.DisabledPluginsI;
            workspaceDoc = obj.WorkspaceManager.Documents(1);
            if ~isempty(disabledPlugins)
                workspaceDoc.setProperty('DisabledPlugins', disabledPlugins);
            end
            
            % Update dynamic plugins
            dynamicPlugins = obj.DynamicPluginsI;
            if ~isempty(dynamicPlugins)
                workspaceDoc.setProperty('DynamicPlugins', dynamicPlugins);
            end    
            
            % Initialize the action manager
            ActionManagerNamespace = [channel 'ActionManager'];
            obj.WSBActionManager = obj.WorkspaceManager.initActions(ActionManagerNamespace, internal.matlab.desktop_workspacebrowser.RemoteWorkspaceBrowser.startPath);
            obj.WSBActionManager.initActions('internal.matlab.variableeditor.Actions.struct', 'internal.matlab.datatoolsservices.actiondataservice.Action');
            
            if obj.DefaultContextMenus
                % Initialize the ContextMenu manager
                ContextMenuNamespace = [channel 'ContextMenuManager'];
                pathToXMLFile = obj.WSBContextMenuActionsFile;
                obj.WSBContextMenuProvider = obj.WorkspaceManager.initContextMenu('.WorkspaceBrowserDocument', pathToXMLFile, ContextMenuNamespace);
            end
            
            % Add Listeners for callbacks (TODO: Add listeners only when
            % users have a valid callbackfn attached)
            
            % Add SelectionChanged listener            
            obj.SelectionChangedListener = addlistener(workspaceDoc.ViewModel,'SelectionChanged',@(e,d)obj.handleSelectionChanged(d));
            
            % Add DataEdit listener
            obj.DataEditListener = addlistener(workspaceDoc.ViewModel, 'DataEditFromClient', @(es,ed) obj.handleDataEdit(ed));
            
            % Add DoubleClick listener
            obj.DoubleClickListener = addlistener(workspaceDoc, 'DoubleClickOnVariable', @(es,ed) obj.handleDoubleClick(ed));
            
            % Add OpenSelection listener
            obj.OpenSelectionListener = addlistener(workspaceDoc, 'OpenSelection', @(es,ed) obj.handleOpenSelection(ed));
            
            % Add Drop listener
            obj.DropListener = addlistener(workspaceDoc, 'DropEvent', @(es,ed) obj.handleDrop(ed));
        end

        function update(~)
        end
        
        function refresh(obj)
            % Refresh the view on the client with the new features
            if ~isempty(obj.WorkspaceManager) && ~isempty(obj.WorkspaceManager.Documents)
                featureConfig = {
                    obj.DataSortable, ...
                    obj.DataEditable, ...
                    obj.DataSingleSelectable, ...
                    obj.DataSelectable,...
                    obj.DataResizable, ...
                    obj.DefaultContextMenus, ...
                    obj.DataDraggable
                    };
                obj.FeatureConfig = cell2struct(featureConfig, cellstr(obj.PluginList), 2);
                obj.deleteListeners;
                delete(obj.WorkspaceManager);
                % Need to create a new manager, so change UUID
                obj.UUID = matlab.lang.internal.uuid;
                obj.markPropertiesDirty({'UUID'});
                obj.setupDocument();
                obj.initFieldColumns();
            end
        end
        
        function val = addDependantPlugins(obj, plugins)
            % Convienience method to disable plugins that cannot be toggeled by the user
            % directly but need to be disabled if all their consumers are disabled
            pNames = fieldnames(obj.DependantPluginsI);
            for i = 1:length(pNames)
                depPlugins = {obj.DependantPluginsI.(pNames{i})};
                if ismember(depPlugins, plugins)
                    plugins{end+1} = pNames{i}; %#ok<AGROW> 
                end
            end
            val = plugins;
        end
        
        function handleSelectionChanged(this, eventData)
            % This is the property callback that needs to be implemented by
            % consumers of the WorkspaceBrowser to listen to
            % selectionChange
            selectionObj = struct('SelectedRows', eventData.Selection{1}, 'SelectedVariables', this.SelectedVariables);
            if ~isempty(this.SelectionChangedCallbackFcn)
                try 
                    this.SelectionChangedCallbackFcn(selectionObj);
                catch
                end
            end
        end
        
        function handleDataEdit(this, eventData)
            % This is the property callback that needs to be implemented by
            % consumers of the WorkspaceBrowser in order to react to data
            % edit.
            if isa(this.Workspace, 'matlab.internal.datatoolsservices.AppWorkspace')
                wce = matlab.internal.datatoolsservices.AppWorkspaceChangeEvent;
                wce.Type = 'VariablesChanged';
                wce.Workspace = this.Workspace;
                this.Workspace.notify('VariablesChanged', wce);
                try
                    % Force Data Model to update (this forces an update of
                    % the data model state, by changing the data then
                    % forcing it back.
                    this.WorkspaceManager.Documents(1).ViewModel.DataModel.workspaceUpdated('');
                    this.WorkspaceManager.Documents(1).ViewModel.DataModel.workspaceUpdated();
                catch e
                    internal.matlab.datatoolsservices.logDebug('uicomponents::workspacebrowser::handleDataEdit', 'Error updating data model: ' + e.message);
                end
            end

            if ~isempty(this.DataEditCallbackFcn)
                try
                    this.DataEditCallbackFcn(eventData);
                catch
                end
            end
        end
        
        function handleDoubleClick(this, eventData)
            %Property callback to get notified on double click of a
            % variable
            if ~isempty(this.DoubleClickCallbackFcn)
                try
                    this.DoubleClickCallbackFcn(eventData);
                catch
                end
            end
        end
        
        function handleOpenSelection(this, eventData)
            %Property callback to get notified on RightClick-> Open
            %Selection or Ctrl+D usecase
            if ~isempty(this.OpenSelectionCallbackFcn)
                try
                    this.OpenSelectionCallbackFcn(eventData);
                catch
                end
            end
        end
        
        function handleDrop(this, eventData)
            % Property callback to get notified on drop of a
            % variable
            if ~isempty(this.DropCallbackFcn)
                try
                    % Fetch the right incoming workspace to return as a
                    % part of the eventData;
                    factory = internal.matlab.desktop_workspacebrowser.MF0ViewModelWorkspaceBrowserFactory.getInstance();
                    mgr = factory.getManagerByWorkspace(eventData.Workspace);
                    eventData.Workspace = mgr.Workspace;
                    this.DropCallbackFcn(eventData);
                catch
                end
            end
        end
        
        function deleteListeners(obj)
            if ~isempty(obj.SelectionChangedListener)
                delete(obj.SelectionChangedListener);
                obj.SelectionChangedListener = [];
            end

            if ~isempty(obj.DataEditListener)
                delete(obj.DataEditListener);
                obj.DataEditListener = [];
            end
           
            if ~isempty(obj.DoubleClickListener)
                delete(obj.DoubleClickListener);
                obj.DoubleClickListener = [];
            end
            
             if ~isempty(obj.OpenSelectionListener)
                delete(obj.OpenSelectionListener);
                obj.OpenSelectionListener = [];
             end
             
             if ~isempty(obj.DropListener)
                delete(obj.DropListener);
                obj.DropListener = [];
             end
        end
    end

end

