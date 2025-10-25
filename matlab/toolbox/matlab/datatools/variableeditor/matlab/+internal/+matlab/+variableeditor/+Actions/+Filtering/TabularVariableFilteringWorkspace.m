classdef TabularVariableFilteringWorkspace < internal.matlab.variableeditor.MLWorkspace & dynamicprops

    % Copyright 2018-2024 The MathWorks, Inc.

    properties(Constant)
        SERIALIZATION_VERSION = "1.0";

        DURATION_SERIALIZATION_FORMAT = "hh:mm:ss.SSSSSSSSS";
    end

    properties(Access='protected')
        OrigTable_I;
        SearchStrings_I;
        SelectedCats_I;
        OriginalCats_I;
        NumericRanges_I;
        ExcluededMissings_I;
        Figures_I;
        FilteredTable_I;
    end

    events
        FilteredDataChanged;
    end

    properties(GetAccess='public', Dependent=true, SetAccess='private')
        FilteredTable;
        ExcludedMissings;
    end

    properties (Dependent)
        OriginalTable;
    end
    methods
        function val = get.FilteredTable(this)
            if isempty(this.FilteredTable_I)
                this.FilteredTable_I = this.getFilteredTable('');
            end
            val = this.FilteredTable_I;
        end

        function val = get.ExcludedMissings(this)
            val = this.ExcluededMissings_I;
        end

        function val = get.OriginalTable(this)
            val = this.OrigTable_I;
        end

        function set.OriginalTable(this, val)
            this.OrigTable_I = val;
            this.resetExistingCache();
            this.buildWorkspaceVariables();
        end

        function updateOriginalTable(this, val, varName, doNotification)
            arguments
                this
                val
                varName
                doNotification (1,1) logical = true
            end
            this.OrigTable_I = val;
            varVal = val.(varName);
            if this.isCategoricalLikeVariable(varVal)
                groupTable_cats = rmmissing(groupsummary(this.OrigTable_I, varName, 'IncludeEmptyGroups', true));
                cats = groupTable_cats.(varName);
                this.OriginalCats_I(varName) = cats;
                if ~isempty(cats)
                    % If cats is empty, then we know the column only has
                    % missing values
                    checkMap = containers.Map(cellstr(cats), [1:length(cats)]');
                    selectedCats = true(length(cats), 1);
                    % Creating a hashmap which contains
                    %     1. checkedArray: Array containing the selection state of cats
                    %     2. indexMap: Hashmap containing the indices of the cats
                    this.SelectedCats_I(varName) = struct('checkedArray', selectedCats, 'indexMap', checkMap);
                else
                    % Since there are no cats, setting the checkMap and
                    % selectedCats to empty
                    selectedCats = [];
                    checkMap = [];
                    this.SelectedCats_I(varName) = struct('checkedArray', selectedCats, 'indexMap', checkMap);
                end
            end
            if (doNotification)
                try
                    notify(this, 'VariablesChanged');
                    notify(this, 'FilteredDataChanged');
                catch e
                    internal.matlab.datatoolsservices.logDebug('TabularVariableFilteringWorkspace', e.message);
                end
            end
        end

        function sd = serializeFilters(this)
            import internal.matlab.variableeditor.Actions.Filtering.TabularVariableFilteringWorkspace;
            sd = struct('Version', TabularVariableFilteringWorkspace.SERIALIZATION_VERSION, 'NumericFilters', struct, 'CategoricalFilters', struct);
            numericVars = keys(this.NumericRanges_I);
            for i=1:length(numericVars)
                varName = numericVars{i};
                [l,u,excludeMissing] = this.getNumericFilterBounds(varName);
                isDuration = false;
                if isduration(l)
                    origFormat = l.Format;
                    l.Format = TabularVariableFilteringWorkspace.DURATION_SERIALIZATION_FORMAT;
                    u.Format = TabularVariableFilteringWorkspace.DURATION_SERIALIZATION_FORMAT;
                    sd.NumericFilters.(varName) = struct('min', string(l), 'max', string(u), 'includeMissing', ~excludeMissing, 'durationFormat', origFormat);
                else
                    sd.NumericFilters.(varName) = struct('min', l, 'max', u, 'includeMissing', ~excludeMissing);
                end
            end
            catVars = keys(this.SelectedCats_I);
            for i=1:length(catVars)
                varName = catVars{i};
                filterData = this.SelectedCats_I(varName);
                [cats, excludeMissing] = getSelectedCategories(this, varName);
                if ~all(filterData.checkedArray) || excludeMissing
                    sd.CategoricalFilters.(varName) = struct('categories', string(cats), 'includeMissing', ~excludeMissing);
                end
            end
        end

        function [cats, excludeMissing] = getSelectedCategories(this, varName)
            cats = {};
            if isKey(this.SelectedCats_I, varName)
                vals = this.SelectedCats_I(varName).indexMap.keys;
                cats = vals(this.SelectedCats_I(varName).checkedArray);
            end
            excludeMissing = isKey(this.ExcluededMissings_I, varName);
        end

        function setSelectedCategories(this, varName, cats, sendNotification)
            arguments
                this
                varName
                cats = {}
                sendNotification (1,1) logical = true
            end

            if ~isKey(this.SelectedCats_I, varName)
                this.updateOriginalTable(this.OriginalTable, varName, false);
            end

            % Deselect everything first
            this.deselectAll(varName);
            filter = this.SelectedCats_I(varName);

            for c=1:length(cats)
                cat = cats{c};
                if isKey(filter.indexMap, cat)
                    index = filter.indexMap(cat);
                    filter.checkedArray(index) = 1;
                end
            end
            this.SelectedCats_I(varName) = filter;

            if sendNotification
                try
                    notify(this, 'VariablesChanged');
                    notify(this, 'FilteredDataChanged');
                catch
                    % Ignore the exceptions
                end
            end
        end

        function deserializeFilters(this, sd)
            arguments
                this
                sd struct {mustBeScalarOrEmpty} = struct.empty
            end
            import internal.matlab.variableeditor.Actions.Filtering.TabularVariableFilteringWorkspace;

            if ~isempty(sd) && ~isfield(sd, 'Version') ||...
                    ~isempty(sd) && ~strcmp(sd.Version, TabularVariableFilteringWorkspace.SERIALIZATION_VERSION)
                error('Unsupported serialization version');
            end

            this.resetFilters();

            if ~isempty(sd)
                if isfield(sd, 'NumericFilters')
                    vars = fields(sd.NumericFilters);
                    for i=1:length(vars)
                        varName = vars{i};
                        filterData = sd.NumericFilters.(varName);
                        % Set Numeric Range
                        l = filterData.min;
                        u = filterData.max;
                        if (isfield(filterData, "durationFormat"))
                            l = duration(l, "InputFormat", TabularVariableFilteringWorkspace.DURATION_SERIALIZATION_FORMAT, "Format", filterData.durationFormat);
                            u = duration(u, "InputFormat", TabularVariableFilteringWorkspace.DURATION_SERIALIZATION_FORMAT, "Format", filterData.durationFormat);
                        end
                        this.setNumericRange(varName, l, u, false);
                        if (~filterData.includeMissing)
                            this.ExcluededMissings_I(varName) = 1;
                        end
                    end
                end
    
                if isfield(sd, 'CategoricalFilters')
                    vars = fields(sd.CategoricalFilters);
                    for i=1:length(vars)
                        varName = vars{i};
                        filterData = sd.CategoricalFilters.(varName);
                        % Set Selected Categories
                        this.setSelectedCategories(varName, filterData.categories, false);
                        if (~filterData.includeMissing)
                            this.ExcluededMissings_I(varName) = 1;
                        end
                    end
                end
            end

            try
                notify(this, 'VariablesChanged');
                notify(this, 'FilteredDataChanged');
            catch e
                internal.matlab.datatoolsservices.logDebug('TabularVariableFilteringWorkspace', e.message);
            end
        end

        function [filteredCols, filteredIndices] = getFilteredColumns(this)
            filteredCols = string.empty;
            filteredIndices = [];

            filteredCols = [filteredCols string(this.NumericRanges_I.keys)];
            catVars = this.SelectedCats_I.keys;
            if ~isempty(catVars)
                for i=1:numel(catVars)
                    varName = catVars{i};
                    if ~all(this.SelectedCats_I(varName).checkedArray)
                        filteredCols(end+1) = string(varName); %#ok<AGROW>
                    end
                end
            end
            filteredCols = [filteredCols string(this.ExcluededMissings_I.keys)];
            filteredCols = unique(filteredCols);

            if ~isempty(filteredCols)
                filteredIndices = find(cellfun(@(v)ismember(v,filteredCols), this.OrigTable_I.Properties.VariableNames));
            end
        end

        function updateTableAndResetCache(this, val, docID)
            filterManagerChannel = strcat('/VE/filter', docID);
            mgrs = internal.matlab.variableeditor.peer.VEFactory.getManagerInstances;
            if ~(any(strcmp(mgrs.keys, filterManagerChannel)) == 0)
                filterManager = internal.matlab.variableeditor.peer.VEFactory.createManager(filterManagerChannel, false);
                for i=length(filterManager.Documents):-1:1
                    if isvalid(filterManager.Documents(i))
                        filterManager.closevar(filterManager.Documents(i).Name, filterManager.Documents(i).Workspace);
                    end
                end
            end
            this.deleteFigures();
            this.resetExistingCache();
            this.resetOriginalData(val);

            try
                notify(this, 'VariablesChanged');
                notify(this, 'FilteredDataChanged');
            catch e
                internal.matlab.datatoolsservices.logDebug('TabularVariableFilteringWorkspace', e.message);
            end
        end

        function resetExistingCache(this)
            this.FilteredTable_I = [];
            this.SearchStrings_I = containers.Map();
            this.SelectedCats_I = containers.Map();
            this.OriginalCats_I = containers.Map();
            this.NumericRanges_I = containers.Map();
            this.ExcluededMissings_I = containers.Map();
        end

        function resetOriginalData(this, val)
            this.OrigTable_I = val;
            this.OriginalTable = val;
            try
                notify(this, 'VariablesChanged');
                notify(this, 'FilteredDataChanged');
            catch e
                internal.matlab.datatoolsservices.logDebug('TabularVariableFilteringWorkspace', e.message);
            end
        end
    end


    methods
        function this = TabularVariableFilteringWorkspace(tbl)
            this.OrigTable_I = tbl;
            this.SearchStrings_I = containers.Map();
            this.SelectedCats_I = containers.Map();
            this.OriginalCats_I = containers.Map();
            this.NumericRanges_I = containers.Map();
            this.ExcluededMissings_I = containers.Map();
            this.Figures_I = containers.Map();
            this.FilteredTable_I = [];

            this.buildWorkspaceVariables();
        end

        function isvar = isVariable(this, varName)
            isvar = ismember(varName, this.OrigTable_I.Properties.VariableNames);
        end

        function searchVariable(this, varName, searchString)
            this.SearchStrings_I(varName) = searchString;
            try
                notify(this, 'VariablesChanged');
            catch
                % Ignore the exceptions
            end
        end

        function clearSearch(this, varName)
            if isKey(this.SearchStrings_I, varName)
                this.SearchStrings_I.remove(varName);
                try
                    notify(this, 'VariablesChanged');
                catch
                    % Ignore the exceptions
                end
            end
        end

        function setNumericRange(this, varName, lowerBound, upperBound, sendNotification)
            arguments
                this
                varName
                lowerBound = []
                upperBound = []
                sendNotification (1,1) logical = true
            end

            if ~isempty(lowerBound) || ~isempty(upperBound)
                [minV, maxV] = this.checkInvalidValues(this.(varName)(1,:), lowerBound, upperBound);
                this.NumericRanges_I(varName) = ...
                    struct('lowerBound',minV, ...
                    'upperBound', maxV);
                this.FilteredTable_I = [];
                if sendNotification
                    try
                        notify(this, 'VariablesChanged');
                        notify(this, 'FilteredDataChanged');
                    catch
                        % Ignore the exceptions
                    end
                end
            end
        end

        function [minV, maxV] = checkInvalidValues(~, tableVar, minVal, maxVal)
            if (minVal > maxVal)
                if minVal == tableVar.SelectedRangeMin
                    maxVal = minVal;
                elseif maxVal == tableVar.SelectedRangeMax
                    minVal = maxVal;
                end
            end
            if minVal < tableVar.OriginalMin
                minV = tableVar.OriginalMin;
            elseif minVal > tableVar.OriginalMax
                minV = tableVar.OriginalMax;
            elseif ismissing(minVal)
                minV = tableVar.SelectedRangeMin;
            else
                minV = minVal;
            end
            if maxVal > tableVar.OriginalMax
                maxV = tableVar.OriginalMax;
            elseif maxVal < tableVar.OriginalMin
                maxV = tableVar.OriginalMin;
            elseif ismissing(maxVal)
                maxV = tableVar.SelectedRangeMax;
            else
                maxV = maxVal;
            end
        end

        function [lowerBound, upperBound, excludeMissing] = getNumericFilterBounds(this, varName)
            lowerBound = [];
            upperBound = [];
            if isKey(this.NumericRanges_I, varName)
                range = this.NumericRanges_I(varName);
                lowerBound = range.lowerBound;
                upperBound = range.upperBound;
            end

            % g3152826: If the duration string is of a time unit
            % (e.g., seconds, minutes), we cannot directly transform
            % it into a duration using `duration(stringQuantity)`.
            % We must use a slightly different approach to do this conversion.
            if isduration(lowerBound)
                isUnitDuration = any(strcmp(lowerBound.Format, ["s" "m" "h" "d" "y"]));
                if isUnitDuration
                    lowerBound = internal.matlab.variableeditor.Actions.Filtering.convertStringUnitDurationToDuration(lowerBound, lowerBound.Format, true);
                end
            end
            if isduration(upperBound)
                isUnitDuration = any(strcmp(upperBound.Format, ["s" "m" "h" "d" "y"]));
                if isUnitDuration
                    upperBound = internal.matlab.variableeditor.Actions.Filtering.convertStringUnitDurationToDuration(upperBound, upperBound.Format, true);
                end
            end

            excludeMissing = isKey(this.ExcluededMissings_I, varName);
        end

        function filter = getNumericFilterString(this, varName, minV, maxV)
            filter = '';
            [lowerBound, upperBound] = this.getNumericFilterBounds(varName);

            if (issparse(lowerBound))
                lowerBound = full(lowerBound);
            end
            if (issparse(upperBound))
                upperBound = full(upperBound);
            end

            % g1769653: If the max or max has been reset to the Original
            % Values, do not generate a filter string with stringified
            % values since this would result in the loss of precision.
            if isequal(lowerBound, minV)
                lowerBound = [];
            end
            if isequal(upperBound, maxV)
                upperBound = [];
            end

            if ~isempty(lowerBound) && ~ismissing(lowerBound)
                if isdatetime(lowerBound)
                    fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(lowerBound.Format);
                    lowerBound.Format = fmt;
                    % Use char for conversion from datetime to strings to
                    % preserve the right format (across locales)(g2201066)
                    dtLowerBound = [char(39) char(lowerBound) char(39)];
                elseif isduration(lowerBound)
                    lowerBound = [char(39) char(lowerBound) char(39)];
                else
                    lowerBound = string(lowerBound);
                end
            else
                dtLowerBound = lowerBound;
            end

            if ~isempty(upperBound) && ~ismissing(upperBound)
                if isdatetime(upperBound)
                    fmt = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(upperBound.Format);
                    upperBound.Format = fmt;
                    upperBound = dateshift(upperBound, 'end', internal.matlab.variableeditor.peer.PeerDataUtils.getDatetimePrecisionFromFormat(upperBound.Format));
                    % Use char for conversion from datetime to strings to
                    % preserve the right format (across locales)(g2201066)
                    dtUpperBound = [char(39) char(upperBound) char(39)];
                elseif isduration(upperBound)
                    upperBound = [char(39) char(upperBound) char(39)];
                else
                    upperBound = string(upperBound);
                end
            else
                % g1884664: Must defined the dtUpperBound and dtLowerBound
                % for datetime variables with all missing
                dtUpperBound = upperBound;
            end

            if ~isempty(lowerBound) && ~isempty(upperBound)
                if (~isdatetime(lowerBound) && ~isdatetime(upperBound))
                    filter = sprintf('(filteredTable.%s >= %s & filteredTable.%s <= %s)', ...
                        varName, lowerBound, varName, upperBound);
                else
                    filter = sprintf('(filteredTable.%s >= %s & filteredTable.%s < %s)', ...
                        varName, dtLowerBound, varName, dtUpperBound);
                end
            elseif ~isempty(lowerBound)
                if ~isdatetime(lowerBound)
                    filter = sprintf('(filteredTable.%s >= %s)', ...
                        varName, lowerBound);
                else
                    filter = sprintf('(filteredTable.%s >= %s)', ...
                        varName, dtLowerBound);
                end
            elseif ~isempty(upperBound)
                if ~isdatetime(upperBound)
                    filter = sprintf('(filteredTable.%s <= %s)', ...
                        varName, upperBound);
                else
                    filter = sprintf('(filteredTable.%s < %s)', ...
                        varName, dtUpperBound);
                end
            end

            excludeMissingFilter = this.getExcludeMissingFilter(varName);
            includeMissingFilter = this.getIncludeMissingFilter(varName);
            if ~isempty(excludeMissingFilter)
                if ~isempty(filter)
                    filter = [filter ' & '];
                end
                filter = [filter excludeMissingFilter];
            elseif ~isempty(includeMissingFilter)
                if ~isempty(filter)
                    filter = [filter ' | ' includeMissingFilter];
                end
            end
        end

        function clearNumericRange(this, varName, sendNotification)
            if nargin < 3 || isempty(sendNotification)
                sendNotification = true;
            end
            if isKey(this.NumericRanges_I, varName)
                this.NumericRanges_I.remove(varName);
            end
            this.FilteredTable_I = [];
            if sendNotification
                try
                    notify(this, 'VariablesChanged');
                    notify(this, 'FilteredDataChanged');
                catch
                    % Ignore the exceptions
                end
            end
        end

        function excludeMissing(this, varName, sendNotification)
            if nargin < 3 || isempty(sendNotification)
                sendNotification = true;
            end
            if ~isKey(this.ExcluededMissings_I, varName)
                this.ExcluededMissings_I(varName) = true;
                this.FilteredTable_I = [];
                if sendNotification
                    try
                        notify(this, 'VariablesChanged');
                        notify(this, 'FilteredDataChanged');
                    catch
                        % Ignore the exceptions
                    end
                end
            end
        end

        function includeMissing(this, varName, sendNotification)
            if nargin < 3 || isempty(sendNotification)
                sendNotification = true;
            end
            if isKey(this.ExcluededMissings_I, varName)
                this.ExcluededMissings_I.remove(varName);
                this.FilteredTable_I = [];
                if sendNotification
                    try
                        notify(this, 'VariablesChanged');
                        notify(this, 'FilteredDataChanged');
                    catch
                        % Ignore the exceptions
                    end
                end
            end
        end

        function filtCount = getFilteredCount(this)
            filteredTable = this.getFilteredTable('');
            filtCount = height(filteredTable);
        end

        function filtCount = getOriginalCount(this)
            filtCount = height(this.OrigTable_I);
        end

        function selectAll(this, varName)
            if isprop(this, varName)
                this.(varName).Selected(:) = true;
            end
        end

        function resetFilters(this)
            varNames = this.OrigTable_I.Properties.VariableNames;
            for i=1:length(varNames)
                varName = varNames{i};
                this.selectAll(varName);
            end

            this.ExcluededMissings_I.remove(keys(this.ExcluededMissings_I));
            this.NumericRanges_I.remove(keys(this.NumericRanges_I));
        end

        function deselectAll(this, varName)
            if isprop(this, varName)
                this.(varName).Selected(:) = false;
            end
        end

        % This function takes the string datetime values sent from the
        % client and converts them into MATLAB datetimes.
        function colValue = handleDateTimeUpdates(~, colVal)
            if colVal.rangeMinDispVal(1) ~= colVal.rangeMinDispVal(2)
                dateFormat = matlab.internal.datetime.filterTimeIdentifiers(colVal.SelectedRangeMin.Format);
                timeFormat = replace(colVal.SelectedRangeMin.Format, dateFormat, '');
                dtVar = datetime(colVal.rangeMinDispVal(1), 'TimeZone', colVal.SelectedRangeMin.TimeZone, 'InputFormat', ['MM/dd/yyyy' timeFormat]);
                dtVar.Format = colVal.SelectedRangeMin.Format;
                colVal.SelectedRangeMin(1) = dtVar;
            end
            if colVal.rangeMaxDispVal(1) ~= colVal.rangeMaxDispVal(2)
                dateFormat = matlab.internal.datetime.filterTimeIdentifiers(colVal.SelectedRangeMax.Format);
                timeFormat = replace(colVal.SelectedRangeMax.Format, dateFormat, '');
                dtVar = datetime(colVal.rangeMaxDispVal(1), 'TimeZone', colVal.SelectedRangeMax.TimeZone, 'InputFormat', ['MM/dd/yyyy' timeFormat]);
                dtVar.Format = colVal.SelectedRangeMax.Format;
                colVal.SelectedRangeMax(1) = dtVar;
            end
            colVal.FilteredMinDispVal(1) = string(colVal.SelectedRangeMin(1));
            colVal.FilteredMaxDispVal(1) = string(colVal.SelectedRangeMax(1));
            colValue = colVal;
        end

        % This function takes the string duration values sent from the
        % client and converts them into MATLAB durations.
        function colValue = handleDurationUpdates(~, colVal)
            if colVal.rangeMinDispVal(1) ~= colVal.rangeMinDispVal(2)
                durVar = duration(colVal.rangeMinDispVal(1), 'InputFormat', colVal.SelectedRangeMin.Format);
                colVal.SelectedRangeMin(1) = durVar;
            end
            if colVal.rangeMaxDispVal(1) ~= colVal.rangeMaxDispVal(2)
                durVar = duration(colVal.rangeMaxDispVal(1), 'InputFormat', colVal.SelectedRangeMax.Format);
                colVal.SelectedRangeMax(1) = durVar;
            end
            colVal.FilteredMinDispVal(1) = string(colVal.SelectedRangeMin(1));
            colVal.FilteredMaxDispVal(1) = string(colVal.SelectedRangeMax(1));
            colValue = colVal;
        end

        function fig = getFigure(this, varName)
            if ~isKey(this.Figures_I, varName)
                this.createFigure(varName);
            end
            fig = this.Figures_I(varName);
        end

        function figH = getFigureHandle(this, varName)
            f = this.getFigure(varName);
            figH = f.getFigureHandle();
        end

        function id = getFigureData(this, varName)
            f = this.getFigure(varName);
            id = f.getFigureData();
        end

        function delete(this)
            this.deleteFigures();
        end

        function deleteFigures(this)
            if ~isempty(this.Figures_I)
                k = keys(this.Figures_I);
                for i=1:length(k)
                    f = this.Figures_I(k{i});
                    remove(this.Figures_I, k{i});
                    delete(f);
                end
            end
            this.Figures_I = containers.Map();
        end

        function deleteFigure(this, ID)
            if ~isempty(this.Figures_I) && isKey(this.Figures_I, ID)
                fig = this.Figures_I(ID);
                remove(this.Figures_I, ID);
                delete(fig);
            end
        end

        function isSupported = isCategoricalLikeVariable(~, val)
            isSupported = isstring(val)...
                || ischar(val)...
                || iscellstr(val)...
                || iscategorical(val);
        end

        function isSupported = isSupportedNumeric(~, val)
            isSupported = (isreal(val) && isnumeric(val)) || isdatetime(val) || isduration(val);
        end

        function isSupported = isLogicalVariable(~, val)
            isSupported = islogical(val);
        end
    end

    methods(Access='private')
        function filteredTable = getFilteredTable(this, iVarName)
            filteredTable = this.OrigTable_I;
            varNames = this.OrigTable_I.Properties.VariableNames;
            numVars = length(varNames);
            for i=1:numVars
                varName = varNames{i};
                if ~strcmp(varName, iVarName) % Ignore filters on current variable
                    val = this.OrigTable_I.(varName);
                    if (ischar(val))
                        val = cellstr(val);
                    end
                    if this.isLogicalVariable(val)
                        if isKey(this.SelectedCats_I, varName)
                            cats = this.OriginalCats_I(varName);
                            unselectedArray = ~(this.SelectedCats_I(varName).checkedArray);
                            filteredTable = filteredTable(~ismember(categorical(filteredTable.(varName)), cats(unselectedArray)),:);
                        end
                    elseif this.isCategoricalLikeVariable(val)
                        if isKey(this.SelectedCats_I, varName)
                            cats = this.OriginalCats_I(varName);
                            unselectedArray = ~(this.SelectedCats_I(varName).checkedArray);
                            excludeMissingFilter = this.getExcludeMissingFilter(varName);
                            if ~isempty(excludeMissingFilter)
                                filteredTable = filteredTable(~ismember(string(filteredTable.(varName)), string(cats(unselectedArray))) & ...
                                    ~ismissing(filteredTable.(varName)),:);
                            else
                                filteredTable = filteredTable(~ismember(string(filteredTable.(varName)), string(cats(unselectedArray))) | ...
                                    ismissing(filteredTable.(varName)),:);
                            end
                        end
                    elseif this.isSupportedNumeric(val)
                        minV = min(this.OriginalTable.(varName));
                        maxV = max(this.OriginalTable.(varName));
                        filterString = this.getNumericFilterString(varName, minV, maxV);
                        if ~isempty(filterString)
                            filteredTable = filteredTable(eval(filterString),:);
                        end
                    end
                end
            end
        end

        function isMissingInc = isMissingIncluded(this, varName)
            isMissingInc = ~isKey(this.ExcluededMissings_I, varName);
        end

        function missingFilter = getExcludeMissingFilter(this, varName)
            missingFilter = '';
            if isKey(this.ExcluededMissings_I, varName)
                missingFilter = this.getIncludeMissingFilter(varName);
                if ~isempty(missingFilter)
                    missingFilter = ['~' missingFilter];
                end
            end
        end

        function missingFilter = getIncludeMissingFilter(this, varName)
            missingFilter = '';
            var = this.OrigTable_I.(varName);
            if (ischar(var))
                return;
            end
            [~, missingString, ~] = getMissingForVariable(this, var, var);
            if ~isempty(missingString)
                missingFilter = sprintf('ismissing(filteredTable.%s)', varName);
            end
        end

        function [missingType, missingString, missingCount] = getMissingForVariable(this, origVar, filtVar)
            missingType = [];
            missingString = '';
            missingCount = 0;
            if this.isSupportedNumeric(origVar)
                type = class(origVar);
                switch type
                    case {'double', 'single', 'duration', 'calendarDuration'}
                        missingType = NaN;
                        missingString = 'NaN';
                    case 'datetime'
                        missingType = NaT;
                        missingString = 'NaT';
                    otherwise
                        missingString = "";
                end
                missingCount = sum(ismissing(filtVar));
            elseif isstring(origVar)
                missingType = string(missing);
                % g1772977: Using a non-printing character [Unit Separator; char(31)]
                % because we cannot create a category called <missing>.
                % Using char(31) since that is less likely to appear in the
                % user data and cause conflicts.
                missingString = ['<' char(31) 'missing' char(31) '>'];
                missingCount = sum(ismissing(filtVar));
            elseif ischar(origVar)
                % missing string must be empty for chars within tables
            elseif (iscellstr(origVar))
                missingType = {''};
                missingString = ''''' (missing)';
                missingCount = sum(ismissing(filtVar));
            elseif iscategorical(origVar)
                missingType = categorical(missing);
                missingString = ['<' char(31) 'undefined' char(31) '>'];
                missingCount = sum(ismissing(filtVar));
            end
        end

        function val = getPropVal(this, varName, ignoreSearch)
            if nargin<3 || isempty(ignoreSearch)
                ignoreSearch = false;
            end
            val = this.OrigTable_I.(varName);
            filtTable = this.getFilteredTable(varName);
            filtVal = filtTable.(varName);

            [~, missingString, missingCount] = this.getMissingForVariable(val, filtVal);
            if ischar(val)
                showMissing = false;
            else
                showMissing = (~isempty(missingString) && ~isKey(this.SearchStrings_I, varName)) || ignoreSearch;
            end
            if this.isLogicalVariable(val)
                val = this.getLogicalTable(varName, ignoreSearch);
            elseif this.isCategoricalLikeVariable(val)
                val = this.getCategoricalLikeTable(varName, ignoreSearch, showMissing,  missingString, missingCount);
            elseif this.isSupportedNumeric(val)
                val = this.getNumericTable(varName, val, filtVal, missingString, missingCount);
            end
        end

        function val = getCategoricalLikeTable(this, varName, ignoreSearch, showMissing, missingString, missingCount)
            if isKey(this.SelectedCats_I, varName)
                checks = this.SelectedCats_I(varName).checkedArray;
                cats = this.OriginalCats_I(varName);
            else
                % Chars within tables containing ' ' are considered
                % missing, remove on origTable before groupsummary.
                uniqueIdx = ~ismissing(this.OrigTable_I.(varName));
                groupTable_cats = groupsummary(this.OrigTable_I(uniqueIdx,:), varName);
                cats = groupTable_cats.(varName);
                % Checks must be logical as they are rendered as checkboxes
                checks = true(length(cats), 1);
                if ischar(cats)
                    if isempty(cats)
                        % We are doing this because cellstr of empty char
                        % is not an empty cellstr
                        cats = cellstr(string.empty);
                    else
                        % Convert to strings to ensure that we preserve
                        % empty spaces
                        cats = cellstr(string(cats));
                    end
                end
                if ~isempty(cats)
                    % If cats is empty, then we know the column only has
                    % missing values
                    checkMap = containers.Map(cellstr(cats), [1:length(cats)]');
                    selectedCats = checks;
                    % Creating a hashmap which contains
                    %     1. checkedArray: Array containing the selection state of cats
                    %     2. indexMap: Hashmap containing the indices of the cats
                    this.SelectedCats_I(varName) = struct('checkedArray', selectedCats, 'indexMap', checkMap);
                else
                    % Since there are no cats, setting the checkMap and
                    % selectedCats to empty
                    selectedCats = [];
                    checkMap = [];
                    this.SelectedCats_I(varName) = struct('checkedArray', selectedCats, 'indexMap', checkMap);
                end
                % Caching the original cats because groupsummary is an expensive operation
                this.OriginalCats_I(varName) = cats;
            end
            filteredTable = this.getFilteredTable(varName);
            uniqueFilteredIdx = ~ismissing(filteredTable.(varName));
            groupTable_counts = groupsummary(filteredTable(uniqueFilteredIdx,:), varName);

            if height(groupTable_counts) < length(cats)
                % Loop through the groupsummary only if the table is
                % filtered and has fewer cats.
                counts = zeros(length(cats),1);
                temp = this.SelectedCats_I(varName);
                % Convert to string to preserve spaces in groupnames
                groupNames = cellstr(string(groupTable_counts{:,1}));
                groupCounts = groupTable_counts{:,2};
                for i = 1:height(groupTable_counts)
                    countIdx = temp.indexMap(groupNames{i});
                    counts(countIdx) = groupCounts(i);
                end
            else
                counts = groupTable_counts.GroupCount;
            end

            if showMissing
                % case where cats is an empty ordinal
                if isempty(cats) && iscategorical(cats) && isordinal(cats)
                    if isordinal(cats)
                        cats = ordinal({missingString});
                    end
                else
                    % cats non empty
                    if iscategorical(cats) && isordinal(cats)
                        % g1772769: Need to use ADDCATS to add the missing
                        % category for ordinal columns
                        temp = categories(cats);
                        cats = addcats(cats, {missingString}, 'Before', temp{1});
                    end
                    cats(2:end+1) = cats(1:end);
                    cats(1) = {missingString};
                end

                counts(2:end+1) = counts(1:end);
                counts(1) = missingCount;

                checks(2:end+1) = checks(1:end);
                checks(1) = this.isMissingIncluded(varName);
            end

            if isstring(this.OrigTable_I.(varName))
                if showMissing
                    cats(1) = categorical(cats(1));
                end
            elseif ischar(this.OrigTable_I.(varName)) || ...
                    iscellstr(this.OrigTable_I.(varName))
                if showMissing
                    cats{1} = categorical(cellstr(cats(1)));
                end
            end
            if ~iscolumn(cats)
                cats = cats';
            end
            if ~iscolumn(checks)
                checks = checks';
            end
            if ~iscolumn(counts)
                counts = counts';
            end
            val = table(checks, cats, counts, 'VariableNames', {'Selected','Values','Counts'});

            if isKey(this.SearchStrings_I, varName) && ~ignoreSearch
                filter = this.SearchStrings_I(varName);
                if ~isempty(filter)
                    val = val(contains(string(val.Values), filter, 'IgnoreCase', true),:);
                end
            end
        end

        function val = getLogicalTable(this, varName, ignoreSearch)
            if isKey(this.SelectedCats_I, varName)
                checks = this.SelectedCats_I(varName).checkedArray;
                cats = this.OriginalCats_I(varName);
            else
                groupTable_cats = groupsummary(this.OrigTable_I, varName);
                cats = categorical(groupTable_cats.(varName));
                checks = true(length(cats), 1);

                checkMap = containers.Map(cellstr(cats), [1:length(cats)]');
                selectedCats = checks;
                % Creating a hashmap which contains
                %     1. checkedArray: Array containing the selection state of cats
                %     2. indexMap: Hashmap containing the indices of the cats
                this.SelectedCats_I(varName) = struct('checkedArray', selectedCats, 'indexMap', checkMap);

                % Caching the original cats
                this.OriginalCats_I(varName) = cats;
            end
            filteredTable = this.getFilteredTable(varName);
            groupTable_counts = groupsummary(filteredTable, varName);

            if height(groupTable_counts) < length(cats)
                % Loop through the groupsummary only if the table is
                % filtered and has fewer cats.
                counts = zeros(length(cats),1);
                temp = this.SelectedCats_I(varName);
                for i = 1:height(groupTable_counts)
                    countIdx = temp.indexMap((string(groupTable_counts{i,1})));
                    counts(countIdx) = groupTable_counts{i,2};
                end
            else
                counts = groupTable_counts.GroupCount;
            end

            if ~iscolumn(cats)
                cats = cats';
            end
            if ~iscolumn(checks)
                checks = checks';
            end
            if ~iscolumn(counts)
                counts = counts';
            end
            val = table(checks, cats, counts, 'VariableNames', {'Selected','Values','Counts'});

            if isKey(this.SearchStrings_I, varName) && ~ignoreSearch
                filter = this.SearchStrings_I(varName);
                if ~isempty(filter)
                    val = val(contains(string(val.Values), filter, 'IgnoreCase', true),:);
                end
            end
        end


        % This method gets the fields of the filtered table. This method
        % takes care of formatting the fields correctly for client-side
        % display as well as handles sparse array formatting
        function tableVal = getNumericTable(this, varName, val, filtVal, missingString, missingCount)
            numRows = length(filtVal);
            hasSparseValues = issparse(val);
            hasDatetimeValues = isdatetime(val);
            hasDurationValues = isduration(val);
            origMinValue = min(val);
            origMaxValue = max(val);
            dataType = class(val);

            % originalMin/ OriginalMax calculations
            if isinteger(val)
                origMin = cast(ones(numRows, 1), dataType)*origMinValue;
                origMax = cast(ones(numRows, 1), dataType)*origMaxValue;
            elseif hasDatetimeValues
                origMin = repmat(origMinValue, numRows, 1);
                origMax = repmat(origMaxValue, numRows, 1);
            elseif hasDurationValues
                durationFormat = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDurationFiltering(val.Format);
                if (durationFormat ~= val.Format)
                    origMinValue.Format = durationFormat;
                    origMaxValue.Format = durationFormat;
                end
                origMin = repmat(origMinValue, numRows, 1);
                origMax = repmat(origMaxValue, numRows, 1);
            else
                origMin = ones(numRows, 1)*origMinValue;
                origMax = ones(numRows, 1)*origMaxValue;
            end

            % FilteredMin/FilteredMax calculations
            if ~isempty(filtVal)
                filtMinValue = min(filtVal);
                filtMaxValue = max(filtVal);
            else
                filtMinValue = NaN;
                filtMaxValue = NaN;
            end

            if isinteger(val)
                filtMin = cast(ones(numRows, 1), dataType)*filtMinValue;
                filtMax = cast(ones(numRows, 1), dataType)*filtMaxValue;
            elseif isdatetime(val) || isduration(val)
                filtMin = repmat(filtMinValue, numRows, 1);
                filtMax = repmat(filtMaxValue, numRows, 1);
            else
                filtMin = ones(numRows, 1)*filtMinValue;
                filtMax = ones(numRows, 1)*filtMaxValue;
            end

            % Include missing calculations
            missingStrings = repmat(missingString, numRows, 1);
            missingCounts = ones(numRows, 1)*missingCount;
            includeMissing = ~isKey(this.ExcluededMissings_I, varName);
            includeMissing = true(numRows, 1)&includeMissing;

            [rangeMin, rangeMax] = this.getNumericFilterBounds(varName);

            % Full precision calculations for
            % rangemin/rangemax/originalmin/originalmax.
            if hasSparseValues
                fullRangeMin = matlab.internal.display.numericDisplay(full(rangeMin), full(rangeMin), 'Format', 'long');
                fullRangeMax = matlab.internal.display.numericDisplay(full(rangeMax), full(rangeMax), 'Format', 'long');
                fullOrigMin = matlab.internal.display.numericDisplay(full(origMinValue), full(origMinValue), 'Format', 'long');
                fullOrigeMax = matlab.internal.display.numericDisplay(full(origMaxValue), full(origMaxValue), 'Format', 'long');
            elseif hasDatetimeValues || hasDurationValues
                fullRangeMin = this.formatNumericForDisplay(full(rangeMin));
                fullRangeMax = this.formatNumericForDisplay(full(rangeMax));
                fullOrigMin = this.formatNumericForDisplay(full(origMinValue));
                fullOrigeMax = this.formatNumericForDisplay(full(origMaxValue));
            else
                fullRangeMin = matlab.internal.display.numericDisplay(rangeMin, rangeMin, 'Format', 'long');
                fullRangeMax = matlab.internal.display.numericDisplay(rangeMax, rangeMax, 'Format', 'long');
                fullOrigMin = matlab.internal.display.numericDisplay(origMinValue, origMinValue, 'Format', 'long');
                fullOrigeMax = matlab.internal.display.numericDisplay(origMaxValue, origMaxValue, 'Format', 'long');
            end

            % Range Min calculations
            if ~isempty(rangeMin)
                rangeMinDispValue = rangeMin;
                rangeMin = repmat(rangeMin, numRows, 1);
                fullRangeMin = repmat(fullRangeMin, numRows, 1);
            else
                if ~isinteger(origMinValue) && ~(hasDatetimeValues || hasDurationValues)
                    rangeMin = ones(numRows, 1)*origMinValue;
                elseif hasDatetimeValues || hasDurationValues
                    rangeMin = repmat(origMinValue, numRows, 1);
                else
                    rangeMin = cast(ones(numRows, 1), class(origMinValue))*origMinValue;
                end
                rangeMinDispValue = origMinValue;
                fullRangeMin = repmat(this.formatNumericForDisplay(fullOrigMin), numRows, 1);
            end

            % Range Max Calculations
            if ~isempty(rangeMax)
                rangeMaxDispValue = rangeMax;
                rangeMax = repmat(rangeMax, numRows, 1);
                fullRangeMax = repmat(fullRangeMax, numRows, 1);
            else
                rangeMaxDispValue = origMaxValue;
                if ~isinteger(origMaxValue) && ~(hasDatetimeValues || hasDurationValues)
                    rangeMax = ones(numRows, 1)*origMaxValue;
                elseif hasDatetimeValues || hasDurationValues
                    rangeMax = repmat(origMaxValue, numRows, 1);
                else
                    rangeMax = cast(ones(numRows, 1), class(origMaxValue))*origMaxValue;
                end
                fullRangeMax = repmat(this.formatNumericForDisplay(fullOrigeMax), numRows, 1);
            end

            % Format Values to short for display on filtering menu. These values are always
            % displayed in short format on the client.

            % For performance reasons, any conversions/ format displays are
            % to be done before we repmat.

            if hasSparseValues
                filtMinValue = full(filtMinValue);
                filtMaxValue = full(filtMaxValue);
                missingCount = full(missingCount);
                rangeMinDispValue = full(rangeMinDispValue);
                rangeMaxDispValue = full(rangeMaxDispValue);
            end

            formattedMinDispValue = this.formatNumericForDisplay(filtMinValue);
            formattedMaxDispValue = this.formatNumericForDisplay(filtMaxValue);
            filtMinDisp = repmat(formattedMinDispValue, numRows, 1);
            filtMaxDisp = repmat(formattedMaxDispValue, numRows, 1);
            formattedMissingCount = this.formatNumericForDisplay(missingCount);
            missingCountDisp = repmat(formattedMissingCount, numRows, 1);
            formattedRangeMin = this.formatNumericForDisplay(rangeMinDispValue);
            rangeMinDisp = repmat(formattedRangeMin, numRows, 1);
            formattedRangeMax = this.formatNumericForDisplay(rangeMaxDispValue);
            rangeMaxDisp = repmat(formattedRangeMax, numRows, 1);

            fullOrigMinDispVal = repmat(fullOrigMin, numRows, 1);
            fullOrigMaxDispVal = repmat(fullOrigeMax, numRows, 1);

            tableVal = table(filtVal, origMin, origMax, filtMin, filtMax,...
                includeMissing, missingCounts, ...
                rangeMin, rangeMax, fullRangeMin, fullRangeMax, ...
                filtMinDisp, filtMaxDisp, rangeMinDisp, rangeMaxDisp, missingCountDisp, ...
                fullOrigMinDispVal, fullOrigMaxDispVal, ...
                'VariableNames',...
                {'Values','OriginalMin','OriginalMax',...
                'FilteredMin','FilteredMax',...
                'IncludeMissing','MissingCount',...
                'SelectedRangeMin','SelectedRangeMax','SelectedRangeMinFullPrecision','SelectedRangeMaxFullPrecision', ...
                'FilteredMinDispVal', 'FilteredMaxDispVal', 'rangeMinDispVal', 'rangeMaxDispVal', 'missingCountsDispVal', ...
                'OriginalMinFullPrecision', 'OriginalMaxFullPrecision'});

            % The table constructor won't allow creation of a table with a char row,
            % so add this var separately after construction and move it.
            tableVal.MissingString = missingStrings;
            tableVal = movevars(tableVal,'MissingString','before','MissingCount');

            if hasDatetimeValues
                origDateFormat = matlab.internal.datetime.filterTimeIdentifiers(val.Format);
                if (strcmp(origDateFormat,val.Format))
                    showTimes = false;
                else
                    showTimes = true;
                end
                dateFormat = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDatetimeFiltering(origDateFormat);
                dateFormatVal = repmat(dateFormat, numRows, 1);
                showTimes = repmat(showTimes, numRows, 1);

                if ismissing(origMinValue)
                    origMinDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, 'NaT'), numRows, 1);
                    origMaxDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, 'NaT'), numRows, 1);
                else
                    [yr,mo,d] = ymd(origMinValue);
                    timeStr = internal.matlab.variableeditor.peer.PeerDataUtils.getTimeStringFromDatetime(origMinValue);
                    origMinDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, ...
                        struct('years', yr, 'months', mo, 'days', d, 'timeStr', timeStr)), numRows, 1);

                    [yr,mo,d] = ymd(origMaxValue);
                    timeStr = internal.matlab.variableeditor.peer.PeerDataUtils.getTimeStringFromDatetime(origMaxValue);
                    origMaxDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, ...
                        struct('years', yr, 'months', mo, 'days', d, 'timeStr', timeStr)), numRows, 1);
                end

                % g1860764: Ensure that the rangeMin and rangeMax is not
                % empty (which can happen if numRows is zero)
                if ~isempty(rangeMin) && ~isempty(rangeMax)
                    rangeMin = rangeMin(1);
                    rangeMax = rangeMax(1);
                end

                if ismissing(rangeMin)
                    rangeMinDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, 'NaT'), numRows, 1);
                    rangeMaxDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, 'NaT'), numRows, 1);
                else
                    [yr,mo,d] = ymd(rangeMin);
                    timeStr = internal.matlab.variableeditor.peer.PeerDataUtils.getTimeStringFromDatetime(rangeMin);
                    rangeMinDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, ...
                        struct('years', yr, 'months', mo, 'days', d, 'timeStr', timeStr)), numRows, 1);

                    [yr,mo,d] = ymd(rangeMax);
                    timeStr = internal.matlab.variableeditor.peer.PeerDataUtils.getTimeStringFromDatetime(rangeMax);
                    rangeMaxDT = repmat(internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, ...
                        struct('years', yr, 'months', mo, 'days', d, 'timeStr', timeStr)), numRows, 1);
                end

                timeFormat = replace(val.Format, origDateFormat, '');
                if isempty(timeFormat)
                    timeFormat = ' ';
                end

                tableVal.TimeFormatVal = repmat(timeFormat, numRows, 1);
                tableVal.DateFormatVal = dateFormatVal;
                tableVal.OrigMinDT = origMinDT;
                tableVal.OrigMaxDT = origMaxDT;
                tableVal.CurrMinDT = rangeMinDT;
                tableVal.CurrMaxDT = rangeMaxDT;
                tableVal.ShowTimes = showTimes;
                tableVal.TimeFormatVal = repmat(timeFormat, numRows, 1);
            elseif hasDurationValues
                durationFormat = internal.matlab.variableeditor.peer.PeerDataUtils.getCorrectFormatForDurationFiltering(val.Format);
                tableVal.TimeFormatVal = repmat(durationFormat, numRows, 1);
            end
        end

        % This formats the value provided in short format
        function val = formatNumericForDisplay(~, curVal)
            currentFormat = get(0, 'format');
            format short;
            try
                val = evalc('disp(curVal)');
                val = string(strtrim(val));
            catch
                format(currentFormat);
            end
            format(currentFormat);
        end

        function setPropVal(this, varName, colValue)
            val = this.OrigTable_I.(varName);

            % g1930951: Do not call handle datetime updates or handle
            % duration updates if there is only 1 row in the variable since
            % filtering is disabled in this case.
            if isdatetime(val) && (height(colValue) > 1)
                colValue = this.handleDateTimeUpdates(colValue);
            elseif isduration(val) && (height(colValue) > 1)
                colValue = this.handleDurationUpdates(colValue);
            end
            if istable(colValue) && this.isCategoricalLikeVariable(val)
                includeMissing = ~isKey(this.ExcluededMissings_I, varName);
                [~,missingString,~] = getMissingForVariable(this, val, val);
                selectedArray = this.SelectedCats_I(varName).checkedArray;
                cats = string(colValue.Values);
                checks = colValue.Selected;
                temp = this.SelectedCats_I(varName);
                for i=1:length(cats)
                    if ~strcmp(missingString, char(cats(i)))
                        if (length(cats) - 1 < length(selectedArray))
                            temp.checkedArray(temp.indexMap((char(cats(i))))) = checks(i);
                        else
                            temp.checkedArray(i-1) = checks(i);
                        end
                        this.SelectedCats_I(varName) = temp;
                    else
                        includeMissing = checks(i);
                    end
                end

                if includeMissing
                    this.includeMissing(varName, false);
                else
                    this.excludeMissing(varName, false);
                end

            elseif this.isSupportedNumeric(val)
                includeMissing = colValue.IncludeMissing(1);
                if includeMissing
                    this.includeMissing(varName, false);
                else
                    this.excludeMissing(varName, false);
                end
                origMin = colValue.OriginalMin(1);
                origMax = colValue.OriginalMax(1);
                rangeMin = colValue.SelectedRangeMin(1);
                rangeMax = colValue.SelectedRangeMax(1);
                if (origMin ~= rangeMin) || (origMax ~= rangeMax)
                    this.setNumericRange(varName, rangeMin, rangeMax, false);
                else
                    this.clearNumericRange(varName, false);
                end
            elseif this.isLogicalVariable(val)
                selectedArray = this.SelectedCats_I(varName).checkedArray;
                cats = string(colValue.Values);
                checks = colValue.Selected;
                temp = this.SelectedCats_I(varName);
                for i=1:length(cats)
                    if (length(cats) - 1 < length(selectedArray))
                        temp.checkedArray(temp.indexMap((char(cats(i))))) = checks(i);
                    else
                        temp.checkedArray(i-1) = checks(i);
                    end
                    this.SelectedCats_I(varName) = temp;
                end
            end
            this.FilteredTable_I = [];
            try
                notify(this, 'VariablesChanged');
                notify(this, 'FilteredDataChanged');
            catch
                % Ignore the exceptions
            end
        end

        function fds = getFilteredDataSummary(this)
            fds = struct('FilteredRowCount', this.getFilteredCount, 'OriginalRowCount', this.getOriginalCount);
        end

        function removeDynamicProps(this)
            % Find dynamic properties
            allprops = properties(this);
            for i=1:numel(allprops)
                m = findprop(this,allprops{i});
                if isa(m,'meta.DynamicProperty')
                    delete(m);
                end
            end
        end

        function buildWorkspaceVariables(this)
            this.removeDynamicProps();
            if ~isempty(this.OrigTable_I) &&...
                    (istable(this.OrigTable_I) || istimetable(this.OrigTable_I))
                varNames = this.OrigTable_I.Properties.VariableNames;
                numVars = length(varNames);
                for i=1:numVars
                    varName = varNames{i};
                    if isvarname(varName)
                        p = addprop(this, varName);
                        getFcn = @(o)getPropVal(o,varName);
                        setFcn = @(o,v)setPropVal(o,varName,v);
                        p.GetMethod = getFcn;
                        p.SetMethod = setFcn;

                        % Add to the unsearched struct
                        % g1884590: Use Column Index instead of Name as the UID
                        % to create the unsearched props since otherwise we
                        % risk have a prop. name that is greater than namelengthmax
                        % characters (not allowed).
                        unsearchedVarName = ['unsearched_' num2str(i)];
                        if ~isprop(this, unsearchedVarName)
                            p = addprop(this, unsearchedVarName);
                            p.Hidden = true;
                            getFcn = @(o)getPropVal(o,varName, true);
                            setFcn = @(o,v)setPropVal(o,varName,v);
                            p.GetMethod = getFcn;
                            p.SetMethod = setFcn;
                        else
                            % Update the property linkage in case variable
                            % names have changed
                            p = findprop(this, unsearchedVarName);
                            getFcn = @(o)getPropVal(o,varName, true);
                            setFcn = @(o,v)setPropVal(o,varName,v);
                            p.GetMethod = getFcn;
                            p.SetMethod = setFcn;
                        end
                    end
                end

                p = addprop(this, 'FilteredDataSummary');
                p.SetAccess = 'private';
                getFcn = @(o)getFilteredDataSummary(o);
                p.GetMethod = getFcn;
            end
        end

        function createFigure(this, varName)
            if isKey(this.Figures_I, varName)
                f = this.Figures_I(varName);
                this.Figures_I.remove(varName);
                delete(f);
            end
            f = internal.matlab.variableeditor.Actions.Filtering.FilterFigure(this, varName);
            this.Figures_I(varName) = f;
        end
    end
end
