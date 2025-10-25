classdef (Hidden = true,Sealed = true) ComputeByGroupTask < matlab.task.LiveTask
    % Compute by Group - live task for grouping workflows
    % that assits users in groupsummary, grouptransform, and groupfilter
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    
    %   Copyright 2021-2024 The MathWorks, Inc.
        
    properties (Access = public, Transient, Hidden)
        UIFigure                    matlab.ui.Figure
        Accordion                   matlab.ui.container.internal.Accordion
        % Input section
        InputGrid                   matlab.ui.container.GridLayout
        % grouping widgets
        GroupWSDD                   matlab.ui.control.internal.model.WorkspaceDropDown
        GroupTableVarDD             matlab.ui.control.DropDown
        BinningSelector             matlab.internal.dataui.BinningPopoutIcon
        GroupSubtractButton         matlab.ui.control.Image
        GroupAddButton              matlab.ui.control.Image
        % datavar widgets
        DataVarLabel                matlab.ui.control.Label
        DataVarTypeDropDown         matlab.ui.control.DropDown
        DataVarGrid                 matlab.ui.container.GridLayout
        DataVarDropDowns            matlab.ui.control.DropDown
        DataVarSubtractButton       matlab.ui.control.Image
        DataVarAddButton            matlab.ui.control.Image
        DataVarWSDD                 matlab.ui.control.internal.model.WorkspaceDropDown
        % Grouping function section
        FunctionPanel               matlab.ui.container.internal.AccordionPanel
        FunctionGrid                matlab.ui.container.GridLayout
        FcnTypeButtonGroup          matlab.ui.container.ButtonGroup
        CustomFcnControl            matlab.internal.dataui.FunctionSelector
        % groupsummary methods
        StatsGrid                   matlab.ui.container.GridLayout
        StatsFcnDummyDropDown       matlab.ui.control.DropDown
        StatsDropdownIcon           matlab.ui.control.Image
        SelectAllCheckbox           matlab.ui.control.CheckBox
        StatsCheckboxes             matlab.ui.control.CheckBox
        % grouptransform methods
        TransformGrid               matlab.ui.container.GridLayout
        TransformMethodDD           matlab.ui.control.DropDown
        % groupfilter methods
        FilterGrid                  matlab.ui.container.GridLayout
        % Remaining nv pairs
        IncludedEdgeLabel           matlab.ui.control.Label
        IncludedEdgeDD              matlab.ui.control.DropDown
        ReplaceValuesCheckbox       matlab.ui.control.CheckBox
        IncludeEmptyCheckbox        matlab.ui.control.CheckBox
        IncludeMissingCheckbox      matlab.ui.control.CheckBox
        % For display
        DisplayPanel                matlab.ui.container.internal.AccordionPanel
        InputTableCheckbox          matlab.ui.control.CheckBox
        OutputTableCheckbox         matlab.ui.control.CheckBox
        % helpers
        IsTabularInput              logical
        InputHeight                 double
        NumDataVars                 double
        NumGroupVars                double
        StatsAllowedByDatatype      logical
        GroupHasMissing             logical
        GroupIsCat                  logical
        HandleValues                cell
    end
    
    properties (Constant, Transient, Hidden)
        AutoRunCutOff   = 1e6;  % height to trigger turning off AutoRun
        DropDownWidth   = 120;  % width of input dds
        TextRowHeight   = 22;   % Same as App Designer default
        IconWidth       = 16;   % +/- buttons
        LargeIconWidth  = 150;  % function button width
        LargeIconHeight = 60;   % function button height
        SelectVariable  = 'select variable'; % default value for wsdd
        OutputName      = 'newTable';
        % Serialization Versions - used for managing forward compatibility
        %     1: original ship        (R2021b)
        %     2: Use Base Class       (R2022a)
        %     3: Use FunctionSelector (R2022b)
        %     4: Add numunique method (R2023a)
        %     5: Use BinningPopoutIcon(R2024a)
        Version = 5;
    end
    
    properties
        % Required by base class
        State
        Summary
        % Required by app
        Workspace = "base"
    end

    events
        % Event for data cleaner so rich editors can get updated without
        % running generated script and updating app document
        StateChangedFromRichEditor
    end
    
    % Write over constructor so we can keep this API with dataCleaner app
    methods (Access = public)
        function app = ComputeByGroupTask(fig,workspace)
            arguments
                fig = uifigure;
                workspace = "base";
            end
            app@matlab.task.LiveTask("Parent",fig);
            app.UIFigure = fig;
            app.Workspace = workspace;
        end
    end

    % setup required by base class
    methods (Access = protected)
        function setup(app)
            app.LayoutManager.Parent.WindowButtonDownFcn = @app.collapseDropdown;
            createComponents(app);
            doUpdate(app);
        end
    end
    
    % internal methods for construction/layout
    methods (Access = private)
        % implementation in createComponents.m
        createComponents(app)
        
        % methods used to add rows in initial construction, but also on
        % callback from '+' buttons
        function addGroupRow(app,n)
            app.GroupWSDD(n) = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.InputGrid,...
                'ValueChangedFcn',@app.doUpdate,'UserData',n,...
                'Tag','GroupingVarChange','Workspace',app.Workspace,...
                'Tooltip',getMsgText(app,'GroupWSDDTooltip'),...
                'ShowNonExistentVariable',true);
            if n > 1
                app.GroupWSDD(n).FilterVariablesFcn = @app.filterArrayGroups;
            end
            app.GroupWSDD(n).Layout.Column = 2;
            app.GroupWSDD(n).Layout.Row = n;            
            app.GroupTableVarDD(n) = uidropdown(app.InputGrid,...
                'ValueChangedFcn',@app.doUpdate,...
                'Tag','GroupingVarChange','UserData',n);
            app.GroupTableVarDD(n).Layout.Column = 3;
            app.GroupTableVarDD(n).Layout.Row = n;

            app.BinningSelector(n) = matlab.internal.dataui.BinningPopoutIcon( ...
                Parent=app.InputGrid, ValueChangedFcn=@app.doUpdate, Workspace=app.Workspace);
            app.BinningSelector(n).Layout.Column = 4;
            app.BinningSelector(n).Layout.Row = n;

            app.GroupSubtractButton(n) = uiimage(app.InputGrid,'ScaleMethod','none',...
                'ImageClickedFcn',@app.subtractRow,'UserData',n,'Tag','GroupButton',...
                'Tooltip',getMsgText(app,'SubtractGroupTooltip'));
            matlab.ui.control.internal.specifyIconID(app.GroupSubtractButton(n),...
                'minusUI',app.IconWidth,app.IconWidth);
            app.GroupSubtractButton(n).Layout.Column = 5;
            app.GroupSubtractButton(n).Layout.Row = n;
            app.GroupAddButton(n) = uiimage(app.InputGrid,'ScaleMethod','none',...
                'ImageClickedFcn',@app.addRow,'UserData',n,'Tag','GroupButton',...
                'Tooltip',getMsgText(app,'AddGroupTooltip'));
            matlab.ui.control.internal.specifyIconID(app.GroupAddButton(n),...
                'plusUI',app.IconWidth,app.IconWidth);
            app.GroupAddButton(n).Layout.Column = 6;
            app.GroupAddButton(n).Layout.Row = n;
            app.NumGroupVars = n;
        end
        
        function addDataVarRow(app,n)
            app.DataVarDropDowns(n) = uidropdown(app.DataVarGrid,...
                'ValueChangedFcn',@app.doUpdate,'Tag','DataVarChange');
            app.DataVarDropDowns(n).Layout.Column = 1;
            app.DataVarDropDowns(n).Layout.Row = n;
            
            app.DataVarSubtractButton(n) = uiimage(app.DataVarGrid,'ScaleMethod','none',...
                'ImageClickedFcn',@app.subtractRow,'UserData',n, 'Tag','DataVarChange',...
                'Tooltip',getMsgText(app,'SubtractDataVarTooltip',false));
            matlab.ui.control.internal.specifyIconID(app.DataVarSubtractButton(n),...
                'minusUI',app.IconWidth,app.IconWidth);
            app.DataVarSubtractButton(n).Layout.Column = 2;
            app.DataVarSubtractButton(n).Layout.Row = n;
            
            app.DataVarAddButton(n) = uiimage(app.DataVarGrid,'ScaleMethod','none',...
                'ImageClickedFcn',@app.addRow,'UserData',n,'Tag','DataVarChange',...
                'Tooltip',getMsgText(app,'AddDataVarTooltip',false));
            matlab.ui.control.internal.specifyIconID(app.DataVarAddButton(n),...
                'plusUI',app.IconWidth,app.IconWidth);
            app.DataVarAddButton(n).Layout.Column = 3;
            app.DataVarAddButton(n).Layout.Row = n;
            
            app.NumDataVars = n;
        end
    end
    
    % filtering workspace dropdowns
    methods (Access = private)
        function issupported = filterInput(~,t)
            % grouping vars from workspace or tabular input from workspace
            issupported = ~isempty(t) && ismatrix(t) && ...
                (istabular(t) || matlab.internal.dataui.isValidGroupingVar(t,false));
            if issupported && istable(t)
                % make sure there is at least one valid grouping variable
                % timetables can always use row times
                for k = 1:width(t)
                    hasValidVar = matlab.internal.dataui.isValidGroupingVar(t.(k));
                    if hasValidVar
                        break
                    end
                end
                issupported = hasValidVar;
            end
        end

        function issupported = filterDataVar(app,d)
            issupported = false;
            didClear = checkForClearedWorkspaceVariables(app);
            if didClear
                app.doUpdate;
            elseif hasData(app)
                issupported = ~isempty(d) && size(d,1) == app.InputHeight && ismatrix(d) && ...
                    (isnumeric(d) || isduration(d) || isdatetime(d) || iscalendarduration(d) ||...
                    isstring(d) || iscell(d) || ischar(d) || iscategorical(d) || islogical(d));
            end
        end
        
        function issupported = filterArrayGroups(app,g)
            % grouping vars from workspace (but not first row!)
            issupported = false;
            didClear = checkForClearedWorkspaceVariables(app);
            if didClear
                app.doUpdate;                
            elseif hasData(app)
                % this is more restrictive than the underlying function, but
                % makes more sense for the live task
                issupported = ~isempty(g) && size(g,1) == app.InputHeight && ismatrix(g) && ...
                    matlab.internal.dataui.isValidGroupingVar(g,false);
            end
        end
    end
    
    % callbacks
    methods (Access = private)
        function collapseDropdown(app,src,~)
            % WindowButtonDownFcn callback for uifigure to close
            % multiselect dd if its open
            obj = src.CurrentObject;
            % exception is if obj is the multiselect dd itself
            if ~app.StatsDropdownIcon.UserData.Collapsed && ...
                    ~ismember(obj,[app.StatsDropdownIcon app.SelectAllCheckbox app.StatsCheckboxes])                    
                toggleCollapsed(app,app.StatsDropdownIcon);
            end
        end
        
        function subtractRow(app,src,~,row)
            didClear = checkForClearedWorkspaceVariables(app);
            if didClear
                % input has been cleared, no more work to be done here
                doUpdate(app);
                return
            end
            if nargin < 4
                row = src.UserData;
            end
            tag = src.Tag;
            inputval = '';
            if isequal(tag,'GroupButton')
                type = 'GroupVars';
                widgets = ["GroupWSDD" "GroupTableVarDD" "BinningSelector"];
                buttons = ["GroupSubtractButton" "GroupAddButton"];
                if app.IsTabularInput
                    inputval = app.GroupWSDD(1).Value;
                end
                app.GroupHasMissing(row) = [];
                app.GroupIsCat(row) = [];
            else
                type = 'DataVars';
                widgets = "DataVarDropDowns";
                buttons = ["DataVarAddButton" "DataVarSubtractButton"];
            end
            if app.(['Num' type]) == 1
                % Need at least one row - don't delete it
                % Not testable - this is in case user hits '-' button too
                % fast before doUpdate can hide the last one
                return
            end
            % move values below current row up a row
            
            rowsToMove = (row + 1) : app.(['Num' type]);
            shiftWidgetValues(app,rowsToMove,rowsToMove-1,widgets);
            if ~isempty(inputval)
                % reset input table in case it got cleared
                if ~ismember(inputval,app.GroupWSDD(1).ItemsData)
                    app.GroupWSDD(1).ItemsData = [app.GroupWSDD(1).ItemsData {inputval}];
                    app.GroupWSDD(1).Items = [app.GroupWSDD(1).Items {inputval}];
                end
                app.GroupWSDD(1).Value = inputval;
            end
            % delete widgets on last row
            for k = [widgets buttons]
                delete(app.(k)(end));
                app.(k)(end) = [];
            end
            app.(['Num' type]) = app.(['Num' type]) - 1;
            if nargin < 4
                % else comes from initializing, resetting, or setState
                % in case widget got deleted, send in a struct instead
                doUpdate(app,struct('Tag',tag));
            end
        end
        
        function addRow(app,src,~)
            didClear = checkForClearedWorkspaceVariables(app);
            if didClear
                % input has been cleared, no more work to be done here
                doUpdate(app);
                return
            end
            row = src.UserData + 1;
            isGroup = isequal(src.Tag,'GroupButton');
            % add a new row to the bottom of the grid
            if isGroup
                n = app.NumGroupVars;
                addGroupRow(app,n+1)
                widgets = ["GroupWSDD" "GroupTableVarDD" "BinningSelector"];
            else
                n = app.NumDataVars;
                if n+1 > width(app.GroupWSDD(1).WorkspaceValue)
                    % Case hit add button too quickly before doUpdate can hide it
                    % Not testable
                    return
                end
                addDataVarRow(app,n+1);
                widgets = "DataVarDropDowns";
            end
            
            % Shift values down so the new widget appears to be directly
            % following the row of the add button clicked.
            % Go in reverse so as to not copy the first row multiple times
            rowsToMove = n:-1:row;
            shiftWidgetValues(app,rowsToMove,rowsToMove+1,widgets);
            if isGroup
                % also shift GroupHasMissing & GroupIsCat properties
                app.GroupHasMissing(rowsToMove+1) = app.GroupHasMissing(rowsToMove);
                app.GroupIsCat(rowsToMove+1) = app.GroupIsCat(rowsToMove);
                % set default items/values of new row
                app.GroupTableVarDD(row).Items = app.GroupTableVarDD(1).Items;
                app.GroupTableVarDD(row).ItemsData = app.GroupTableVarDD(1).ItemsData;
                app.GroupWSDD(row).Value = app.SelectVariable;
                updateGroupingRowOptions(app,row);
                setBinningValuesToDefault(app,row);
            elseif row ~= app.NumDataVars
                % make it so the value is the table var not previously
                % selected by other dropdowns
                % will repopulate items in doUpdate
                app.DataVarDropDowns(row).Items = setdiff(app.DataVarDropDowns(end).Items,...
                    app.DataVarDropDowns(end).Value,'stable');
                app.DataVarDropDowns(row).ItemsData = app.DataVarDropDowns(row).Items;
                app.DataVarDropDowns(row).Value = app.DataVarDropDowns(row).Items{1};
            end
            doUpdate(app,src);
        end
        
        function toggleCollapsed(app,src,~)
            % callback for the multiselect dd button/icon
            % also called by the uifigure WindowButtonDownFcn
            src.UserData.Collapsed = ~src.UserData.Collapsed;
            if src.UserData.Collapsed
                app.StatsGrid.RowHeight{2} = 0;
                % for testing, also toggle visibility
                app.SelectAllCheckbox.Parent.Visible = 'off';
            else
                app.StatsGrid.RowHeight{2} = 'fit';
                app.SelectAllCheckbox.Parent.Visible = 'on';
            end
        end
        
        function selectAll(app,src,~)
            % callback for the selectAll checkbox in the multiselect dd
            % don't toggle counts or custom fcn
            [app.StatsCheckboxes(1:end-1).Value] = deal(src.Value);
            doUpdate(app,src);
        end
        
        % implementation in doUpdate.m
        doUpdate(app,src,evt)
        
        % image callback helper
        function shiftWidgetValues(app,fromRows,toRows,widgets)
            for k = 1:numel(fromRows)
                for w = widgets
                    obj = app.(w);
                    if isa(obj,'matlab.internal.dataui.BinningPopoutIcon')
                        % setting State takes care of all Items, Values,
                        % and other props
                        obj(toRows(k)).State = obj(fromRows(k)).State;
                    else
                        if isprop(obj,'Items')
                            obj(toRows(k)).Items = obj(fromRows(k)).Items;
                            obj(toRows(k)).ItemsData = obj(fromRows(k)).ItemsData;
                        end
                        obj(toRows(k)).Value = obj(fromRows(k)).Value;
                    end
                end
            end
        end
    end
    
    % Helper methods
    methods (Access = private)
        % general helpers
        function hasInput = hasData(app)
            hasInput = ~isequal(app.GroupWSDD(1).Value,app.SelectVariable);
        end
        
        function hasInput = hasGroups(app)
            hasInput = hasData(app) && ...
                (app.IsTabularInput || ~any(strcmp({app.GroupWSDD.Value},app.SelectVariable))) ;
        end
        
        function hasInput = hasGroupsAndData(app)
            hasInput = hasGroups(app) && ...
                (app.IsTabularInput || ~strcmp(app.DataVarWSDD.Value,app.SelectVariable));            
        end
        
        function hasInput = hasDataGroupsAndFcn(app)
            hasInput = hasGroupsAndData(app);
            if hasInput
                waitingOnLocal = isempty(app.CustomFcnControl.Value);
                switch app.FcnTypeButtonGroup.SelectedObject.Tag
                    case 'grouptransform'
                        hasInput = ~(isequal(app.TransformMethodDD.Value,'CustomFunction') && waitingOnLocal);
                    case 'groupfilter'
                        hasInput = ~waitingOnLocal;
                    % case groupsummary, always have at least counts, so we
                    % have something to generate if we have data and groups
                end
            end
            % note: edit fields are not allowed to be empty, so in that
            % case, we always have something to generate
        end
        
        function didClear = checkForClearedWorkspaceVariables(app)
            % Check each wsdd to see if it has a variable that has been cleared.
            if ~hasData(app)
                didClear = false;
                return
            end
            didClear = resetWSDDIfCleared(app,app.GroupWSDD(1));
            if didClear
                % reset the app
                setWidgetsToDefault(app);
                % no need to check other wsdds
                return
            end
            for k = 2:app.NumGroupVars
                resetWSDDIfCleared(app,app.GroupWSDD(k));
            end
        end
        
        function didClear = resetWSDDIfCleared(app,widget)
            didClear = false;
            if ~isequal(widget.Value,app.SelectVariable) && isempty(widget.WorkspaceValue)
                widget.Value = app.SelectVariable;
                didClear = true;
            end
        end
        
        function s = getMsgText(~,msgId,usetableui,varargin)
            % gets the appropriate messages from the catalog as a string array
            % input 1 is char or cellstr
            if nargin < 3
                usetableui = true;
            end
            if usetableui
                id = 'MATLAB:tableui:grouping';
            else
                id = 'MATLAB:dataui:';
            end
            fcn = @(str) string(message([id str],varargin{:}));
            if iscell(msgId)
                s = cellfun(fcn,msgId);
            else
                s = fcn(msgId);
            end
        end
        
        function tf = isAppWorkflow(app)
            % determine if we are in Data Cleaner App
            tf = ~isequal(app.Workspace,"base");
        end
        
        % setting defaults and populating items
        function doOpen = setWidgetsToDefault(app)
            if ~hasData(app)
                % show data var widgets by default
                app.IsTabularInput = false;
                app.InputHeight = 1;
            end            
            % grouping rows
            % remove any extra grouping rows
            if app.NumGroupVars > 1
                % go in reverse so we don't move data unnecessarily
                for row = app.NumGroupVars:-1:2
                    subtractRow(app,struct('Tag','GroupButton'),[],row);
                end
            end
            populateGroupingDropdowns(app);
            doOpen = updateGroupingRowOptions(app,1);
            setBinningValuesToDefault(app,1);            
            % data rows
            app.DataVarWSDD.Value = app.SelectVariable;
            app.DataVarTypeDropDown.Items = [getMsgText(app,{'AllNonGrouping' 'AllVariables'})...
                getMsgText(app,{'AllNumeric' 'ManualSelection'},false)];
            app.DataVarTypeDropDown.ItemsData = {'default' 'all' 'numeric' 'manual'};
            allVarsNumeric = false;
            if hasData(app) && app.IsTabularInput
                numericVars = varfun(@isnumeric,...
                    app.GroupWSDD(1).WorkspaceValue,'OutputFormat','uniform');
                allVarsNumeric = all(numericVars);
            end
            if allVarsNumeric
                % 'numeric' is not distinct from 'all'
                app.DataVarTypeDropDown.Items(3) = [];
                app.DataVarTypeDropDown.ItemsData(3) = [];
            end
            app.DataVarTypeDropDown.Value = 'default';
            % remove any extra datavar rows
            if app.NumDataVars > 1
                % go in reverse so we don't move data unnecessarily
                for row = app.NumDataVars:-1:2
                    subtractRow(app,struct('Tag','DataVarChange'),[],row);
                end
            end
            repopulateDataVarDropDowns(app)
            if ~isempty(app.DataVarDropDowns(1).ItemsData)
                % default to the first numeric variable, if there is one
                ind = find(numericVars,1);
                if isempty(ind)
                    app.DataVarDropDowns.Value = app.DataVarDropDowns.ItemsData{1};
                else
                    app.DataVarDropDowns.Value = app.DataVarDropDowns.ItemsData{ind};
                end
            end
            % Computational choices
            % default to groupsummary
            app.FcnTypeButtonGroup.SelectedObject = app.FcnTypeButtonGroup.Buttons(1);
            setStatsAllowedByDatatype(app);
            % default to group counts only
            app.SelectAllCheckbox.Value = false;
            app.StatsCheckboxes(1).Value = true;
            [app.StatsCheckboxes(2:end).Value] = deal(false);
            app.TransformMethodDD.Value = 'CustomFunction';
            if isAppWorkflow(app)
                % local workflow not supported
                app.CustomFcnControl.FcnType = 'handle';
            else
                app.CustomFcnControl.FcnType = 'local';
            end
            app.CustomFcnControl.LocalValue = app.SelectVariable;
            app.HandleValues = {'@(x) nnz(isoutlier(x))','@(x) x./mean(x)','@(x) mean(x) >= 10'};
            app.CustomFcnControl.HandleValue = app.HandleValues{1};
            
            % N/V pair default values
            app.IncludedEdgeDD.Value = 'left';
            app.ReplaceValuesCheckbox.Value = true;
            app.IncludeMissingCheckbox.Value = true;
            app.IncludeEmptyCheckbox.Value = false;
            
            % default display options
            app.InputTableCheckbox.Value = false;
            app.OutputTableCheckbox.Value = ~isAppWorkflow(app);
        end
                
        function repopulateDataVarDropDowns(app,vars)
            if nargin < 2
                if hasData(app) && app.IsTabularInput
                    vars = app.GroupWSDD(1).WorkspaceValue.Properties.VariableNames;
                else
                    vars = {};
                end
            end
            app.DataVarDropDowns(1).Items = vars;
            app.DataVarDropDowns(1).ItemsData = vars;
            for k = 2:app.NumDataVars
                vars = setdiff(vars,app.DataVarDropDowns(k-1).Value,'stable');
                curVal = app.DataVarDropDowns(k).Value;
                app.DataVarDropDowns(k).Items = vars;
                app.DataVarDropDowns(k).ItemsData = vars;
                if ismember(curVal,vars)
                    % Setting both Items and ItemsData can change Value
                    app.DataVarDropDowns(k).Value = curVal;
                end
            end
        end
        
        function populateGroupingDropdowns(app)
            if hasData(app) && app.IsTabularInput
                T = app.GroupWSDD(1).WorkspaceValue;
                validVars = varfun(@matlab.internal.dataui.isValidGroupingVar,T,'OutputFormat','uniform');
                T = T(:,validVars);                
                items = T.Properties.VariableNames;
                if istimetable(T)
                    items = [T.Properties.DimensionNames(1) items];
                end
                app.GroupTableVarDD.Items = items;
                app.GroupTableVarDD.ItemsData = items;
                index = matlab.internal.dataui.getDefaultGroupingVarIndex(T);
                app.GroupTableVarDD.Value = app.GroupTableVarDD.ItemsData(index);
            else
                % non-tabular uses WSDD
                [app.GroupTableVarDD.Items] = deal({});
                [app.GroupTableVarDD.ItemsData] = deal({});
            end
        end
        
        function doOpen = updateGroupingRowOptions(app,rows)
            if nargin < 2
                % Coming from data cleaner app
                rows = 1:app.NumGroupVars;
            end

            varname = '';
            var = [];
            doOpen = false;
            for k = rows
                selector = app.BinningSelector(k);                
                if hasGroups(app)
                    if app.IsTabularInput
                        varname = app.GroupTableVarDD(k).Value;
                        var = app.GroupWSDD(1).WorkspaceValue.(varname);
                    else
                        varname = app.GroupWSDD(k).Value;
                        var = app.GroupWSDD(k).WorkspaceValue(:,1);
                    end
                end
                if nargin == 2 || ~isequal(selector.VariableName,varname)
                    % Setting the Variable sets all Items and Values to default
                    % based on the variable being set.
                    % If coming from data cleaner, only need to update if
                    % the Variable is newly selected.
                    selector.VariableName = varname;
                    selector.Variable = var;
                    if nargin == 2 && ~isequal(selector.Value,'"none"')
                        % Auto-open selector if binning by default
                        % But wait until other controls are positioned
                        % correctly
                        doOpen = true;
                    end
                end 
                app.GroupHasMissing(k) = selector.HasMissing;
                app.GroupIsCat(k) = iscategorical(var) || islogical(var) || isenum(var);
            end
        end
        
        function setBinningValuesToDefault(app,row)
            app.BinningSelector(row).resetDefaults();
        end
        
        function setStatsAllowedByDatatype(app)
            % reset items in grouptransform method list
            transformMethods = {'zscore' 'norm' 'meancenter' 'rescale' ...
                'meanfill' 'linearfill' 'CustomFunction'};
            app.TransformMethodDD.Items = getMsgText(app,transformMethods);
            app.TransformMethodDD.ItemsData = transformMethods;
            if ~hasData(app)
                app.StatsAllowedByDatatype = true(1,numel(app.StatsCheckboxes));
            else
                % get input data
                if app.IsTabularInput
                    input = app.GroupWSDD(1).WorkspaceValue;
                    if isequal(app.DataVarTypeDropDown.Value,'default')
                        % remove the grouping vars (except for rowtimes)
                        input(:,setdiff({app.GroupTableVarDD.Value},input.Properties.DimensionNames(1))) = [];
                    elseif isequal(app.DataVarTypeDropDown.Value,'numeric')
                        % only use numeric vars
                        input = input(:,vartype('numeric'));
                    elseif isequal(app.DataVarTypeDropDown.Value,'manual')
                        % only the selected vars
                        input = input(:,{app.DataVarDropDowns.Value});
                    end
                else
                    input = app.DataVarWSDD.WorkspaceValue;
                end
                
                % update stats checkboxes based on datatype:
                filterdictionary = matlab.internal.dataui.groupsummaryMethodName2FilterFcn();
                for k = 1:numel(app.StatsCheckboxes)-1
                    app.StatsAllowedByDatatype(k+1) = checkInputDataType(app,input,filterdictionary(app.StatsCheckboxes(k+1).Tag));
                end
                
                % update grouptransform methods by datatype
                % zscore, norm, meancenter: float only
                % rescale: real numeric and logical
                % meanfill: float, real ints, duration, datetime, logical
                % linearfill: numeric, duration, datetime, logical
                val = app.TransformMethodDD.Value;
                if ~checkInputDataType(app,input,@(x) isnumeric(x) || islogical(x) || isduration(x) || isdatetime(x))
                    % only leave "Custom"
                    app.TransformMethodDD.Items(1:6) = [];
                    app.TransformMethodDD.ItemsData(1:6) = [];
                else
                    if checkInputDataType(app,input,@(x) isinteger(x) && ~isreal(x),'any')
                        % remove meanfill
                        app.TransformMethodDD.Items(5) = [];
                        app.TransformMethodDD.ItemsData(5) = [];
                    end                    
                    if checkInputDataType(app,input,@(x) isdatetime(x) || isduration(x) || ~isreal(x),'any')
                        % remove rescale
                        app.TransformMethodDD.Items(4) = [];
                        app.TransformMethodDD.ItemsData(4) = [];
                    end
                    if ~checkInputDataType(app,input,@isfloat)
                        % remove rescale
                        app.TransformMethodDD.Items(1:3) = [];
                        app.TransformMethodDD.ItemsData(1:3) = [];
                    end                    
                end
                if ismember(val,app.TransformMethodDD.ItemsData)
                    % reset user-selected value if still valid
                    app.TransformMethodDD.Value = val;
                end
            end
        end

        function tf = checkInputDataType(app,input,fcnHandle,anyAll)
            if nargin < 4
                anyAll = 'all';
            end
            if app.IsTabularInput
                tf = varfun(fcnHandle,input,"OutputFormat","uniform");
                if strcmp(anyAll,'all')
                    tf = all(tf);
                else
                    tf = any(tf);
                end
            else
                tf = fcnHandle(input);
            end
        end
        
        % implementation in getGroupExampleFcnText.m
        [txt,fcnName] = getGroupExampleFcnText(app,tag)
    end
    
    % methods required for embedding in a Live Script
    methods (Access = public)
        function reset(app)
            setWidgetsToDefault(app);
            doUpdate(app);
        end

        % implementation in generateScript.m
        [code,outputs] = generateScript(app,isForExport,overwriteInput)
        
        function code = generateVisualizationScript(app)
            code = '';
            needVisualization = app.InputTableCheckbox.Value && app.IsTabularInput;
            if ~hasDataGroupsAndFcn(app) || ~needVisualization
                return
            end

            % if matrix input, we have already displayed inputTable when it
            % was created.
            % For table input, only need to display the table(s)
            code = ['% ' char(getMsgText(app,'Visualizeresults',false)) newline];

            % display the tables
            code = [code '`' app.GroupWSDD(1).Value '`'];
            if app.OutputTableCheckbox.Value
                code = [code newline app.OutputName];
            end
        end

        function [code,outputs] = generateCode(app)
            [code,outputs] = generateScript(app);
            vcode = generateVisualizationScript(app);
            if ~isempty(vcode)
                code = [code newline newline vcode];
            end
        end

        function initialize(app,NVpairs)
            % Executed by container after creation of task
            % This method programmatically sets widget values and runs the
            % appropriate callbacks
            arguments
                app
                NVpairs.Inputs  string = "";
                NVpairs.TableVariableNames string = "";
                NVpairs.Code string = "";
            end
            % Inputs - The name of the workspace input. If "Inputs" is a
            %          string array, only the first name is used.
            % TableVariableNames - not used, for now
            
            if ~isempty(NVpairs.Inputs)
                app.GroupWSDD(1).populateVariables();
                if ismember(NVpairs.Inputs(1),app.GroupWSDD(1).ItemsData)
                    app.GroupWSDD(1).Value = NVpairs.Inputs(1);
                    doUpdate(app,app.GroupWSDD(1));
                end
            end
        end

        function setTaskState(app,state,widget)
            if nargin < 3
                widget = '';
            end
            
            if ~isfield(state,'minCompatibleVersion') || state.minCompatibleVersion > app.Version
                % comes from a future incompatible version, don't update
                app.doUpdate;
            else
                % update state fields based on changes in app
                addNumUnique = true;
                if isequal(widget,'CustomGroupingControl')
                    % control only updates fields in GroupingStruct, need to
                    % update appropriate state fields
                    s = state.GroupingStruct;
                    state.GroupTableVarDDValue = s.GroupTableVarDDValue;
                    if isempty(state.GroupTableVarDDValue)
                        % Do not allow user do deselect all vars in the app
                        % Live task requires at least one selected
                        return
                    end
                    state.BinningDropdownValue = s.BinningDropdownValue;
                    state.BinningDropdownItems = s.BinningDropdownItems;
                    state.BinningDropdownItemsData = s.BinningDropdownItemsData;
                    state.NumBinsSpinnerValue = s.NumBinsSpinnerValue;
                    state.TimeBinDDValue = s.TimeBinDDValue;
                    state.TimeBinDDItems = s.TimeBinDDItems;
                    state.TimeBinDDItemsData = s.TimeBinDDItemsData;
                    state.BinWidthSpinnerValue = s.BinWidthSpinnerValue;
                    state.BinWidthUnitsDDValue = s.BinWidthUnitsDDValue;
                    state.BinWidthUnitsDDItems = s.BinWidthUnitsDDItems;
                    state.BinWidthUnitsDDItemsData = s.BinWidthUnitsDDItemsData;
                    state.NumGroupVars = numel(s.GroupTableVarDDValue);
                    state.GroupTableVarDDItemsData = repmat(state.GroupTableVarDDItemsData(1),1,state.NumGroupVars);
                    state.GroupTableVarDDItems = state.GroupTableVarDDItemsData;
                    % additional things we need to set selectorState
                    state.BinEdgesWSDDValue = repmat({app.SelectVariable},1,numel(s.BinningDropdownValue));
                    % Make it so the binning is defined by these
                    % state fields and not the BinningSelectorStates field
                    % Also, app should not attempt to alter GroupWSDDValue
                    state = rmfield(state,{'BinningSelectorStates' 'GroupWSDDValue'});
                elseif isequal(widget,'GroupWSDD')
                    state.GroupWSDDValue{1} = state.InputTableValue;
                elseif isequal(widget,'DataVarDropDowns')
                    state.NumDataVars = numel(state.DataVarDropDownsValue);
                elseif isequal(widget,'StatsCheckboxes')
                    state.StatsCheckboxesValue = ismember({app.StatsCheckboxes.Text},state.StatsCheckboxesValueApp);
                    addNumUnique = false;
                end
                setGrpVariableName = false;
                if ~isfield(state,'BinningSelectorStates') && isfield(state,'BinningDropdownValue')
                    % Comes from previous version, need to construct states
                    % to set on the selectors
                    binEdgesEditFieldValue = repmat({''},numel(state.BinningDropdownValue),1);
                    binEdgesUnitsDDValue = repmat({'years'},numel(state.BinningDropdownValue),1);
                    state.BinningSelectorStates = struct(...
                        "BinningDropdownItemsData",state.BinningDropdownItemsData(:),...
                        "BinningDropdownValue",state.BinningDropdownValue(:),...
                        "NumBinsSpinnerValue",num2cell(state.NumBinsSpinnerValue(:)),...
                        "BinEdgesWSDDValue",state.BinEdgesWSDDValue(:),...
                        "BinEdgesEditFieldValue",binEdgesEditFieldValue,...
                        "BinEdgesUnitsDDValue",binEdgesUnitsDDValue,...
                        "TimeBinDDItemsData",state.TimeBinDDItemsData(:),...
                        "TimeBinDDValue",state.TimeBinDDValue(:),...
                        "BinWidthSpinnerValue",num2cell(state.BinWidthSpinnerValue(:)),...
                        "BinWidthUnitsDDItemsData",state.BinWidthUnitsDDItemsData(:),...
                        "BinWidthUnitsDDValue",state.BinWidthUnitsDDValue(:),...
                        "MinCompatibleVersion",1, ...
                        "HasMissing",num2cell(state.GroupHasMissing(:)));
                    % Unable to set fields: NumUnique, DefaultTimeBin, VariableClass
                    % Will set VariableName momentarily
                    setGrpVariableName = true;
                end
                % Grouping Rows
                if isfield(state,'NumGroupVars')
                    % add or subtract group rows as necessary
                    % can only go into at most one of these loops
                    for k = app.NumGroupVars+1 : state.NumGroupVars
                        addGroupRow(app,k);
                    end
                    for k = app.NumGroupVars:-1:state.NumGroupVars+1
                        % go in reverse order so we are not shifting values
                        % and items unnecessarily
                        subtractRow(app,struct('Tag','GroupButton'),[],k);
                    end
                    
                    for row = 1:state.NumGroupVars
                        % set grouping wsdd values
                        if isfield(state,"GroupWSDDValue")
                            app.GroupWSDD(row).Value = state.GroupWSDDValue{row};
                        end
                        % set grouping table var dd values
                        if isfield(state,"GroupTableVarDDItemsData")
                            itemsData = state.GroupTableVarDDItemsData{row};
                            % because of jsonencode/decode, empties
                            % don't flow through nicely
                            if ~isempty(itemsData)
                                app.GroupTableVarDD(row).ItemsData = itemsData;
                                app.GroupTableVarDD(row).Items = state.GroupTableVarDDItems{row};
                                app.GroupTableVarDD(row).Value = state.GroupTableVarDDValue{row};
                            else
                                app.GroupTableVarDD(row).ItemsData = {};
                                app.GroupTableVarDD(row).Items = {};
                            end
                        end
                        % set binning options
                        if ~isempty(state.BinningSelectorStates(row).BinningDropdownItemsData)
                            app.BinningSelector(row).State = state.BinningSelectorStates(row);
                            if setGrpVariableName
                                if state.IsTabularInput
                                    varname = app.GroupTableVarDD(row).Value;
                                else
                                    varname = app.GroupWSDD(row).Value;
                                end
                                app.BinningSelector(row).VariableName = varname;
                            end                            
                        end % else coming from data cleaner app, where a 
                        % new row of controls has yet to be initialized. In
                        % this case we will be updating the whole row with
                        % default values in doUpdate.
                    end
                end
                % Data Var Rows
                if isfield(state,"DataVarWSDDValue")
                    app.DataVarWSDD.Value = state.DataVarWSDDValue;
                end
                if isfield(state,'NumDataVars')
                    % add or subtract input rows as necessary
                    % can only go into at most one of these loops
                    for k = app.NumDataVars + 1: state.NumDataVars
                        addDataVarRow(app,k);
                    end
                    for k = app.NumDataVars : -1: state.NumDataVars+1
                        subtractRow(app,struct('Tag','DataVarChange'),[],k)
                    end
                    app.NumDataVars = state.NumDataVars;
                end
                if isfield(state,'DataVarTypeDropDownItems')
                    app.DataVarTypeDropDown.Items = state.DataVarTypeDropDownItems;
                    app.DataVarTypeDropDown.ItemsData = state.DataVarTypeDropDownItemsData;
                end
                if isfield(state,'TableVarNames')
                    % set all the dataVarDDs to have all the variables
                    % then set the values, then trim the items
                    vars = state.TableVarNames;
                    if isempty(vars)
                        % jsonencoding by live editor changes empty cells
                        % to empty doubles, change it back
                        vars = {};
                    end
                    [app.DataVarDropDowns.Items] = deal(vars);
                    [app.DataVarDropDowns.ItemsData] = deal(vars);
                    if ~isempty(vars)
                        [app.DataVarDropDowns.Value] = state.DataVarDropDownsValue{:};
                    end
                    repopulateDataVarDropDowns(app,vars);
                end
                
                % Handle numunique: added R2023a
                if isfield(state,"StatsCheckboxesValue") && addNumUnique
                    % Value is saved separately except when coming from app
                    if isfield(state,"NumUniqueCheckboxValue")
                        numuniqueval = state.NumUniqueCheckboxValue;
                    else
                        % from older release
                        numuniqueval = false;
                    end
                    state.StatsCheckboxesValue(end:(end+1)) = [numuniqueval state.StatsCheckboxesValue(end)];
                end
                if isfield(state,"StatsAllowedByDatatype")
                    if isfield(state,"NumUniqueAllowed")
                        numuniqueallowed = state.NumUniqueAllowed;
                    else
                        numuniqueallowed = true;
                    end
                    state.StatsAllowedByDatatype(end:(end+1)) = [numuniqueallowed state.StatsAllowedByDatatype(end)];
                end

                % set values from arrays
                if isfield(state,"StatsCheckboxesValue")
                    vals = num2cell(state.StatsCheckboxesValue);
                    [app.StatsCheckboxes.Value] = vals{:};
                end

                % set items/itemsData
                if isfield(state,'TransformMethodDDItems')
                    app.TransformMethodDD.Items = state.TransformMethodDDItems;
                    app.TransformMethodDD.ItemsData = state.TransformMethodDDItemsData;
                end
                
                % set all other single 'Values'
                for k = ["DataVarTypeDropDown" "TransformMethodDD" "IncludedEdgeDD"...
                        "ReplaceValuesCheckbox" "IncludeEmptyCheckbox" "IncludeMissingCheckbox"...
                        "InputTableCheckbox" "OutputTableCheckbox" "SelectAllCheckbox"]
                    if isfield(state,k + "Value")
                        app.(k).Value = state.(k + "Value");
                    end
                end
                % set fcn button
                if isfield(state,'FcnType')
                    app.FcnTypeButtonGroup.SelectedObject = app.FcnTypeButtonGroup.Buttons(state.FcnType);
                end
                % set other app properties
                for k = ["IsTabularInput" "StatsAllowedByDatatype"...
                        "InputHeight" "GroupHasMissing" "GroupIsCat"]
                    if isfield(state,k)
                        app.(k) = state.(k);
                    end
                end
                % set CustomFcnTypeDD properties
                if isfield(state,'StatsFcnEditFieldValue')
                    app.HandleValues{1} = state.StatsFcnEditFieldValue;
                    app.HandleValues{2} = state.TransformFcnEditFieldValue;
                    app.HandleValues{3} = state.FilterFcnEditFieldValue;
                end
                if ~isequal(widget,'CustomFcnControl')
                    % set based on current handle value
                    app.CustomFcnControl.HandleValue = ...
                        app.HandleValues{app.FcnTypeButtonGroup.SelectedObject.UserData};
                    % else we will set and validate the new handle in a
                    % moment
                end
                if isfield(state,'CustomFcnTypeDDValue')
                    app.CustomFcnControl.FcnType = state.CustomFcnTypeDDValue;
                end
                if isempty(widget)
                    app.doUpdate;
                elseif isequal(widget,'CustomGroupingControl')
                    % send in a src with correct tag to trigger
                    % repopulating all binning rows
                    app.doUpdate(struct('Tag',widget));
                elseif isequal(widget,'CustomFcnControl')
                    % save current value to be used by validator
                    event = struct('PreviousValue',app.CustomFcnControl.HandleValue);
                    % set value of the editfield from the app
                    app.CustomFcnControl.HandleValue = state.CustomFcnControlValue;
                    % need to validate function handle coming in from app
                    % validation function triggers a doUpdate
                    app.CustomFcnControl.validateFcnHandle(app.CustomFcnControl.HandleEditField,event)
                    % keep helper property up to date
                    app.HandleValues{app.FcnTypeButtonGroup.SelectedObject.UserData} = ...
                        app.CustomFcnControl.HandleValue;
                else
                    % if coming from the data cleaner app, also send in
                    % widget that was updated
                    app.doUpdate(app.(widget));
                end
                if isfield(state,'LocalFcnDDValue')
                    app.CustomFcnControl.LocalValue = state.LocalFcnDDValue;
                end
            end
        end

        function propTable = getPropertyInformation(app)
            % propTable is a list of all the controls visible in the Data
            % Cleaner app along with everything needed to map the
            % uifigure into the property inspector

            % Limitations:
            % Works with tabular inputs only
            % No bin edges wsdd
            % No local function workflow (only editfield)

            Name = ["GroupWSDD"; "CustomGroupingControl";
                "DataVarTypeDropDown"; "DataVarDropDowns";...
                "FcnTypeButtonGroup"; "StatsCheckboxes";...
                "TransformMethodDD"; "CustomFcnControl";...
                "IncludedEdgeDD"; "IncludeEmptyCheckbox"; ...
                "IncludeMissingCheckbox"; "ReplaceValuesCheckbox"];
            Group = [repmat(getMsgText(app,'DataDelimiter'),4,1);...
                repmat(getMsgText(app,'FunctionDelimiter'),8,1)];
            DisplayName = getMsgText(app,{'SelectInput'; 'GroupingVariable';...
                'DataVarLabel'; 'DataVarSpecifiedVarsLabel'; ...
                'ComputationType'; 'MethodLabel2';...
                'MethodLabel1'; 'CustomFunction';...
                'IncludedEdge'; 'IncludeEmpty';...
                'IncludeMissing'; 'ReplaceValues'});
            StateName = Name + "Value";
            N = numel(Name);
            Type = repmat({''},N,1);
            Items = repmat({[]},N,1);
            ItemsData = repmat({[]},N,1);
            Tooltip = repmat({''},N,1);
            Visible = repmat(matlab.lang.OnOffSwitchState.on,N,1);
            Enable = repmat(matlab.lang.OnOffSwitchState.on,N,1);
            SpinnerProperties = repmat({[]},N,1);
            app.GroupWSDD(1).populateVariables();
            for k = [1 3:N]
                widget = app.(Name(k));
                Type{k} = class(widget);
                if isprop(widget,'Items')
                    Items{k} = widget(1).Items;
                    ItemsData{k} = widget(1).ItemsData;
                end
                Tooltip{k} = widget(1).Tooltip;
                Visible(k) = widget(1).Visible && widget(1).Parent.Visible;
                Enable(k) = widget(1).Enable;
            end
            % Only show input dropdown if multiple tables are in the app
            % workspace
            Visible(1) = numel(app.GroupWSDD(1).Items) > 2;
            StateName(1) = "InputTableValue";
            % we do not support all that the tooltip implies in this context
            Tooltip{1} = '';
            % 'CustomGroupingControl' to replace GroupTableVarDDs and all
            % binning controls
            StateName(2) = "GroupingStruct";
            Type{2} = 'matlab.internal.dataui.richeditors.GroupingVariableControl';
            Enable(2) = app.GroupTableVarDD(1).Enable;
            % Multiple DataVarDropDowns into a multiselect
            Type{4} = 'MultiselectDropDown';
            Items{4} = [cellstr(getMsgText(app,'DataVarLabel')) Items{4}];
            ItemsData{4} = [{'select variable'} ItemsData{4}];
            Visible(4) = Visible(4) && app.DataVarGrid.Visible;
            % FcnTypeButtonGroup into a custom editor
            StateName(5) = "FcnType";
            Type{5} = 'matlab.internal.dataui.richeditors.GroupFunctionButtonControl';
            Enable(5) = app.FcnTypeButtonGroup.SelectedObject.Enable;
            % Stats checkboxes into a multiselect
            % only show the enabled methods
            StateName(6) = StateName(6) + "App";
            Type{6} = 'MultiselectDropDown';
            Items{6} = {char(getMsgText(app,'MethodLabel3')) app.StatsCheckboxes([app.StatsCheckboxes.Enable]).Text};
            ItemsData{6} = {'select' app.StatsCheckboxes([app.StatsCheckboxes.Enable]).Text};
            Tooltip{6} = '';
            Visible(6) = app.StatsGrid.Visible;

            InitializeFlag = zeros(N,1);
            InSubgroup = false(N,1);
            GroupExpanded = true(N,1);

            propTable = table(Name,Group,DisplayName,StateName,Type,Tooltip,Items,ItemsData,...
                Visible,Enable,InitializeFlag,InSubgroup,GroupExpanded,SpinnerProperties);
        end

        function msg = getInspectorDisplayMsg(app)
            % Used in data cleaner app to display when no valid inputs.
            % All non-empty tables and timetables with at least one valid
            % grouping variable
            msg = '';
            app.GroupWSDD.populateVariables();
            if isscalar(app.GroupWSDD.Items)
                % input only has "select"
                msg = getMsgText(app,'NoValidInput');
            end
        end
    end
    
    % get/set methods for base class properties
    methods
        function summary = get.Summary(app)
            if ~hasDataGroupsAndFcn(app)
                summary = string(message('MATLAB:tableui:Tool_ComputeByGroupTask_Description'));
                return
            end
            if app.IsTabularInput
                inputName = ['`' app.GroupWSDD(1).Value '`'];
            else
                inputName = ['`' app.DataVarWSDD.Value '`'];
            end
            groups = {};
            if app.NumGroupVars <= 2
                if app.IsTabularInput
                    groups = {app.GroupTableVarDD.Value};
                else
                    groups = {app.GroupWSDD.Value};
                end
            end
            groups = strcat('`',groups,'`');
            
            type = app.FcnTypeButtonGroup.SelectedObject.Tag;
            
            switch type
                case 'groupsummary'
                    numMethods = nnz([app.StatsCheckboxes.Value]);
                    if numMethods == 1
                        if app.StatsCheckboxes(end).Value
                            method = getMsgText(app,'ACustomFunction');
                        else
                            % use message already displayed by checkboxes
                            methodIdx = [app.StatsCheckboxes.Value];
                            method = lower(app.StatsCheckboxes(methodIdx).Text);
                        end
                    else
                        method = getMsgText(app,'MultipleStatistics');
                    end
                    summary = getMsgText(app,['groupsummarySummary' num2str(numel(groups))],true,inputName,method,groups{:});
                case 'grouptransform'
                    % Display names are too long, get a short verb form for each
                    method = app.TransformMethodDD.Value;
                    if strcmp(method,'CustomFunction')
                        method = getMsgText(app,'Transform');
                    elseif ismember(method,{'meanfill' 'linearfill'})
                        method = getMsgText(app,'FillMissing');
                    else
                        method = getMsgText(app,[method 'summary']);
                    end
                    summary = getMsgText(app,['grouptransformSummary' num2str(numel(groups))],true,inputName,method,groups{:});
                case 'groupfilter'
                    summary = getMsgText(app,['groupfilterSummary' num2str(numel(groups))],true,inputName,groups{:});
            end
        end

        function state = get.State(app)
            state = struct('versionSavedFrom',app.Version,...
                'minCompatibleVersion',1,...
                'NumDataVars',app.NumDataVars,...
                'NumGroupVars',app.NumGroupVars,...
                'StatsAllowedByDatatype',app.StatsAllowedByDatatype,...
                'InputHeight',app.InputHeight,...
                'IsTabularInput',app.IsTabularInput,...
                'GroupHasMissing',app.GroupHasMissing,...
                'GroupIsCat',app.GroupIsCat);
            for k = ["DataVarTypeDropDown" "DataVarWSDD" "TransformMethodDD"...
                    "IncludedEdgeDD" "ReplaceValuesCheckbox"...
                    "IncludeEmptyCheckbox" "IncludeMissingCheckbox"...
                    "InputTableCheckbox" "OutputTableCheckbox"...
                    "SelectAllCheckbox" "CustomFcnControl"]
                % save one value
                state.(k +"Value") = app.(k).Value;
            end
            state.StatsFcnEditFieldValue = app.HandleValues{1};
            state.TransformFcnEditFieldValue = app.HandleValues{2};
            state.FilterFcnEditFieldValue = app.HandleValues{3};
            state.CustomFcnTypeDDValue = app.CustomFcnControl.FcnType;
            state.LocalFcnDDValue = app.CustomFcnControl.LocalValue;

            state.TransformMethodDDItems = app.TransformMethodDD.Items;
            state.TransformMethodDDItemsData = app.TransformMethodDD.ItemsData;
            for k = ["DataVarDropDowns" "GroupTableVarDD" "GroupWSDD"]
                % save a cell array of values
                state.(k + "Value") = {app.(k).Value};
            end
            % save a cell array of cellstrs
            state.GroupTableVarDDItemsData = {app.GroupTableVarDD.ItemsData};
            state.GroupTableVarDDItems = {app.GroupTableVarDD.Items};
            % save logical vector of values
            state.StatsCheckboxesValue = [app.StatsCheckboxes.Value];
            % save binning options via State of the custom component
            state.BinningSelectorStates = [app.BinningSelector.State];
            % Other fields
            state.DataVarTypeDropDownItems = app.DataVarTypeDropDown.Items;
            state.DataVarTypeDropDownItemsData = app.DataVarTypeDropDown.ItemsData;
            state.TableVarNames = app.DataVarDropDowns(1).Items;
            state.FcnType = app.FcnTypeButtonGroup.SelectedObject.UserData;
            
            % Fields needed for backward compatibility

            % save 'numunique' checkbox and its enable/disable state
            % separately from other checkboxes (introduced 23a)
            state.NumUniqueCheckboxValue = state.StatsCheckboxesValue(end-1);
            state.StatsCheckboxesValue(end-1) =[];
            state.NumUniqueAllowed = state.StatsAllowedByDatatype(end-1);
            state.StatsAllowedByDatatype(end-1) = [];
            % save all binning options as used in pre R2024a
            for k = ["BinningDropdown" "TimeBinDD" "BinEdgesWSDD" "BinWidthUnitsDD"]
                % cellstrs
                controls = [app.BinningSelector.(k)];
                state.(k+"Value") = {controls.Value};
            end
            % Disallow 'binEdgesInPlace' from this field (introduced 24a)
            % The updated value is still stored in BinningSelectorStates
            state.BinningDropdownValue = replace(state.BinningDropdownValue,'binEdgesInPlace','none');
            for k = ["NumBinsSpinner" "BinWidthSpinner"]
                % numeric vectors
                controls = [app.BinningSelector.(k)];
                state.(k+"Value") = [controls.Value];
            end
            for k = ["BinningDropdown" "TimeBinDD" "BinWidthUnitsDD"]
                % cell array of cellstrs
                controls = [app.BinningSelector.(k)];
                state.(k + "ItemsData") = {controls.ItemsData};
                state.(k + "Items") = {controls.Items};
            end
            
            % Fields needed for Data Cleaner App
            state.InputTableValue = state.GroupWSDDValue{1};
            state.StatsCheckboxesValueApp = {app.StatsCheckboxes(state.StatsCheckboxesValue).Text};
            % GroupingStruct is the Value of the app's custom grouping component
            state.GroupingStruct = struct();
            state.GroupingStruct.TableVarNames = state.GroupTableVarDDItems{1};
            state.GroupingStruct.GroupTableVarDDValue = state.GroupTableVarDDValue;
            state.GroupingStruct.BinningDropdownValue = state.BinningDropdownValue;
            state.GroupingStruct.BinningDropdownItems = state.BinningDropdownItems;
            state.GroupingStruct.BinningDropdownItemsData = state.BinningDropdownItemsData;
            state.GroupingStruct.NumBinsSpinnerValue = state.NumBinsSpinnerValue;
            state.GroupingStruct.TimeBinDDValue = state.TimeBinDDValue;
            state.GroupingStruct.TimeBinDDItems = state.TimeBinDDItems;
            state.GroupingStruct.TimeBinDDItemsData = state.TimeBinDDItemsData;
            state.GroupingStruct.BinWidthSpinnerValue = state.BinWidthSpinnerValue;
            state.GroupingStruct.BinWidthUnitsDDValue = state.BinWidthUnitsDDValue;
            state.GroupingStruct.BinWidthUnitsDDItems = state.BinWidthUnitsDDItems;
            state.GroupingStruct.BinWidthUnitsDDItemsData = state.BinWidthUnitsDDItemsData;
        end

        function set.State(app,state)
            setTaskState(app,state);
        end

        function set.Workspace(app,ws)
            app.Workspace = ws;
            [app.GroupWSDD.Workspace] = deal(ws); %#ok<MCSUP>
            [app.BinningSelector.Workspace] = deal(ws); %#ok<MCSUP>
            app.DataVarWSDD.Workspace = ws; %#ok<MCSUP>
        end
    end
end