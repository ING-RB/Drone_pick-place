function [isStatisticsSet,specifiedStats,doCounts,doLowDetail,isDataVarsSet,dataVarInd,statsIsDefault] = parseSummaryNVArgs(NVPairs,Xistabular,Xislogical,X,hasStructOutput)
%parseSummaryNVArgs Parse the name-value arguments for summary,
%   tabular/summary, and categorical/summary.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2024 The MathWorks, Inc.

isStatisticsSet = false;
specifiedStats = {};

% Used for categorical input/variable
doCounts = true;

% Used for tabular input
isDataVarsSet = false;
dataVarInd = [];
doLowDetail = true;
statsIsDefault = true; % default stats will vary based on variable type

num = numel(NVPairs);
if rem(num,2) ~= 0
    error(message('MATLAB:summary:KeyWithoutValue'));
end
NVnames = ["Statistics" "Detail"];
if Xistabular
    NVnames = [NVnames "DataVariables"];
end
validDetailLevels = ["low" "high"];
for j = 1:2:num
    nameTF = matlab.internal.math.checkInputName(NVPairs{j},NVnames);
    if nnz(nameTF) ~= 1
        if Xistabular
            error(message('MATLAB:summary:ParseNamesTabular'));
        else
            error(message('MATLAB:summary:ParseNames'));
        end
    end
    if nameTF(1) % Statistics
        [specifiedStats,doCounts,statsIsDefault] = validateStats(NVPairs{j+1},Xislogical,X);
        isStatisticsSet = true;
    elseif nameTF(2) % Detail
        % Detail is allowed for all input types, but it is only meaningful
        % when the input is tabular and the output is display.
        detailLevel = matlab.internal.math.checkInputName(NVPairs{j+1},validDetailLevels);
        doLowDetail = detailLevel(1);
        if nnz(detailLevel) ~= 1
            error(message('MATLAB:summary:InvalidDetail'));
        elseif doLowDetail && Xistabular && hasStructOutput
            % When the input is tabular and the output is a struct, we
            % always return all summary information, never a "low" Detail
            % amount of information.
            warning(message('MATLAB:summary:LowDetailStructOutput'));
        end
    else % DataVariables
        dataVarInd = matlab.internal.math.checkDataVariables(X,NVPairs{j+1},"summary");
        isDataVarsSet = true;
    end
end
end

%--------------------------------------------------------------------------
function [stats,isKeywordSpecified,isOnlyDefault] = validateStats(stats,Xislogical,X)
% Adapted from parseMethods in groupsummary 
% Assemble the specified statistics into a cell array. Check and replace
% keywords ("counts", "allstats", and "default") with the corresponding
% list of statistics.
if isstring(stats)
    stats = num2cell(stats);
elseif ~iscell(stats)
    stats = {stats};
end
numStats = numel(stats);
isOnlyDefault = false;

if isscalar(stats) 
    if matlab.internal.math.checkInputName(stats{1},"none",2)
        % No computations when statistics is specified as "none"
        stats = {};
        isKeywordSpecified = false;
        return
    elseif matlab.internal.math.checkInputName(stats{1},"default",1)
        stats = matlab.internal.math.getDefaultSummaryStatistics(X);
        isKeywordSpecified = true;
        isOnlyDefault = true;
        return
    end
end

% Track locations of the keywords: "counts", "allstats", and "default"
idxKeywords = false(1,numStats);
firstKeyword = (numStats+1) .* ones(1,3);

% Check for invalid stats and keywords.
% We perform more specific checks for ambiguity and deduping later in the
% code after we have parsed all NV arguments.
validStats = ["nummissing", "min", "q1", "median", "q3", "max", "range", "mean", "std", ...
    "var", "sum", "mode", "nnz", "numunique"];
for k = numStats:-1:1
    if ~isa(stats{k},"function_handle")
        ind = matlab.internal.math.checkInputName(stats{k},[validStats "counts" "allstats" "default"]);
        if ~any(ind)
            if matlab.internal.math.checkInputName(stats{k},"none")
                error(message('MATLAB:summary:StatisticsHasInvalidNone'));
            else
                error(message('MATLAB:summary:InvalidMethodOption'));
            end
        elseif ind(end-2) % counts
            idxKeywords(k) = true;
            firstKeyword(1) = k;
        elseif ind(end-1) % allstats
            idxKeywords(k) = true;
            firstKeyword(2) = k;
        elseif ind(end) % default
            idxKeywords(k) = true;
            firstKeyword(3) = k;
        end
    end
end

isKeywordSpecified = any(idxKeywords);
if isKeywordSpecified
    % Delete keywords ("counts", "allstats", and "default") from the list
    % of stats and replace them with the actual stats they represent.
    stats(idxKeywords) = [];
    [sortedIdx,keywordOrder] = sort(firstKeyword);
    numAdded = 0;
    ii = 1;
    % Process "counts", "allstats", and "default" in the order they were
    % specified. We can stop if sortedIdx(ii) indicates they were not
    % specified at all.
    while ii <= 3 && sortedIdx(ii) <= numStats
        keyword = keywordOrder(ii);
        startIdx = sortedIdx(ii) + numAdded - nnz(idxKeywords(1:sortedIdx(ii)));
        if keyword == 1 % counts
            if Xislogical
                stats = [stats(1:startIdx) {"true" "false"} stats(startIdx+1:end)];
                numAdded = numAdded + 2;
            end
        elseif keyword == 2 % allstats
            if Xislogical && ii == 1
                stats = [stats(1:startIdx) num2cell(validStats) {"true" "false"} stats(startIdx+1:end)];
            else
                stats = [stats(1:startIdx) num2cell(validStats) stats(startIdx+1:end)];
            end
            % Once "allstats" is processed, we do not need to look for
            % "counts" or "default" because those stats would be deleted
            % later anyway when the stats are deduped.
            break;
        else % default
            defaultStats = matlab.internal.math.getDefaultSummaryStatistics(X);
            stats = [stats(1:startIdx) defaultStats stats(startIdx+1:end)];
            numAdded = numAdded + numel(defaultStats);
        end
        ii = ii + 1;
    end
end
end