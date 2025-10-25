function createComponents(app)
% Setup the layout for the ComputeByGroupTask

%   Copyright 2021-2023 The MathWorks, Inc.

% Create the ui components and lay them out in the figure
app.LayoutManager.RowHeight = {'fit'};
app.LayoutManager.ColumnWidth = {'1x'};
% The grid is split into accordion panels
app.Accordion = matlab.ui.container.internal.Accordion('Parent',app.LayoutManager);

%% Input panel: input/groupvars (and bins), datavars
inputpanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion,...
    'Title',getMsgText(app,'DataDelimiter'));
app.InputGrid = uigridlayout(inputpanel,'Padding',0,'ColumnWidth',...
    {'fit' 'fit' 'fit' app.TextRowHeight app.IconWidth app.IconWidth},...
    'RowHeight',{app.TextRowHeight,app.TextRowHeight,app.TextRowHeight,'fit'},...
    'RowSpacing',5,'ColumnSpacing',5);

% Row 1, GroupWSDD (table or array), GroupTableVar (table only), binning
uilabel(app.InputGrid,'Text',getMsgText(app,'GroupingVariable'));
addGroupRow(app,1);
app.GroupWSDD(1).FilterVariablesFcn = @app.filterInput;
app.GroupWSDD(1).Tooltip = getMsgText(app,'InputTooltip');
app.GroupWSDD(1).Tag = 'InputChange';
% additional grouping rows are added to the InputGrid

% Row 2-3, data variables (table or array)
app.DataVarLabel = uilabel(app.InputGrid,'Text',getMsgText(app,'DataVarLabel'));
app.DataVarTypeDropDown = uidropdown(app.InputGrid,...
    'ValueChangedFcn',@app.doUpdate,'Tag','DataVarChange',...
    'Tooltip',getMsgText(app,'DataVarTooltip'));
% each new data var gets its own row in the subgrid DataVarGrid
app.DataVarGrid = uigridlayout(app.InputGrid,'Padding',0,'ColumnWidth',...
    {'fit' app.IconWidth app.IconWidth},'RowSpacing',5);
app.DataVarGrid.Layout.Column = [3 6];
addDataVarRow(app,1);
app.DataVarWSDD = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.InputGrid,...
    'ValueChangedFcn',@app.doUpdate,'Tag','DataVarArrayChange',...
    'Tooltip',getMsgText(app,'DataVarWSDDTooltip'),'ShowNonExistentVariable',true);
app.DataVarWSDD.FilterVariablesFcn = @app.filterDataVar;
app.DataVarWSDD.Layout.Column = 2;

%% Function panel: choose underlying function and method

app.FunctionPanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
app.FunctionPanel.Title = getMsgText(app,'FunctionDelimiter');

app.FunctionGrid = uigridlayout(app.FunctionPanel,'Padding',0,'RowSpacing',5,...
    'ColumnWidth',{'1x'},'RowHeight',{app.LargeIconHeight,'fit','fit'});
% 1st row of FunctionGrid is buttons to choose between 3 grouping functions
app.FcnTypeButtonGroup = uibuttongroup(app.FunctionGrid,'BorderType','none',...
    'Tag','FcnTypeButtonGroup','SelectionChangedFcn',@app.doUpdate);
buttonTag = {'groupsummary' 'grouptransform' 'groupfilter'};
buttonText = getMsgText(app,strcat(buttonTag,'Label'));
buttonTooltip = getMsgText(app,strcat(buttonTag,'Tooltip'));
buttonIcon = {'groupSummaryPlot' 'groupTransformPlot' 'groupFilterPlot'};
for k = 1:3
    b = uitogglebutton(app.FcnTypeButtonGroup,...
        'Position',[app.LargeIconWidth*(k-1)+1 1 app.LargeIconWidth-1 app.LargeIconHeight-1],...
        'IconAlignment','left','Tooltip',buttonTooltip(k),...
        'UserData',k,'Text',buttonText(k),'Tag',buttonTag{k});
    matlab.ui.control.internal.specifyIconID(b,buttonIcon{k},50,40);
end
% 2nd row of FunctionGrid is 1 of 3 grids corresponding to selected button

% groupsummary method input
app.StatsGrid = uigridlayout(app.FunctionGrid,'Padding',0,'RowSpacing',5,...
    'ColumnWidth',{'fit','fit','fit','fit','fit'},...
    'RowHeight',{app.TextRowHeight,0,'fit'});
% stats grid has 3 rows, 2nd is for when the "checkboxdropdown" is opened,
% 3rd is for nvpairs
uilabel(app.StatsGrid,'Text',getMsgText(app,'MethodLabel2'));
app.StatsFcnDummyDropDown = uidropdown(app.StatsGrid);
app.StatsDropdownIcon = uiimage(app.StatsGrid,'ScaleMethod','stretch',...
    'ImageSource',fullfile(matlabroot,'toolbox','matlab','tableui','resources','blankIcon.png'),...
    'ImageClickedFcn',@app.toggleCollapsed,'UserData',struct('Collapsed',true));
app.StatsDropdownIcon.Layout.Column = 2;
app.CustomFcnControl = matlab.internal.dataui.FunctionSelector(app.StatsGrid,...
    'ValueChangedFcn',@app.doUpdate);
app.CustomFcnControl.Layout.Row = 1;
% This panel with checkboxes, along with the StatsFcnDummyDropDown and
% StatsDropdownIcon make up the "multiselect dropdown"
p = uipanel(app.StatsGrid);
p.Layout.Row = 2;
p.Layout.Column = 2;
cbGrid = uigridlayout(p,'Padding',[2 0 2 0],'ColumnWidth',{'fit'},...
    'ColumnSpacing',0,'RowSpacing',0,'Visible','off');
% changing order here affects method setStatsAllowedByDatatype
tags = {'counts' 'sum' 'mean' 'median' 'mode' 'max' 'min' 'range' ...
    'std' 'var' 'nnz' 'nummissing' 'numunique' 'CustomFunction'};
cbGrid.RowHeight = app.TextRowHeight*ones(1,numel(tags)+1);
app.SelectAllCheckbox = uicheckbox(cbGrid,'Text',getMsgText(app,'Selectall'),...
    'ValueChangedFcn',@app.selectAll);
text = getMsgText(app,tags);
for k = 1:numel(text)
    app.StatsCheckboxes(k) = uicheckbox(cbGrid,...
        'ValueChangedFcn',@app.doUpdate,'Text',text(k),'Tag',tags{k});
end
% row 3 of stats grid is for n/v pairs
% Included edge: moves grids, but always comes first if applicable
% Only applicable when doing binning.
app.IncludedEdgeLabel = uilabel(app.StatsGrid,'Text',getMsgText(app,'IncludedEdge'));
app.IncludedEdgeLabel.Layout.Row = 3;
app.IncludedEdgeLabel.Layout.Column = 1;
app.IncludedEdgeDD = uidropdown(app.StatsGrid,'ValueChangedFcn',...
    @app.doUpdate,'Items',getMsgText(app,{'Left' 'Right'}),...
    'ItemsData',{'left' 'right'},'Tooltip',getMsgText(app,'IncludedEdgeTooltip'));
% IncludeEmpty/Missing, only for groupsummary
app.IncludeEmptyCheckbox = uicheckbox(app.StatsGrid,'ValueChangedFcn',@app.doUpdate,...
    'Text',getMsgText(app,'IncludeEmpty'),'Tooltip',getMsgText(app,'IncludeEmptyTooltip'));
app.IncludeMissingCheckbox = uicheckbox(app.StatsGrid,'ValueChangedFcn',@app.doUpdate,...
    'Text', getMsgText(app,'IncludeMissing'),'Tooltip',getMsgText(app,'IncludeMissingTooltip'));

% grouptransform method input
app.TransformGrid = uigridlayout(app.FunctionGrid,'Padding',0,'RowSpacing',5,...
    'ColumnWidth',{'fit','fit','fit','fit'},...
    'RowHeight',{app.TextRowHeight,app.TextRowHeight});
app.TransformGrid.Layout.Row = 2;
app.TransformGrid.Layout.Column = 1;
uilabel(app.TransformGrid,'Text',getMsgText(app,'MethodLabel1'));
app.TransformMethodDD = uidropdown(app.TransformGrid,'ValueChangedFcn',@app.doUpdate);
app.TransformMethodDD.Layout.Column = [2 3];
% ReplaceValues, only for grouptransform
app.ReplaceValuesCheckbox = uicheckbox(app.TransformGrid,'ValueChangedFcn',@app.doUpdate,...
    'Text',getMsgText(app,'ReplaceValues'),'Tooltip',getMsgText(app,'ReplaceValuesTooltip'));
app.ReplaceValuesCheckbox.Layout.Row = 2;

% groupfilter method input
app.FilterGrid = uigridlayout(app.FunctionGrid,'Padding',0,'RowSpacing',5,...
    'ColumnWidth',{'fit','fit','fit'},'RowHeight',{app.TextRowHeight,'fit'});
app.FilterGrid.Layout.Row = 2;
app.FilterGrid.Layout.Column = 1;
uilabel(app.FilterGrid,'Text',getMsgText(app,'MethodLabel1'));

%% input/output display
app.DisplayPanel = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
app.DisplayPanel.Title = getMsgText(app,'Visualizeresults',false);
app.DisplayPanel.Collapsed = true;
g = uigridlayout(app.DisplayPanel,'Padding',0,'RowSpacing',5,...
    'RowHeight',{app.TextRowHeight},'ColumnWidth',{'fit','fit'});
app.InputTableCheckbox = uicheckbox(g,...
    'Text',getMsgText(app,'InputTable'),'ValueChangedFcn',@app.doUpdate);
app.OutputTableCheckbox = uicheckbox(g,...
    'Text',getMsgText(app,'OutputTable'),'ValueChangedFcn',@app.doUpdate);

%% layout is complete, set default values
setWidgetsToDefault(app);