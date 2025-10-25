function [code,outputs] = generateCode(app)
% Generate the script for the PivotTableTask based on its current state

%   Copyright 2023 The MathWorks, Inc.

outputs = {};
code = '';
if ~hasData(app)
    return
elseif isequal(app.MethodDropDown.Value,'CustomFunction') && isempty(app.CustomMethodSelector.Value)
    % Must display a message prompting user to select a function
    % If user adds a function while no script is generated, task can
    % disappear
    code = ['disp("' getString(message('MATLAB:dataui:fcnSelectorDispMessage')) '")'];
    return
elseif app.NumColumns == 0 && app.NumRows == 0
    if isequal(app.MethodDropDown.Value,'CustomFunction') && isequal(app.CustomMethodSelector.FcnType,'local')
        % We expect users to have a local function in the script. We
        % therefore must generate some line of code so that the editor does
        % not interpret the script as a function file and make the task
        % disappear
        code = ['disp("' char(getMsgText(app,'CodeCommentNeedGroups')) '")'];
    end
    return
elseif any(app.FilterSize == 0)
    % Instead of letting pivot error with empty input, show a nicer message
    code = ['disp("' char(getMsgText(app,'CodeCommentTooFiltered')) '")'];
    return
end

outputT = app.OutputName;
outputs = {outputT};
% ticks needed for LE parsing
inputT = ['`' app.InputDropDown.Value '`'];

doFiltering = ~isequal(app.FilterSize(1),app.InputHeight);
if doFiltering
    code = ['% ' char(getMsgText(app,"CodeCommentFilter"))];
    % Copy the input table
    code = [code newline 'filteredTable = ' inputT ';'];
    % Filter it using the VariableEditor's generated code
    for k = 1:numel(app.FilterScript)
        code = [code newline app.FilterScript{k}]; %#ok<AGROW>
    end
    code = [code newline newline];
    inputT = 'filteredTable';
end

code = [code '% ' char(getMsgText(app,"CodeCommentPivot"))];
code = [code newline outputT ' = pivot(' inputT];

% grouping and binning
code = generateScriptRowsColumns(app,code,'Rows');
code = generateScriptRowsColumns(app,code,'Columns');

% DataVariable
if ~ismember(app.MethodDropDown.Value,{'count' 'percentage'})
    code = matlab.internal.dataui.addCharToCode(code,...
        [', DataVariable=' matlab.internal.dataui.cleanVarName(app.DataVarDropDown.Value)]);
end

% Method
if isequal(app.MethodDropDown.Value,'CustomFunction')
    code = matlab.internal.dataui.addCharToCode(code,[', Method=' app.CustomMethodSelector.Value]);
elseif ~isequal(app.MethodDropDown.Value,'count')
    code = matlab.internal.dataui.addCharToCode(code,[', Method="' app.MethodDropDown.Value '"']);
end % else 'count' is default and we don't need to generate it

% Remaining NV pairs, only generate if non-default value
% IncludedEdge
if app.IncludedEdgeDropDown.Visible && isequal(app.IncludedEdgeDropDown.Value,'right')
    code = matlab.internal.dataui.addCharToCode(code,', IncludedEdge="right"');
end
% OutputFormat
if app.OutputFormatDropDown.Visible && isequal(app.OutputFormatDropDown.Value,'flat')
    code = matlab.internal.dataui.addCharToCode(code,', OutputFormat="flat"');
end
% IncludeTotals
if app.IncludeColumnTotalsCB.Value || app.IncludeRowTotalsCB.Value
    code = matlab.internal.dataui.addCharToCode(code,', IncludeTotals=true');
end
% IncludeMissingGroups
if app.IncludeMissingGroupsCB.Enable && ~app.IncludeMissingGroupsCB.Value
    code = matlab.internal.dataui.addCharToCode(code,', IncludeMissingGroups=false');
end
% IncludeEmptyGroups
if app.IncludeEmptyGroupsCB.Enable && app.IncludeEmptyGroupsCB.Value
    code = matlab.internal.dataui.addCharToCode(code,', IncludeEmptyGroups=true');
end
% RowLabelPlacement
if app.RowLabelLocationDropDown.Visible && isequal(app.RowLabelLocationDropDown.Value,'rowNames')
    code = matlab.internal.dataui.addCharToCode(code,', RowLabelPlacement="rownames"');
end

% End function call
code = [code ')'];

% Remove extra Totals Row/Col as needed: pivot function does both or
% neither, unless only one of Row or Cols is selected
if ~app.IncludeColumnTotalsCB.Value && app.IncludeColumnTotalsCB.Enable && app.IncludeRowTotalsCB.Value
    code = [code ';' newline outputT '(end,:) = []'];
elseif ~app.IncludeRowTotalsCB.Value && app.IncludeRowTotalsCB.Enable && app.IncludeColumnTotalsCB.Value
    code = [code ';' newline outputT '(:,end) = []'];
end

% Suppress table display
if ~app.DisplayTableCB.Value
    code = [code ';'];
end

% Generate chart
doChart = ~isequal(app.ChartDropDown.Value,'none');
doTiledLayout = false;
if doChart
    code = [code newline newline '% ' char(getMsgText(app,['CodeComment' app.ChartDropDown.Value])) ];

    % Title of each chart matches the Summary of the task
    % But LE needs ticks to bold some things, so remove them
    titlestr = ['"' char(replace(app.Summary,'`','')) '"'];

    % Extract labels for rows, columns, and data
    rowIndex = '';
    colIndex = '';
    dataIndex = '';
    if ~isequal(app.ChartDropDown.Value,'heatmap')
        % Grab everything but row/column totals
        % For heatmap, keep the totals for now since we'll use them
        if app.IncludeRowTotalsCB.Value && app.IncludeColumnTotalsCB.Value
            rowIndex = '(1:end-1)';
            colIndex = '(1:end-1)';
            dataIndex = '(1:end-1,1:end-1)';
        elseif app.IncludeRowTotalsCB.Value
            colIndex = '(1:end-1)';
            dataIndex = '(:,1:end-1)';
        elseif app.IncludeColumnTotalsCB.Value
            rowIndex = '(1:end-1)';
            dataIndex = '(1:end-1,:)';
        end
    end
    code = [code newline 'rowNames = ' outputT '.Properties.RowNames' rowIndex ';'];
    code = [code newline 'colNames = ' outputT '.Properties.VariableNames' colIndex ';'];
    code = [code newline 'data = table2array(' outputT dataIndex ');'];

    switch app.ChartDropDown.Value
        case 'heatmap'
            doTiledLayout = true;
            if app.IncludeRowTotalsCB.Value && app.IncludeColumnTotalsCB.Value
                % build 4 heatmaps in a 2x2 grid
                code = [code newline 'T = tiledlayout(5,5);'];
                % No good way to set a title of a tiled layout without
                % grabbing the handle of the tiledlayout object
                code = [code newline 'title(T, ' titlestr ');'];
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapValues"))];
                code = [code newline 'nexttile([4,4])'];
                % Heatmap for all the data that isn't totals
                % Don't show column labels since they will be duplicated below
                % The "big" heatmap is at a 4-to-1 scale with the row/column totals
                code = [code newline 'heatmap(colNames(1:end-1),rowNames(1:end-1),data(1:end-1,1:end-1), ...'];
                code = [code newline '    ColorbarVisible=false, Interpreter="none", ...'];
                code = [code newline '    XDisplayLabels=repmat("",1,length(colNames)-1));'];
                % Heatmap for the row totals
                % Don't show row labels as we already have them in the first
                % heatmap, and don't show column labels since they will be
                % duplicated below
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapRowTotals"))];
                code = [code newline 'nexttile([4,1])'];
                code = [code newline 'heatmap(colNames(end),rowNames(1:end-1),data(1:end-1,end), ...'];
                code = [code newline '    YDisplayLabels=repmat("",1,length(rowNames)-1), ...'];
                code = [code newline '    XDisplayLabels="", ColorbarVisible=false, Interpreter="none");'];
                % Heatmap for the column totals
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapColTotals"))];
                code = [code newline 'nexttile([1,4])'];
                code = [code newline 'heatmap(colNames(1:end-1),rowNames(end),data(end,1:end-1), ...'];
                code = [code newline '    ColorbarVisible=false, Interpreter="none");'];
                % Single-square heatmap for the overall total
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapGrandTotal"))];
                code = [code newline 'nexttile([1,1])'];
                code = [code newline 'heatmap(colNames(end),rowNames(end),data(end,end), ...'];
                code = [code newline '    ColorbarVisible=false, Interpreter="none", YDisplayLabels="");'];
                % Make it so next "plot" call doesn't change the last tile
                code = [code newline 'set(gcf,NextPlot="ReplaceChildren");'];
            elseif app.IncludeRowTotalsCB.Value
                % build 2 heatmaps in a 1x2 grid
                code = [code newline 'T = tiledlayout(4,5);'];
                code = [code newline 'title(T, ' titlestr ');'];
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapValues"))];
                code = [code newline 'nexttile([4,4])'];
                code = [code newline 'heatmap(colNames(1:end-1),rowNames,data(:,1:end-1), ...'];
                code = [code newline '    ColorbarVisible=false, Interpreter="none");'];
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapRowTotals"))];
                code = [code newline 'nexttile([4,1])'];
                code = [code newline 'heatmap(colNames(end),rowNames,data(:,end), ...'];
                code = [code newline '    YDisplayLabels=repmat("",1,length(rowNames)), ...'];
                code = [code newline '    ColorbarVisible=false, Interpreter="none");'];
                code = [code newline 'set(gcf,NextPlot="ReplaceChildren");'];
            elseif app.IncludeColumnTotalsCB.Value
                % build 2 heatmaps in a 2x1 grid
                code = [code newline 'T = tiledlayout(5,4);'];
                code = [code newline 'title(T, ' titlestr ');'];
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapValues"))];
                code = [code newline 'nexttile([4,4])'];
                code = [code newline 'heatmap(colNames,rowNames(1:end-1),data(1:end-1,:), ...'];
                code = [code newline '    ColorbarVisible=false, Interpreter="none", ...'];
                code = [code newline '    XDisplayLabels=repmat("",1,length(colNames)));'];
                code = [code newline '% ' char(getMsgText(app,"CodeCommentHeatmapColTotals"))];
                code = [code newline 'nexttile([1,4])'];
                code = [code newline 'heatmap(colNames,rowNames(end),data(end,:), ...'];
                code = [code newline '    ColorbarVisible=false, Interpreter="none");'];
                code = [code newline 'set(gcf,NextPlot="ReplaceChildren");'];
            else
                % no totals, build just one heatmap
                code = [code newline 'heatmap(colNames,rowNames,data, Interpreter="none", ...'];
                code = [code newline '    Title=' titlestr ');'];
                doTiledLayout = false;
            end
        case 'bar3'
            % categorical only available for y input, but that leads to odd
            % looking bars, so mimic categorical axes by manipulating ticks
            code = [code newline 'bar3(data);'];
            code = [code newline 'xticks(1:numel(colNames));'];
            code = [code newline 'xticklabels(colNames);'];
            code = [code newline 'yticks(1:numel(rowNames));'];
            code = [code newline 'yticklabels(rowNames);'];
            % Set interpreter for when underscores are in row/col names
            code = [code newline 'set(gca,TickLabelInterpreter="none");'];
            code = [code newline 'title(' titlestr ');'];
        case 'bar'
            % categorical axes for 2D works much better
            code = [code newline 'bar(categorical(rowNames),data);'];
            code = [code newline 'set(gca,TickLabelInterpreter="none");'];
            code = [code newline 'legend(colNames,Interpreter="none");'];
            code = [code newline 'title(' titlestr ');'];
        case 'bars'
            code = [code newline 'bar(categorical(rowNames),data,"stacked");'];
            code = [code newline 'set(gca,TickLabelInterpreter="none");'];
            code = [code newline 'legend(colNames,Interpreter="none");'];
            code = [code newline 'title(' titlestr ');'];
    end
end

% Clear temp variables
if doFiltering || doChart
    code = [code newline newline 'clear'];
    if doFiltering
        code = [code ' filteredTable'];
    end
    if doChart
        code = [code ' rowNames colNames data'];
        if doTiledLayout
            code = [code ' T'];
        end
    end
end
end

function code = generateScriptRowsColumns(app,code,RC)
% Script for Rows/Columns and RowsBinMethod/ColumnsBinMethod NV pairs
if app.(['Num' RC]) > 0
    % Columns/Rows
    str = matlab.internal.dataui.addCellStrToCode([', ' RC '='],{app.([RC 'DropDowns']).Value});
    code = matlab.internal.dataui.addCharToCode(code,str);

    % Columns/RowsBinMethod
    bins = {app.([RC 'BinningSelectors']).Value};
    uniqbins = unique(bins);
    if numel(uniqbins) > 1
        % specify each separate binning method in a string or cell array
        doStrArray = all(startsWith(bins,'"'));
        if doStrArray
            % all binning methods are strings, make a string array
            code = matlab.internal.dataui.addCharToCode(code, [', ' RC 'BinMethod=[' bins{1} ',']);
        else
            % make a cell array
            code = matlab.internal.dataui.addCharToCode(code, [', ' RC 'BinMethod={' bins{1} ',']);
        end
        for k = 2:numel(bins)
            % one at a time for appropriate code wrapping
            code = matlab.internal.dataui.addCharToCode(code, [ bins{k} ',']);
        end
        % remove final comma and close the array
        if doStrArray
            code = [code(1:end-1) ']'];
        else
            code = [code(1:end-1) '}'];
        end
    elseif numel(uniqbins) == 1 && ~isequal(uniqbins{1},'"none"')
        % Only one Rows/Cols variable or all binned the same way
        code = matlab.internal.dataui.addCharToCode(code,[', ' RC 'BinMethod=' uniqbins{1}]);
    end % else all are "none" and we don't need to generate anything
end
end