classdef SearchAction < internal.matlab.variableeditor.VEAction
    %SearchAction
    %       searches in the current variable

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'SearchAction'
        SearchChannelPrefix = "/VE/search/";

        FirstMatchMaxColumns = 100;
        FirstMatchMaxRows = 10000;

        FirstMatchMaxDataSize = internal.matlab.variableeditor.Actions.SearchAction.FirstMatchMaxColumns * internal.matlab.variableeditor.Actions.SearchAction.FirstMatchMaxRows;
    end

    properties (Access=protected)
        BackgroundQueue = {}
    end

    methods
        function this = SearchAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.SearchAction.ActionType;
            props.Enabled = false;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.Search;
            this.BackgroundQueue = {};
            this.Enabled = false;
        end

        % Main Callback Method
        function [matchedBlocks, totalMatches, actionsInitiated] = Search(this, searchInfo, executeInThreadpool)
            arguments
                this (1,1) internal.matlab.variableeditor.Actions.SearchAction
                searchInfo struct {mustBeScalarOrEmpty} = struct.empty
                executeInThreadpool (1,1) logical = true
            end

            matchedBlocks = [];
            totalMatches = 0;
            actionsInitiated = string.empty;


            % Get the focused document
            focusedDoc = this.veManager.FocusedDocument;
            vm = focusedDoc.ViewModel;
            
            if ~isa(vm, 'internal.matlab.variableeditor.peer.RemoteArrayViewModel')
                return;
            end

            currNumericFormat = vm.DisplayFormatProvider.NumDisplayFormat;

            % Set Feature Flag to global state if not already on
            if ~vm.getProperty('ShowSearchLintbars')
                vm.setProperty('ShowSearchLintbars', internal.matlab.variableeditor.Actions.SearchAction.EnableLintbar);
            end

            % Search results are sent via pub/sub, create unique channel
            % per document
            channel = strcat(internal.matlab.variableeditor.Actions.SearchAction.SearchChannelPrefix,focusedDoc.DocID);

            internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::channel", channel);

            % The Toolstrip/Context menu actions fire an open message, we
            % need to relay this to the client-side action
            if (isempty(searchInfo) || isfield(searchInfo, 'open'))
                sendMessage(channel, 'open')
                actionsInitiated = "open";
                internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::open", channel);
                return;
            end

            % The Toolstrip/Context menu actions fire an open message, we
            % need to relay this to the client-side action
            if (isfield(searchInfo, 'bindKeys'))
                sendMessage(channel, 'bindKeys')
                actionsInitiated = "bindKeys";
                internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::bindKeys", channel);
                return;
            end

            % Cancel and currently running futures, if we're either closing
            % or running another search, there is no need to have the
            % current futures continue running
            this.stopAllFutures;

            % If the client-side dialog closes this let's us exit after
            % canceling any currently running futures
            if (isfield(searchInfo, 'close'))
                % Only need to stop current futures and return
                internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::close", channel);
                return;
            end

            if isfield (searchInfo, 'SearchText')
                searchText = searchInfo.SearchText;
            else
                searchText = "";
            end

            if isdatetime(searchText) && isnat(searchText)
                searchText = "NaT";
            end

            if isnumeric(searchText) && isnan(searchText)
                searchText = "NaN";
            end

            if ~isfield(searchInfo, 'IgnoreCase')
                searchInfo.IgnoreCase = true;
            end
            if ~isfield(searchInfo, 'WholeWord')
                searchInfo.WholeWord = false;
            end
            if ~isfield(searchInfo, 'Regex')
                searchInfo.Regex = false;
            end
            if ~isfield(searchInfo, 'FindInSelection')
                searchInfo.FindInSelection = false;
            end

            if exist('struct2text', 'file')
                internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::search", struct2text(searchInfo));
            end

            selectedColIntervals = vm.SelectedColumnIntervals;
            selectedRowIntervals = vm.SelectedRowIntervals;

            s = vm.getSize();

            fullData = vm.DataModel.Data;
            dataIsStruct = isstruct(fullData) && isscalar(fullData);

            if ~searchInfo.FindInSelection || (isempty(selectedRowIntervals) && ~dataIsStruct)
                selectedRowIntervals = [1 s(1)];
            end

            if ~searchInfo.FindInSelection || (isempty(selectedColIntervals) && ~dataIsStruct)
                selectedColIntervals = [1 s(2)];
            end

            if dataIsStruct && isequal(selectedRowIntervals, [1,1]) % Default selection
                selectedRowIntervals = [];
            end
            
            % For structs, get the selected fields
            if dataIsStruct
                structData = struct;
                structData.data = fullData;
                structData.selectedFields = string.empty;
                structData.varName = vm.DataModel.Name;
                if ~isempty(selectedRowIntervals)
                    sf = vm.getSelectedFields();
                    structData.selectedFields = sf;
                end
                fullData = structData;
            end

            % Search all cells if only one cell is selected
            if height(selectedRowIntervals) == 1 && height(selectedColIntervals) == 1 ...
                && (selectedRowIntervals(1) == selectedRowIntervals(2)) ...
                && (selectedColIntervals(1) == selectedColIntervals(2))
                selectedRowIntervals = [1 s(1)];
                selectedColIntervals = [1 s(2)];
            end

            % Adjust row and columns selection in case inf grid is being
            % used
            for ri = 1:height(selectedRowIntervals)
                % Account for inifinite grid
                selectedRowIntervals(ri,2) = min(s(1), selectedRowIntervals(ri,2));
            end

            for ci = 1:height(selectedColIntervals)
                % Account for inifinite grid
                selectedColIntervals(ci,2) = min(s(2), selectedColIntervals(ci,2));
            end

            if isa(vm, 'internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel')
                fullData = vm.convertObjectArrayToCell(fullData, vm.DataModel.getProperties());
            end

            % If the data total search area is larger than FirstMatchMaxDataSize
            % Do an initial pass of the data first to provide some "fast"
            % results to the user
            doFirstMatch = ~dataIsStruct && (height(fullData) * width(fullData) > internal.matlab.variableeditor.Actions.SearchAction.FirstMatchMaxDataSize) || ...
                    (executeInThreadpool && ~this.isThreadpoolStarted);

            % Run subset of data first if it's large
            if (doFirstMatch)
                isPartial = (height(fullData) * width(fullData) > internal.matlab.variableeditor.Actions.SearchAction.FirstMatchMaxDataSize);
                % Run first match
                actionsInitiated(end+1) = "firstSeach";
                if (this.isThreadpoolStarted)
                    actionsInitiated(end+1) = "backgroundThread";
                    executeInMainThread = false;
                    % Execute in background threadpool
                    try
                        pool = matlab.internal.threadPool();
                        f = parfeval(pool, @searchAndSend, 2, channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, isPartial, currNumericFormat, ~dataIsStruct);

                        afterEach(f, @logErrors, 0, "PassFuture", true);
                        afterEach(f, @this.cleanupQueue, 0, "PassFuture", true);

                        % If the future fails try running in matn
                        % threadpool
                        afterEach(f, @(f)runInMainThreadIfError(f, channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, isPartial, currNumericFormat, dataIsStruct, this, vm), 0, "PassFuture", true);

                        this.BackgroundQueue{end+1} = f;
                    catch e
                        internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::error", "e1: " + e.message);
                        executeInMainThread = true;
                    end

                    if executeInMainThread
                        try
                            actionsInitiated(end+1) = "mainThread";
                            actionsInitiated(end+1) = "fallback";
                            % Execute on main MATLAB thread
                            [matchedBlocks, totalMatches] = searchAndSend(channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, isPartial, currNumericFormat, ~dataIsStruct);
                            if dataIsStruct
                                this.expandAndSendStructMatches(channel, vm, matchedBlocks, totalMatches, selectedRowIntervals, selectedColIntervals, searchText, searchInfo);
                            end
                        catch ME
                            internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::error", "e2: " + ME.message);
                        end
                    end
                else
                    try
                        % Execute on main MATLAB thread
                        [matchedBlocks, totalMatches] = searchAndSend(channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, isPartial, currNumericFormat, ~dataIsStruct);
                        if dataIsStruct
                            this.expandAndSendStructMatches(channel, vm, matchedBlocks, totalMatches, selectedRowIntervals, selectedColIntervals, searchText, searchInfo);
                        end
                        actionsInitiated(end+1) = "mainThread";
                    catch ME
                        internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::error", "e3: " + ME.message);
                    end
                end
            end

            if (executeInThreadpool)
                % Dispatch data search and send to background threadpool
                actionsInitiated(end+1) = "fullSearch";
                actionsInitiated(end+1) = "backgroundThread";
                executeInMainThread = false;
                try
                    pool = matlab.internal.threadPool();
                    f = parfeval(pool, @searchAndSend, 2, channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, false, currNumericFormat, ~dataIsStruct);

                    afterEach(f, @logErrors, 0, "PassFuture", true);
                    afterEach(f, @this.cleanupQueue, 0, "PassFuture", true);

                    % If the future fails try running in matn
                    % threadpool
                    afterEach(f, @(f)runInMainThreadIfError(f, channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, false, currNumericFormat, dataIsStruct, this, vm), 0, "PassFuture", true);

                    this.BackgroundQueue{end+1} = f;
                catch e
                    internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::error", "e4: " + e.message);
                    executeInMainThread = true;
                end

                if executeInMainThread
                    try
                        actionsInitiated(end+1) = "mainThread";
                        actionsInitiated(end+1) = "fallback";
                        [matchedBlocks, totalMatches] = searchAndSend(channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, false, currNumericFormat, ~dataIsStruct);
                        if dataIsStruct
                            this.expandAndSendStructMatches(channel, vm, matchedBlocks, totalMatches, selectedRowIntervals, selectedColIntervals, searchText, searchInfo);
                        end
                    catch ME
                        internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::error", "e5: " + ME.message);
                    end
                end
            else
                try
                    actionsInitiated(end+1) = "fullSearch";
                    actionsInitiated(end+1) = "mainThread";
                    [matchedBlocks, totalMatches] = searchAndSend(channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchInfo, false, currNumericFormat, ~dataIsStruct);
                    if dataIsStruct
                        this.expandAndSendStructMatches(channel, vm, matchedBlocks, totalMatches, selectedRowIntervals, selectedColIntervals, searchText, searchInfo);
                    end
                catch ME
                    internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::error", "e6: " + ME.message);
                end
            end

            internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::search::actions", join(actionsInitiated, ","));
        end

        function  UpdateActionState(this)
            this.checkForDebugging();
            if ~isempty(this.veManager)
                focusedDoc = this.veManager.FocusedDocument;
                if ~isempty(focusedDoc)
                    vm = focusedDoc.ViewModel;
                    this.Enabled = isa(vm, 'internal.matlab.variableeditor.peer.RemoteArrayViewModel') && ~isa(vm.DataModel.Data, 'dataset');
                    return;
                end
            end
            this.Enabled = false;
        end

        function expandAndSendStructMatches(this, channel, vm, matchBlocks, totalMatches, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions)
            % Struct matches are returned relative to a fully expanded tree
            % We need to only expand the tree to where matches exist and
            % the offset the match results relative to those matches
            dataSize = vm.getSize();
            matches = zeros(dataSize(1), dataSize(2));
            if (totalMatches > 0)
                % Make sure all matches are expanded
                modifiedMatchIDs = internal.matlab.variableeditor.VEUtils.getCustomDelimitedRowIdVersion(matchBlocks.matchIDs);

                vm.expandFields(modifiedMatchIDs);
                % If all expandable fields are expanded, set IsFullyExpanded to true
                allExpandableFields = vm.fetchAllExpandableFieldNames(vm.DataModel.Data, vm.DataModel.Name, string.empty, 0, true);
                if all(ismember(allExpandableFields, vm.ExpansionList))
                    vm.setExpandedState();
                end
                
                [r,c] = find(matchBlocks.matches == 1);
                r = unique(r);

                rowIDs = vm.getFieldRows(modifiedMatchIDs);
                matches(rowIDs,1:2) =  matchBlocks.matches(r,:);
            end


            matchBlock = struct;
            matchBlock.startRow = 1;
            matchBlock.endRow = height(matches);
            matchBlock.startColumn = 1;
            matchBlock.endColumn = dataSize(2);
            matchBlock.matches = matches;
            matchBlock.dataIsStruct = true;

            matchBlocks = matchBlock;

            sendMatches(channel, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, matchBlocks, totalMatches, false);
        end

        function goToMatch(this, index)
            arguments
                this
                index (1,1) {mustPositiveNumericOrIn(index, ["next", "previous"])}
            end

            focusedDoc = this.veManager.FocusedDocument;
            vm = focusedDoc.ViewModel;
            
            if ~isa(vm, 'internal.matlab.variableeditor.peer.RemoteArrayViewModel')
                return;
            end

            % Search results are sent via pub/sub, create unique channel
            % per document
            channel = strcat(internal.matlab.variableeditor.Actions.SearchAction.SearchChannelPrefix,focusedDoc.DocID);

            sendMessage(channel, 'goToMatch', index);
        end
    end

    methods(Access=protected)
        function checkForDebugging(this)
            % Debug
            if internal.matlab.variableeditor.Actions.SearchAction.getSetDebugMode
                for i=1:length(this.veManager.Documents)
                    this.veManager.Documents(i).IgnoreScopeChange = true;
                end
            end
        end

        function stopAllFutures(this)
            % Stop all currently running background searchs
            for i=1:length(this.BackgroundQueue)
                try
                    f = this.BackgroundQueue{i};
                    f.cancel();
                catch
                    % Do nothing if error
                end
            end
            this.BackgroundQueue = {};
        end

        function cleanupQueue(this, f)
            % Removes the passed in future from the background queue
            for i=1:length(this.BackgroundQueue)
                if this.BackgroundQueue{i} == f
                    this.BackgroundQueue{i} = [];
                    break;
                end
            end
        end
    end

    methods(Static)
        function [matchBlocks, totalMatches] = StringSearch(data, pat, NVPairs)
            % Public method to run a string search.  Used for
            % testing purposes.
            arguments
                data
                pat (:,1) string
                NVPairs.IgnoreCase (1,1) logical = true
                NVPairs.WholeWord (1,1) logical = false
                NVPairs.Regex (1,1) logical = false
                NVPairs.SelectedRowIntervals = [1 height(data)]
                NVPairs.SelectedColumnIntervals = [1 width(data)];
                NVPairs.UseNumericDisplay (1,1) logical = false
                NVPairs.NumericFormat (1,1) string = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat()
            end

            [matchBlocks, totalMatches] = doTextSearch(data, NVPairs.SelectedRowIntervals, NVPairs.SelectedColumnIntervals, pat, NVPairs, false, NVPairs.UseNumericDisplay, NVPairs.NumericFormat);
        end

        function [backgrounPoolIsRunning] = isThreadpoolStarted(whichPool)
            % Returns true if the background thread pool is started
            arguments
                whichPool (1,1) parallel.internal.pool.PoolApiTag = parallel.internal.pool.PoolApiTag.Internal
            end
                
            % TODO:  revisit when a new API is available
            manager = parallel.internal.pool.PoolManager.getInstance;
            backgrounPoolIsRunning = ~isempty(getAllPools(manager, whichPool));
        end

        function isLintbarEnabled = EnableLintbar(enabled)
            arguments
                enabled logical {mustBeScalarOrEmpty} = logical.empty
            end

            persistent LintBarEnabled;
            if isempty(LintBarEnabled)
                LintBarEnabled = false;
            end

            if ~isempty(enabled)
                LintBarEnabled = enabled;
            end

            isLintbarEnabled = LintBarEnabled;
        end
    end
end

function data = expandNestedStructData(structData)
    data = string.empty;
    if isempty(structData.selectedFields)
        data = getStructSearchData(structData.data, structData.varName);
    else
        for i=1:length(structData.selectedFields)
            fName = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(structData.selectedFields(i));
            varName = structData.varName;
            d = eval("structData.data." + fName);
            selectedData = matlab.internal.datatoolsservices.getWorkspaceDisplay({d}, "name", "value");
            lastName = fName.split(".");
            lastName = lastName(end);
            selectedData = [varName + "." + fName, lastName, selectedData.Value];
            subData = string.empty;
            if isstruct(d) && isscalar(d)
                subData = getStructSearchData(d, structData.varName + "." + fName);
            end
            if isempty(subData)
                subData = selectedData;
            else
                subData = [selectedData;subData];
            end
            if isempty(data)
                data = subData;
            else
                data = [data;subData];
            end
        end
    end
end

function [matchBlocks, totalMatches] = doTextSearch(fullData, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, findFirstMatch, useNumericDisp, numericFormat)
    % Loops through all the search intervals and calls the stringSearch
    % utility on the data createing an array of matched block results
    arguments
        fullData
        selectedRowIntervals
        selectedColIntervals
        searchText
        searchTextOptions
        findFirstMatch (1,1) logical = false
        useNumericDisp (1,1) logical = false
        numericFormat (1,1) string = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat()
    end

    blockCount = 1;
    totalMatches = 0;
    dataIsStruct = isstruct(fullData) && isfield(fullData, 'selectedFields');

    % Expand out nested structure data
    if dataIsStruct
        origFullData = fullData;
        fullData = expandNestedStructData(fullData);
        % Match in fully expanded data, but ignore first column because
        % that's the ID column
        selectedRowIntervals = [1,height(fullData)];
        selectedColIntervals = [2,3];
    end

    for rowInterval=1:height(selectedRowIntervals)
        for colInterval=1:height(selectedColIntervals)
            if ~findFirstMatch
                startRow = selectedRowIntervals(rowInterval,1);
                endRow = selectedRowIntervals(rowInterval,2);
                startColumn = selectedColIntervals(colInterval,1);
                endColumn = selectedColIntervals(colInterval,2);
            else
                startRow = selectedRowIntervals(rowInterval,1);
                endRow = min(selectedRowIntervals(rowInterval,2), startRow + internal.matlab.variableeditor.Actions.SearchAction.FirstMatchMaxRows);
                startColumn = selectedColIntervals(colInterval,1);
                endColumn = min(selectedColIntervals(colInterval,2), startColumn + internal.matlab.variableeditor.Actions.SearchAction.FirstMatchMaxColumns);
            end

            matchBlock.startRow = startRow;
            matchBlock.endRow = endRow;
            matchBlock.startColumn = startColumn;
            matchBlock.endColumn = endColumn;
            matchBlock.matches = [];
            matchBlock.dataIsStruct = dataIsStruct;
            matchBlock.matchIDs = [];
    
            matchColIndex = 1;
            % Convert datasets to tables to index correctly on search. 
            % Conversion to table could emit warnings, supress warnings on find.
            if isa(fullData, 'dataset')
                fullData = internal.matlab.datatoolsservices.VariableUtils.convertDatasetToTable(fullData);
            end
            for column=startColumn:endColumn
                if istabular(fullData)
                    currentData = fullData{startRow:endRow, column};
                elseif ischar(fullData)
                    currentData = string(fullData);
                elseif isstruct(fullData)
                    currentData = struct2cell(fullData)';
                    currentData = currentData(startRow:endRow, column);
                else
                    currentData = fullData(startRow:endRow, column);
                end
                if istable(currentData)
                    currentData = currentData{:,1};
                end
                if ischar(currentData) || iscellstr(currentData)
                    currentData = string(currentData);
                elseif iscell(currentData)
                    currentData = strtrim(regexprep(regexprep(strtrim(strsplit(strtrim(string(evalc('disp(currentData)'))), newline))', '^{', ''), '}$', ''));
                    % Remove brackets from scalar values
                    currentData = regexprep(currentData, "^\[([^,]*)\]$", "$1");
                end

                w = width(currentData);
                if (w == 1)
                    [m] = matlab.internal.datatoolsservices.stringSearch(...
                        currentData,...
                        searchText,...
                        IgnoreCase=searchTextOptions.IgnoreCase,...
                        WholeWord=searchTextOptions.WholeWord,...
                        Regex=searchTextOptions.Regex, ...
                        UseNumericDisplay=useNumericDisp, ...
                        NumericFormat=numericFormat);
                    matchBlock.matches(:,matchColIndex) = m;
                    matchColIndex = matchColIndex + 1;
                    totalMatches = totalMatches + sum(m);
                else
                    matchMask = zeros(height(currentData), 1);
                    for i=1:w
                        [m] = matlab.internal.datatoolsservices.stringSearch(...
                            currentData(:,i),...
                            searchText,...
                            IgnoreCase=searchTextOptions.IgnoreCase,...
                            WholeWord=searchTextOptions.WholeWord,...
                            Regex=searchTextOptions.Regex, ...
                            UseNumericDisplay=useNumericDisp, ...
                            NumericFormat=numericFormat);
                        matchMask = m | matchMask;
                    end
                    matchBlock.matches(:,matchColIndex) = matchMask;
                    matchColIndex = matchColIndex + 1;
                    totalMatches = totalMatches + sum(matchMask);
                end

                if dataIsStruct
                    matchBlock.matchIDs = unique([matchBlock.matchIDs;fullData(matchBlock.matches(:,matchColIndex-1)==1, 1)]);
                end
            end
    
            matchBlocks(blockCount) = matchBlock; %#ok<AGROW> 
            blockCount = blockCount + 1;

            if findFirstMatch && totalMatches > 0
                break;
            end
        end
    end

    if ~exist("matchBlocks", "var")
        matchBlocks = [];
    end
end

function [matchBlocks, totalMatches] = searchAndSend(channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, isPartial, numericFormat, sendData)
    arguments
        channel
        fullData
        selectedRowIntervals
        selectedColIntervals
        searchText
        searchTextOptions
        isPartial
        numericFormat
        sendData (1,1) logical = true
    end

    % Send full match
    [matchBlocks, totalMatches] = doTextSearch(fullData, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, isPartial, true, numericFormat);

    if sendData
        sendMatches(channel, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, matchBlocks, totalMatches, isPartial);
    end
end

function sendMatches(channel, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, matchBlocks, totalMatches, isPartial)
    arguments
        channel,
        selectedRowIntervals,
        selectedColIntervals,
        searchText,
        searchTextOptions,
        matchBlocks,
        totalMatches,
        isPartial
    end

    s = struct;
    s.selectedRowIntervals = selectedRowIntervals;
    s.selectedColIntervals = selectedColIntervals;
    s.searchText = searchText;
    s.searchTextOptions = searchTextOptions;
    s.matches = matchBlocks;
    s.totalMatches = totalMatches;
    s.partialMatch = isPartial;

    sendMessage(channel, 'matches', s);
end

function affectsViewport = doesViewportOverlapSelection(viewport, selectedRowIntervals, selectedColIntervals) %#ok<DEFNU> 
    affectsViewport = false;
    for rowInterval=1:height(selectedRowIntervals)
        for colInterval=1:height(selectedColIntervals)
            startRow = selectedRowIntervals(rowInterval,1);
            endRow = selectedRowIntervals(rowInterval,2);
            startColumn = selectedColIntervals(colInterval,1);
            endColumn = selectedColIntervals(colInterval,2);
    
            for column=startColumn:endColumn
                r1 = [viewport.StartRow viewport.StartColumn viewport.EndRow-viewport.StartRow+1 viewport.EndColumn-viewport.StartColumn+1];
                r2 = [startRow startColumn endRow-startRow+1 endColumn-startColumn+1];
                affectsViewport = rectint(r1, r2) > 0;
                if (affectsViewport)
                    return;
                end
            end
        end
    end
end

function [matchedBlocks, totalMatches] = runInMainThreadIfError(f, channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, isPartial, cf, dataIsStruct, searchAction, vm)
    matchedBlocks = [];
    totalMatches = [];
    if ~isempty(f.Error)
        try
            internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::search", "main thread");
            % Execute on main MATLAB thread
            [matchedBlocks, totalMatches] = searchAndSend(channel, fullData, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions, isPartial, cf, ~dataIsStruct);
            if dataIsStruct
                searchAction.expandAndSendStructMatches(channel, vm, matchedBlocks, totalMatches, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions);
            end
        catch ME
            internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction::error", "e7: " + ME.message);
        end
    elseif dataIsStruct
        [matchedBlocks, totalMatches] = f.fetchOutputs();
        searchAction.expandAndSendStructMatches(channel, vm, matchedBlocks, totalMatches, selectedRowIntervals, selectedColIntervals, searchText, searchTextOptions);
    end
end

function sendMessage(channel, type, data)
    arguments
        channel (1,1) string
        type (1,1) string
        data = []
    end
    s = struct;
    s.type = type;
    if ~isempty(data)
        s.data = data;
    end

    message.publish(channel, s);
end

function logErrors(f, varargin)
    if ~isempty(f.Error)
        errorStr = sprintf("\n**************************************************\n");
        errorStr = errorStr + sprintf("* Error executing search in background thread: \n** %s\n", f.Error.message);
        if ~isempty(f.Error.stack)
            errorStr = errorStr + sprintf("*** %s - %d\n", f.Error.stack(1).name, f.Error.stack(1).line);
        end
        errorStr = errorStr + sprintf("**************************************************\n");
        internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction", errorStr);
    else
        internal.matlab.datatoolsservices.logDebug("variableeditor::searchaction", sprintf("Background Search Completed Successfully: \n"));
    end
end

function sd = getStructSearchData(s, varName)
    arguments
        s (1,1)
        varName string {mustBeScalarOrEmpty} = string.empty
    end

    sd = string.empty;
    if isempty(varName)
        varName = inputname(1);
    end

    if isstruct(s)
        fns = fieldnames(s);
    elseif isobject(s)
        fns = properties(s);
    end

    for i=1:length(fns)
        fName = fns{i};
        fVal = s.(fName);
        d = matlab.internal.datatoolsservices.getWorkspaceDisplay({fVal}, "name", "value");
        sd(end+1, 1:3) = [varName + "." + fName, fName, d.Value];
        if isstruct(fVal) && isscalar(fVal) && ~isempty(fVal) && ~isempty(fieldnames(fVal))
            rs = getStructSearchData(fVal, varName + "." + fName);
            sd = [sd; rs];
        elseif istabular(fVal) && ~isempty(fVal) && ~isempty(fVal.Properties.VariableNames)
            if istimetable(fVal)
                timeName = fVal.Properties.DimensionNames{1};
                % Add time column for timetables
                d = matlab.internal.datatoolsservices.getWorkspaceDisplay({fVal.(timeName)}, "name", "value");
                sd(end+1, 1:3) = [varName + "." + fName + "." + timeName, timeName, d.Value];
            end
            varNames = fVal.Properties.VariableNames;
            for propIdx = 1:length(varNames)
                vName = varNames{propIdx};
                d = matlab.internal.datatoolsservices.getWorkspaceDisplay({fVal.(vName)}, "name", "value");
                sd(end+1, 1:3) = [varName + "." + fName + "." + vName, vName, d.Value];
            end
        elseif isobject(fVal) && isscalar(fVal) && ~isempty(fVal) && ~isempty(properties(fVal))
            rs = getStructSearchData(fVal, varName + "." + fName);
            sd = [sd; rs];
        end
    end
end

function expansionCount = getStructExpansionRowCount(s, breakCheck)
    arguments
        s (1,1) struct
        breakCheck (1,1) double = inf
    end

    expansionCount = 0;

    fns = fieldnames(s);

    for i=1:length(fns)
        fName = fns{i};
        fVal = s.(fName);
        expansionCount = expansionCount + 1;
        if isstruct(fVal) && isscalar(fVal) && ~isempty(fVal) && ~isempty(fieldnames(fVal))
            expansionCount = expansionCount + getStructExpansionRowCount(fVal);
        end
        if (expansionCount > breakCheck)
            return
        end
    end
end

function handleStructResults(fullData, vm, searchResults)
end

function mustPositiveNumericOrIn(var, stringList)
    if (isnumeric(var) && var <= 0) || (~isnumeric(var) && ~ismember(var, stringList))
        error("Not positive number or in [" + strjoin(stringList,",") + "]");
    end
end
