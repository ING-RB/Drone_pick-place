function sz = braceListLength(t, idxOp, context)
%

% Copyright 2021-2024 The MathWorks, Inc.

if isscalar(idxOp) % one level of subscripting on a table
    sz = 1; % table returns one array for braces
elseif context == matlab.mixin.util.IndexingContext.Assignment
    sz = 1; % table subsasgn only ever accepts one rhs value
elseif idxOp(end).Type == matlab.indexing.IndexingOperationType.Paren
    % This should never be called with parentheses as the last
    % subscript, but return 1 for that just in case
    sz = 1;
else % multiple subscripting levels
    try
        var = t.(idxOp(1));
        % The first brace could be followed by parens or another brace that
        % might be using row labels inherited from t. Since var would not know
        % anything about the row labels, call listLengthRecurser to handle the
        % row label translation before calling var's listLength method.
        sz = t.listLengthRecurser(var,idxOp(2:end),context);
    catch ME
        throw(ME); 
    end
end
