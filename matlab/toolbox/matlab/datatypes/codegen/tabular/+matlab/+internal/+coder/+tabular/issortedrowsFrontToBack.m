function tf = issortedrowsFrontToBack(A,dirCodes,varargin) %#codegen
% ISSORTEDFRONTTOBACK   Front-to-Back issortedrows algorithm
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(dirCodes,varargin);

dirStrs = {'ascend','descend','monotonic',...
    'strictascend','strictdescend','strictmonotonic'};

tf = true;
getColFcn = @(A,jj) A{jj}; % get entry in cell vector

% Return TRUE for empty inputs:
numCols = size(A,2);
if coder.internal.isConstTrue(numCols == 0)
    return
end
numRows = size(getColFcn(A,1),1);
if coder.internal.isConstTrue(numRows == 0)
    return
end

if coder.internal.isConstTrue(numCols == 1) && ~iscellstr(getColFcn(A,1)) %#ok<*ISCLSTR>
    % Simply call ISSORTED on only one column:
    jj = 1; % Spelled out for try-catch error purposes
    tf = issorted(getColFcn(A,jj),dirStrs{dirCodes(jj)},varargin{:});
else

    % Use the groups found in the previous column (or tabular variable):
    if numRows > 1
        % Use 'ascend' for previous column ids because they are always
        % sorted -- they are the third output of a stable unique call:
        baseGroupIdsPrevCol = zeros(numRows,1);
        dirPrevCol = 'ascend';
    else
        % Ensure 'strictascend' returns false for 1 row of missing data:
        baseGroupIdsPrevCol = [];
        dirPrevCol = '';
    end

    coder.unroll(coder.internal.isConst(numCols));
    for jj = 1:numCols
        
        if jj == 1
            groupIdsPrevCol = baseGroupIdsPrevCol;
        end

        % Call ISSORTED and/or SORT to get group ids for this column:
        groupIdsThisCol = getGroupIds(getColFcn(A,jj),varargin{:});

        % issortedrows builtin on a numRows-by-2 double matrix of group ids
        % formed from the groups found in the previous and current column
        % (varargin gives correct MissingPlacement behavior via NaN groups):
        if isequal(dirPrevCol,'')
            dirVec = {dirStrs{dirCodes(jj)}};
        else
            dirVec = {dirPrevCol dirStrs{dirCodes(jj)}};
        end
        
        tf = issortedrows([groupIdsPrevCol groupIdsThisCol],dirVec,varargin{:});

        if tf && (dirCodes(jj) < 4) && (jj < numCols)
            % Data is sorted in the non-strict sense (ascend/descend/monotonic),
            % BUT it could have ties. Find new groups and go to next column
            % (convert NaN ids to 0 to force unique 'rows' to treat NaNs as ties):
            groupIdsThisCol(isnan(groupIdsThisCol)) = 0;
            [~,~,groupIdsPrevCol] = unique([groupIdsPrevCol groupIdsThisCol],'rows','stable');

            % Stop if there are no ties to break:
            if max(groupIdsPrevCol) == numRows
                return
            end
        else
            % Stop if not sorted at all
            %   OR
            % if the j-th sort direction is strictascend/strictdescend/strictmonotonic.
            return
        end
    end
end

%--------------------------------------------------------------------------
function groupIdsWithNaN = getGroupIds(A,varargin)
% Returns similar output to third output of unique: [~,~,IC] = unique(A).
% But, takes into account name-value pairs provided to issortedrows.
% Hence, it produces the correct behavior when varargin contains
%   'MissingPlacement','auto'/'first'/'last' and/or
%   'ComparisonMethod','auto'/'abs'/'real'.
% A must be a column.

if iscellstr(A) 
    tmpA = A;
    if coder.internal.isConst(size(A))
        % Ensure tmp is homogeneous
        coder.varsize('tmpA',[],[false false]);
    end
    % For cellstr variables error if any NV pair is supplied.
    coder.internal.assert(numel(varargin) <= 1,'MATLAB:table:sortrows:NVPairsCellstr');
    [sortedA,indSortA] = matlab.internal.coder.datatypes.cellstr_sort(tmpA,varargin{:});
    % Indices where a new group starts:
    nElem = numel(sortedA);
    groupIdsWithNaN = true(nElem,1);
    coder.unroll(coder.internal.isConst(nElem));
    for i = 1:numel(sortedA)-1
        groupIdsWithNaN(i+1) = ~isequal(sortedA{i},sortedA{i+1});
    end
    % The only cellstr value that is accepted right now is RowNames and hence it
    % cannot have any missing value.
    mA = [];
else
    if issorted(A,varargin{:})
        indSortA = (1:numel(A))';
        sortedA = A;
    else
        [sortedA,indSortA] = sort(A,varargin{:});
    end
    % Indices where a new group starts:
    groupIdsWithNaN = [true; sortedA(1:end-1) ~= sortedA(2:end)];
    % Treat missing (NaN) as ties, make sure all NaNs belong to a single group:
    mA = find(ismissing(sortedA));
end


groupIdsWithNaN(mA(2:end)) = false;

% Turn into group ids and permute to match initial input ordering:
groupIdsWithNaN = cumsum(groupIdsWithNaN);
% Use NaN ids for missing data to ensure correct MissingPlacement behavior:
groupIdsWithNaN(mA) = NaN;
groupIdsWithNaN(indSortA) = groupIdsWithNaN;


