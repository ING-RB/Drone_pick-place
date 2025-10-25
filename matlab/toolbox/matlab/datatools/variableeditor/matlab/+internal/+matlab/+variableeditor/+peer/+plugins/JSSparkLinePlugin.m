classdef JSSparkLinePlugin < internal.matlab.variableeditor.peer.plugins.MetaDataPlugin 
    %JSSparkLinePlugin
    % This plugin computes spark lines per column

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Constant)
        DEFAULT_SPARKLINE_HEIGHT = 32;
        DEFAULT_SPARKLINE_WIDTH = 150; % Matches Sparkline.js
        DEFAULT_SPARKLINE_DATETIME_WIDTH = 200; % Matches Sparkline.js

        NUM_UNIQUE_INTS_FOR_HIST = 100;
        PERCENT_UNQIUE_INTS_FOR_HIST = 0.1;

        DATAPOINTS_PER_PIXEL = 3;
        ABSOLUTE_MAXIMUM_DATAPOINTS = 100000;
    end

    properties (Access=protected)
        SparkLines
        Statistics
        LastShowSparkLines (1,1) logical = false
        LastShowStatistics (1,1) logical = false

        SettingsRoot;
        StatNumelLimit (1,1) double = 500000;
    end

    properties (Access=protected, Transient)
        DataChangeListener
        TableMetaDataChangedListener
        ColumnMetaDataChangedListener
    end

    methods
        % Constructor inherits from SparkLinePlugin
        function this = JSSparkLinePlugin(viewModel)
            this@internal.matlab.variableeditor.peer.plugins.MetaDataPlugin(viewModel);
            this.SparkLines = dictionary(string.empty, struct);
            this.Statistics = dictionary(string.empty, struct);
            this.NAME = 'SERVER_JS_SPARKLINES';

            % NOTE: Do not set sparklines and stats initial state on
            % tableModelProps as it will cause re-renders. Wait for request
            % from client. (See handleEventFromClient 'initializeSparklines')
            this.DataChangeListener = addlistener(this.ViewModel, 'DataChange', @(e,d)this.handleDataChange);
            this.TableMetaDataChangedListener = addlistener(this.ViewModel, 'TableMetaDataChanged', @(e,d)this.handleTableMetaDataChange);
            this.ColumnMetaDataChangedListener = addlistener(this.ViewModel, 'ColumnMetaDataChanged', @(e,d)this.handleColumnMetaDataChange(d));

            this.ColumnMetaDataChangedListener.Enabled = false; % Only enable when showing spark lines
            this.DataChangeListener.Enabled = false; % Only enable when showing spark lines

            this.initStatSettings();
        end

        % This is called whenever metadata changes or is requested from
        % client. Compute ColumnWidth based on cell Content length.
        function updateColumnModelInformation(this, startCol, endCol)
            % CheckForDebugging
            this.checkForDebugging;

            internal.matlab.datatoolsservices.logDebug("variableeditor::jssparklineplugin", "updateColumnModelInformation(" + startCol + "," + endCol + ")");

            showSparkLines = this.ViewModel.getTableModelProperty('ShowSparkLines');
            if isempty(showSparkLines)
                showSparkLines = false;
            end
            showStatistics = this.ViewModel.getTableModelProperty('ShowStatistics');
            if isempty(showStatistics)
                showStatistics = false;
            end

            numTextElements = getTextElementCount(this.ViewModel.DataModel.Data);

            % Turn off sparklines and summary stats for tables that are too
            % large
            if (showSparkLines || showStatistics) && numTextElements > this.StatNumelLimit
                this.ViewModel.setTableModelProperty('ShowSparkLines', false);
                this.ViewModel.setTableModelProperty('ShowStatistics', false);
                showSparkLines = false;
                showStatistics = false;
                this.LastShowSparkLines = showSparkLines;
                this.LastShowStatistics = showStatistics;

                % Show user warning dialog
                showDialog = this.SettingsRoot.statistics.ShowMaxTextElementDialog.ActiveValue;

                if showDialog
                    msgString = sprintf(string(getString(message('MATLAB:codetools:variableeditor:StatsLimitExceeded', this.StatNumelLimit))));
                    changeLimitButtonPref = string(getString(message('MATLAB:codetools:variableeditor:ChangeStatsLimit')));
                    okButton = getString(message('MATLAB:codetools:variableeditor:DialogOK'));
                    
                    showConfirmationDialog(internal.matlab.datatoolsservices.DTDialogHandler.getInstance, msgString, 'Warning', 'Icon', 'warning', 'DialogType',...
                        'modal', 'DialogButtons', [changeLimitButtonPref, okButton], 'CallbackFcn', @shouldOpenPrefsDialogForVariables, ...
                        'SettingPath','matlab.desktop.variables.statistics', 'SettingVal', 'ShowMaxTextElementDialog');
                end
            end

            if ~isempty(showSparkLines) && ~isempty(showStatistics) && (showSparkLines || showStatistics)
                this.computeSparksAndStats(startCol, endCol, this.ViewModel.DataModel.Data, showSparkLines, showStatistics, this.ViewModel.getGroupedColumnCounts());
            end
        end

        function computeSparksAndStats(this, startCol, endCol, data, showSparkLines, showStatistics, gColCounts, totalColsRequested, viewColumnIndex, isNested)
            arguments
                this
                startCol
                endCol
                data
                showSparkLines
                showStatistics
                gColCounts;
                totalColsRequested = endCol;
                viewColumnIndex = startCol
                isNested = false;
            end
            inNestedTable = isNested;
            isTimeTable = strcmp(this.ViewModel.DataModel.getClassType, 'timetable');
            rowTimes = [];
            if isTimeTable
                rowTimes = data{:,1};
            end
            actualStartColumn = startCol;
            actualEndColumn = endCol;
            dataIdx = 1;
            if isa(this.ViewModel, 'internal.matlab.variableeditor.SpannedTableViewModel')
                nestedTableIndices = internal.matlab.variableeditor.SpannedTableViewModel.findNestedTableInfo(data);
                hasNested = any(nestedTableIndices > 1);
            else
                hasNested = false;
            end
            hasGrouped = ~isempty(gColCounts);
            if hasGrouped || hasNested
                if hasGrouped && hasNested
                    cummCount = (gColCounts + nestedTableIndices) -1;
                elseif hasNested
                    cummCount = nestedTableIndices;
                else
                    cummCount = gColCounts;
                end
                [~, actualStartColumn, actualEndColumn, dataIdx] = internal.matlab.variableeditor.SpannedTableViewModel.getColumnStartForRange(startCol, endCol, cummCount);
            end
            % viewColumnIndex keeps track of the index into the view. (Flattened indices)
            colsLen = endCol - startCol + 1;
            tableProps = data.Properties;
            varNames = tableProps.VariableNames;
            isTimeTableTimeColumn = isTimeTable && viewColumnIndex == 1;  
            rowDimData = internal.matlab.variableeditor.SpannedTableViewModel.getRowDimNames(data);
            isRowName = (actualStartColumn == 1 && ~isempty(rowDimData) && isNested);
            if isRowName
                rowDimensionName = tableProps.DimensionNames{1};
            end
            for columnIndex=actualStartColumn:actualEndColumn
                try
                    % gColCount has the number of sub-columns within the current column var.
                    colStr = string(viewColumnIndex);
                    gColCount = 1;
                    if ~isempty(gColCounts)
                        gColCount = gColCounts(columnIndex);
                        colStr = string(columnIndex);
                    end
                    if isRowName
                        varName = rowDimensionName;
                        varData = rowDimData;
                    else
                        varName =  varNames{columnIndex};
                        varData = data.(varName);
                    end
                    isNestedTable = istabular(varData);
                    supportsNestedTables = isNestedTable && hasNested;
                    if supportsNestedTables
                        nestedColsAvailable = nestedTableIndices(columnIndex) - dataIdx + 1; 
                        nestedEndCol = min(totalColsRequested-viewColumnIndex+1, nestedColsAvailable);
                        gcols = [];
                        [~, gcolumnCount, origSize, ~] = internal.matlab.variableeditor.SpannedTableViewModel.getTableFlatSize(varData);
                        % Cache grouped column indices after computing once
                        if gcolumnCount > origSize(2)
                            gColStartIndices = internal.matlab.variableeditor.TableViewModel.getColumnStartIndicies(varData,1,origSize(2));
                            gcols = diff(gColStartIndices);
                        end
                        
                        this.computeSparksAndStats(dataIdx, dataIdx+nestedEndCol-1, varData, showSparkLines, showStatistics, gcols, totalColsRequested, viewColumnIndex, true);
                        viewColumnIndex = viewColumnIndex + nestedEndCol;
                    else
                        if ~inNestedTable
                            isTimeTableTimeColumn = isTimeTable && columnIndex == 1;
                        end
                        if (isempty(this.SparkLines) || ~isKey(this.SparkLines, colStr)) && showSparkLines
                            columnWidth = this.ViewModel.getColumnModelProperty(viewColumnIndex, 'ColumnWidth');
                            if isempty(columnWidth)
                                if isdatetime(varData)
                                    columnWidth = this.DEFAULT_SPARKLINE_DATETIME_WIDTH;
                                else
                                    columnWidth = this.DEFAULT_SPARKLINE_WIDTH;
                                end
                            else
                                columnWidth = sum(columnWidth{:});
                                if columnWidth <= 0
                                    if isdatetime(varData)
                                        columnWidth = this.DEFAULT_SPARKLINE_DATETIME_WIDTH;
                                    else
                                        columnWidth = this.DEFAULT_SPARKLINE_WIDTH;
                                    end
                                end
                            end
                            [plotData] = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.makeVarSparkLine(data, varName, isTimeTable, isTimeTableTimeColumn, rowTimes, columnWidth);
                            this.SparkLines(colStr) = plotData;
                        end
    
                        if (isempty(this.Statistics) || ~isKey(this.Statistics, colStr)) && showStatistics
                            statsData = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.makeStatsData(data, varName);
                            this.Statistics(colStr) = statsData;
                        end
    
                        % For grouped columns, sparklines are computed once and
                        % paged in gradually Set ColumnModelProperty only for
                        % the column indices requested
                        if isKey(this.SparkLines, colStr)
                            sparkLineStruct = this.SparkLines(colStr);
                        else
                            sparkLineStruct = struct;
                        end
                        if isKey(this.Statistics, colStr)
                            stats = this.Statistics(colStr);
                            if (isfield(stats, 'GroupVarCount') && stats.GroupVarCount > 1)
                                if ~isfield(sparkLineStruct, "plots")
                                    sparkLineStruct.plots = [];
                                end
    
                                for group = 1:length(stats.stats)
                                    if length(sparkLineStruct.plots) < group
                                        sparkLineStruct.plots{group} = struct;
                                    end
    
                                    sparkLineStruct.plots{group}.stats = stats.stats{group};
                                end
                            else
                                sparkLineStruct.stats = stats;
                            end
                        else
                            sparkLineStruct.stats = struct;
                        end
    
                        if (isfield(sparkLineStruct, 'GroupVarCount') && sparkLineStruct.GroupVarCount > 1)
                            if isNestedTable && ~hasNested
                                this.ViewModel.setColumnModelProperty(viewColumnIndex, 'SparkLine', sparkLineStruct, false);
                                viewColumnIndex = viewColumnIndex + 1;
                            else
                                sparkLineStruct = sparkLineStruct.plots;
                                colsAvailable = min(gColCount-dataIdx+1, colsLen);
                                % Use dataIdx, we could be paging in from the middle of a grouped column on to a flat variable
                                for i=dataIdx:dataIdx+colsAvailable-1
                                    this.ViewModel.setColumnModelProperty(viewColumnIndex, 'SparkLine', sparkLineStruct{i}, false);
                                    viewColumnIndex = viewColumnIndex + 1;
                                end
                            end
                        else
                            this.ViewModel.setColumnModelProperty(viewColumnIndex, 'SparkLine', sparkLineStruct, false);
                            viewColumnIndex = viewColumnIndex + 1;
                        end
                    end
                catch sparklineError
                    internal.matlab.datatoolsservices.logDebug("variableeditor::jssparklineplugin::computeSparksAndStats", "Error varName=" + varName + " error:" + sparklineError.message);
                    this.ViewModel.setColumnModelProperty(viewColumnIndex, 'SparkLine', struct, false);
                    viewColumnIndex = viewColumnIndex + 1;
                end
            end
        end

        % Handles peerEvents on the viewModel. If eventType ==
        % initializeSparklines, we read from settings and initialize
        % tableModelProps. 
        function handled = handleEventFromClient(this, ed)
            handled = false;
            if isfield(ed, 'data') && isfield(ed.data,'type')
                if strcmp(ed.data.type, 'initializeSparklines')
                    showSparklines = ed.data.isSparklinesOn;
                    showStats = ed.data.isSummaryStatsOn;
                    % Setting tableModelProps will trigger a sparkine re-rendering
                    this.ViewModel.setTableModelProperties('ShowSparkLines', showSparklines, 'ShowStatistics', showStats);
                    handled = true;
                end
            end
        end

        % Called on cleanup.  Make sure to delete listeners and figure
        function delete(this)
            delete(this.DataChangeListener);
        end
    end


    methods (Access=protected)

        function handleDataChange(this)
            this.SparkLines = dictionary(string.empty, struct);
            this.Statistics = dictionary(string.empty, struct);
            this.rerenderSparkLines();
        end

        % Handle meta data changes on the table.  If the ShowSparkLines
        % property has changed, then react to it, otherwise noop
        function handleTableMetaDataChange(this)
            showSparkLines = this.ViewModel.getTableModelProperty('ShowSparkLines');
            showStatistics = this.ViewModel.getTableModelProperty('ShowStatistics');
            if ~isempty(showSparkLines) && ~isempty(showStatistics)
                if this.LastShowSparkLines ~= showSparkLines || this.LastShowStatistics ~= showStatistics
                    this.LastShowSparkLines = showSparkLines;
                    this.LastShowStatistics = showStatistics;
                    if showSparkLines || showStatistics
                        this.rerenderSparkLines();
                    end
                end
                this.ColumnMetaDataChangedListener.Enabled = showSparkLines || showStatistics;
                this.DataChangeListener.Enabled = showSparkLines || showStatistics;
            end
        end

        function handleColumnMetaDataChange(this, ed)
            if ~isempty(ed) && any(strcmp(ed.Key, 'ColumnWidth'))
                column = ed.Column;
                if ~isempty(column)
                    colStr = string(num2str(column));
                    if isKey(this.SparkLines, colStr)
                        this.SparkLines = remove(this.SparkLines, colStr);
                    end
                    this.updateColumnModelInformation(column, column);
                end
            end
        end

        % Handler for data change and table model property changes
        function rerenderSparkLines(this)
            startCol = this.ViewModel.ViewportStartColumn;
            endCol = this.ViewModel.ViewportEndColumn;

            s = this.ViewModel.getTabularDataSize;
            startCol = min(max(1,startCol), s(2));
            endCol = min(s(2), endCol);

            if (startCol > 0 & endCol > 0)
                this.updateColumnModelInformation(startCol, endCol);
            end

            metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            % Invalidate non-viewport cache by sending column information
            % as entire size.
            metaDataEvent.Column = 1:s(2);
            this.ViewModel.notify('ColumnMetaDataChanged', metaDataEvent);
        end

    
        function initStatSettings(this)
            if isempty(this.SettingsRoot)
                s = settings;
                this.SettingsRoot = s.matlab.desktop.variables;
            end
            this.StatNumelLimit = this.SettingsRoot.statistics.TextElementLimit.ActiveValue;
        end
    end

    methods(Static)
        function [statsData] = makeStatsData(inputTable, tableVarName)
            yData = inputTable.(tableVarName);

            if isvector(yData) || ischar(yData)
                plotType = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.getPlotType(yData);
                statsData = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.generateStatsData(yData, plotType);
            else
                statsData.GroupVarCount = width(yData);
                plotType = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.getPlotType(yData);
                for i=1:width(yData)
                    if (istabular(yData))
                        y = yData{:,i};                        
                        % Get plot type of y
                        plotType = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.getPlotType(y);
                    else
                        y = yData(:,i);
                    end
                    if ~isempty(plotType)
                        statsData.stats{i} = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.generateStatsData(y, plotType);
                    else
                        s = struct;
                        s.numMissing = string(sum(ismissing(y), 'all'));
                        s.type = string(internal.matlab.datatoolsservices.FormatDataUtils.getClassString(y));
                        statsData.stats{i} = s;
                    end
                end
            end


        end

        function [plotData] = makeVarSparkLine(inputTable, tableVarName, isTimeTable, isTimeTableTimeColumn, rowTimes, plotWidth)
            arguments
                inputTable
                tableVarName
                isTimeTable = false
                isTimeTableTimeColumn = false
                rowTimes = []
                plotWidth = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.DEFAULT_SPARKLINE_WIDTH
            end
            yData = inputTable.(tableVarName);
            xData = 1:height(yData);
            xLabel = inputTable.Properties.DimensionNames{1};
            yLabel = tableVarName;

            plotData = struct;
            plotType = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.getPlotType(yData);

            if isTimeTable
                if ~isTimeTableTimeColumn
                    xData = rowTimes;
                    xLabel = inputTable.Properties.VariableNames{1};
                else
                    xData = 1:length(yData);
                end
            elseif isnumeric(yData) && ~isreal(yData)
                xLabel = getString(message('MATLAB:codetools:variableeditor:Real'));
                yLabel = getString(message('MATLAB:codetools:variableeditor:Imaginary'));
                plotType = "plot";
            end

            if isvector(yData) || ischar(yData)
                if ~isempty(plotType)
                    plotData = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.generatePlotData(xData, yData, plotWidth, plotType);
                    plotData.GroupVarCount = 1;

                    plotData.yLabel = yLabel;
                    plotData.xLabel = xLabel;
                else
                    plotData.stats = struct;
                    plotData.stats.numMissing = string(sum(ismissing(yData), 'all'));
                    plotData.stats.type = string(internal.matlab.datatoolsservices.FormatDataUtils.getClassString(yData));
                end
            else
                plotData.GroupVarCount = width(yData);
                % Only get the plot type once, so that all plots in
                % the group are the same kind of plot
                plotType = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.getPlotType(yData);
                for i=1:width(yData)
                    if (istabular(yData))
                        y = yData{:,i};
                        % Get plotType of y
                        plotType = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.getPlotType(y);
                    else
                        y = yData(:,i);
                    end
                    if ~isempty(plotType)
                        p = internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.generatePlotData(xData, y, plotWidth, plotType);
                        if (~p.isLinear)
                            p.categories = string(p.categories);
                        end
                        p.yLabel = yLabel + "(:," + i + ")";
                        p.xLabel = xLabel;

                        plotData.plots{i} = p;
                    else
                        pd = struct;
                        pd.stats = struct;
                        pd.stats.numMissing = string(sum(ismissing(y), 'all'));
                        pd.stats.type = string(internal.matlab.datatoolsservices.FormatDataUtils.getClassString(y));
                        plotData.plots{i} = pd;
                    end
                end
            end

        end

        function plotType = getPlotType(yData)
            plotType = string.empty;

            if (isnumeric(yData) && ~isenum(yData)) || isduration(yData) || isdatetime(yData) || iscalendarduration(yData)
                if ~isduration(yData) && ~isdatetime(yData)
                    plotType = "plot";
                    try
                        dataSize = length(yData);
                        allIntValues = all(isequaln(floor(yData), yData), 'all');
                        numUnique = length(yData);
                        if (allIntValues)
                            % Only compute this if al ints, this is
                            % expensive
                            numUnique = length(unique(yData));
                        end
                        if (allIntValues && ...
                                (numUnique < internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.NUM_UNIQUE_INTS_FOR_HIST) || ...
                                numUnique <= (internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.PERCENT_UNQIUE_INTS_FOR_HIST & dataSize))
                            plotType = 'strhistogram';
                        end
                    catch
                        % Some numeric datatypes may not support unique
                        % like the half datastype. leave these as plot type
                    end
                else
                    plotType = "plot";
                end
            elseif isstring(yData) | iscellstr(yData) | ischar(yData) | iscategorical(yData) | islogical(yData) | isenum(yData) | all(ismissing(yData),'all')
                plotType = "strhistogram";
            end
        end

        function [stats] = generateStatsData(yData, plotType)
            if strcmp(plotType, "strhistogram") | strcmp(plotType, "histogram")
                stats = matlab.internal.datatoolsservices.getSummaryStats(yData, "categorical");
            else
                stats = matlab.internal.datatoolsservices.getSummaryStats(yData, "numeric");
            end
        end

        function [plotData] = generatePlotData(xData, yData, plotWidth, plotType)
            arguments
                xData
                yData
                plotWidth
                plotType (1,1) string
            end

            plotData = struct;
            plotData.type = plotType; % Keep this here for non-strhistogram, non-histogram, and non-plot types

            if strcmp(plotData.type, "strhistogram") | strcmp(plotData.type, "histogram")
                [cats, counts] = internal.matlab.variableeditor.peer.plugins.PrepHistDataForPlotting(yData, plotWidth);
                plotData.isLinear = false;
                plotData.categories = cats;
                plotData.categoryCounts = counts;
                % plotData = internal.matlab.variableeditor.peer.plugins.GenerateHistogramData(yData, plotWidth);
                % plotData.type = plotType; % Need to reassign it
            elseif strcmp(plotData.type, "plot")
                numDataPoints = min(plotWidth * internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.DATAPOINTS_PER_PIXEL, ...
                    internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.ABSOLUTE_MAXIMUM_DATAPOINTS);
                plotData.isLinear = true;
                [x, y, displayData, xDisplayData] = thinDataForSparklines(xData, yData, numDataPoints);
                plotData.x = x;
                plotData.y = y;
                if ~isempty(displayData)
                    plotData.displayData = displayData;
                end
                if ~isempty(xDisplayData)
                    plotData.xDisplayData = xDisplayData;
                end
            end
        end
    end

    methods(Static, Access={?matlab.unittest.TestCase})
        function [cats, counts]  = callPrepHistDataForPlotting(yData, plotWidth)
            [cats, counts]  = internal.matlab.variableeditor.peer.plugins.PrepHistDataForPlotting(yData, plotWidth);
        end

        function [x, y, displayData, xDisplayData] = callThinDataForSparklines(xData, yData, maxElements)
            arguments
                xData (:,1)
                yData (:,1)
                maxElements (1,1) double = 10000
            end

            [x, y, displayData, xDisplayData] = thinDataForSparklines(xData, yData, maxElements);
        end
    end

    methods(Static, Hidden)
        function ids = getSetDebugMode(mode)
            persistent isDebugSet;

            if nargin > 0
                isDebugSet = mode;
            end

            if isempty(isDebugSet)
                isDebugSet = false;
            end

            ids = isDebugSet;
        end
    end

    methods(Access=protected)
        function checkForDebugging(this)
            % Debug
            if internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin.getSetDebugMode
                w = warning("off");
                s = struct(this.ViewModel);
                for i=1:length(s.Provider.Manager.Documents)
                    s.Provider.Manager.Documents(i).IgnoreScopeChange = true;
                end
                warning(w);
            end
        end
    end
end

function [x, y, displayData, xDisplayData] = thinDataForSparklines(xData, yData, maxElements)
arguments
    xData (:,1)
    yData (:,1)
    maxElements (1,1) double = 10000
end

h = height(yData);
x = 1:h;
y = yData;

displayData = [];
xDisplayData = [];

[y, x, xInd] = matlab.internal.datatoolsservices.thinDataForPlotting(yData, "XData", xData, "MaxElements", maxElements, "Method", "minMax");

if isduration(yData) || isdatetime(yData) || iscalendarduration(yData)
    displayData = string(yData(xInd));
end

% Make sure timestamps are laid out correctly
if isduration(xData) || isdatetime(xData) || iscalendarduration(xData)
    xDisplayData = string(xData(xInd));
end
end



function shouldOpenPrefsDialogForVariables(response)
    if (response.response == 1)
        preferences Variables;
    end
end

function tec = getTextElementCount(t)
    arguments
        t {mustBeA(t, ["table", "timetable"])}
    end

    numRows = height(t);
    varTypes = t.Properties.VariableTypes;
    
    cellColumns = varTypes == "cell";
    stringColumns = varTypes == "string";
    categoricalColumns = varTypes == "categorical";

    cellstrColCount = sum(arrayfun(@(v)iscellstr(t.(string(v))), t.Properties.VariableNames(cellColumns)));
    categoricalCount = sum(arrayfun(@(v)length(categories(t.(string(v)))), t.Properties.VariableNames(categoricalColumns)));

    tec = (sum(stringColumns) + cellstrColCount) * numRows + categoricalCount;
end