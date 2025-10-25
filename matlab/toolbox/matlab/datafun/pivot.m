function P = pivot(T,varargin)
% Syntax:
%     P = pivot(T,Name=Value)
%
%     Name-Value Arguments:
%         Columns
%         Rows
%         DataVariable
%         Method
%         ColumnsBinMethod
%         RowsBinMethod
%         IncludedEdge
%         OutputFormat
%         IncludeTotals
%         IncludeMissingGroups
%         IncludeEmptyGroups
%         RowLabelPlacement
%
% For more information, see documentation

%   Copyright 2022-2024 The MathWorks, Inc.

% -------------------------------------------------------------------------
% Step 0: Input validation
if ~istabular(T)
    error(message('MATLAB:pivot:NonTabularInput'))
elseif rem(nargin,2) ~= 1
    error(message('MATLAB:pivot:KeyWithoutValue'))
end
[colData,rowData,groupingData,dataVar,dataVarInd,...
    method,methodName,gbins,gbprovided,expandBins,doflat,includedEdge,...
    includeTotals,includeMissing,includeEmpty,useRowNames] = validateNVpairs(T,varargin);

% -------------------------------------------------------------------------
% Step 1: group and aggregate with reducebygroup, over both cols and rows
numMethods = double(~isempty(method)); % if count or percent, numMethods = 0
needCounts = isempty(method);
[gCount,gData,gStats,gvLabels,~,gBinned] = matlab.internal.math.reducebygroup(T,...
    groupingData,[colData rowData],[colData rowData],gbprovided,gbins,...
    includedEdge,expandBins,false,dataVar,isempty(dataVar),{},method,methodName,...
    numMethods,1,"pivot",true,true,false,needCounts,includeMissing,true,includeEmpty);

cols = 1:numel(colData);
rows = numel(colData) + (1:numel(rowData));
if isempty(method)
    gStats = gCount;
    if isequal(methodName,"percentage")
        sumcounts = sum(gCount,1);
        if sumcounts ~= 0
            gStats = (gStats*100)/sumcounts;
        end
    end
else
    gStats = gStats{1};
end


% -------------------------------------------------------------------------
% Step 2: Reshape aggregated data
numCols = zeros(size(cols));
statsNonScalar = ~isvector(gStats);
szStats = size(gStats);
heightP = szStats(1);
widthP = 1;
if ~isempty(cols)
    for j = cols
        numCols(j) = size(gData{j},1);
    end
    widthP = prod(numCols);
    heightP = szStats(1)/widthP;
    if statsNonScalar
        % custom function returns non-scalar: rearrange rows of data
        % without loosing the ordering within each row
        gStatsOrig = gStats;
        idx = repmat({':'},numel(szStats)-1,1);
        gStats = repmat(gStats(1:heightP,idx{:}),1,widthP);
        for k = 2:widthP
            gStats(:,(szStats(2)*(k-1)+1):(szStats(2)*k),idx{2:end}) = gStatsOrig((heightP*(k-1)+1):(heightP*k),idx{:});
        end
    else
        gStats = reshape(gStats,[],widthP);
    end
end
if statsNonScalar
    NDsizes = num2cell(szStats(3:end));
end

% -------------------------------------------------------------------------
% Step 3: Calculate margins as needed
if includeTotals
    totalBySum = matches(methodName,["count" "percentage" "sum" "nummissing" "nnz"]);

    needDummyGvar = false;
    if ~totalBySum && ~includeMissing
        % Calculating grand total requires omitting rows from the data var
        % corresponding to missings from the grouping vars
        missingInd = false(size(gBinned{1}));
        for k = 1:numel(gBinned)
            missingInd = missingInd | ismissing(gBinned{k});
        end
        if any(missingInd) && ~isempty(rowData) && ~isempty(colData)
            % Create a dummy grouping variable that is missing where any of
            % the grouping variables contains missing, but otherwise is
            % just one group. Then, when calling reducebygroup separately
            % for *row* grouping variables, the data values corresponding
            % to missings in the *column* grouping variables are
            % appropriately omitted (and vice versa).
            needDummyGvar = true;
            dummyGvar = ones(size(missingInd));
            dummyGvar(missingInd) = NaN;
        end
    end

    % overall total
    if totalBySum
        % Sum over the stats we already calculated
        grandTotal = sum(gStats,"all","omitmissing");
    else
        % Send the whole data var into the appropriate function
        data = T.(dataVarInd);
        if ~includeMissing
            % Omit data corresponding to missings in the grouping variables
            data(missingInd,:) = [];
        end
        grandTotal = method{1}(data);
    end

    % row totals
    if isempty(colData)
        % edge case: do not include row totals
        rowTotals = [];
    elseif isempty(rowData)
        % we have already done this calculation in grandTotal
        rowTotals = grandTotal;
    elseif totalBySum
        rowTotals = sum(gStats,2,"omitmissing");
    else
        % Do reducebygroup again, but with only "Rows" groups
        % We also don't need any groupnames this time
        if needDummyGvar
            % dummy var to omit values where cols variables have missing
            binningData = [gBinned(rows) {dummyGvar}];
        else
            binningData = gBinned(rows);
        end
        [~,~,rowTotals] = matlab.internal.math.reducebygroup(T,...
            binningData,rowData,rowData,false,{},includedEdge,...
            false,false,dataVar,isempty(dataVar),{},method,methodName,...
            numMethods,1,"pivot",true,false,false,false,includeMissing,...
            true,includeEmpty);
        rowTotals = rowTotals{1};
    end

    % column totals
    if isempty(rowData)
        % edge case: do not include column totals
        columnTotals = [];
    elseif isempty(colData)
        % we have already done this calculation in grandTotal
        columnTotals = grandTotal;
    elseif totalBySum
        columnTotals = sum(gStats,1,"omitmissing");
    else
        % Do reducebygroup again, but with only "Columns" groups
        % We also don't need any groupnames this time
        if needDummyGvar
            % dummy var to omit values where rows variables have missing
            binningData = [gBinned(cols) {dummyGvar}];
        else
            binningData = gBinned(cols);
        end
        [~,~,columnTotals] = matlab.internal.math.reducebygroup(T,...
            binningData,colData,colData,false,{},includedEdge,...
            false,false,dataVar,isempty(dataVar),{},method,methodName,...
            numMethods,1,"pivot",true,false,false,false,includeMissing,...
            true,includeEmpty);
        columnTotals = columnTotals{1};

        % rearrange to row instead of column
        if statsNonScalar
            % Case function handle returns row vector or ND:
            % reorient without loosing rows of data
            columnTotals = reshape(pagetranspose(columnTotals),1,widthP*szStats(2),NDsizes{:});
        else
            columnTotals = columnTotals';
        end
    end
    % concatenate with data. Do this before reorganizing into nested tables
    if ~isempty(columnTotals)
        gStats = [gStats; columnTotals];
        heightP = heightP+1;
    end
    if ~isempty(rowTotals) && ~isempty(columnTotals)
        rowTotals = [rowTotals; grandTotal];
    end
end
% put each would-be table variable in a cell to be put into table(s) later
if statsNonScalar
    gStats = mat2cell(gStats,heightP,repmat(szStats(2),1,widthP),NDsizes{:});
else
    gStats = num2cell(gStats,1);
end
% -------------------------------------------------------------------------
% Step 4: Get data and labels to build resulting table

% Marginal labels and label for single row/col output
if includeTotals || numel(rows) == 0 || numel(cols) == 0
    if startsWith(methodName,"fun_")
        % Named custom function, just use the provided name
        methodName = extractAfter(methodName,"_");
    end
    % label for total row and total column
    totalLabel = "Overall_" + methodName;
    % label for single row/column result
    if isempty(method)
        % case count or percentage
        gStatsLabel = methodName;
    else
        gStatsLabel = methodName + "_" + dataVar;
    end
end
% Stats data and corresponding variable names
if isempty(cols)
    colLabels = gStatsLabel;
elseif isscalar(cols)
    colLabels = vals2labels(gData{cols},gvLabels(cols));
elseif doflat
    colLabels = cell(size(cols));
    for k = cols
        colLabels{k} = vals2labels(gData{k},gvLabels(k));
    end
    colLabels = combos(true,colLabels{:});
else % nested
    colLabels = cell(size(cols));
    for k = cols
        % each layer of labels need to be deduped against reserved names
        colLabels{k} = dedupelabels(vals2labels(gData{k},gvLabels(k)));
    end
    % Create the layers of tables and re-place them in cells
    numTotal = prod(numCols);
    for k = numel(cols): -1 : 2
        numK = numCols(k);
        for j = 1:(numTotal/numK)
            ind = ((j-1)*numK + 1):(j*numK);
            if j==1
                % initialize one sub-table to be used across each layer
                nestedTable = table.init(gStats(ind),heightP,{},numK,colLabels{k});
                gStats{j} = nestedTable;
            else
                % update the data for each subsequent sub-table since each
                % sub-table per layer shares same size, type, and labels
                for m = 1:numel(ind)
                    nestedTable.(m) = gStats{ind(m)};
                end
                gStats{j} = nestedTable;
            end
        end
        numTotal = numTotal/numK;
    end
    gStats = gStats(:,1:numTotal);
    colLabels = colLabels{1};
end
% Row data and corresponding variable names
rowData = gData(rows);
numR = numel(rows);
if useRowNames
    if numR > 1
        % Convert all the row data to string
        rowLabels = cell(size(rows));
        for k = 1:numR
            rowLabels{k} = vals2labels(rowData{k},gvLabels(rows(k)));
        end
        % Duplicate and concatenate them together for row labels
        rowLabels = combos(true,rowLabels{:});
    elseif numR == 1
        % Convert the column of row data to string
        rowLabels = vals2labels(rowData{1},gvLabels(rows));
    else
        rowLabels = {};
    end
    if includeTotals && ~isempty(columnTotals)
        % Add a row for column totals
        rowLabels(end+1) = matlab.lang.makeUniqueStrings(totalLabel,rowLabels);
    end
    rowDataNames = {};
    rowData = {};
else
    if numR > 1
        rowData = combos(false,rowData{:});
    end
    if includeTotals && ~isempty(columnTotals)
        strIdx = [];
        needCellstr = false;
        needCategory = false;
        for k = 1:numR
            % add an appropriate missing at the bottom of each row variable
            rowData{k} = [rowData{k}; matlab.internal.datatypes.defaultarrayLike([1 1],"like",rowData{k});];
            if isempty(strIdx)
                % find the first string, cellstr, or categorical to put a label
                if iscellstr(rowData{k})
                    strIdx = k;
                    needCellstr = true;
                elseif iscategorical(rowData{k})
                    strIdx = k;
                    needCategory = true;
                elseif isstring(rowData{k})
                    strIdx = k;
                end
            end
        end
        % add label to total row in the left-most valid Rows variable
        if ~isempty(strIdx)
            % uniquify label (e.g. if Overall_count is already a group name)
            colTotalLabel = matlab.lang.makeUniqueStrings(totalLabel,string(rowData{strIdx}(1:end-1)));
            if needCategory
                % For categorical, add as a proper category (necessary for ordinals)
                currCats = categories(rowData{strIdx});
                rowData{strIdx} = addcats(rowData{strIdx},colTotalLabel,'After',currCats{end});
            end
            if needCellstr
                rowData{strIdx}(end) = cellstr(colTotalLabel);
            else % string or cat
                rowData{strIdx}(end) = colTotalLabel;
            end
        end
        % if no string, cat, or cellstr Rows variable, label is omitted
    end
    rowDataNames = gvLabels(rows);
    rowLabels = {};
end

% -------------------------------------------------------------------------
% Step 5: Put all the pieces together
if includeTotals && ~isempty(rowTotals)
    varNames = dedupelabels([rowDataNames(:); colLabels(:); totalLabel]);
    vars = [rowData gStats {rowTotals}];
else
    varNames = dedupelabels([rowDataNames(:); colLabels(:)]);
    vars = [rowData gStats];
end
P = table.init(vars,heightP,rowLabels,numel(varNames),varNames);

% -------------------------------------------------------------------------
% Helpers
function [colData,rowData,groupingData,dataVar,dataVarInd,...
    method,methodName,gBins,gbprovided,expandBins,doflat,includedEdge,...
    includeTotals,includeMissing,includeEmpty,useRowNames] = validateNVpairs(T,nvpairs)

% Parameter defaults
colGroupingData = cell(1,0);
colData = string.empty;
rowGroupingData = cell(1,0);
rowData = string.empty;
dataVar = [];
dataVarInd = [];
methodSupplied = false;
colBinsProvided = false;
colBins = [];
rowBinsProvided = false;
rowBins = [];
doflat = false;
includedEdge = "left";
inclEdgeProvided = false;
includeTotals = false;
includeMissing = true;
includeEmpty = false;
useRowNames = false;
% Validate NV pairs
NVnames = ["Columns" "Rows" "DataVariable" "Method" "ColumnsBinMethod" "RowsBinMethod" ...
    "IncludedEdge" "OutputFormat" "IncludeTotals" "IncludeMissingGroups" ...
    "IncludeEmptyGroups" "RowLabelPlacement"];
for j = 1:2:length(nvpairs)
    NVind = matlab.internal.math.checkInputName(nvpairs{j},NVnames);
    if nnz(NVind) ~= 1
        if NVind(1) && NVind(5)
            % allow "Col" to mean "Columns", not "ColumnsBinMethod"
            NVind(5) = false;
        elseif NVind(2) && NVind(6)
            % allow "Row" to mean "Rows", not "RowsBinMethod"
            NVind(6) = false;
        else
            error(message("MATLAB:pivot:ParseFlags"))
        end
    end
    val = nvpairs{j+1};
    if NVind(1) % Columns
        [colGroupingData,colData] = matlab.internal.math.parseGroupVars(val,true,"pivot:Cols",T);
    elseif NVind(2) % Rows
        [rowGroupingData,rowData] = matlab.internal.math.parseGroupVars(val,true,"pivot:Rows",T);
    elseif NVind(3) % DataVariable
        dataVarInd = matlab.internal.math.checkDataVariables(T,val,"pivot","Data");
        if numel(dataVarInd) > 1
            error(message("MATLAB:pivot:OnlyOneDataVariable"));
        elseif ~isempty(dataVarInd)
            % get the var names for better error messages
            names = T.Properties.VariableNames;
            dataVar = string(names(dataVarInd));
        end
    elseif NVind(4) % Method
        method = val;
        % allow method=[] for specifying default
        methodSupplied = ~(isempty(method) && isa(method,'double'));
        if methodSupplied && ~isa(method,"function_handle") && ~any(matlab.internal.math.checkInputName(method,...
                ["count","percentage","mean","sum","min","max","range","median",...
                "mode","var","std","nummissing","nnz","numunique","none"]))
            error(message("MATLAB:pivot:InvalidMethodOption"));
        end
    elseif NVind(5) % ColumnsBinMethod
        colBins = val;
        colBinsProvided = true;
        % need number of groups to validate this input
    elseif NVind(6) % RowsBinMethod
        rowBins = val;
        rowBinsProvided = true;
        % need number of groups to validate this input
    elseif NVind(7) % IncludedEdge
        inclEdgeOpts = ["left","right"];
        inclEdgeInd = matlab.internal.math.checkInputName(val,inclEdgeOpts);
        if ~any(inclEdgeInd)
            error(message("MATLAB:pivot:InvalidIncludedEdge"));
        end
        includedEdge = inclEdgeOpts(inclEdgeInd);
        inclEdgeProvided = true;
    elseif NVind(8) % OutputFormat
        fmtInd = matlab.internal.math.checkInputName(val,["nested" "flat"]);
        if ~any(fmtInd)
            error(message("MATLAB:pivot:InvalidOutputFormat"));
        end
        doflat = fmtInd(2);
    elseif NVind(9) % IncludeTotals
        includeTotals = matlab.internal.datatypes.validateLogical(val,"IncludeTotals");
    elseif NVind(10) % IncludeMissingGroups
        includeMissing = matlab.internal.datatypes.validateLogical(val,"IncludeMissingGroups");
    elseif NVind(11) % IncludeEmptyGroups
        includeEmpty = matlab.internal.datatypes.validateLogical(val,"IncludeEmptyGroups");
    else % RowLabelPlacement
        locInd = matlab.internal.math.checkInputName(val,["rownames" "variable"]);
        if ~any(locInd)
            error(message("MATLAB:pivot:InvalidRowLabelPlacement"));
        end
        useRowNames = locInd(1);
    end
end
% Must have at least one grouping variable
if isempty(rowData) && isempty(colData)
    error(message("MATLAB:pivot:SpecifyColumnsOrRows"));
end

% Set default method based on dataVar
if ~methodSupplied
    method = "count";
    if ~isempty(dataVar)
        val = T.(dataVarInd);
        if isnumeric(val) || isduration(val) || islogical(val)
            method = "sum";
        end
    end
end
% Get function handle and name for provided method
[method,methodName] = matlab.internal.math.groupMethod2FcnHandle(method,"pivot");
if ~isempty(method)
    if isequal(methodName,"fun")
        str = func2str(method);
        if ~startsWith(str,'@')
            % Named function: adding "fun_" delineates this method from
            % named methods in internal helpers. It should be removed
            % before string goes into error messages or variable names.
            methodName = "fun_" + str;
        end
    elseif isequal(methodName,"none") && includeTotals
        error(message("MATLAB:pivot:IncludeTotalsWithNoAggregation"));
    end
    % reducebygroup helper assumes function handles stored in a cell array
    method = {method};
    % else: case count and percentage, no function handle to apply
end

if isempty(dataVar) && ~isempty(method)
    % Function specified, but not data var
    % If there is only one left, then pick it
    names = T.Properties.VariableNames;
    [dataVar,dataVarInd] = setdiff(names,[rowData colData]);
    if numel(dataVar) ~= 1
        error(message("MATLAB:pivot:DataVariableNotSupplied"));
    end
end
% Validate and/or set defaults for binning options
gbprovided = colBinsProvided|| rowBinsProvided;
[rowBins,expandRBins,expandRVars] = validateBinMethod(rowBins,"Rows",gbprovided,rowBinsProvided,numel(rowData));
[colBins,expandCBins,expandCVars] = validateBinMethod(colBins,"Cols",gbprovided,colBinsProvided,numel(colData));
gBins = [colBins rowBins];
expandBins = expandRBins || expandCBins;
if ~gbprovided && inclEdgeProvided
    % binning isn't specified, so IncludedEdge shouldn't be either
    error(message("MATLAB:pivot:IncludedEdgeNoGroupBins"));
end
% Expand grouping variable if needed
if expandRVars
    rowGroupingData = repmat(rowGroupingData, 1, numel(rowBins));
    rowData = repmat(rowData, 1, numel(rowBins));
end
if expandCVars
    colGroupingData = repmat(colGroupingData, 1, numel(colBins));
    colData = repmat(colData, 1, numel(colBins));
end
groupingData = [colGroupingData rowGroupingData];

function [bins,didexpand,expandvars] = validateBinMethod(bins,flag,gbprovided,binsprovided,numG)
% Validate RowsBinMethod and ColumnsBinMethod
didexpand = false;
expandvars = false;
if ~gbprovided
    % Bins are unused
    bins = [];
elseif ~binsprovided
    % Bins are concatenated with user provided bins
    bins = repmat({"none"},1,numG);
elseif ~isempty(bins) && matlab.internal.math.isgroupbins(bins,"pivot")
    [bins,didexpand,expandvars] = matlab.internal.math.parsegroupbins(bins,numG,"pivot:" + flag);
    for k = 1:numel(bins)
        if isempty(bins{k})
            % For other grouping functions, discgroupvar checks this, but
            % to get the appropriate message we should check it here
            error(message("MATLAB:pivot:" + flag + "BinsEmpty"));
        end
    end
else
    error(message("MATLAB:pivot:" + flag + "BinsEmpty"));
end

% -------------------------------------------------------------------------
function names = vals2labels(names,varname)
% Convert NAMES to string from any datatype and fill any missing values in
% NAMES with "<missing_VARNAME>"

% Groups are defined by datatypes that are all able to be "stringified":
% string, categorical, duration, datetime, numeric, logical, cellstr
if issparse(names)
    names = full(names);
end
names = string(names);
% Group names have already been uniquified and if there is a missing, it is
% the last group
if ismissing(names(end))
    % Example <missing_Region>
    names(end) ="<missing_" + varname + ">";
end
if strcmp(names(1),"")
    % Empty char ({''} and "") are not treated as missing, but instead get
    % sorted to the first position. Show "" as table var name.
    % Note that it is possible to have both "" and <missing> in string
    % grouping variables.
    names(1) = """""";
end

% -------------------------------------------------------------------------
function names = dedupelabels(names)
% Take NAMES and dedupe them against each other and against reserved names
% for tables and dimension names of the output
reservedNames = matlab.internal.tabular.private.varNamesDim.reservedNames;
names = matlab.lang.makeUniqueStrings(names,...
    [reservedNames "Row" "Variables"],namelengthmax);

% -------------------------------------------------------------------------
function data = combos(doUniform,varargin)
% Return all element combinations of inputs in one array.
numOfInputElems = zeros(1,numel(varargin));
for j = 1:numel(varargin)
    numOfInputElems(j) = numel(varargin{j});
end
if doUniform
    % case all inputs are string vectors and want a single concattenated
    % string vector out (groupnames with "flat" Columns or RowNames)
    idxes = matlab.internal.math.combos(numOfInputElems);
    data = varargin{1}(idxes(:,1));
    for j = 2:length(numOfInputElems)
        data = data + "_" + varargin{j}(idxes(:,j));
    end
else
    % case put each input in its own cell (groups in Rows variables)
    [~,data] = matlab.internal.math.combos(numOfInputElems,varargin);
end