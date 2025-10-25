function [code,outputs] = generateScript(app,isForExport,overwriteInput)
% Generate the functional script for the Clean Outlier Data task

% Copyright 2021-2024 The MathWorks, Inc.

code = '';
outputs = {};
if nargin < 2
    % Second input is for "cleaned up" export code. In this case, since we
    % are not exporting plot code, we don't want additional outputs or
    % unused temp vars.
    isForExport = false;
end
if nargin < 3
    % Third input is for whether or not we want to overwrite the input with
    % the output.  Here, want to skip the output = input line and write
    % directly onto the input.
    overwriteInput = isForExport;
end
if overwriteInput && ~isForExport
    % overwriting input is only supported for export script and should not
    % be used internally prior to plotting
    return
end
if ~hasInputDataAndSamplePoints(app) || ...
        (isequal(app.FindMethodDropDown.Value,'workspace') && ...
        isequal(app.OutlierLocationsWSDD.Value,app.SelectVariable))
    return
end

doTableOutput = app.outputIsTable;
if overwriteInput
    outputs = {app.getInputDataVarNameForGeneratedScript};
elseif doTableOutput
    outputs = {app.OutputForTable};
else
    outputs = {app.OutputForArray};
end
if ~isequal(app.CleanMethodDropDown.Value,'none') && ~isForExport
    outputs{2} = app.OutputIndices;
end

% Optional outputs are only needed for plotting
doOptionalOutputs = app.SupportsVisualization && ~isForExport;
if isequal(app.CleanMethodDropDown.Value,'fill')
    code = [code '% ' char(getMsgText(app,getMsgId(app,'Filloutliers')))];  
    fillMethod = app.FillMethodDropDown.Value;
    iscliptorange = isequal(fillMethod,'clip') && isequal(app.FindMethodDropDown.Value,'range');
    doAppendClipToRange = iscliptorange && doTableOutput && isequal(app.OutputTypeDropDown.Value, 'append');
    [code,lowert,uppert] = generateScriptIsBetween(app,code,doAppendClipToRange);
    % Only return the outputs that we need for plotting
    if doOptionalOutputs
        rhs = generateOptionalOutputNames(app,true);
    else
        rhs = {};
    end
    A = [getInputDataVarNameForGeneratedScript(app) getSmallTableCode(app)];    
    if iscliptorange
        % special case, use clip instead of filloutliers
        if doAppendClipToRange
            % logical array coming out of isbetween needs to be expanded to
            % size of A to match the second output of filloutliers
            code = [code newline outputs{2} ' = [false(size(' A ')) ' outputs{2} '];'];
        end
        code = [code newline outputs{1} ' = '];
        code = matlab.internal.dataui.addCharToCode(code,['clip(' A ',']);
        code = matlab.internal.dataui.addCharToCode(code,[lowert ',']);
        code = matlab.internal.dataui.addCharToCode(code,uppert);
        code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
    else
        if isForExport
            code = [code newline outputs{1} ' = '];
        else
            code = [code newline '[' outputs{1} ',' outputs{2} rhs{:} '] = '];
        end
        code = matlab.internal.dataui.addCharToCode(code,['filloutliers(' A]);
        if isequal(fillMethod,'constant')
            code = matlab.internal.dataui.addCharToCode(code,[',' num2str(app.FillConstantSpinner.Value,'%.16g')]);
        elseif isequal(fillMethod,'convertToMissing')
            code = matlab.internal.dataui.addCharToCode(code,',NaN');
        else
            code = matlab.internal.dataui.addCharToCode(code,[',"' fillMethod '"']);
        end
        code = generateScriptForCompute(app,code);
    end
    code = matlab.internal.dataui.addCharToCode(code,getReplaceValuesNameValuePair(app));
    code = [code ');'];
elseif isequal(app.CleanMethodDropDown.Value,'remove')
    code = ['% ' char(getMsgText(app,getMsgId(app,'Removeoutliers')))];
    code = generateScriptIsBetween(app,code);
    % Only return the outputs that we need for plotting
    if doOptionalOutputs
        % get threshold and center outputs as needed
        rhs = generateOptionalOutputNames(app,true);
        if hasMultipleDataVariables(app) && any([app.PlotInputDataCheckBox.Value ...
                app.PlotOutliersCheckBox.Value app.PlotThresholdsCheckBox.Value ...
                (app.PlotCleanedDataCheckBox.Value && app.PlotCleanedDataCheckBox.Visible) ...
                app.PlotCenterCheckBox.Value app.PlotOtherRemovedCheckBox.Value])
            rhs = [{[',' app.TempIndices]} rhs];
        elseif ~isempty(rhs)
            rhs = [{',~'} rhs];
        end
    else
        rhs = {};
    end

    if isForExport
        code = [code newline outputs{1} ' = '];
    else
        code = [code newline '[' outputs{1} ',' outputs{2} rhs{:} '] = '];
    end
    code = matlab.internal.dataui.addCharToCode(code,['rmoutliers(' getInputDataVarNameForGeneratedScript(app)]);
    code = [code getSmallTableCode(app)];
    code = generateScriptForCompute(app,code);
    code = [code ');'];

else % detect
    % isForExport not supported
    code = ['% ' char(getMsgText(app,getMsgId(app,'Findoutliers')))];
    if ~app.InputDataHasTableVars || ~isequal(app.OutputTypeDropDown.Value, 'append')
        outputs = {app.OutputIndices};
    end
    if isequal(app.FindMethodDropDown.Value,'range')
        % For 'range', don't use isoutlier. Just use isbetween
        code = generateScriptIsBetween(app,code,false,outputs{1});
    else
        % Only return the outputs that we need for plotting
        if doOptionalOutputs
            rhs = generateOptionalOutputNames(app,true);
        else
            rhs = {};
        end
        if ~isempty(rhs)
            code = [code newline '[' outputs{1} rhs{:} '] = '];
        else
            code = [code newline outputs{1} ' = '];
        end
        code = matlab.internal.dataui.addCharToCode(code,['isoutlier(' getInputDataVarNameForGeneratedScript(app)]);
        code = generateScriptForCompute(app,code);
        code = matlab.internal.dataui.addCharToCode(code,getOutputFormatNameValuePair(app));
        code = [code ');'];
    end
    code = generateScriptAppendLogical(app,code,outputs{1},'outliers');
end
end

% Helpers
% -------------------------------------------------------------------------  
function [code,lowerT,upperT] = generateScriptIsBetween(app,code,doAppendClipToRange,outName)
if ~isequal(app.FindMethodDropDown.Value,'range')
    lowerT = '';
    upperT = '';
    return
end
if nargin < 4
    outName = app.OutputIndices;
    if nargin < 3
        % To mimic second output of filloutliers, need to return indexed
        % down logical which will get appended to array of false. All other
        % cases are either indexed table or full-size logical.
        doAppendClipToRange = false;
    end
end
% Get chars for the thresholds that go into isbetween (could represent temp
% vars or numeric values)
lowerT = app.LowerRangeEditField.Value;
upperT = app.UpperRangeEditField.Value;
% if needed for plotting, store vector-valued thresholds in a temp var
tempVars = generateOptionalOutputNames(app,false);
if matches(app.AdditionalOutputs{1},tempVars)
    lowerT = app.AdditionalOutputs{1};
    code = [code newline lowerT ' = ' app.LowerRangeEditField.Value ';'];
end
if matches(app.AdditionalOutputs{2},tempVars)
    upperT = app.AdditionalOutputs{2};
    code = [code newline upperT ' = ' app.UpperRangeEditField.Value ';'];
end
A = getInputDataVarNameForGeneratedScript(app);
A = [A getSmallTableCode(app,doAppendClipToRange)];
code = [code newline outName ' = ~isbetween(' A ',' lowerT ',' upperT];
if ~doAppendClipToRange
    code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
end
if outputIsTable(app) && isequal(app.CleanMethodDropDown.Value,'none')
    % Need isbetween to return tabular
    code = matlab.internal.dataui.addCharToCode(code,',OutputFormat="tabular"');  
end
code = [code ');'];
end

function code = generateScriptForCompute(app,code)
% Generate the script that is the same for find, fill, and remove
findMethod = app.FindMethodDropDown.Value;
% Method (positional input)
if ~matches(findMethod,["median" "range" "workspace"])
    % median is default, 
    % range & workspace use OutlierLocations instead of find method input
    code = matlab.internal.dataui.addCharToCode(code,[',"' findMethod '"']);
end
if isequal(findMethod,'percentiles')
    % Percentiles threshold (positional input)
    code = matlab.internal.dataui.addCharToCode(code,[',[' ...
        num2str(app.LowerPercentileSpinner.Value,'%.16g') ' '...
        num2str(app.UpperPercentileSpinner.Value,'%.16g') ']']);
elseif isequal(findMethod,"range")
    % OutlierLocations NV pair
    code = matlab.internal.dataui.addCharToCode(code,[',OutlierLocations=' app.OutputIndices]);
elseif isequal(findMethod,"workspace")
    code = matlab.internal.dataui.addCharToCode(code,[',OutlierLocations=' app.OutlierLocationsWSDD.Value]);
else
    % Threshold NV pair
    if isequal(findMethod,'gesd') || isequal(findMethod,'grubbs')
        defaultThreshold = 0.5;
    elseif isequal(app.FindMethodDropDown.Value,'quartiles')
        defaultThreshold = 1.5;
    elseif startsWith(findMethod,"mov")
        % Before ThresholdFactor, we need the positional moving window input
        code = matlab.internal.dataui.addCharToCode(code,[',' generateScriptForWindowSize(app)]);
        defaultThreshold = 3;
    else
        defaultThreshold = 3;
    end
    if app.ThresholdSpinner.Value ~= defaultThreshold
        code = matlab.internal.dataui.addCharToCode(code,...
            [',ThresholdFactor=' num2str(app.ThresholdSpinner.Value,'%.16g')]);
    end
end
% DataVariables NV pair
code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app,...
    isequal(app.CleanMethodDropDown.Value,'none') && ...
    app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'smalltable')));
% SamplePoints NV pair
code = matlab.internal.dataui.addCharToCode(code,getSamplePointsNameValuePair(app,false));
end