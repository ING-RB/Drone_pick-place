function sz = parenListLength(t, idxOp, context)
%

% Copyright 2021-2024 The MathWorks, Inc.

if isscalar(idxOp) % one level of subscripting on a table
    sz = 1; % table returns one array for parens
elseif context == matlab.mixin.util.IndexingContext.Assignment
    sz = 1; % table subsasgn only ever accepts one rhs value
elseif idxOp(end).Type == matlab.indexing.IndexingOperationType.Paren
    % This should never be called with parentheses as the last
    % subscript, but return 1 for that just in case
    sz = 1;
else % multiple subscripting levels
    try
        % subTable obtained from paren subscripting inherits the row label
        % information from t. So unlike brace and dot, we do not need to call
        % listLengthRecurser to handle cases that would require row label
        % translation.
        subTable = t.(idxOp(1));
        % Transform t(row,:).Var into t.Var(row) for performance.
        if numel(idxOp) == 2 && idxOp(2).Type == matlab.indexing.IndexingOperationType.Dot ...
                && ischar(idxOp(1).Indices{2}) && isscalar(idxOp(1).Indices{2}) && idxOp(1).Indices{2} == ':' ...
                && ~matches(idxOp(2).Name,matlab.internal.tabular.private.varNamesDim.reservedNames) 
            sz = 1;
            return;
        end
        % Paren can only be followed by dot so we can directly call
        % dotListLength. For all the other cases, front end would throw an error.
        sz = dotListLength(subTable,idxOp(2:end),context);
    catch ME
        throw(ME); 
    end
end
