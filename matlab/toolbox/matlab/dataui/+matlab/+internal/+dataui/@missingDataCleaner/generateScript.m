function [code,outputs] = generateScript(app,isForExport,overwriteInput)
% Generate the functional script for the Clean Missing Data task

%   Copyright 2021-2024 The MathWorks, Inc.

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
if ~hasInputDataAndSamplePoints(app)
    return
elseif waitingOnLocalFunctionSelection(app)    
    code = ['disp("' char(getMsgText(app,'fcnSelectorDispMessage')) '")'];
    return
end

input = getInputDataVarNameForGeneratedScript(app,inputIsRowTimes(app));
appendIndices = app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append') && isequal(app.CleanMethodDropDown.Value,'none');
input = [input getSmallTableCode(app,appendIndices)];
doTableOutput = app.outputIsTable;
doStandardizeMissing = isequal(app.StandardizeDropDown.Value,'nonstandard') && ~isempty(app.IndicatorEditField.Value);
if overwriteInput
    outputs = {app.getInputDataVarNameForGeneratedScript};
elseif app.InputDataHasTableVars && (ismember(app.OutputTypeDropDown.Value,{'replace' 'append'}) || ...
        (isequal(app.OutputTypeDropDown.Value,'smalltable') && ...
        (~isequal(app.CleanMethodDropDown.Value,'none') || doStandardizeMissing)))
    outputs = {app.OutputTable};
elseif ~isequal(app.CleanMethodDropDown.Value,'none') || doStandardizeMissing
    outputs = {app.OutputVector};
end
if ~isequal(app.CleanMethodDropDown.Value,'fill') && ~appendIndices
    outputs = [outputs {app.OutputIndices}];
end

if doTableOutput && inputIsRowTimes(app) && ~overwriteInput
    % copy output to input
    code = [code newline app.OutputTable ' = ' ...
        getInputDataVarNameForGeneratedScript(app) ';' newline];
end
outName = outputs{1};
if doTableOutput && inputIsRowTimes(app)
    outName = addTableVarName(app,outName);
end

% standardizeMissing
if doStandardizeMissing
    code = [code '% ' char(getMsgText(app,getMsgId(app,'StandardizeComment')))];
    code = [code newline outName ' = standardizeMissing(' input ','];
    % turn comma separated list into array
    indVal = app.IndicatorEditField.Value;
    if contains(indVal,',')
        if app.InputDataHasTableVars
            indVal = ['{' indVal '}'];
        else
            indVal = ['[' indVal ']'];
        end
    end
    code = matlab.internal.dataui.addCharToCode(code,indVal);
    if ~appendIndices
        code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
        code = matlab.internal.dataui.addCharToCode(code,getReplaceValuesNameValuePair(app));
    end
    code = [code ');' newline];
    input = outName;
    % if rmmissing, we may also need the per-variable indices
    if ~isForExport && isequal(app.CleanMethodDropDown.Value,'remove') && app.PlotOtherRemovedCheckBox.Visible && ...
            (app.PlotMissingDataCheckBox.Value || app.PlotOtherRemovedCheckBox.Value)
        if isnumeric(app.TableVarPlotDropDown.Value)
            % setup for tiled layout. multiple per-variable indices needed,
            % so pass in the whole table
            code = [code app.TempPlotIndices ' = ismissing(' outName ');' newline];
        else
            % Only need one logical vector for plotting
            code = [code app.TempPlotIndices ' = ismissing(' addDotIndexingToTableName(app,outName) ');' newline];
        end
    end
end

% fillmissing
if isequal(app.CleanMethodDropDown.Value,'fill')
    code = [code '% ' char(getMsgText(app,getMsgId(app,'Fillmissingdata')))];
    if app.SupportsVisualization && ~isForExport && app.PlotMissingDataCheckBox.Value
        % need indices for plotting, will clear in plot code
        code = [code newline '[' outName ',' app.OutputIndices '] = '];
    else
        code = [code newline outName ' = '];
    end

    code = matlab.internal.dataui.addCharToCode(code,['fillmissing(' input]);

    fillMethod = app.FillMethodDropDown.Value;
    doKnn = false;
    if isequal(fillMethod,'constant')
        constantVal = num2str(app.FillConstantSpinner.Value,'%.16g');
        if app.FillConstantUnitsDropDown.Visible % duration or calendarDuration
            constantVal = [app.FillConstantUnitsDropDown.Value '(' constantVal ')'];
            if ~app.AverageableData % calendarDuration, since duration is averageable
                constantVal = ['cal' constantVal];
            end
        end
        code = matlab.internal.dataui.addCharToCode(code,[',"constant",' constantVal]);
    elseif isequal(fillMethod,'movmedian') || isequal(fillMethod,'movmean')
        code = matlab.internal.dataui.addCharToCode(code,[',"' fillMethod ...
            '",' generateScriptForWindowSize(app)]);
    elseif isequal(app.FillMethodDropDown.Value,'knn')
        doKnn = true;
        code = matlab.internal.dataui.addCharToCode(code,',"knn"');
        % k
        if app.KnnKSpinner.Value > 1
            code = matlab.internal.dataui.addCharToCode(code,[',' num2str(app.KnnKSpinner.Value)]);
        end
        % Distance NV pair
        if isequal(app.KnnDistanceDropDown.Value,'seuclidean')
            code = matlab.internal.dataui.addCharToCode(code,',Distance="seuclidean"');
        elseif isequal(app.KnnDistanceDropDown.Value,'custom')
            code = matlab.internal.dataui.addCharToCode(code,[',Distance=' app.CustomKnnDistanceSelector.Value]);
        end % else euclidean, default
    elseif isequal(fillMethod,'custom')
        code = matlab.internal.dataui.addCharToCode(code,[',' app.CustomFillMethodSelector.Value ',']);
        code = matlab.internal.dataui.addCharToCode(code,generateScriptForWindowSize(app));
    else
        code = matlab.internal.dataui.addCharToCode(code,[',"' fillMethod '"']);
    end

    if ~doKnn
        % EndValues NV pair
        if isequal(app.EndValueDropDown.Value,'scalar')
            if app.EndValueConstantUnitsDropDown.Visible
                code = matlab.internal.dataui.addCharToCode(code,[',EndValues=' ...
                    app.EndValueConstantUnitsDropDown.Value '(' num2str(app.EndValueConstantSpinner.Value,'%.16g') ')']);
            else %isnumeric(A)
                code = matlab.internal.dataui.addCharToCode(code,[',EndValues=' num2str(app.EndValueConstantSpinner.Value,'%.16g')]);
            end
        elseif ~isequal(app.EndValueDropDown.Value,'extrap')
            code = matlab.internal.dataui.addCharToCode(code,[',EndValues="' app.EndValueDropDown.Value '"']);
        end

        % MaxGap NV pair
        if isfinite(app.MaxGapSpinner.Value)
            MGtxt = ',MaxGap=';
            if isequal(app.SamplePointsVarClass,"datetime") && matches(app.MaxGapUnitsDropDown.Value,{'years' 'quarters' 'months' 'weeks' 'days'})
                MGtxt = [MGtxt 'cal'];
            end
            if matches(app.SamplePointsVarClass,["datetime", "duration"])
                MGtxt = [MGtxt app.MaxGapUnitsDropDown.Value '(' num2str(app.MaxGapSpinner.Value,'%.16g') ')'];
            else
                MGtxt = [MGtxt num2str(app.MaxGapSpinner.Value,'%.16g')];
            end
            code = matlab.internal.dataui.addCharToCode(code,MGtxt);
        end
    end

    % Remaining NV pairs: DataVariables, SamplePoints, ReplaceValues
    if doStandardizeMissing && app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')
        % replace the variables already appended by standardizemissing
        ind1 = app.InputSize(2) + 1;
        ind2 = app.InputSize(2) + numel(app.getSelectedVarNames);
        code = matlab.internal.dataui.addCharToCode(code,[',DataVariables=' num2str(ind1) ':' num2str(ind2) ]);
        if ~doKnn
            code = matlab.internal.dataui.addCharToCode(code,getSamplePointsNameValuePair(app));
        end
    else
        code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
        if ~doKnn
            code = matlab.internal.dataui.addCharToCode(code,getSamplePointsNameValuePair(app));
        end
        code = matlab.internal.dataui.addCharToCode(code,getReplaceValuesNameValuePair(app));
    end

    code = [code ');'];

% rmmissing
elseif isequal(app.CleanMethodDropDown.Value,'remove')
    code = [code '% ' char(getMsgText(app,getMsgId(app,'Removemissingdata')))];
    if doTableOutput && inputIsRowTimes(app)
        % rmmissing does not support table output with time
        % vector input, so we will do this manually:
        % indices = ismissing(input.Time)
        % input.Time(indices) = [];

        % note: in export script, indices is a temp var that
        % we expect the data cleaner to clear
        code = [code newline outputs{2} ' = '];
        code = matlab.internal.dataui.addCharToCode(code,['ismissing(' input ');']);
        code = [code newline outputs{1} '(' outputs{2} ',:) = [];'];
    else
        if isForExport
            % don't need to pollute workspace with indices,
            % data cleaner app will just clear it anyway
            code = [code newline outName ' = '];
        else
            code = [code newline '[' outName ',' outputs{2} '] = '];
        end
        code = matlab.internal.dataui.addCharToCode(code,['rmmissing(' input]);
        code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
        if app.MinNumMissingSpinner.Visible && app.MinNumMissingSpinner.Value ~= 1
            code = matlab.internal.dataui.addCharToCode(code,[',MinNumMissing=' num2str(app.MinNumMissingSpinner.Value)]);
        end
        code = [code ');'];
    end

% ismissing
else
    code = [code '% ' char(getMsgText(app,getMsgId(app,'Findmissingdata')))];
    code = [code newline outputs{end} ' = '];
    code = matlab.internal.dataui.addCharToCode(code,['ismissing(' input]);
    code = matlab.internal.dataui.addCharToCode(code,getOutputFormatNameValuePair(app));
    code = [code ');'];
    code = generateScriptAppendLogical(app,code,outputs{end},'missing');
end
end