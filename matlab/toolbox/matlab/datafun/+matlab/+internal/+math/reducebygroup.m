function [gCount,gData,gStats,gvLabels,gStatsLabel,groupingData] = reducebygroup(T,...
    groupingData,groupVars,gvLabels,gbProvided,groupBins,inclEdge,scalarExpandBins,...
    scalarExpandVars,dataVars,dvNotProvided,dvSets,methods,methodPrefix,numMethods,numMethodInput,...
    eid,tableFlag,doGDataUnique,doGDataCombos,needCounts,inclNan,inclEmpty,inclEmptyCats)
%REDUCEBYGROUP holds the groupsummary/pivot implementation after
%input parsing and before output arrangement
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2022-2024 The MathWorks, Inc.

isforGS = isequal(eid,"groupsummary");
if gbProvided
    % Discretize grouping variables and remove repeated pairs of grouping
    % variables and group bins
    [groupingData,groupVars,gvLabels] = matlab.internal.math.discgroupvar(groupingData,...
        groupVars,gvLabels,groupBins,inclEdge,scalarExpandBins,scalarExpandVars,eid,tableFlag);
elseif tableFlag && isforGS
    % Remove repeated grouping variables
    [groupVars,ridx] = unique(groupVars,"stable");
    groupingData = groupingData(ridx);
    gvLabels = gvLabels(ridx);
end

% Compute grouping index and data
numrows = size(T,1);
if iscell(T) && ~iscellstr(T) && ~isempty(T) %#ok<ISCLSTR>
    numrows = size(T{1},1);
end
if nargin < 24
    inclEmptyCats = inclEmpty;
end
[gvIdx,numGroups,gDataUnique,gDataCombos,gCount] = matlab.internal.math.mgrp2idx(groupingData,...
    numrows,inclNan,inclEmpty,doGDataUnique,doGDataCombos,needCounts,inclEmptyCats);
if doGDataCombos
    gData = gDataCombos;
else
    gData = gDataUnique;
end

% Set group count correctly in case of 0xN input
if ~tableFlag && numrows == 0
    numGroups = 0;
    if needCounts
        gCount = zeros(0,1);
    end
end

% Extract data variables
if numMethods == 0
    gStatsLabel = strings(0);
    gStats = {};
    return
else
    if numMethodInput > 1
        % Each column of dvData will have the data input sets
        if tableFlag
            numDataVars = numel(dataVars);
            dataLabels = dataVars;
            dvData = cell(size(dvSets));
            for k=1:numel(dvSets)
                dvData{k} = T.(dvSets(k));
            end
        else
            numDVSets = unique(cellfun(@(x)size(x,2),T));
            if numel(numDVSets) > 2 || (numel(numDVSets) == 2 && numDVSets(1) ~= 1)
                error(message("MATLAB:groupsummary:FirstInputSizeCell"));
            end
            numDataVars = numDVSets(end);

            % To avoid errors create numbered labels
            dataLabels = string(1:numDataVars);

            % Copy columns over to cell array
            if numDataVars ~= 0
                dvData = cell(numMethodInput,numDataVars);
                for k=1:numel(T)
                    if size(T{k},2) == 1
                        for jj = 1:numDataVars
                            dvData{k,jj} = T{k}(:,1);
                        end
                    else
                        for jj = 1:size(T{k},2)
                            dvData{k,jj} = T{k}(:,jj);
                        end
                    end
                end
            else
                % Special case where cell contains nx0 matrices
                dvData = T(:);
                numDataVars = 1;
                dataLabels="1";
            end
        end
    else
        [dvData,dataLabels,numDataVars] = matlab.internal.math.extractDataVars(T,groupVars,dataVars,tableFlag,dvNotProvided,true);
    end
end

% Compute group summary computations
gStats = cell(1,numMethods*numDataVars);
gStatsLabel = strings(1,numMethods*numDataVars);
% Remove NaNs from gvIdx, which represent missing groups when we don't include them
idx = ~isnan(gvIdx);
gvIdx = gvIdx(idx);

% Special case 'sum'/'min'/'max'/'mean' under certain conditions

useAccumarray = false(1,numMethods);
if numDataVars == 1 && numMethodInput == 1 && iscolumn(dvData{:}) && ...
        ~issparse(dvData{:}) && (isnumeric(dvData{:}) || islogical(dvData{:})) ...
        && ~isobject(dvData{:})
    useAccumarray = matches(methodPrefix,["sum","min","max","mean"]);
end

needToApplyFunByGroup = ~all(useAccumarray) && ~isempty(gvIdx) && ~isequal(numGroups,1);
if needToApplyFunByGroup
    % Sort the groups and get index.
    [gvIdx,sortOrd] = sort(gvIdx);
    % Find the first and last element for each group
    grpStart = find([1;diff(gvIdx)>0]);
    grpEnd = [grpStart(2:end)-1;length(gvIdx)];
    outGrpIdx = gvIdx(grpStart);
    % Avoid fillval issues if we don't actually have empty groups
    inclEmpty = inclEmpty && (numel(grpStart) ~= numGroups);
end

for ii = 1:numDataVars
    % Extract set of data to be passed to method. x will be a cell,
    % where each cell is the data for each input to the method
    x = dvData(:,ii);
    szX = nnz(idx);

    if numMethodInput == 1
        % Special case one input for performance
        x = x{1};
        if ~isempty(x)
            higherDimSizes = size(x,2:ndims(x));
            x = x(idx,:);
            if needToApplyFunByGroup
                x = x(sortOrd,:);
            end
            if numel(higherDimSizes) > 1
                x = reshape(x, [szX,higherDimSizes]);
            end
        end
        x = {x};
    else
        % When not including missing groups, need to remove data associated with those groups
        for k = 1:numMethodInput
            if ~isempty(x{k})
                szX = size(x{k},1);
                higherDimSizes = size(x{k},2:ndims(x{k}));
                % Need this in case x is a table
                x{k} = x{k}(idx,:);
                if needToApplyFunByGroup
                    x{k} = x{k}(sortOrd,:);
                end
                if numel(higherDimSizes) > 1
                    x{k} = reshape(x{k}, [szX,higherDimSizes]);
                end
            end
        end
    end
    for jj = 1:numMethods        
        if isequal(methodPrefix(jj),"median") && ischar(dvData{ii})
            % Error for median of char
            error(message("MATLAB:groupsummary:MedianMethodWithChar"));
        elseif isequal(methodPrefix(jj),"numunique") && ~(iscolumn(dvData{ii}) || isempty(dvData{ii}))
            % Error for numunique of 2D/ND
            error(message("MATLAB:groupsummary:NumUniqueWithNonColumn"))
        end

        try
            f = methods{jj};
            % If not grouping by anything then apply method directly
            if isempty(gvIdx) || isequal(numGroups,1)
                d = f(x{:});
                if tableFlag
                    if size(d,1) > 1
                        error(message("MATLAB:groupsummary:InvalidMethodOutputTable"));
                    end
                else
                    if numel(d) > 1
                        error(message("MATLAB:groupsummary:InvalidMethodOutputArray"));
                    end
                end
                if isempty(gvIdx)
                    % If we need to build empty for x, build it out of the class of d
                    if any(cellfun(@isempty,x))
                        c = str2func([class(d) '.empty']);
                        if (numGroups == 0)
                            if issparse(d)
                                d = sparse(c(size(x{1},1),size(x{1},2)));
                            else
                                d = c(size(x{1},1),size(x{1},2));
                            end
                        elseif inclEmpty && isempty(d)
                            if issparse(d)
                                d = sparse(c(1,0));
                            else
                                d = c(1,0);
                            end
                        end
                    end
                    % Expand d to make sure we have the right number of groups
                    % (which will all be empty in this case)
                    d = repmat(d,numGroups,1);
                end
            else
                % Otherwise apply function by group
                if inclEmpty
                    fillval = matlab.internal.math.groupGetFillVal(x,methods{jj},methodPrefix(jj));
                else
                    if useAccumarray(jj)
                        fillval = zeros(0,'like',x{:});
                    else
                        fillval = [];
                    end
                end

                if useAccumarray(jj)
                    d = applyAccumarray(x,gvIdx,gCount,numGroups,methodPrefix(jj),needCounts,fillval,inclEmpty);
                else
                    d = applyFunByGroup(grpStart,grpEnd,outGrpIdx,x,numGroups,f,numMethodInput,tableFlag,fillval);
                end
            end

            gStats{(ii-1)*numMethods + jj} = d;
            gStatsLabel((ii-1)*numMethods + jj) = methodPrefix(jj) + '_' + dataLabels(ii);
        catch ME
            % Return error message with added information
            if tableFlag
                mid = "MATLAB:groupsummary:ApplyDataVarsError";
            else
                mid = "MATLAB:groupsummary:ApplyDataVecsError";
            end
            methodName = methodPrefix(jj);
            if ~isforGS && startsWith(methodName,"fun_")
                % Named custom function, just use the provided name
                methodName = extractAfter(methodName,"_");
            end
            m = message(mid,methodName,dataLabels(ii));
            throw(addCause(MException(m.Identifier,'%s',getString(m)),ME));
        end
    end
end
end

%--------------------------------------------------------------------------
function a = applyFunByGroup(grpStart,grpEnd,outGrpIdx,x,numGroups,fun,numMethodInput,tableFlag,fillval)
% APPLYFUNBYGROUP Apply function to data using sorted groups

% Apply the function to the first group to get the type/size of the output
% to preallocate

if numMethodInput == 1
    multMethodInputs = false;
    x = x{:};
    needReshape = ~ismatrix(x);
else
    multMethodInputs = true;
    gvals = cell(1,numMethodInput);
end
xIsColumn = iscolumn(x) && ~istabular(x);

grpSz = grpEnd(1) - grpStart(1) + 1;
if multMethodInputs
    ndimsData = zeros(numMethodInput,1);
    for k = 1:numMethodInput % A for loop is faster than using cellfun
        ndimsData(k) = ndims(x{k});
        ind = repmat({':'},ndimsData(k)-1,1);
        gvals{k} = x{k}(grpStart(1):grpEnd(1),ind{:});
    end
    ind = repmat({':'},max(ndimsData)-1,1);
    d = fun(gvals{:});
else
    if needReshape
        szXiter = size(x,2:ndims(x));
        gvals = reshape(x(grpStart(1):grpEnd(1),:), [grpSz, szXiter]);
    else
        if xIsColumn
            % Column vector inputs are indexed differently for performance
            gvals = x(grpStart(1):grpEnd(1));
        else
            gvals = x(grpStart(1):grpEnd(1),:);
        end
    end
    d = fun(gvals);
end

% Check to make sure method returned one element per group
if tableFlag
    if size(d,1) > 1
        error(message("MATLAB:groupsummary:InvalidMethodOutputTable"));
    end
else
    if numel(d) > 1
        error(message("MATLAB:groupsummary:InvalidMethodOutputArray"));
    end
end
useIdxOutput = false;
if ~ismatrix(d)
    useIdxOutput = true;
    idxOutput = repmat({':'},ndims(d)-1,1);
end
sz = [numGroups, size(d,2:ndims(d))];
if isempty(fillval)
    a = repmat(d,[numGroups 1]);
else
    maxDim = max(ndims(fillval),ndims(d));
    fillvalSameSize = all(size(fillval,1:maxDim) == size(d,1:maxDim));
    if ~(isscalar(fillval) || fillvalSameSize)
        % If the fillval is not a scalar or the same size as d, just make
        % it missing
        fillval = missing;
        fillvalSameSize = false;
    end
    if isa(fillval,'missing')
        % Get around the fact that you can't replace a value in a vector of
        % missing
        szFV = size(fillval);
        if isempty(d)
            temp = [d,fillval];
            fillval = temp(1);
        else
            temp = [d(1),fillval(1)];
            fillval = temp(2);
        end
        fillval = repmat(fillval,szFV);
    end
    if fillvalSameSize
        % If the fillval is the same size as d, just expand first dimension
        a = repmat(fillval,[numGroups 1]);
    else
        % If fillval is a scalar expand in all dimensions to get output the
        % right size
        a = repmat(fillval,sz);
    end
    % Correct sparsity in case fill value was not sparse and d was sparse
    if issparse(d) && ~issparse(fillval)
        a = sparse(a);
    end
    if useIdxOutput
        a(outGrpIdx(1),idxOutput{:}) = d;
    else
        a(outGrpIdx(1),:) = d;
    end
end
szD = size(d);

% Apply function to remaining groups
for g = 2:length(grpStart)
    grpSz = grpEnd(g) - grpStart(g) + 1;
    if multMethodInputs
        for k = 1:numMethodInput
            % Using ind here is faster than using reshape
            gvals{k} = x{k}(grpStart(g):grpEnd(g),ind{:});
        end
        d = fun(gvals{:});
    else
        if needReshape
            gvals = reshape(x(grpStart(g):grpEnd(g),:), [grpSz, szXiter]);
        else
            if xIsColumn
                % Column vector inputs are indexed differently for performance
                gvals = x(grpStart(g):grpEnd(g));
            else
                gvals = x(grpStart(g):grpEnd(g),:);
            end
        end
        d = fun(gvals);
    end

    % Check to make sure method returned one element per group
    if ~isequal(size(d),szD)
        if tableFlag
            error(message("MATLAB:groupsummary:InvalidMethodOutputTable"));
        else
            error(message("MATLAB:groupsummary:InvalidMethodOutputArray"));
        end
    end
    if useIdxOutput
        a(outGrpIdx(g),idxOutput{:}) = d;
    else
        a(outGrpIdx(g),:) = d;
    end
end
end

%--------------------------------------------------------------------------
function d = applyAccumarray(x,gvIdx,gCount,numGroups,currentMethodPrefix,needCounts,fillval,inclEmpty)
y = x{:}; % It is guaranteed that y is a vector
if isequal(currentMethodPrefix,"sum")
    % Default sum in accumarray includes NaNs
    missingLoc = isnan(y);
    if any(missingLoc)
        y(missingLoc) = 0;
    end
    f = @sum;
elseif isequal(currentMethodPrefix,"mean")
    % Compute mean fast by using accumarray to get
    % sum and counts and then divide
    if inclEmpty && ismissing(fillval)
        % Use a fill value that matches the output type of MEAN
        if isa(y,'single')
            fillval = nan('single');
        else
            fillval = nan;
        end
    end
    if anynan(y)
        % Need to compute counts again since
        % mean method does 'omitnan'
        nanLoc = isnan(y);
        gCountNoNaN = accumarray(gvIdx(~nanLoc),1,[numGroups 1]);
        % Default sum in accumarray includes NaNs
        y(nanLoc) = 0;
    elseif ~needCounts
        gCountNoNaN = accumarray(gvIdx,1,[numGroups 1]);
    else
        gCountNoNaN = gCount;
    end
    f = @sum;
else % method is "min" or "max"
    if inclEmpty && ismissing(fillval)
        % y must be a float to reach this branch because fillval is the
        % same type as y for these methods
        fillval = nan("like",y);
    end
    if isequal(currentMethodPrefix,"min")
        f = @min;
    else % "max"
        f = @max;
    end
end
d = accumarray(gvIdx,y,[numGroups 1],f,fillval);
if isequal(currentMethodPrefix,"mean")
    d = d./gCountNoNaN;
end
end