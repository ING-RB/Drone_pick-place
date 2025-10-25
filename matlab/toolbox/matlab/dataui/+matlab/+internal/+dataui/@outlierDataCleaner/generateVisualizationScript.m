function code = generateVisualizationScript(app)
% Generate the plot script for the Clean Outlier Data task

% Copyright 2021-2024 The MathWorks, Inc.

code = '';
if ~hasInputDataAndSamplePoints(app) || ~app.SupportsVisualization ||...
        (isequal(app.FindMethodDropDown.Value,'workspace') && ...
        isequal(app.OutlierLocationsWSDD.Value,app.SelectVariable))
    return;
end

resetVariablesToBeCleared(app);
doTableOutput = app.outputIsTable;
didHoldOn = false;
doHistogram = isequal(app.PlotTypeDropDown.Value,'histogram');
doTiledLayout = isnumeric(app.TableVarPlotDropDown.Value);
[lowTh,upTh,c] = getIndexedAdditionalOutputs(app,doTiledLayout);

if isequal(app.CleanMethodDropDown.Value,'fill')
    doFilled = app.PlotFilledCheckBox.Value && app.PlotFilledCheckBox.Visible;
    numPlots = sum([app.PlotCleanedDataCheckBox.Value app.PlotInputDataCheckBox.Value doFilled...
        app.PlotOutliersCheckBox.Value app.PlotThresholdsCheckBox.Value app.PlotCenterCheckBox.Value]);
    if numPlots == 0
        return;
    end
    tempVars = generateOptionalOutputNames(app,false);
    markAsVariablesToBeCleared(app,tempVars{:});
    code = addVisualizeResultsLine(app);

    % get all the variable names we will need    
    x1 = getSamplePointsVarNameForGeneratedScript(app);
    if doTiledLayout
        [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,true);
        a1 = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];        
        
        if isequal(app.OutputTypeDropDown.Value,'append')
            outIndex = [outIndex '+' num2str(app.InputSize(2))];
        end
        a2 = [app.OutputForTable '.(' outIndex ')'];
        mask = [app.OutputIndices '(:,' outIndex ')'];
        tab = '    ';
    else
        a1 = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
        if app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')
            a2 = addIndexingIntoAppendedVar(app,app.OutputForTable);
        elseif doTableOutput
            a2 = addDotIndexingToTableName(app,app.OutputForTable);
        else
            a2 = app.OutputForArray;
        end
        mask = addSubscriptIndexingToTableName(app,app.OutputIndices); 
        tab = '';
    end
    % generate script
    if doHistogram
        % find bin edges
        if app.PlotCleanedDataCheckBox.Value || app.PlotInputDataCheckBox.Value ||...
                app.PlotOutliersCheckBox.Value
            code = generateScriptBinEdges(app,code,a1,lowTh,upTh,tab);
        end
        % input and cleaned data are plotted in reverse order
        if app.PlotCleanedDataCheckBox.Value
            code = [code newline tab 'histogram(' a2 ','];
            code = matlab.internal.dataui.addCharToCode(code,'BinEdges=binEdges,',doTiledLayout);
            code = matlab.internal.dataui.addCharToCode(code,'SeriesIndex=1,',doTiledLayout);
            code = matlab.internal.dataui.addCharToCode(code,'FaceAlpha=1,',doTiledLayout);
            code = addDisplayName(app,code,char(getMsgText(app,'CleanedData')),doTiledLayout);
            [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
        end
        if app.PlotInputDataCheckBox.Value
            code = generateInputPlot(app,code,x1,a1,doHistogram,tab);
            [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
        end
    else
        if app.PlotInputDataCheckBox.Value
            code = generateInputPlot(app,code,x1,a1,doHistogram,tab);
            [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
        end
        if app.PlotCleanedDataCheckBox.Value
            code = generateScriptPlotCleanedData(app,code,x1,a2,tab);
            [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
        end
    end

    if app.PlotOutliersCheckBox.Value
        code = generateOutlierPlot(app,code,x1,a1,mask,[],doHistogram,tab);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if doFilled
        if ~isempty(x1)
            x2 = [x1 '(' mask ')'];
        else
            x2 = ['find(' mask ')'];
        end
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotfilledoutliers')))];
        code = [code newline tab 'plot(' x2 ',' a2 '(' mask '),"."'];
        code = matlab.internal.dataui.addCharToCode(code,',MarkerSize=12',doTiledLayout);
        code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex=2,',doTiledLayout);
        code = addDisplayName(app,code,char(getMsgText(app,getMsgId(app,'FilledOutliers'))),doTiledLayout);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotThresholdsCheckBox.Value
        if doHistogram
            code = generateScriptThresholdHistogram(app,code,lowTh,upTh,tab);
        else
            code = generateScriptPlotThresholds(app,code,x1,a1,lowTh,upTh,tab);
        end
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotCenterCheckBox.Value
        code = generatePlotCenter(app,code,x1,c,doHistogram,tab);
    end
    maskForTitle = mask;
elseif isequal(app.CleanMethodDropDown.Value,'remove')
    doCleaned = app.PlotCleanedDataCheckBox.Value && app.PlotCleanedDataCheckBox.Visible;
    doOtherRemoved = app.PlotOtherRemovedCheckBox.Value && app.PlotOtherRemovedCheckBox.Visible;
    numPlots = sum([app.PlotInputDataCheckBox.Value app.PlotOutliersCheckBox.Value ...
        app.PlotThresholdsCheckBox.Value app.PlotCenterCheckBox.Value doCleaned doOtherRemoved]);
    if numPlots == 0
        return;
    end

    if hasMultipleDataVariables(app)
        markAsVariablesToBeCleared(app,app.TempIndices)
    end
    tempVars = generateOptionalOutputNames(app,false);
    markAsVariablesToBeCleared(app,tempVars{:});

    code = addVisualizeResultsLine(app);
    % get all the variables we will need
    x = getSamplePointsVarNameForGeneratedScript(app);
    if doTiledLayout
        needOutputLoc = ~isequal(app.OutputTypeDropDown.Value,'replace') && doCleaned;
        [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutputLoc);
        a1 = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
        a2 = [app.OutputForTable '.(' outIndex ')'];
        mask = [app.TempIndices '(:,' outIndex ')'];
        tab = '    ';
    else
        a1 = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
        mask = app.OutputIndices;
        if doTableOutput
            % Note append is not supported with remove, so we can rely
            % on the output variable name
            a2 = addDotIndexingToTableName(app,app.OutputForTable);
            if hasMultipleDataVariables(app)
                mask = addSubscriptIndexingToTableName(app,app.TempIndices);
            end
        else
            a2 = app.OutputForArray;
        end
        tab = '';
    end
    maskForTitle = mask;
    
    % generate script
    if doHistogram && (app.PlotInputDataCheckBox.Value || app.PlotOutliersCheckBox.Value || doOtherRemoved)
        code = generateScriptBinEdges(app,code,a1,lowTh,upTh,tab);
    end

    if app.PlotInputDataCheckBox.Value
        code = generateInputPlot(app,code,x,a1,doHistogram,tab);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if doCleaned        
        if ~isempty(x)
            x21 = [x '(~' app.OutputIndices ')'];
        else
            x21 = ['find(~' app.OutputIndices ')'];
        end
        code = generateScriptPlotCleanedData(app,code,x21,a2,tab);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotOutliersCheckBox.Value
        code = generateOutlierPlot(app,code,x,a1,mask,'2',doHistogram,tab);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if doOtherRemoved
        code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plototherremoved')))];
        code = [code newline tab 'mask = ' app.OutputIndices ' & ~' mask ';'];
        mask = 'mask';
        if doHistogram
            code = [code newline tab 'histogram(' a1 '(' mask '),'];
            code = matlab.internal.dataui.addCharToCode(code,'BinEdges=binEdges,',doTiledLayout);
            code = matlab.internal.dataui.addCharToCode(code,['FaceColor=' app.MiddleGray ','],doTiledLayout);
            code = matlab.internal.dataui.addCharToCode(code,'FaceAlpha=1,',doTiledLayout);
        else
            if ~isempty(x)
                x2 = [x '(' mask ')'];
            else
                x2 = ['find(' mask ')'];
            end
            code = [code newline tab 'plot(' x2 ','];
            code = matlab.internal.dataui.addCharToCode(code,[a1 '(' mask ')'],doTiledLayout);
            code = matlab.internal.dataui.addCharToCode(code,',"x"',doTiledLayout);
            code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex="none",',doTiledLayout);
        end
        code = addDisplayName(app,code,char(getMsgText(app,'OtherRemovedData')),doTiledLayout);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
        markAsVariablesToBeCleared(app,mask);
    end

    if app.PlotThresholdsCheckBox.Value
        if doHistogram
            code = generateScriptThresholdHistogram(app,code,lowTh,upTh,tab);
        else
            code = generateScriptPlotThresholds(app,code,x,a1,lowTh,upTh,tab);
        end
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotCenterCheckBox.Value
        code = generatePlotCenter(app,code,x,c,doHistogram,tab);
    end

else % none (find only)
    numPlots = sum([app.PlotInputDataCheckBox.Value app.PlotOutliersCheckBox.Value ...
        app.PlotThresholdsCheckBox.Value app.PlotCenterCheckBox.Value]);
    if numPlots == 0
        return;
    end
    tempVars = generateOptionalOutputNames(app,false);
    markAsVariablesToBeCleared(app,tempVars{:});
    code = addVisualizeResultsLine(app);

    % get all the variables we will need
    x = getSamplePointsVarNameForGeneratedScript(app);
    if doTiledLayout
        [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,true);
        a = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
        if isequal(app.OutputTypeDropDown.Value,'append')
            mask = [app.OutputForTable '.(' outIndex '+' num2str(app.InputSize(2)) ')'];
        elseif isequal(app.OutputTypeDropDown.Value,'smalltable')
            mask = [app.OutputIndices '.(' outIndex ')'];
        end
        tab = '    ';
    else
        a = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
        if isequal(app.OutputTypeDropDown.Value,'append')
            mask = addIndexingIntoAppendedVar(app,app.OutputForTable);
        else
            mask = app.OutputIndices;
            if isequal(app.OutputTypeDropDown.Value,'smalltable')
                mask = addDotIndexingToTableName(app,mask);
            end % else 'vector'
        end
        tab = '';
    end
    maskForTitle = mask;

    % generate script
    if doHistogram && (app.PlotInputDataCheckBox.Value || app.PlotOutliersCheckBox.Value)
        code = generateScriptBinEdges(app,code,a,lowTh,upTh,tab);
    end

    if app.PlotInputDataCheckBox.Value
        code = generateInputPlot(app,code,x,a,doHistogram,tab);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotOutliersCheckBox.Value
        code = generateOutlierPlot(app,code,x,a,mask,'"none"',doHistogram,tab);
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotThresholdsCheckBox.Value
        if doHistogram
            code = generateScriptThresholdHistogram(app,code,lowTh,upTh,tab);
        else
            code = generateScriptPlotThresholds(app,code,x,a,lowTh,upTh,tab);
        end
        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
    end

    if app.PlotCenterCheckBox.Value
        code = generatePlotCenter(app,code,x,c,doHistogram,tab);
    end
end

code = [code newline];
code = addHold(app,code,'off',didHoldOn,numPlots,tab);
code = addTitle(app,code,maskForTitle,tab);
code = addLegendAndAxesLabels(app,code,tab,~doHistogram);
if doTiledLayout
    code = generateScriptEndTiledLayout(app,code);
end
if ~isAppWorkflow(app)
    % if we are in app mode, do not clear since we may want to
    % plot multiple variables with one call to generateScript
    code = addClear(app,code);
end
end

% Helpers
% -------------------------------------------------------------------------
function [lowTh,upTh,c] = getIndexedAdditionalOutputs(app,doTiledLayout)
lowTh = app.AdditionalOutputs{1};
upTh = app.AdditionalOutputs{2};
c = app.AdditionalOutputs{3};
if isequal(app.FindMethodDropDown.Value,"range")
    % Thresholds are either scalars or vectors. If thresholds are vectors,
    % need indexing. If scalar, use a hard-coded threshold value instead of
    % generating and indexing into an unecessary temp variable. Center not
    % supported, so no change needed
    doIndexLower = startsWith(app.LowerRangeEditField.Value,'[');
    doIndexUpper = startsWith(app.UpperRangeEditField.Value,'['); 
    if doIndexUpper || doIndexLower
        if doTiledLayout
            % Index with 'k' from generated loop
            idx = 'k';
        else
            % Index with location of the var we are plotting within
            % selected subtable
            useInputTable = isequal(app.DataVarSelectionTypeDropDown.Value,'all');
            ignoreAppend = true;
            [~,k] = addSubscriptIndexingToTableName(app,'',useInputTable,ignoreAppend);
            idx = num2str(k);
        end
    end
    if doIndexLower
        lowTh = [lowTh '(' idx ')'];
    else
        lowTh = app.LowerRangeEditField.Value;
    end
    if doIndexUpper
        upTh = [upTh '(' idx ')'];
    else
        upTh = app.UpperRangeEditField.Value;
    end
elseif doTiledLayout
    % Thresholds and center are tables, index with 'k' from generated loop
    lowTh = [lowTh '.(k)'];
    upTh = [upTh '.(k)'];
    c = [c '.(k)'];
else
    % Thresholds and center may be tables or scalars. Index as needed using
    % the table variable name
    lowTh = addDotIndexingToTableName(app,lowTh);
    upTh = addDotIndexingToTableName(app,upTh);
    c = addDotIndexingToTableName(app,c);
end
end

function code = generateInputPlot(app,code,x,y,doHistogram,tab)
if doHistogram
    isindented = ~isempty(tab);
    code = [code newline tab 'histogram(' y ','];
    code = matlab.internal.dataui.addCharToCode(code,'BinEdges=binEdges,',isindented);
    code = matlab.internal.dataui.addCharToCode(code,'SeriesIndex=6,',isindented);
    code = matlab.internal.dataui.addCharToCode(code,'FaceAlpha=1,',isindented);
    code = addDisplayName(app,code,char(getMsgText(app,'InputData')),isindented);
else
    code = generateScriptPlotInputData(app,code,x,y,tab);
end
end

function code = generateScriptBinEdges(app,code,y,lowTh,upTh,tab)
code = [code newline tab '[~,binEdges] = histcounts(' y ');'];
if ~isequal(app.FindMethodDropDown.Value,'workspace')
    % include thresholds so bins don't get split by the threshold lines
    code = [code newline tab 'binEdges = unique([binEdges ' lowTh ' ' upTh ']);'];
end % else thresholds not defined with OutlierLocations
code = [code newline tab 'binEdges = binEdges(isfinite(binEdges));'];
markAsVariablesToBeCleared(app,'binEdges');
end

function code = generateOutlierPlot(app,code,x,y,mask,srsIdx,doHistogram,tab)
code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotoutliers')))];
isindented = ~isempty(tab);
if doHistogram
    code = [code newline tab 'histogram(' y '(' mask '),'];
    code = matlab.internal.dataui.addCharToCode(code,'BinEdges=binEdges,',isindented);
    code = matlab.internal.dataui.addCharToCode(code,'SeriesIndex=2,',isindented);
    code = matlab.internal.dataui.addCharToCode(code,'FaceAlpha=1,',isindented);
else
    if ~isempty(x)
        x = [x '(' mask ')'];
    else
        x = ['find(' mask ')'];
    end
    code = [code newline tab 'plot(' x ',' y '(' mask ')'];
    code = matlab.internal.dataui.addCharToCode(code,',"x"',isindented);
    if isempty(srsIdx)
        code = matlab.internal.dataui.addCharToCode(code,[',Color=' app.MiddleGray ','],isindented);
    else
        code = matlab.internal.dataui.addCharToCode(code,[',SeriesIndex=' srsIdx ','],isindented);
    end
end
code = addDisplayName(app,code,char(getMsgText(app,getMsgId(app,'Outliers'))),isindented);
end

function code = generateScriptThresholdHistogram(app,code,lowTh,upTh,tab)
code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotoutlierthresholds')))];
code = setAxesLimitToDefault(app,code,'y');
code = [code newline tab 'plot([' lowTh ' ' lowTh ' missing ' upTh ' ' upTh '],'];
isindented = ~isempty(tab);
code = matlab.internal.dataui.addCharToCode(code,'[ylim missing ylim],',isindented);
code = matlab.internal.dataui.addCharToCode(code,'"--",',isindented);
code = matlab.internal.dataui.addCharToCode(code,'SeriesIndex="none",',isindented);
code = addDisplayName(app,code,char(getMsgText(app,getMsgId(app,'OutlierThresholds'))),isindented);
code = restoreAxesLimit(app,code,'y',tab);
end

function code = generateScriptPlotThresholds(app,code,x,a,lowTh,upTh,tab)
code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotoutlierthresholds')))];
findMethod = app.FindMethodDropDown.Value;
isindented = ~isempty(tab);
code = setAxesLimitToDefault(app,code,'x');
if ~(isequal(findMethod,'movmedian') || isequal(findMethod,'movmean'))
    code = [code newline tab 'plot([xlim missing xlim]'];
    code = matlab.internal.dataui.addCharToCode(code,[',[' lowTh ' ' lowTh ' missing ' upTh ' ' upTh ']'],isindented);
else
    if isempty(x)
        x = ['(1:numel(' a '))'''];
    else
        x = [x '(:)'];
    end
    code = [code newline tab 'plot([' x '; missing; ' x ']'];
    code = matlab.internal.dataui.addCharToCode(code,[',[' upTh '(:); missing; ' lowTh '(:)]'],isindented);
end
code = matlab.internal.dataui.addCharToCode(code,[',Color=' app.MiddleGray ','],isindented);
code = addDisplayName(app,code,char(getMsgText(app,getMsgId(app,'OutlierThresholds'))),isindented);
code = restoreAxesLimit(app,code,'x',tab);
end

function code = generatePlotCenter(app,code,x,c,doHistogram,tab)
code = [code newline newline tab '% ' char(getMsgText(app,getMsgId(app,'Plotoutliercenter')))];
isindented = ~isempty(tab);
if doHistogram
    code = [code newline tab 'plot([' c ',' c '],ylim,'];
    code = matlab.internal.dataui.addCharToCode(code,['Color=' app.MiddleGray],isindented);
else
    findMethod = app.FindMethodDropDown.Value;
    if ~(isequal(findMethod,'movmedian') || isequal(findMethod,'movmean'))
        code = [code newline tab 'plot(xlim,[' c ',' c ']'];
    else
        code = [code newline tab 'plot(' x addComma(app,x) c];
    end
    code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex="none"',isindented);
end
code = matlab.internal.dataui.addCharToCode(code,',LineWidth=2,',isindented);
code = addDisplayName(app,code,char(getMsgText(app,getMsgId(app,'OutlierCenter'))),isindented);
end

function code = addTitle(app,code,mask,tab)
if isequal(app.CleanMethodDropDown.Value,'none')
    titleMsg = char(getMsgText(app,getMsgId(app,'NumberofOutliers')));
else
    titleMsg = char(getMsgText(app,getMsgId(app,'NumberofOutliersCleaned')));
end
code = [code newline tab 'title("' titleMsg ': " + nnz(' mask '))'];
end