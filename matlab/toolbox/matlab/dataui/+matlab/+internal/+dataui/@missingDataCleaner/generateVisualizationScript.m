function code = generateVisualizationScript(app)
% Generate the plot script for the Clean Missing Data task

% Copyright 2021-2024 The MathWorks, Inc.

code = '';
if ~hasInputDataAndSamplePoints(app) || ~app.SupportsVisualization|| ...
        waitingOnLocalFunctionSelection(app)
    return;
end
numPlots = sum([app.PlotDataCheckBox.Value app.PlotMissingDataCheckBox.Value ...
    (app.PlotOtherRemovedCheckBox.Value && app.PlotOtherRemovedCheckBox.Visible)]);
if numPlots == 0
    return;
end
resetVariablesToBeCleared(app);

code = addVisualizeResultsLine(app);
didHoldOn = false;
x = getSamplePointsVarNameForGeneratedScript(app); % 'X' or ''
doTiledLayout = isnumeric(app.TableVarPlotDropDown.Value);
doLinePlot = doTiledLayout || matches(app.SelectedVarType,["numeric" "logical" "datetime" "duration"]);
doDiscretize = app.SelectedVarNumUnique >= 30;
if isequal(app.CleanMethodDropDown.Value,'fill')
    if doTiledLayout
        needOutLocation = ~isequal(app.OutputTypeDropDown.Value,'replace');
        [code,~,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLocation);
        if isequal(app.OutputTypeDropDown.Value,'append')
            outIndex = [outIndex '+' num2str(app.InputSize(2))];
        end
        a2 = [app.OutputTable '.(' outIndex ')'];
        mask = [app.OutputIndices '(:,' outIndex ')'];
        tab = '    ';
    else
        if app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')
            a2 = addIndexingIntoAppendedVar(app,app.OutputTable);
        elseif app.outputIsTable
            a2 = addDotIndexingToTableName(app,app.OutputTable);
        else
            a2 = app.OutputVector;
        end
        [mask,maskIndex] = addSubscriptIndexingToTableName(app,app.OutputIndices);
        tab = '';
    end
    
    % Generate setup script if needed
    if doDiscretize
        code = generateScriptConvertAndDiscretize(app,code,a2,app.PlotMissingDataCheckBox.Value,app.OutputIndices,maskIndex,false);
    elseif ~doLinePlot
        [code,a2] = generateScriptConvert(app,code,a2);
    end

    % Plot cleaned data
    if app.PlotDataCheckBox.Value
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'PlotCleanedData')))];
        if doLinePlot
            code = generateScriptPlotCleanedData(app,code,x,a2,tab);
        elseif doDiscretize
            code = generateScriptForHistogram(app,code,[],'catNames','counts',false,'1','CleanedData');
        else
            code = generateScriptForHistogram(app,code,a2,[],[],false,'1','CleanedData');
        end
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    % Plot filled missing entries
    if app.PlotMissingDataCheckBox.Value
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotfilledmissing')))];
        txt = getMsgId(app,'FilledMissingEntries');
        if doLinePlot
            code = generateScriptForMarkerPlot(app,code,x,a2,mask,'.','12','2',txt,tab);
        elseif doDiscretize
            code = generateScriptForHistogram(app,code,[],'catNames','missingCounts',false,'2',txt);
        else
            code = generateScriptForHistogram(app,code,[a2 '(' mask ')'],[],[],...
                false,'2',txt);
        end
        code = [code newline tab 'title("' char(getMsgText(app,getMsgId(app,'NumberofFilledMissingEntries'))) ': " + nnz(' mask '))'];
        markAsVariablesToBeCleared(app,app.OutputIndices);
    end

elseif isequal(app.CleanMethodDropDown.Value,'remove')
    mask = app.OutputIndices;
    if doTiledLayout
        needOutLocation = ~isequal(app.OutputTypeDropDown.Value,'replace') && app.PlotDataCheckBox.Value;
        [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLocation);
        a1 = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
        a2 = [app.OutputTable '.(' outIndex ')'];
        tab = '    ';
    else
        a1 = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
        if app.outputIsTable
            a2 = addDotIndexingToTableName(app,app.OutputTable);
        else
            a2 = app.OutputVector;
        end
        tab = '';
    end
    if app.outputIsTable && ~isempty(app.TimetableDimName) && ~app.inputIsRowTimes
        % Utilize the new timetable instead of indexing into
        % input row times
        x2 = [app.OutputTable '.' app.TimetableDimName];
    elseif ~isempty(x)
        x2 = [x '(~' mask ')'];
    else
        x2 = ['find(~' mask ')'];
    end
    % Generate setup script if needed
    doOtherRemoved = app.PlotOtherRemovedCheckBox.Visible && app.PlotOtherRemovedCheckBox.Value;
    mask2 = [];
    if hasMultipleDataVariables(app) && (doOtherRemoved || app.PlotMissingDataCheckBox.Value)
        % Generate per-variable mask
        mask = app.TempPlotIndices;
        markAsVariablesToBeCleared(app,mask);
        if ~isequal(app.StandardizeDropDown.Value,'nonstandard') || isempty(app.IndicatorEditField.Value)
            code = [code newline tab '% ' char(getMsgText(app,getMsgId(app,'GetDataLocations')))];
            code = [code newline tab mask ' = ismissing(' a1 ');'];
        elseif doTiledLayout
            % We have generated mask in generateScript, but need to index into it
            mask = [mask '(:,' outIndex ')'];
        end
        
        if doOtherRemoved
            mask2 = 'mask';
            code = [code newline tab mask2 ' = ' app.OutputIndices ' & ~' mask ';'];
            markAsVariablesToBeCleared(app,mask2);
        end
    end
    if doDiscretize        
        code = generateScriptConvertAndDiscretize(app,code,a2,doOtherRemoved,mask2,[],true);
    elseif ~doLinePlot
        [code,a1] = generateScriptConvert(app,code,a1);
    end

    % Plot cleaned data
    if app.PlotDataCheckBox.Value
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'PlotCleanedData')))];
        if doLinePlot
            code = generateScriptPlotCleanedData(app,code,x2,a2,tab);
        elseif doDiscretize
            code = generateScriptForHistogram(app,code,[],'catNames','counts',false,'1','CleanedData');
        else
            code = generateScriptForHistogram(app,code,[a1 '(~' app.OutputIndices ')'],[],[],true,'1','CleanedData');
        end
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end
    
    % Plot data removed by other variables
    if doOtherRemoved
        % This plot needs to go before the vertical lines so that it plots
        % with the appropriate limits when input data is not plotted
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plototherremoved')))];        
        if doLinePlot
            code = generateScriptForMarkerPlot(app,code,x,a1,mask2,'x',[],'"none"','OtherRemovedData',tab);
        elseif doDiscretize
            code = generateScriptForHistogram(app,code,[],'catNames','missingCounts',false,'"none"','OtherRemovedData');
        else
            code = generateScriptForHistogram(app,code,[a1 '(' mask2 ')'],[],[],true,'"none"','OtherRemovedData');
        end
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotMissingDataCheckBox.Value
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotremovedmissing')))];
        txt = getMsgId(app,'RemovedMissingEntries');
        if doLinePlot
            code = addVerticalLines(app,code,mask,x,char(getMsgText(app,txt)),['"Color",' app.MiddleGray ','],'',tab);
        elseif doDiscretize
            code = generateScriptForHistogram(app,code,[],'catNames',['[zeros(1,numel(catNames)-1) nnz(' mask ')]'],false,[],txt);
        else
            code = generateScriptForHistogram(app,code,[a1 '(' mask ')'],[],[],true,[],txt);
        end
        code = [code newline tab 'title("' char(getMsgText(app,getMsgId(app,'NumberofRemovedMissingEntries'))) ': " + nnz(' mask '))'];
    end

else % detect
    if doTiledLayout
        needOutLocation = ~isequal(app.OutputTypeDropDown.Value,'replace') && app.PlotMissingDataCheckBox.Value;
        [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLocation);
        a1 = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
        if isequal(app.OutputTypeDropDown.Value,'append')
            mask = [app.OutputTable '.(' outIndex '+' num2str(app.InputSize(2)) ')'];
        else %small table
            mask = [app.OutputIndices '.(' outIndex ')'];
        end
        tab = '    ';
    else
         a1 = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
        if app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')
            mask = addIndexingIntoAppendedVar(app,app.OutputTable);
        else
            mask = app.OutputIndices;
            if isequal(app.OutputTypeDropDown.Value,'smalltable')
                mask = addDotIndexingToTableName(app,mask);
            else
                mask = addSubscriptIndexingToTableName(app,mask);
            end
        end
        tab = '';
    end

    % Generate setup script if needed
    if doDiscretize
        code = generateScriptConvertAndDiscretize(app,code,a1,false,[],[],true);
    elseif ~doLinePlot
        [code,a1] = generateScriptConvert(app,code,a1);
    end

    % Plot input data
    if app.PlotDataCheckBox.Value
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'PlotInputData')))];
        if doLinePlot
            code = generateScriptPlotInputData(app,code,x,a1,tab);
        elseif doDiscretize
            code = generateScriptForHistogram(app,code,[],'catNames','counts',false,'6','InputData');
        else
            code = generateScriptForHistogram(app,code,a1,[],[],true,'6','InputData');
        end
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    % Plot missing data
    if app.PlotMissingDataCheckBox.Value
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotmissingentries')))];
        if doLinePlot
            code = addVerticalLines(app,code,mask,x,char(getMsgText(app,getMsgId(app,'MissingEntries'))),['Color=' app.MiddleGray ','],'',tab);
        elseif doDiscretize
            code = generateScriptForHistogram(app,code,[],'catNames',['[zeros(1,numel(catNames)-1) nnz(' mask ')]'], ...
                false,[],getMsgId(app,'MissingEntries'));
        else
            code = generateScriptForHistogram(app,code,[a1 '(' mask ')'],[],[],true,[],getMsgId(app,'MissingEntries'));
        end
        code = [code newline tab 'title("' char(getMsgText(app,getMsgId(app,'NumberofMissingEntries'))) ': " + nnz(' mask '))'];
    end
end

code = [code newline];
code = addHold(app,code,'off',didHoldOn,numPlots,tab);
code = addLegendAndAxesLabels(app,code,tab,doLinePlot);
% if only missing lines, need to set xaxis limits
if doLinePlot && numPlots == 1 && app.PlotMissingDataCheckBox.Value
    code = addXLimits(app,code,x,tab);
end
if doTiledLayout
    code = generateScriptEndTiledLayout(app,code);
end
if ~isAppWorkflow(app)
    % if we are in app mode, do not clear since we may want to
    % plot multiple variables with one call to generateScript
    code = addClear(app,code);
end
end

%% Helpers

function [code,dataName] = generateScriptConvert(app,code,dataName)
if ~isequal(app.SelectedVarType,"categorical")
    code = [code newline '% ' char(getMsgText(app,getMsgId(app,'ConvertToCat')))];
    if isequal(app.SelectedVarType,"char")
        % data must be converted to string first, then categorical
        dataName = ['string(' dataName ')'];
    end
    code = [code newline 'catVar = categorical(' dataName ');'];
    dataName = 'catVar';
    markAsVariablesToBeCleared(app,'catVar');
end
end

function code = generateScriptConvertAndDiscretize(app,code,data,doSortMask,maskName,maskIndex,doMissingCat)
code = [code newline '% ' char(getMsgText(app,getMsgId(app,'ConvertToCatAndSort')))];
if isequal(app.SelectedVarType,"char")
    % data must be converted to string first, then categorical
    data = ['string(' data ')'];
end
if doSortMask
    code = [code newline '[catVar,ind] = sort(categorical(' data '));'];
    code = [code newline 'missingCounts = countcats(catVar(' maskName '(ind'];
    if isempty(maskIndex)
        code = [code ')));'];
    else
        code = [code ',' num2str(maskIndex) ')));'];
    end
    markAsVariablesToBeCleared(app,'catVar','ind','missingCounts','catNames','groupedCounts','counts');
else
    code = [code newline 'catVar = sort(categorical(' data '));'];
    markAsVariablesToBeCleared(app,'catVar','catNames','counts','ind');
end
code = [code newline 'catNames = categories(catVar);'];
if app.SelectedVarNumUnique >= 60
    numCats = '20';
else
    numCats = '10';
end
code = [code newline '% ' char(getMsgText(app,getMsgId(app,'Discretize'),numCats))];
if doSortMask
    code = [code newline '[groupedCounts,~,ind] = groupsummary([countcats(catVar(:)) missingCounts(:)], ...'];
    code = [code newline '    (1:numel(catNames))'',' numCats ',"sum");'];
    code = [code newline 'counts = groupedCounts(:,1);'];
    code = [code newline 'missingCounts = groupedCounts(:,2);'];
else
    code = [code newline '[counts,~,ind] = groupsummary(countcats(catVar(:)),(1:numel(catNames))'',' numCats ',"sum");'];
end
code = [code newline 'ind = cumsum(ind);'];
code = [code newline 'catNames = strcat(catNames([0; ind(1:end-1)] + 1)," - ",catNames(ind));'];
if doMissingCat
    code = [code newline 'counts = [counts; 0];'];
    if doSortMask
        code = [code newline 'missingCounts = [missingCounts; 0];'];
    end
    code = [code newline 'catNames = [catNames; "Missing entries"];'];
end
end

function code = generateScriptForHistogram(app,code,inputCat,catNames,counts,doShowOthers,srsIdx,dispName)
code = [code newline 'histogram('];
if ~isempty(inputCat)
    code = [code inputCat];
else
    code = [code 'Categories=' catNames];
    code = matlab.internal.dataui.addCharToCode(code,[',BinCounts=' counts]);
end
if doShowOthers
    code = matlab.internal.dataui.addCharToCode(code,',ShowOthers="on"');
end
if isempty(srsIdx)
    % No SeriesIndex value for gray
    code = matlab.internal.dataui.addCharToCode(code,[',FaceColor=' app.MiddleGray]);
else
    code = matlab.internal.dataui.addCharToCode(code,[',SeriesIndex=' srsIdx]);
end
code = matlab.internal.dataui.addCharToCode(code,',FaceAlpha=1,');
code = addDisplayName(app,code,char(getMsgText(app,dispName)),false);
end

function code = generateScriptForMarkerPlot(app,code,x,y,mask,marker,markerSz,srsIdx,txt,tab)
if ~isempty(x)
    x = [x '(' mask ')'];
else
    x = ['find(' mask ')'];
end
code = [code newline tab 'plot(' x ',' y '(' mask '),"' marker '"'];
isindented = ~isempty(tab);
if ~isempty(markerSz)
    code = matlab.internal.dataui.addCharToCode(code,[',MarkerSize=' markerSz],isindented);
end
code = matlab.internal.dataui.addCharToCode(code,[',SeriesIndex=' srsIdx ','],isindented);
code = addDisplayName(app,code,char(getMsgText(app,txt)),isindented);
end