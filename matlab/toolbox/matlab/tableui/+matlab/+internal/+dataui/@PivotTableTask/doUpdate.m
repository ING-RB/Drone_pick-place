function doUpdate(app,src,~)
% Update the display of the PivotTableTask based on current state

%   Copyright 2023-2024 The MathWorks, Inc.

if nargin > 1
    % Having a src indicates we are coming from a callback

    % Check if we need to update after loading and then interacting, or if
    % variables have been cleared
    didClear = refreshStaleTask(app);
    if ~didClear
        % Coming from a callback for a particular control, may need to update
        % some other controls based on this change
        if isequal(src.Tag,'InputDropDown')
            setValuesToDefault(app);
            if hasData(app)
                % Auto-open accordion for main pivot controls
                app.Accordion.Children(3).Collapsed = false;

                % If data is too large, turn auto-run off.
                % Once triggered, user is in control, so no need to reset to
                % true for small data
                if app.InputHeight > app.AutoRunCutOff
                    app.AutoRun = false;
                end
            end
        elseif isequal(src.Tag,'DataVarDropDown')
            setMethodDDByDataVar(app);
        elseif isequal(src.Tag,'ColumnsDropDowns')
            updateBinningSelectorData(app,'Columns',src.UserData);
        elseif isequal(src.Tag,'RowsDropDowns')
            updateBinningSelectorData(app,'Rows',src.UserData);
        end
    end
end

% Accordion 2 - Filter panel
hasinput = hasData(app);
% Update the title of the filter panel
if hasinput
    if isequal(app.FilterSize(1),app.InputHeight)
        % No filtering has been done, do the basic title
        app.Accordion.Children(2).Title = getMsgText(app,"SectionHeaderFilter");
    else
        % Filtering has been done, add more to the title
        app.Accordion.Children(2).Title = getMsgText(app,"SectionHeaderFilter") + ...
            " (" + getMsgText(app,"SectionHeaderFilter2",app.InputHeight,app.FilterSize(1)) + ")";
    end
else
    % basic title
    app.Accordion.Children(2).Title = getMsgText(app,"SectionHeaderFilter");
    % Also, collapse all the accordions
    [app.Accordion.Children(2:end).Collapsed] = deal(true);
end
% Update label with the current size of the filtered table
app.VELabel.Text = app.FilterSize(1) + " × " + app.FilterSize(2) + " " + app.InputClass;
% Update the Variable Editor depending on if we want to show or hide the
% sparklines and summaries
app.VariableEditor.SparkLinesVisible = app.ShowSparklines;
app.VariableEditor.StatisticsVisible = app.ShowSparklines;
if app.ShowSparklines
    % need a little more vertical space
    app.Accordion.Children(2).Children.RowHeight{4} = 2.5*app.PanelHeight;
    matlab.ui.control.internal.specifyIconID(app.SparklinesIcon,...
        'sparklineApplied',app.IconWidth,app.IconWidth);
else
    app.Accordion.Children(2).Children.RowHeight{4} = 1.5*app.PanelHeight;
    matlab.ui.control.internal.specifyIconID(app.SparklinesIcon,...
        'sparklineNotApplied',app.IconWidth,app.IconWidth);
end
app.SparklinesIcon.Visible = hasinput;
app.VariableEditor.Visible = hasinput;
% VE has its own border, so don't double up and make it thicker
app.VariableEditor.Parent.Parent.BorderWidth = app.PanelBorder - hasinput;

% Accordion 3 - Rows/Columns/Values panels
% Rows panel
app.RowsMainAddButton.Visible = app.NumRows == 0;
app.RowsMainAddButton.Enable = hasinput;
hasBinnableRows = updateBinningSelectors(app,'Rows');

% Columns panel
app.ColumnsMainAddButton.Visible = app.NumColumns == 0;
app.ColumnsMainAddButton.Enable = hasinput;
hasBinnableColumns = updateBinningSelectors(app,'Columns');

hasBinning = false;
hasColumns = app.NumColumns > 0;
hasRows = app.NumRows > 0;
if hasBinnableColumns || hasBinnableRows
    hasColBinning = hasColumns && any(~strcmp({app.ColumnsBinningSelectors.Value},'"none"'));
    hasRowBinning = hasRows && any(~strcmp({app.RowsBinningSelectors.Value},'"none"'));
    hasBinning = hasColBinning || hasRowBinning;
end

% Values panel
app.DataVarDropDown.Enable = hasinput;
app.MethodDropDown.Enable = hasinput;
app.CustomMethodSelector.Visible = isequal(app.MethodDropDown.Value,'CustomFunction');
method = app.MethodDropDown.Value;
if ismember(method,{'count','percentage'})
    app.ValuesPanel.Tooltip = getMsgText(app,"ValuesTooltip" + method);
else
    app.ValuesPanel.Tooltip = getMsgText(app,"ValuesTooltip" + method,app.DataVarDropDown.Value);
end

% Accordion 4 - options section
totalsAllowed = ~isequal(method,"none");
app.IncludeColumnTotalsCB.Enable = hasRows && totalsAllowed;
if ~app.IncludeColumnTotalsCB.Enable
    % pivot function does not calculate column totals
    app.IncludeColumnTotalsCB.Value = false;
end
app.IncludeRowTotalsCB.Enable = hasColumns && totalsAllowed;
if ~app.IncludeRowTotalsCB.Enable
    % pivot function does not calculate row totals
    app.IncludeRowTotalsCB.Value = false;
end
if totalsAllowed
    % basic tooltips for row/col totals
    app.IncludeColumnTotalsCB.Tooltip = getMsgText(app,"IncludeTotalsTooltipColumns");
    app.IncludeRowTotalsCB.Tooltip = getMsgText(app,"IncludeTotalsTooltipRows");
else
    % tooltips when no aggregation to explain why disabled
    app.IncludeColumnTotalsCB.Tooltip = getMsgText(app,"IncludeTotalsNotAllowedNoAggregation");
    app.IncludeRowTotalsCB.Tooltip = getMsgText(app,"IncludeTotalsNotAllowedNoAggregation");
end

grpHasMissing = any([app.RowsBinningSelectors.HasMissing app.ColumnsBinningSelectors.HasMissing]);
app.IncludeMissingGroupsCB.Enable = hasinput && grpHasMissing;
if hasinput && ~grpHasMissing
    app.IncludeMissingGroupsCB.Tooltip = getMsgText(app,"IncludeMissingGroupsTooltipDisabled");
else
    app.IncludeMissingGroupsCB.Tooltip = getMsgText(app,"IncludeMissingGroupsTooltip");
end
couldHaveEmpties = hasBinning || any(ismember({app.RowsBinningSelectors.VariableClass ...
    app.ColumnsBinningSelectors.VariableClass},{'categorical' 'logical'}));
app.IncludeEmptyGroupsCB.Enable = hasinput && couldHaveEmpties;
if hasinput && ~couldHaveEmpties
    app.IncludeEmptyGroupsCB.Tooltip = getMsgText(app,"IncludeEmptyGroupsTooltipDisabled");
else
    app.IncludeEmptyGroupsCB.Tooltip = getMsgText(app,"IncludeEmptyGroupsTooltip");
end

app.RowLabelLocationDropDown.Enable = hasinput;
app.RowLabelLocationLabel.Visible = hasRows;
app.RowLabelLocationDropDown.Visible = hasRows;
if app.NumRows > 1
    app.RowLabelLocationDropDown.Items{2} = char(getMsgText(app,"FirstTableVariables"));
else
    app.RowLabelLocationDropDown.Items{2} = char(getMsgText(app,"FirstTableVariable"));
end
app.OutputFormatDropDown.Enable = hasinput;
app.OutputFormatDropDown.Visible = app.NumColumns > 1;
app.OutputFormatLabel.Visible = app.NumColumns > 1;
app.IncludedEdgeDropDown.Enable = hasinput;
app.IncludedEdgeDropDown.Visible = hasBinning;
app.IncludedEdgeLabel.Visible = hasBinning;
matlab.internal.dataui.setParentForWidgets([app.RowLabelLocationLabel app.RowLabelLocationDropDown ...
    app.OutputFormatLabel app.OutputFormatDropDown ...
    app.IncludedEdgeLabel app.IncludedEdgeDropDown],app.Accordion.Children(4).Children)

% Accordion 5 - display results
hasGrps = hasinput && (app.NumColumns > 0 || app.NumRows > 0);
% if ~hasGrps, we aren't generating any code, so disable this section
app.DisplayTableCB.Enable = hasGrps;
app.ChartDropDown.Enable = hasGrps;
app.ChartDropDown.Tooltip = '';
if hasGrps
    methodReturnsNumeric = app.DataVarIsNumeric || ...
        ismember(method,{'count' 'percentage' 'nnz' 'nummissing' 'numunique' 'var' 'CustomFunction'}) || ...
        (app.DataVarActsNumeric && ismember(method,{'sum' 'mean' 'std' 'range'}));
    hasUseableRowNames = ~hasRows || isequal(app.RowLabelLocationDropDown.Value,'rowNames');
    app.ChartDropDown.Enable = methodReturnsNumeric && hasUseableRowNames && ...
        (app.NumColumns < 2 || isequal(app.OutputFormatDropDown.Value,'flat'));
    if ~app.ChartDropDown.Enable
        app.ChartDropDown.Value = 'none';
        if ~methodReturnsNumeric
            % tooltip says method needs to return numeric
            app.ChartDropDown.Tooltip = getMsgText(app,"ChartDisabled1");
        elseif ~hasUseableRowNames
            % tooltip says to use 'rownames'
            app.ChartDropDown.Tooltip = getMsgText(app,"ChartDisabled2");
        else
            % tooltip says to use 'flat'
            app.ChartDropDown.Tooltip = getMsgText(app,"ChartDisabled3");
        end
    end
end

% Tell the listener (LE) to update State and generated script
notify(app,'StateChanged');
end

function didClear = refreshStaleTask(app)
% Called on doUpdate to check if we need to refresh the VE after the task
% has been loaded with no data in the workspace. If variable is still not
% in the workspace or if the variable has been cleared, then we need to
% reset the task.

didClear = false;
if isempty(app.InputDropDown.WorkspaceValue) && hasData(app)
    % The selected variable is not in the workspace
    app.InputDropDown.Value = app.InputDropDown.ItemsData{1};
    setValuesToDefault(app);
    % No longer need to worry about updating stale VE
    app.TaskIsStale = false;
    didClear = true;
end
if ~app.TaskIsStale
    return
end
% Since TaskIsStale, we now data in the workspace and we need to re-attempt
% to set the VE display table and Filter state
assignin(app.VEWorkspace,app.FilterName,app.InputDropDown.WorkspaceValue);
try
    app.VariableEditor.setFilterState(app.StaleFilterState);
catch
    % After variable is in workspace and has had a chance to be updated, we
    % still cannot set the filter state. Likely the table currently in the
    % workspace is different than initially selected table. So revert
    % filters to default.
    app.VariableEditor.resetFilters();
    app.FilterScript = {};
    app.FilterSize = size(app.InputDropDown.WorkspaceValue);
end
app.TaskIsStale = false;
end