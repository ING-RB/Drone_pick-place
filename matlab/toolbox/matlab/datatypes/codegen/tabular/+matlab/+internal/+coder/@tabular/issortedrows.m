function tf = issortedrows(T,varargin) %#codegen
%ISSORTEDROWS TRUE for a sorted table.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(varargin);

[vars,varData,sortMode,nvStart] = sortrowsFlagChecks(true,T,varargin{:});

if isempty(vars)
    % Ensure consistency with sortrows(T,[],...) not sorting and returning
    % T, i.e., issortedrows(sortrows(T,[],...),[],...) returns true.
    tf = true;
    return
end

% Prepare the data for the sort check:
hasMultiColumnVars = false;
ncols = 0;
labels = coder.const(feval('horzcat',{T.metaDim.labels{1}},T.varDim.labels));

coder.unroll(coder.internal.isConst(numel(vars)));
for jj = 1:numel(vars)
    V = varData{jj};
    % Same errors as in tabular.sortrows
    coder.internal.assert(ismatrix(V),...
            'MATLAB:table:issortedrows:NDVar',labels{vars(jj)+1});
    % Error gracefully when trying to sort tables of tables
    coder.internal.assert(~isa(V,'tabular'),...
            'MATLAB:table:issortedrows:IssortedOnVarFailed',labels{vars(jj)+1},class(V));
    % There is no issortedrows support for cellstr variables in MATLAB, so we
    % convert cellstrs to strings. Since strings are not supported in codegen,
    % we allow cellstrs only for row names.
    coder.internal.errorIf(iscellstr(V) && vars(jj) ~= 0,...
        'MATLAB:table:issortedrows:CellstrVar',labels{vars(jj)+1}) %#ok<ISCLSTR>
    % Ensure that we do not have variable width variables, since we need to
    % split the multi-column variables and put them into a cell array.
    cols = size(V,2);
    coder.internal.assert(coder.internal.isConst(cols),...
        'MATLAB:table:issortedrows:NonConstantVarWidth',labels{vars(jj)+1});
    hasMultiColumnVars = hasMultiColumnVars | (cols > 1);
    ncols = ncols + cols;
end
if hasMultiColumnVars
    % Convert multi-column variables into separate columns to facilitate
    % tiebreak behavior for duplicate missing rows in matrix variables:
    varsSplit = zeros(1,ncols);
    varDataSplit = coder.nullcopy(cell(1,ncols));
    sortModeSplit = zeros(1,ncols);
    thisjj = 1;
    for jj = 1:numel(vars)
        V = varData{jj};
        nV = size(V,2);
        varsSplit(thisjj:(thisjj+nV-1)) = vars(jj);
        for ii = thisjj:(thisjj+nV-1)
           varDataSplit{ii} = V(:,ii-thisjj+1); 
        end
        sortModeSplit(thisjj:(thisjj+nV-1)) = sortMode(jj);
        thisjj = thisjj+nV;
    end
else
    varDataSplit = varData;
    sortModeSplit = sortMode;
end

% Perform issortedrows check starting with the first specified table
% variable and moving on to the next one if ties are present:
tf = matlab.internal.coder.tabular.issortedrowsFrontToBack(varDataSplit,sortModeSplit,varargin{nvStart:end});