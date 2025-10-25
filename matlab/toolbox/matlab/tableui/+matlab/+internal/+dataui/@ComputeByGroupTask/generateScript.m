function [code, outputs] = generateScript(app,isForExport,overwriteInput)
% Generate the script for the ComputeByGroupTask

%   Copyright 2021-2024 The MathWorks, Inc.

if nargin < 2
    % Second input is for "cleaned up" export code. E.g., don't
    % introduce temp vars for plotting. No difference for this task.
    isForExport = false;
end
if nargin < 3
    % Third input is for whether or not we want to overwrite
    % the input with the output
    overwriteInput = isForExport;
end
outputs = {};
code = '';
if overwriteInput && ~isForExport
    % overwriting input is only supported for export script and should not
    % be used internally prior to plotting
    return
end
if ~hasDataGroupsAndFcn(app)
    if hasGroupsAndData(app)
        code = ['disp("' char(getMsgText(app,'fcnSelectorDispMessage',false)) '")'];
    end
    return
end

% get output name and comment line
if overwriteInput
    outputs = {app.GroupWSDD(1).Value};
else
    outputs = {app.OutputName};
end
grpFcn = app.FcnTypeButtonGroup.SelectedObject.Tag;
code = ['% ' char(getMsgText(app,[grpFcn 'Comment'])) newline];

if isAppWorkflow(app)
    tick = '';
else
    tick = '`';
end

% get/create input table
if app.IsTabularInput
    input = [tick app.GroupWSDD(1).Value tick];
else
    % first, convert matrix input to table
    code = [code 'inputTable = table('];
    % first add grouping vars to the table
    groupvars = strcat(tick,{app.GroupWSDD.Value},[tick ',']);
    for idx = 1:numel(groupvars)
        code = matlab.internal.dataui.addCharToCode(code,groupvars{idx});
    end
    % then add data var to the table and complete the table call
    code = matlab.internal.dataui.addCharToCode(code,[tick app.DataVarWSDD.Value tick ')']);
    if ~app.InputTableCheckbox.Value
        % suppress output
        code = [code ';'];
    end
    code = [code newline];
    input = 'inputTable';
end

% output, start function call, and input data
code = [code outputs{1} ' = ' grpFcn '(' input ','];

% groupvars
if app.IsTabularInput
    % use table variable names
    code = matlab.internal.dataui.addCellStrToCode(code,{app.GroupTableVarDD.Value});
else
    % use indices since making a table could have changed the variable names
    if app.NumGroupVars == 1
        code = matlab.internal.dataui.addCharToCode(code,'1');
    else
        code = matlab.internal.dataui.addCharToCode(code,['1:' num2str(app.NumGroupVars)]);
    end
end

% groupbins
bins = {app.BinningSelector.Value};
uniqbins = unique(bins);
if numel(uniqbins) > 1
    % specify each separate binning method in a string or cell array
    doStrArray = all(startsWith(bins,'"'));
    if doStrArray
        % all binning methods are strings, make a string array
        code = matlab.internal.dataui.addCharToCode(code, [',[' bins{1} ',']);
    else
        % make a cell array
        code = matlab.internal.dataui.addCharToCode(code, [',{' bins{1} ',']);
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
elseif isscalar(uniqbins) && ~isequal(uniqbins{1},'"none"')
    % Only one grouping variable or all binned the same way
    code = matlab.internal.dataui.addCharToCode(code,[',' uniqbins{1}]);
end

% method
isCountsOnly = false;
switch grpFcn
    case 'groupsummary'
        % 'counts' is not used as a method
        methodsTF = [false app.StatsCheckboxes(2:end).Value];
        methodsTF(end) = methodsTF(end) && ~isempty(app.CustomFcnControl.Value);
        allMethodNAmes = {app.StatsCheckboxes.Tag};
        methods = allMethodNAmes(methodsTF);
        
        if all(methodsTF(2:end))
            % case ',{"all",@customFcn}'
            code = matlab.internal.dataui.addCharToCode(code,',{"all"');
            code = matlab.internal.dataui.addCharToCode(code,[',' app.CustomFcnControl.Value]);
            code = [code '}'];
        elseif all(methodsTF(2:end-1))
            % case ',"all"'
            code = matlab.internal.dataui.addCharToCode(code,',"all"');
        elseif methodsTF(end) && nnz(methodsTF) > 1
            % case ',{"method1","method2",...,@customFcn}'
            code = matlab.internal.dataui.addCharToCode(code,[',{"' methods{1} '",']);
            for idx = 2:numel(methods)-1
                % add string elements into array
                code = matlab.internal.dataui.addCharToCode(code,['"' methods{idx} '",']);
            end
            code = matlab.internal.dataui.addCharToCode(code(1:end-1),[',' app.CustomFcnControl.Value '}']);
        elseif methodsTF(end)
            % case ',@customFcn'
            code = matlab.internal.dataui.addCharToCode(code,[',' app.CustomFcnControl.Value]);
        elseif ~any(methodsTF)
            % counts only, don't add method to code, but flag that we also
            % cannot add datavars to generated code
            isCountsOnly = true;
        else
            % case ',["method1",...]' or ',"method1"'
            code = [code ','];
            code = matlab.internal.dataui.addCellStrToCode(code,methods);
        end
    case 'grouptransform'
        if isequal(app.TransformMethodDD.Value,'CustomFunction')
            code = matlab.internal.dataui.addCharToCode(code,[',' app.CustomFcnControl.Value]);
        else % builtin method
            code = matlab.internal.dataui.addCharToCode(code,[',"' app.TransformMethodDD.Value '"']);
        end
    case 'groupfilter'
        code = matlab.internal.dataui.addCharToCode(code,[',' app.CustomFcnControl.Value]);
    % otherwise 'groupcounts', no method needed
end

% datavars
if app.IsTabularInput && ~isCountsOnly
    if isequal(app.DataVarTypeDropDown.Value,'numeric')
        % use vartype
        code = matlab.internal.dataui.addCharToCode(code,',vartype("numeric")');
    elseif isequal(app.DataVarTypeDropDown.Value,'all')
        % generate logical vector
        code = matlab.internal.dataui.addCharToCode(code,[',true(1,' num2str(numel(app.DataVarDropDowns(1).Items)) ')']);
    elseif isequal(app.DataVarTypeDropDown.Value,'manual')
        % list variables in a string array
        code = [code ','];
        code = matlab.internal.dataui.addCellStrToCode(code,{app.DataVarDropDowns.Value});
    end
    % If not originally tabular data, default of all non-grouping vars is
    % correct. If groupcounts, no data variables at all.
end

% N/V pairs, list only if not default:

% included edge (all functions, but only when binning)
if ~all(strcmp({app.BinningSelector.Value},'"none"')) && ~isequal(app.IncludedEdgeDD.Value,'left')
    code = matlab.internal.dataui.addCharToCode(code,',IncludedEdge="right"');
end
% include missing groups (groupsummary only)
isgroupsummary = strcmp(grpFcn,'groupsummary');
if isgroupsummary && ~app.IncludeMissingCheckbox.Value && app.IncludeMissingCheckbox.Visible
    code = matlab.internal.dataui.addCharToCode(code,',IncludeMissingGroups=false');
end
% include empty groups (groupsummary only)
if isgroupsummary && app.IncludeEmptyCheckbox.Value && app.IncludeEmptyCheckbox.Visible
    code = matlab.internal.dataui.addCharToCode(code,',IncludeEmptyGroups=true');
end
% replace values (groupfilter only)
if isequal(grpFcn,'grouptransform') && ~app.ReplaceValuesCheckbox.Value
    code = matlab.internal.dataui.addCharToCode(code,',ReplaceValues=false');
end

% end the function call
code = [code ')'];
removeCounts = isgroupsummary && ~app.StatsCheckboxes(1).Value;
% For matrix inputs, we have already displayed input table as needed
% For table inputs, if we need to display the input, then we need to hold
%     off on displaying output here so input can be displayed first
suppressOutput = (app.InputTableCheckbox.Value && app.IsTabularInput) || ~app.OutputTableCheckbox.Value;
if  suppressOutput || removeCounts   
    code = [code ';'];
end
if removeCounts
    % groupsummary, but user has opted for no counts, remove them in a
    % separate line of code: newTable.GroupCount = [];
    code = [code newline outputs{1} '.GroupCount = []'];
    if suppressOutput
        code = [code ';'];
    end
end

if ~app.IsTabularInput
    % clear the "inputTable" we generated
    code = [code newline 'clear inputTable'];
end
end
