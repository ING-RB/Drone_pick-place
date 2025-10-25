function varargout = unique(varargin)
%   Syntax:
%      C = unique(A)
%      C = unique(A,setOrder)
%      C = unique(A,occurrence)
%      C = unique(A,___,'rows')
%      C = unique(A,'rows',___)
%      [C,ia,ic] = unique(___)
%
%      [C,ia,ic] = unique(A,'legacy')
%      [C,ia,ic] = unique(A,'rows','legacy')
%      [C,ia,ic] = unique(A,occurrence,'legacy')
%      [C,ia,ic] = unique(A,'rows',occurrence,'legacy')
%
%   For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

% Determine the number of outputs requested.

if nargout == 0
    nlhs = 1;
else
    nlhs = nargout;
end

narginchk(1,4);
% Convert string flags to char flags to dispatch to the right method
if nargin > 1
    hadStringArguments = false;
    for i = 2:nargin
        if isstring(varargin{i})
            varargin{i} = convertFlag(varargin{i});
            hadStringArguments = true;
        end
    end
    if hadStringArguments
        [varargout{1:nlhs}] = unique(varargin{:});
        return;
    end
end

nrhs = nargin;
if nrhs == 1
    [varargout{1:nlhs}] = uniqueR2012a(varargin{:},true,true,false);
else
    % acceptable combinations, with optional inputs denoted in []
    % unique(A, ['rows'], ['first'/'last'], ['legacy'/'R2012a']),
    % where the position of 'rows' and 'first'/'last' may be reversed
    % unique(A, ['rows'], ['sorted'/'stable']),
    % where the position of 'rows' and 'sorted'/'stable' may be reversed
    flagvals = ["rows" "first" "last" "sorted" "stable" "legacy" "R2012a"];
    % When a flag is found, note the index into varargin where it was found
    flaginds = zeros(1,numel(flagvals));
    for i = 2:nrhs
        flag = varargin{i};
        assert(~isstring(flag))
        if ~ischar(flag)
            error(message('MATLAB:UNIQUE:UnknownInput'));
        end
        foundflag = startsWith(flagvals,flag,'IgnoreCase',true);
        if sum(foundflag) ~= 1
            error(message('MATLAB:UNIQUE:UnknownFlag',flag));
        end
        % Only 1 occurrence of each allowed flag value
        if flaginds(foundflag)
            error(message('MATLAB:UNIQUE:RepeatedFlag',flag));
        end
        flaginds(foundflag) = i;
    end

    % Only 1 of each of the paired flags
    if flaginds(2) && flaginds(3)
        error(message('MATLAB:UNIQUE:OccurrenceConflict'))
    end
    if flaginds(4) && flaginds(5)
        error(message('MATLAB:UNIQUE:SetOrderConflict'))
    end
    if flaginds(6) && flaginds(7)
        error(message('MATLAB:UNIQUE:BehaviorConflict'))
    end
    % 'legacy' and 'R2012a' flags must be trailing
    if flaginds(6) && flaginds(6)~=nrhs
        error(message('MATLAB:UNIQUE:LegacyTrailing'))
    end
    if flaginds(7) && flaginds(7)~=nrhs
        error(message('MATLAB:UNIQUE:R2012aTrailing'))
    end

    byRows = logical(flaginds(1));
    useR2012a = ~logical(flaginds(6));
    firstOccurrence = ( useR2012a && ~logical(flaginds(3)) ) || logical(flaginds(2));
    sortedOutput = ~logical(flaginds(5));

    if flaginds(4) || flaginds(5) % 'stable'/'sorted' specified
        if flaginds(6) || flaginds(7) % does not combine with 'legacy'/'R2012a'
            error(message('MATLAB:UNIQUE:SetOrderBehavior'))
        end
    end
    if useR2012a
        [varargout{1:nlhs}] = uniqueR2012a(varargin{1},sortedOutput,firstOccurrence,byRows);
    else % trailing 'legacy' specified
        [varargout{1:nlhs}] = uniquelegacy(varargin{1},firstOccurrence,byRows);
    end
end
end


function [c,indA,indC] = uniqueR2012a(a,sortedOutput,firstOccurrence,byRows)
% 'R2012a' flag implementation

if (isnumeric(a) || ischar(a) || islogical(a)) && ~issparse(a) && ~isobject(a)
    if nargout > 1
        [c,indA,indC] = matlab.internal.math.uniquehelper(a,sortedOutput,firstOccurrence,byRows);
    else
        c = matlab.internal.math.uniquehelper(a,sortedOutput,firstOccurrence,byRows);
    end
    return;
end

% Determine if A is a row vector.
rowvec = isrow(a);

if ~byRows || iscolumn(a) % default case

    % Convert to column
    a = a(:);
    numelA = numel(a);

    % Sort A and get the indices if needed.
    isSortedA = false;
    if isnumeric(a) && ~isobject(a)
        isSortedA = issorted(a);
    end

    if nargout > 1 || ~sortedOutput
        if isSortedA
            sortA = a;
            indSortA = (1:numelA)';
        else
            [sortA,indSortA] = sort(a);
        end
    else
        if isSortedA
            sortA = a;
        else
            sortA = sort(a);
        end
    end

    % groupsSortA indicates the location of non-matching entries.
    if isnumeric(sortA) && (numelA > 1)
        dSortA = diff(sortA);
        if (isnan(dSortA(1)) || isnan(dSortA(numelA-1)))
            groupsSortA = sortA(1:numelA-1) ~= sortA(2:numelA);
        else
            groupsSortA = dSortA ~= 0;
        end

    else
        groupsSortA = sortA(1:numelA-1) ~= sortA(2:numelA);
    end

    if (numelA ~= 0)
        if ~firstOccurrence
            groupsSortA = [groupsSortA; true];          % Final element is always a member of unique list.
        else  % sorted or stable
            groupsSortA = [true; groupsSortA];          % First element is always a member of unique list.
        end
    else
        groupsSortA = zeros(0,1);
    end

    % Extract unique elements.
    if ~sortedOutput
        invIndSortA = indSortA;
        invIndSortA(invIndSortA) = 1:numelA;  % Find inverse permutation.
        logIndA = groupsSortA(invIndSortA);   % Create new logical by indexing into groupsSortA.
        c = a(logIndA);                       % Create unique list by indexing into unsorted a.
    else
        c = sortA(groupsSortA);         % Create unique list by indexing into sorted list.
    end

    % Find indA.
    if nargout > 1
        if ~sortedOutput
            indA = find(logIndA);           % Find the indices of the unsorted logical.
        else
            indA = indSortA(groupsSortA);   % Find the indices of the sorted logical.
        end
    end

    % Find indC.
    if nargout == 3
        groupsSortA = full(groupsSortA);
        if numelA == 0
            indC = zeros(0,1);
        else
            % Assign group numbers to unique values
            if firstOccurrence
                indC = cumsum(groupsSortA); 
            else
                % groupsSortA marks the last member of each group if
                % occurrence = "last"
                indC = cumsum([1;groupsSortA(1:end-1)]);
            end
            indC(indSortA) = indC;
            if ~sortedOutput && ~isempty(a)
                mapToStableIndex = indC(indA);
                mapToStableIndex(mapToStableIndex) = 1:numel(indA);
                indC = mapToStableIndex(indC);
            end
        end
    end

    % If A is row vector, return C as row vector.
    if rowvec
        c = c.';
    end

else    % 'rows' case
    if ~ismatrix(a)
        error(message('MATLAB:UNIQUE:ANotAMatrix'));
    end

    numRows = size(a,1);

    % Sort A and get the indices if needed.
    isSortedA = false;
    if isnumeric(a) && ~isobject(a)
        isSortedA = issortedrows(a);
    end

    if nargout > 1 || ~sortedOutput
        if isSortedA
            sortA = a;
            indSortA = (1:numRows)';
        else
            [sortA,indSortA] = sortrows(a);
        end
    else
        if isSortedA
            sortA = a;
        else
            sortA = sortrows(a);
        end
    end

    % groupsSortA indicates the location of non-matching entries.
    groupsSortA = sortA(1:numRows-1,:) ~= sortA(2:numRows,:);
    groupsSortA = any(groupsSortA,2);
    if (numRows ~=0)
        if ~firstOccurrence
            groupsSortA = [groupsSortA; true];          % Final row is always member of unique list.
        else  % if (strcmp(order, 'sorted') || strcmp(order, 'stable'))
            groupsSortA = [true; groupsSortA];          % First row is always a member of unique list.
        end
    end

    % Extract Unique elements.
    if ~sortedOutput
        invIndSortA = indSortA;
        invIndSortA(invIndSortA) = 1:numRows;               % Find the inverse permutation of indSortA.
        logIndA = groupsSortA(invIndSortA);                 % Create new logical by indexing into groupsSortA.
        c = a(logIndA,:);                                   % Create unique list by indexing into unsorted a.
    else
        c = sortA(groupsSortA,:);         % Create unique list by indexing into sorted list.
    end

    % Find indA.
    if nargout > 1
        if ~sortedOutput
            indA = find(logIndA);           % Find the indices of the unsorted logical.
        else
            indA = indSortA(groupsSortA);   % Find the indices of the sorted logical.
        end
    end

    % Find indC.
    if nargout == 3
        groupsSortA = full(groupsSortA);
        % Assign group numbers to unique values
        if firstOccurrence
            indC = cumsum(groupsSortA);
        else
            if (numRows == 0)
                indC = cumsum(groupsSortA);                   % Empty A - use all of groupsSortA.
            else
                % groupsSortA marks the last member of each group if
                % occurrence = "last"
                indC = cumsum([1;groupsSortA(1:end-1)]);    
            end
        end
        % Rearrange the indices to match the corresponding elements in A
        indC(indSortA) = indC; 
        if ~sortedOutput && ~isempty(a)
            mapToStableIndex = indC(indA);
            mapToStableIndex(mapToStableIndex) = 1:numel(indA);
            indC = mapToStableIndex(indC);
        end
    end
end
end

function flag = convertFlag(flag)
if isscalar(flag)
    flag = char(flag);
else
    error(message('MATLAB:UNIQUE:UnknownInput'));
end
end
