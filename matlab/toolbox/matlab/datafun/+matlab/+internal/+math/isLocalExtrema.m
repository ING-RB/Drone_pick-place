function [tf, P] = isLocalExtrema(A, isMaxSearch, varargin)
%ISLOCALEXTREMA Mark local minimum or maximum values in an array.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2017-2023 The MathWorks, Inc.

    is2D = false;
    [dim, maxNumExt, minSep, minProm, flatType, x, dataVars, pwin, fmt] = ...
        matlab.internal.math.parseLocalExtremaInputs(A, is2D, varargin{:});

    returnProminence = nargout > 1;
    
    if istabular(A)
        [tf,P] = isLocalExtremaTabular(A, dataVars, maxNumExt, minSep, ...
            minProm, flatType, x, isMaxSearch, returnProminence, pwin, fmt);
    else
        if (dim > ndims(A))
            % There are no local extrema in scalar dimensions.
            tf = false(size(A));
            if returnProminence
                P = zeros(size(A), getProminenceType(A));
            end
        else
            % Operate along rows.
            if (dim ~= 1)
                permvec = [dim, 1:(dim-1), (dim+1):ndims(A)];
                A = permute(A, permvec);
            end
            
            [tf, P] = isLocalExtremaArray(A, maxNumExt, minSep, minProm,...
                flatType, x, isMaxSearch, returnProminence, pwin);
            
            % Reverse permutation.
            if (dim ~= 1)
                tf = ipermute(tf, permvec);
                if returnProminence
                    P = ipermute(P, permvec);
                end
            end
        end
        % Reconvert to sparse if the input was sparse.
        if issparse(A)
            tf = sparse(tf);
            if returnProminence
                P = sparse(P);
            end
        end
    end

end

%--------------------------------------------------------------------------
function [tf, P] = isLocalExtremaTabular(A, dataVars, maxNumExt, minSep,...
    minProm, flatType, x, isMaxSearch, returnProminence, pwin, fmt)
% Search for local extrema in the variables of a table.

    % Check for valid data variables.
    dvValid = true;
    varsAreColumns = true;
    classesMatch = true;
    multiColumn = numel(dataVars) > 1;
    if multiColumn
        % Check if classes match.
        refClass = string(class(A.(dataVars(1))));
    end
    for k = dataVars(:)'
        thisVar = A.(k);
        dvValid = dvValid && validDataVariableType(thisVar);
        varsAreColumns = varsAreColumns && (iscolumn(thisVar) || ...
            (isempty(thisVar) && ismatrix(thisVar) && ...
            all(size(thisVar, 1:2) <= [0 1])));
        classesMatch = multiColumn && classesMatch && (class(thisVar) == refClass);
    end
    if ~dvValid
        if any(varfun(@(x) isnumeric(x) && ~isreal(x), A, ...
            'InputVariables', dataVars, 'OutputFormat', 'uniform'))
            error(message("MATLAB:isLocalExtrema:ComplexInputArray"));
        end
        error(message("MATLAB:isLocalExtrema:NonNumericTableVar"));
    end
    
    % All variables must be column vectors or empties.
    if ~varsAreColumns
        error(message("MATLAB:isLocalExtrema:NonVectorTableVariable"));
    end

    if isequal(fmt,'tabular')
        A = A(:, dataVars);
        P = A;
        tf = A;
        % keep all properties of the input except for these:
        tf.Properties.VariableUnits = {};
        tf.Properties.VariableContinuity = {};
        for i = 1:width(A)
            % Process table variables one at a time, this ensures output
            % variables in tf get set to logical correctly
            [tf.(i), P.(i)] = isLocalExtremaArray(A.(i), maxNumExt, minSep, ...
                 minProm, flatType, x, isMaxSearch, returnProminence, pwin);
        end
    else
        % The data can be processed as one large array if all of the
        % variables are the same type and if they are all columnar data.
        if returnProminence
            P = A(:, dataVars);
        else
            P = [];
        end
        tf = false(size(A));

        if classesMatch && numel(dataVars) > 1
            % Process all table variables at once.
            [tf(:,dataVars), Pout] = isLocalExtremaArray(...
                A{:,dataVars}, maxNumExt, minSep, minProm, flatType, x, ...
                isMaxSearch, returnProminence, pwin);
            if returnProminence
                P{:,:} = Pout;
            end
        else
            % Process table variables one at a time.
            for i = 1:length(dataVars)
                [tf(:,dataVars(i)), Pri] = isLocalExtremaArray(...
                    A.(dataVars(i)), maxNumExt, minSep, minProm, flatType, ...
                    x, isMaxSearch, returnProminence, pwin);
                if returnProminence
                    P.(i) = Pri;
                end
            end
        end
    end
end

%--------------------------------------------------------------------------
function [tf, P] = isLocalExtremaArray(A, maxNumExt, minSep, minProm, ...
    flatType, x, isMaxSearch, returnProminence, pwin)
% Search for local extrema in an array.

    P = [];
    promType = getProminenceType(A);
    if isempty(A)
        tf = false(size(A));
        if returnProminence
            P = zeros(size(A), promType);
        end
        return;
    end

    % Avoid allocating a lot of memory for a sparse logical array.
    sparseLogicalMin = islogical(A) && issparse(A) && ~isMaxSearch;
    if isinteger(A)
        cls = class(A);
        % Convert unsigned types to signed types to preserve diff sign. 
        % For integer types, prominence is always be an unsigned type.
        if cls(1) == 'u'
            scls = cls(2:end);
            imax = cast(intmax(scls), cls);
            B = zeros(size(A), scls);
            idx = A <= imax;
            B(idx) = cast(A(idx), scls) - intmax(scls) - 1;
            B(~idx) = cast(A(~idx) - imax - 1, scls);
            A = B;
        end
        % Reverse the sign of A, and then correct for the elements
        % that were saturated from intmin to intmax.
        if ~isMaxSearch
            satIdx = A == intmin(class(A));
            A = -A;
            A(~satIdx) = A(~satIdx)-1;
        end
    else
        if ~isMaxSearch
            if islogical(A) && ~issparse(A)
                A = ~A;
            else
                A = -A;
            end
        end
    end

    % Cast prominence threshold to the correct class.
    minProm = cast(minProm, promType);
    if sparseLogicalMin
        minProm = double(minProm ~= 0);
    end

    % Reshape A so that we only have 2 dimensions.
    sz = size(A);
    A = reshape(A, size(A,1), []);
    
    if isfloat(A) % single and double
        if issparse(A)
            P = zeros(size(A), 'like', A);
            tf = sparse([], [], false(0,0), size(A,1), size(A,2), nnz(A));
        else
            tf = false(size(A));
            if returnProminence
                P = zeros(size(A), promType);
            end
        end
        % Skip columns that have no non-zeros.
        nontrivialColumns = any(A);
        % Do all columns that have no NaN values.
        nanColumns = any(isnan(A));
        batchCols = ~nanColumns & nontrivialColumns;
        if any(batchCols)
            if all(batchCols)
                [tf, P] = doLocalMaxSearch(...
                    A, maxNumExt, minSep,  minProm, flatType, ...
                    x, returnProminence, pwin);
            else
                [tf(:, batchCols), P(:, batchCols)] = doLocalMaxSearch(...
                    A(:, batchCols), maxNumExt, minSep,  minProm, flatType, ...
                    x, returnProminence, pwin);
            end
        end
        % For each remaining column, remove the points that are NaN.
        nanColumns = find(nanColumns);
        if ~isempty(nanColumns)
            for j = 1:length(nanColumns)
                jdx = nanColumns(j);
                if issparse(A)
                    % Extract the non-NaN rows and compute the result
                    nanRows = find(isnan(A(:,jdx)));
                    [Asub, xsub] = subsampleInputColumnAndSamplePoints(...
                        A, x, jdx, nanRows, minSep, pwin);
                    [tfsub, Psub] = doLocalMaxSearch(Asub, maxNumExt, ...
                        minSep, minProm, flatType, xsub, ...
                        returnProminence, pwin);
                    % Convert the results to fit in the output array.
                    [tf(:,jdx), P(:,jdx)] = resampleResults(tfsub, Psub,...
                        size(A,1), nanRows);
                else
                    % Subsample the input and output.
                    idx = ~isnan(A(:,jdx));
                    if isempty(x)
                        xsub = find(idx);
                    else
                        xsub = x(idx);
                    end
                    [tf(idx,jdx), P(idx,jdx)] = doLocalMaxSearch(...
                        A(idx,jdx), maxNumExt, minSep, minProm, ...
                        flatType, xsub, returnProminence, pwin);
                end
            end
        end
    else % Integer types
        [tf, P] = doLocalMaxSearch(A, maxNumExt, minSep, minProm, ...
            flatType, x, returnProminence, pwin);
    end

    % Reshape the result to the original size of A.
    tf = reshape(tf, sz);
    if returnProminence
        P = reshape(P, sz);
        if sparseLogicalMin
            % Ensure the correct class for the output.
            P = logical(P);
        end
    end

end

%--------------------------------------------------------------------------
function [maxVals, P] = doLocalMaxSearch(A, maxNumExt, minSep, minProm, ...
    flatType, x, returnProminence, pwin)
% Search for local maxima in an array without NaN.

    if issparse(A)
        P = zeros(size(A), 'like', A);
    else
        P = zeros(size(A), getProminenceType(A));
    end
    if size(A,1) < 3
        maxVals = false(size(A));
        return;
    end

    % Replace all positive infinites with NaN temporarily.
    if isfloat(A)
        infMaxVals = isinf(A) & (A > 0);
        A(infMaxVals) = NaN;
    end

    % Get the local maxima and inflection points.
    flatTypeIsLast = strcmp(flatType, 'last');
    if flatTypeIsLast
        % Flip the array for the search, then revert the flip.
        [maxVals, inflectionPts, dA] = getAllLocalMax(flip(A, 1));
        maxVals = flip(maxVals, 1);
        dA = flip(dA);
        inflectionPts = flip(inflectionPts, 1);
    else
        [maxVals, inflectionPts, dA] = getAllLocalMax(A);
    end

    % Recombine the finite and infinite local maxima.
    if isfloat(A)
        maxVals = maxVals | infMaxVals;
        A(infMaxVals) = Inf;
    end

    preFilteredMaxima = maxVals;
    
    % Calculate the prominence and filter local maxima based on the minumum
    % prominence criteria.
    filterByMaxNum = any(maxNumExt < sum(maxVals));
    calculateProminence = returnProminence || filterByMaxNum || (minSep > 0);
    if (minProm > 0) || calculateProminence
        if ~isempty(pwin) && isdatetime(x)
            xs = datetime.toMillis(x);
        elseif ~isempty(pwin) && isduration(x)
            xs = milliseconds(x);
        else
            xs = x;
        end
        if isduration(pwin)
            pwin = milliseconds(pwin);
        end
        if calculateProminence
            [maxVals,P] = matlab.internal.math.getProminence(A, maxVals, ...
                inflectionPts, minProm, xs, pwin);
        else
             maxVals = matlab.internal.math.getProminence(A, maxVals, ...
                inflectionPts, minProm, xs, pwin);
        end
    end

    % Filter local maxima based on distance.
    if (minSep > 0)
        % This will also restrict to the top N most prominent maxima.
        maxVals = filterByDistance(A, P, maxVals, x, minSep, ...
            flatTypeIsLast);
    end
    
    % Restrict to the top N most prominent local maxima.
    if any(maxNumExt < sum(maxVals))
        maxVals = restrictNumberOfExtrema(A, maxVals, maxNumExt, P);
    end

    % Adjust results in flat regions.
    if ~((strcmp(flatType, 'first') || strcmp(flatType, 'last')) && ...
            ~returnProminence)
        [maxVals, P] = adjustFlatRegions(dA, maxVals, preFilteredMaxima, ...
            flatType, P, returnProminence);
    end

end

%--------------------------------------------------------------------------
function [maxVals, inflectionPts, dA] = getAllLocalMax(A)
% Find all local maxima along the rows of A.

    dA = diff(A);
    if issparse(A)
        [maxVals, inflectionPts] = matlab.internal.math.getAllLocalMaxSparse(A);
        return;
    end

    % Find local maxima.
    s = sign(dA);

    if anynan(A)
        nanMask = isnan(A);
        % Non-finites in A represent +Inf entries, and the sign mask must
        % reflect the behavior of +Inf.
        s(nanMask(1:(end-1),:)) = -1;
        s(~nanMask(1:(end-1),:) & nanMask(2:end,:)) = 1;
    end

    maxVals = false(size(A));
    inflectionPts = maxVals;
    if anynan(s)
        s(isnan(s)) = 0;
    end
    mask = s ~= 0;
    if size(A,2) > 1
        for k = 1:size(A,2)
            % Remove repeated points, keep a mask of where our unique points
            % are.  This allows us to assign into the correct locations.
            if ~any(mask(:,k))
                continue;
            end
            sk = s(mask(:,k), k);
            mv = [false; diff(sk) < 0; false];
            ip = [true; sk(1:(end-1)) ~= sk(2:end); true];
            maxVals([true; mask(:,k)],k) = mv;
            inflectionPts([true; mask(:,k)], k) = ip;
        end
    elseif any(mask)
        s = s(mask);
        ds = diff(s);
        mv = [false; ds < 0; false];
        ip = [true; ds ~= 0; true];
        maxVals([true; mask]) = mv;
        inflectionPts([true; mask]) = ip;
    end
end

%--------------------------------------------------------------------------
function maxVals = filterByDistance(A, P, maxVals, x, minSep, ...
    flatTypeIsLast)
% Remove local maxima that are too close to a larger local maxima.

    % Create a linear index array for each column.
    m = size(A,1);
    if ~issparse(A)
        idx = 1:m;
    end

    if issparse(x)
        % Convert implicit sample points to a function handle.
        x = @(k) subsampleImplicitSamplePoints(full(x), k);
    elseif isempty(x)
        x = @(k) k;
    end
    
    for j = 1:size(A,2)
        
        % Get the linear indices of all local maxima in this column.
        if ~issparse(A)
            locMaxima = idx(maxVals(:,j));
        else
            locMaxima = find(maxVals(:,j));
        end
        d = find(diff(A(:,j)));
        n = length(locMaxima);
        
        % Get the left and right indices for each local maxima in this
        % column.  These indices dictate the extent of each local maxima.
        leftIndices = x(locMaxima);
        rightIndices = leftIndices;
        if flatTypeIsLast
            % When 'FlatSelection' is 'last', each flat region is marked by
            % its rightmost point, so we need to extend the left side.
            for i = 1:n
                % Index of the current local maximum
                k = locMaxima(i);
                % Find how many elements it repeats to the left.
                if isfinite(A(k,j))
                    leftIdx = find(d < k, 1, 'last');
                    assert(~isempty(leftIdx));
                    leftIndices(i) = x(d(leftIdx));
                end
            end
        else
            % For all other 'FlatSelection' types, each flat region is
            % marked by the rightmost point, so we need to extend the
            % right side.
            for i = 1:n
                % Index of the current local maximum
                k = locMaxima(i);
                % Find how many elements it repeats to the right.
                if isfinite(A(k,j))
                    rightIdx = find(d >= k, 1, 'first');
                    assert(~isempty(rightIdx));
                    rightIndices(i) = x(d(rightIdx));
                end
            end
        end
        
        % Iterate through each local maxima.
        left = 1;
        right = 1;
        for i = 1:n
            % Find those maxima to the left that are still within range.
            while ((leftIndices(i) - rightIndices(left)) >= minSep)
                left = left + 1;
            end
            % Find those maxima to the right that are still within range.
            right = max(i, right);
            while ((right <= (n-1)) && ...
                    ((leftIndices(right+1) - rightIndices(i)) < minSep))
                right = right + 1;
            end
            % If this local maxima is Inf, move on.
            if ~isfinite(A(locMaxima(i),j))
                continue;
            end
            % Otherwise, find all values we have to compare against.
            leftIdx = locMaxima(left:(i-1));
            % Remove local maxima we already filtered out.
            leftIdx(~maxVals(locMaxima(left:(i-1)),j)) = [];
            leftMax = max(P(leftIdx,j));
            rightMax = max(P(locMaxima((i+1):right), j));
            % Remove this local maxima if there is another to the left
            % or right within range that is larger.
            if ~isempty(leftMax) && (leftMax >= P(locMaxima(i),j))
                maxVals(locMaxima(i),j) = false;
            elseif ~isempty(rightMax) && (rightMax > P(locMaxima(i),j))
                maxVals(locMaxima(i),j) = false;
            end
        end
    end

end

%--------------------------------------------------------------------------
function maxVals = restrictNumberOfExtrema(A, maxVals, maxNumExt, P)
% Keep only the N largest local maxima in each column

    idx = 1:size(A,1);
    for j = 1:size(A,2)
        % Get the linear indices of all local maxima in this column.
        locMaxima = idx(maxVals(:,j));
        % Get the values of all local maxima.
        [~, sortedIdx] = sort(P(locMaxima,j), 'descend');
        maxVals(locMaxima(sortedIdx((maxNumExt+1):end)), j) = false;
    end
end

%---------------------------------------------------------------------------
function [left, right] = findUniqueRanges(d)
    left = [1; 1 + find(d)];
    right = [left(2:end)-1; numel(d)+1];
end

%---------------------------------------------------------------------------
function [maxVals, P] = adjustFlatRegions(dA, maxVals, unfilteredMaxima, ...
    flatType, P, returnProminence)
% Compensate for flat regions.

    flatTypeValue = find(strcmp(flatType, ...
        { 'center', 'first', 'last', 'all' }));
    if ~returnProminence && ((flatTypeValue == 2) || (flatTypeValue == 3))
        % Nothing to do, as nothing needs to be adjusted.
        return;
    end
    if returnProminence
        % If we are returning the prominence, we must set it correctly
        % for flat regions.
        colRng = find(any(unfilteredMaxima, 1));
    else
        % Otherwise just evaluate the regions for the final maxima
        % list.
        colRng = find(any(maxVals,1));
    end
    % Nothing to do, as nothing needs to be adjusted.
    if isempty(colRng)
        return;
    end

    % Go through the columns.
    n = size(dA,1)+1;
    for j = colRng
        if issparse(dA)
            % Find the locations of all unique leading values.
            [leftRange, rightRange] = findUniqueRanges(dA(:,j));
            flatRegion = rightRange > leftRange;
            if ~returnProminence
                if flatTypeValue == 3
                    ismax = unfilteredMaxima(rightRange, j) & flatRegion;
                else
                    ismax = unfilteredMaxima(leftRange, j) & flatRegion;
                end
                leftRange = leftRange(ismax);
                rightRange = rightRange(ismax);
            end
            % Nothing to do for columns that have no flat regions.
            if ~any(leftRange)
                continue;
            end
        else
            % Compute the flat regions.
            % We can use the first-order difference of A to do this by
            % checking for zeros.  We cannot apply the same technique for
            % sparse, as we could end up with huge logical arrays.
            flatElements = dA(:,j) == 0;
            leftRange = [flatElements; false] | [false; flatElements];
            % Find maxima that are part of flat regions.
            if ~returnProminence
                leftRange = leftRange & maxVals(:,j);
            else
                leftRange = leftRange & unfilteredMaxima(:,j);
            end
            if ~any(leftRange)
                continue;
            end
            % Iterate through and compute the left and right ranges for
            % all maxima that are flat regions.
            leftRange = find(leftRange);
            rightRange = leftRange;
            if flatTypeValue == 3
                for k = 1:numel(rightRange)
                    while (leftRange(k) > 1) && flatElements(leftRange(k)-1)
                        leftRange(k) = leftRange(k)-1;
                    end
                end
            else
                for k = 1:numel(leftRange)
                    while (rightRange(k) < n) && flatElements(rightRange(k))
                        rightRange(k) = rightRange(k)+1;
                    end
                end
            end
        end
        % For flat types 'center' or 'all', we need to adjust the
        % maxVals indicator.
        if flatTypeValue == 1
            idx = maxVals(leftRange,j);
            maxVals(leftRange(idx),j) = false;
            maxVals(floor((leftRange(idx) + rightRange(idx))/2), j) = true;
        elseif flatTypeValue == 4
            for k = 1:numel(leftRange)
                if maxVals(leftRange(k),j)
                    maxVals(leftRange(k):rightRange(k),j) = true;
                end
            end
        end
        % Adjust the prominences.
        if ~returnProminence
            continue;
        end
        % Pull the prominence from whichever side it has been stored on.
        if flatTypeValue ~= 3
            % For everything except 'last', this is the left edge.
            Pvals = P(leftRange, j);
        else
            % For 'last', it is the right edge.
            Pvals = P(rightRange, j);
        end
        % Only consider points with non-zero prominence that are flat
        % regions.
        hasprom = (Pvals > 0);
        if any(hasprom)
            % Subset the values and get the ranges.
            Pvals = Pvals(hasprom);
            ranges = [leftRange(hasprom), rightRange(hasprom)];
            for k = 1:size(ranges,1)
                P(ranges(k,1):ranges(k,2), j) = Pvals(k);
            end
        end
    end
    

end

%--------------------------------------------------------------------------
function [Asub, xsub] = subsampleInputColumnAndSamplePoints(A, x, j, ...
    nanRows, minSep, pwin)
% Subsample the array and sample points.
    % Create a NaN-free sparse column.
    Asub = A(:,j);
    Asub(nanRows) = [];
    if (minSep == 0) && isempty(pwin)
        % Don't have to bother with sample points if we won't use them.
        xsub = [];
    else
        if isempty(x)
            % Place the indices to be filtered in a sparse array.
            xsub = sparse(nanRows(:));
        else
            % Make explicit sample points
            xsub = x;
            xsub(nanRows) = [];
        end
    end
end

%--------------------------------------------------------------------------
function [tf, P] = resampleResults(tfsub, Psub, m, nanRows)
% Resampled the subsampled results for the answer.
    tfsub = find(tfsub);
    for i = 1:numel(tfsub)
        tfsub(i) = subsampleImplicitSamplePoints(nanRows, tfsub(i));
    end
    PsubIdx = find(Psub);
    for i = 1:numel(PsubIdx)
        PsubIdx(i) = subsampleImplicitSamplePoints(nanRows, PsubIdx(i));
    end
    % Assign the columns.
    tf = sparse(tfsub, 1, true, m, 1);
    P = sparse(PsubIdx, 1, nonzeros(Psub), m, 1);
end

%--------------------------------------------------------------------------
function k = subsampleImplicitSamplePoints(removedIndices, k)
% Subsample the implicit sampling points
    m = numel(removedIndices);
    k = k(:)' + (0:m)';
    k(k >= [removedIndices(:); inf]) = NaN;
    k = min(k);
end

%--------------------------------------------------------------------------
function tf = validDataVariableType(x)
% Indicates valid data types for table variables
    tf = (isnumeric(x) || islogical(x)) && isreal(x) && ...
        ~(isinteger(x) && ~isreal(x));
end

%--------------------------------------------------------------------------
function pt = getProminenceType(A)
% Return the data type of the prominence
    if isinteger(A) && startsWith(class(A), 'i')
        pt = ['u', class(A)];
    else
        pt = class(A);
    end
end