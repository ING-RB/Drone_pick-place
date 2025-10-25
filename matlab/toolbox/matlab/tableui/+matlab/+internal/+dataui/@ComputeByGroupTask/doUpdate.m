function doUpdate(app,source,~)
% Method for updating layout/enable/visible properties for the
% ComputeByGroupTask

%   Copyright 2021-2023 The MathWorks, Inc.

hasInput = hasData(app);
isFromRichEditor = false;
openSelectorIdx = [];
if nargin >= 2
    didClear = checkForClearedWorkspaceVariables(app);
    if ~didClear
        % widget-specific callbacks
        if isequal(source.Tag,'InputChange')
            if hasInput
                T = app.GroupWSDD(1).WorkspaceValue;
                app.IsTabularInput = isa(T,'tabular');
                % save the height, used for the other GroupWSDDs filter fcn
                % and DataVarWSDD filter fcn
                app.InputHeight = size(T,1);
                % If data is too large, turn auto-run off.
                % Once triggered, user is in control, so no need to reset to
                % true for small data
                if app.InputHeight > app.AutoRunCutOff
                    app.AutoRun = false;
                end
            else
                app.IsTabularInput = false;
                app.InputHeight = 1;
            end
            doOpen = setWidgetsToDefault(app);
            if doOpen
                openSelectorIdx = 1;
            end
        elseif isequal(source.Tag,'DataVarChange')
            repopulateDataVarDropDowns(app);
            setStatsAllowedByDatatype(app);
        elseif isequal(source.Tag,'DataVarArrayChange')
            setStatsAllowedByDatatype(app);
        elseif isequal(source.Tag,'GroupingVarChange')
            doOpen = updateGroupingRowOptions(app,source.UserData);
            if doOpen
                openSelectorIdx = source.UserData;
            end
            setBinningValuesToDefault(app,source.UserData);
            setStatsAllowedByDatatype(app);
        elseif isequal(source.Tag,'GroupButton')
            setStatsAllowedByDatatype(app);
        elseif isequal(source.Tag,'FcnTypeButtonGroup')
            % change the handle value to the newly selected fcn
            app.CustomFcnControl.HandleValue = ...
                app.HandleValues{app.FcnTypeButtonGroup.SelectedObject.UserData};
        elseif isequal(source.Tag,'CustomGroupingControl')
            % update all rows
            updateGroupingRowOptions(app);
            setStatsAllowedByDatatype(app);
            isFromRichEditor = app.isAppWorkflow;
        end
    else
        hasInput = false;
    end
end

% update layout/enable/visible

% grouping row(s)
[app.GroupTableVarDD.Enable] = deal(hasInput);
[app.GroupTableVarDD.Visible] = deal(app.IsTabularInput);
[app.GroupWSDD(2:end).Visible] = deal(~app.IsTabularInput);
matlab.internal.dataui.setParentForWidgets([app.GroupTableVarDD app.GroupWSDD],app.InputGrid);
if hasInput
    drawnow
    for k = 1:numel(app.BinningSelector)
        app.BinningSelector(k).Popout.Target = app.BinningSelector(k).Icon;
    end
else
    app.BinningSelector.Popout.Target = [];
end
hasInput = hasGroups(app);
[app.GroupAddButton.Enable] = deal(hasInput);
% BinningSelector takes care of its own Visible setting
% We just need to have the grid sized correctly
showBinning = any([app.BinningSelector.VariableIsBinnable]);
app.InputGrid.ColumnWidth{4} = app.TextRowHeight*(showBinning);
showSubtract = app.NumGroupVars > 1;
[app.GroupSubtractButton.Visible] = deal(showSubtract);
[app.GroupSubtractButton.Enable] = deal(showSubtract);
app.InputGrid.ColumnWidth{5} = app.IconWidth*showSubtract;

% datavar row(s)
datavarrow = 1 + app.NumGroupVars;
app.DataVarLabel.Layout.Row = datavarrow;
app.DataVarWSDD.Layout.Row = datavarrow;
app.DataVarWSDD.Enable = hasInput;
app.DataVarWSDD.Visible = ~app.IsTabularInput;
app.DataVarTypeDropDown.Enable = hasInput;
app.DataVarTypeDropDown.Visible = app.IsTabularInput;
app.DataVarTypeDropDown.Layout.Row = datavarrow;
app.DataVarGrid.Visible = app.IsTabularInput && isequal(app.DataVarTypeDropDown.Value,'manual');
app.DataVarGrid.Layout.Row = datavarrow + [0 1];
[app.DataVarDropDowns.Enable] = deal(hasInput);
[app.DataVarAddButton.Enable] = deal(hasInput);
[app.DataVarSubtractButton.Enable] = deal(hasInput);
hasMinRows = app.NumDataVars == 1;
[app.DataVarSubtractButton.Visible] = deal(~hasMinRows);
app.DataVarGrid.ColumnWidth{2} = app.IconWidth*(~hasMinRows);
hasMaxRows = hasInput && app.NumDataVars == numel(app.DataVarDropDowns(1).Items);
[app.DataVarAddButton.Visible] = deal(~hasMaxRows);
app.DataVarGrid.ColumnWidth{3} = app.IconWidth*(~hasMaxRows);
app.DataVarGrid.RowHeight = app.TextRowHeight*ones(1,app.NumDataVars);
matlab.internal.dataui.setParentForWidgets([app.DataVarWSDD ...
    app.DataVarTypeDropDown app.DataVarGrid],app.InputGrid);

app.InputGrid.RowHeight = [num2cell(app.TextRowHeight*ones(1,app.NumGroupVars+1)) {'fit'}];
% Now that the InputGrid is positioned correctly, auto-open the popout as needed
if ~isempty(openSelectorIdx)
    drawnow;
    open(app.BinningSelector(openSelectorIdx));
end

% method section
hasInput = hasGroupsAndData(app);
[app.FcnTypeButtonGroup.Buttons.Enable] = deal(hasInput);
% toggle grid
currentFun = app.FcnTypeButtonGroup.SelectedObject.Tag;
app.StatsGrid.Visible = isequal(currentFun,'groupsummary');
app.TransformGrid.Visible = isequal(currentFun,'grouptransform');
app.FilterGrid.Visible = isequal(currentFun,'groupfilter');
matlab.internal.dataui.setParentForWidgets([app.StatsGrid,...
    app.TransformGrid,app.FilterGrid],app.FunctionGrid);
% Enable/Visible
app.SelectAllCheckbox.Enable = hasInput;
doStats = app.StatsAllowedByDatatype;
[app.StatsCheckboxes(~doStats).Value] = deal(false);
[app.StatsCheckboxes(~doStats).Enable] = deal(false);
[app.StatsCheckboxes(~doStats).Tooltip] = deal(getMsgText(app,'StatisticDisabledTooltip'));
[app.StatsCheckboxes(doStats).Enable] = deal(hasInput);
[app.StatsCheckboxes(doStats).Tooltip] = deal('');
% gray out the button
app.StatsFcnDummyDropDown.Enable = hasInput;
% and make it not clickable
app.StatsDropdownIcon.Enable = hasInput;
% update button text
methodidx = [app.StatsCheckboxes.Value];
numMethods = nnz(methodidx);
if numMethods == 1
    % display method choice, e.g. "Counts" or "Sum"
    txt = string(app.StatsCheckboxes(methodidx).Text);
else
    % 0 or 2+, display number of methods chosen, e.g. "3 methods chosen"
    txt = getMsgText(app,'MethodsChosen',true,numMethods);
end
app.StatsFcnDummyDropDown.Items = txt;
app.TransformMethodDD.Enable = hasInput;
app.CustomFcnControl.Enable = hasInput;
% custom function widgets layout, place in correct grid
optionrow = 2;
switch currentFun
    case 'groupsummary'
        parent = app.StatsGrid;
        app.CustomFcnControl.Visible = app.StatsCheckboxes(end).Value;
        app.CustomFcnControl.Tooltip = getMsgText(app,'StatsFunctionTooltip');
        app.HandleValues{1} = app.CustomFcnControl.HandleValue;
        app.CustomFcnControl.Layout.Column = [3 5];
        optionrow = 3;
    case 'grouptransform'
        parent = app.TransformGrid;
        app.CustomFcnControl.Visible = isequal(app.TransformMethodDD.Value,'CustomFunction');
        app.CustomFcnControl.Tooltip = getMsgText(app,'TransformFunctionTooltip');
        app.HandleValues{2} = app.CustomFcnControl.HandleValue;
        app.CustomFcnControl.Layout.Column = 4;        
    case 'groupfilter'
        parent = app.FilterGrid;
        app.CustomFcnControl.Visible = true;
        app.CustomFcnControl.Tooltip = getMsgText(app,'FilteringFunctionTooltip');
        app.HandleValues{3} = app.CustomFcnControl.HandleValue;
        app.CustomFcnControl.Layout.Column = [2 3];
end
matlab.internal.dataui.setParentForWidgets(app.CustomFcnControl,parent);
[app.CustomFcnControl.NewFcnText,app.CustomFcnControl.NewFcnName] = ...
    getGroupExampleFcnText(app,currentFun);

% Options row
doBinning = ~all(strcmp({app.BinningSelector.Value},'"none"'));
app.IncludedEdgeLabel.Visible = doBinning;
app.IncludedEdgeLabel.Layout.Row = optionrow;
app.IncludedEdgeDD.Enable = hasInput;
app.IncludedEdgeDD.Visible = doBinning;
app.IncludedEdgeDD.Layout.Row = optionrow;
matlab.internal.dataui.setParentForWidgets([app.IncludedEdgeLabel,...
    app.IncludedEdgeDD],parent);
app.IncludeEmptyCheckbox.Visible = doBinning || app.NumGroupVars > 1 || any(app.GroupIsCat);
app.IncludeEmptyCheckbox.Enable = hasInput;
app.IncludeEmptyCheckbox.Layout.Column = 1 + 2*doBinning;
app.IncludeMissingCheckbox.Enable = hasInput;
app.IncludeMissingCheckbox.Visible = any(app.GroupHasMissing);
app.IncludeMissingCheckbox.Layout.Column = 1 + app.IncludeEmptyCheckbox.Visible + 2*doBinning;
matlab.internal.dataui.setParentForWidgets([app.IncludeEmptyCheckbox app.IncludeMissingCheckbox],app.StatsGrid);
app.ReplaceValuesCheckbox.Enable = hasInput;
app.ReplaceValuesCheckbox.Layout.Column = 1 + 2*doBinning;

% Display section
app.InputTableCheckbox.Enable = hasInput;
app.OutputTableCheckbox.Enable = hasInput;

if isFromRichEditor
    % Event for data cleaner so rich editors can get updated without
    % running generated script and updating app document
    notify(app,'StateChangedFromRichEditor')
else
    % notify data cleaner of all other changes or notify live editor
    notify(app,'StateChanged');
end