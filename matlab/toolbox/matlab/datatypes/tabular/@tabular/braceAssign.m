function t = braceAssign(t,idxOp,b)
%

% BRACEASSIGN Subscripted assignment into a table using braces.
%   T{I,J} = B assigns the values in the array B into elements of the table
%   T.  I and J are positive integers, vectors of positive integers,
%   row/variable names, string or cell arrays containing one or more
%   row/variable names, or logical vectors.  Columns of B are cast to the types
%   of the target variables if necessary.  If the table elements already exist,
%   T{I,J} may also be followed by further subscripting as supported by the
%   variable.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isColon
import matlab.lang.internal.move % Avoid unsharing of shared-data copy across function call boundary

% '{}' is assignment to or into the contents of a subset of a table array.
% Any sort of subscripting may follow. For brace both assignment and deletion
% (although deletion is always an error for brace) need to be handled by
% braceAssign.

try
    creating = isnumeric(t) && isequal(t,[]);
    
    if creating
        t = b.cloneAsEmpty;
    end
    
    if numel(idxOp(1).Indices) ~= t.metaDim.length
        tabular.throwNDSubscriptError(numel(idxOp(1).Indices))
    end
    
    if ~isscalar(idxOp)
        % Syntax:  t{rowIndices,varIndices}(...) = b
        %          t{rowIndices,varIndices}{...} = b
        %          t{rowIndices,varIndices}.name = b
        %
        % Assignment into contents of a table.
        %
        % t{rowIndices,varIndices} must refer to rows and vars that exist, and the
        % assignment on whatever follows that can't add rows or columns or otherwise
        % reshape the contents.  This avoids cases where the indexing beyond
        % t{rowIndices,varIndices} refers to things outside the subarray, but which
        % already exist in t itself.  So, cannot grow the table by an assignment
        % like this.  Even if the number of elements stayed the same, if the shape
        % of those contents changed, we wouldn't know how to put them back into the
        % original table.
        
        % Get the subarray's contents, and do the assignment on that.
        try
            c = t.braceReference(idxOp(1));
        catch ME
            outOfRangeIDs = ["MATLAB:table:RowIndexOutOfRange" "MATLAB:table:UnrecognizedRowName" ...
                             "MATLAB:table:VarIndexOutOfRange" "MATLAB:table:UnrecognizedVarName"];
            matlab.internal.datatypes.throwInstead(ME, outOfRangeIDs, ...
                "MATLAB:table:InvalidExpansion");
        end
        szOut = size(c);
        % The first brace could be followed by paren or another brace that
        % might be using row labels inherited from t. Since c would not know
        % anything about the row labels, call translateAndForwardAssign to
        % translate these row labels to numeric indices before doing the
        % assignment into c.
        c = t.translateAndForwardAssign(move(c), idxOp(2:end), b);
        
        % The nested assignment is not allowed to change the size of the target.
        if ~isequal(size(c),szOut)
            error(message('MATLAB:table:InvalidContentsReshape'));
        end
        
        % Now let the simple {} subscripting code handle assignment of the updated
        % contents back into the original array.
        b = c;
        idxOp = idxOp(1);
    end
    
    % If the LHS is 0x0, then interpret ':' as the size of the corresponding dim
    % from the RHS, not as nothing.
    assigningInto0x0 = all(size(t) == 0);
    
    % Translate variable (column) names into indices (translate ':' to 1:nvars)
    if assigningInto0x0 && isColon(idxOp(1).Indices{2})
        varIndices = 1:size(b,2);
    else
        varIndices = t.subs2inds(idxOp(1).Indices{2},'varDim',matlab.internal.tabular.private.tabularDimension.subsType_assignment);
    end
    existingVarLocs = find(varIndices <= t.varDim.length); % subscripts corresponding to existing vars
    newVarLocs = find(varIndices > t.varDim.length);  % subscripts corresponding to new vars
    
    % Syntax:  t{rowIndices,varIndices} = b
    %
    % Assignment to contents of a table.
    
    % For successful brace assignment, all variables being assigned to should have
    % the same sizes along all but the second dimension. Verify this and error
    % accordingly. For new variables we assume the size along the second dimension
    % to be 1. Do this check explicitly over here instead of relying on
    % oneLevelParenAssign to ensure that cases when the LHS variables have invalid
    % dimensions, do not succeed because of unintended scalar expansion.
    colSizes = ones(1,length(varIndices));
    if ~isempty(existingVarLocs)
        dims = cellfun('ndims',t.data(varIndices(existingVarLocs)));
        if any(diff(dims)) % verify all variables have same number of dimensions
            error(message('MATLAB:table:ExtractDataDimensionMismatch'));
        end
        sizes = zeros(length(existingVarLocs),dims(1));
        for i = 1:length(existingVarLocs)
            sizes(i,:) = size(t.data{varIndices(existingVarLocs(i))});
        end
        if any(any(diff(sizes(:,3:end),[],1),1))
            error(message('MATLAB:table:ExtractDataSizeMismatch'));
        end
        colSizes(existingVarLocs) = sizes(:,2);
    end
    
    sizeB = size(b);
    % Convert b into a row of cells (same representation as t.data) before
    % passing it to oneLevelParenAssign.
    if isscalar(b)
        b = {b};
    else 
        % We know the number of columns in each existing var, assume one column for
        % new vars.  If we have the right number of columns on the RHS, good.
        if size(b,2) ~= sum(colSizes)
            if (size(b,2) > sum(colSizes)) && isscalar(newVarLocs)
                % If we have too many columns, but there's only one new var, give that var
                % multiple columns.
                colSizes(newVarLocs) = size(b,2) - sum(colSizes(existingVarLocs));
            elseif isnumeric(b) && isequal(b,[]) && builtin('_isEmptySqrBrktLiteral',b)...
                        && isempty(newVarLocs) && (isColon(idxOp(1).Indices{1}) || isColon(idxOp(1).Indices{2}))
                % If we have the wrong number of columns, and this looks like an attempt at
                % deletion of existing contents, say how many columns were expected but also
                % give a helpful error suggesting parens subscripting. Assignment of [] can
                % never be deletion here, so if there's no colons or if there's an out of
                % range subscript, let the else handle it as true assignment.
                error(message('MATLAB:table:BracesAssignDelete',sum(colSizes)));
            else
                % Otherwise say how many columns were expected.
                error(message('MATLAB:table:WrongNumberRHSCols',sum(colSizes)));
            end
        end
    
        % We have already verified that the exsiting variables have the same sizes
        % along the trailing dimensions. Verfiy that even the RHS has the same
        % trailing sizes.
        if ~isempty(existingVarLocs) && ~isequal(sizeB(3:end),sizes(1,3:end))
            error(message('MATLAB:table:WrongSizeRHS'));
        end
        
        if isscalar(colSizes)
            % Optimize the one variable case by avoiding mat2cell and simply
            % wrapping up the RHS in a cell array.
            b = {b};
        else
            dimSz = num2cell(sizeB); dimSz{2} = colSizes;
            b = mat2cell(b,dimSz{:});
        end   
    end
    t = move(t).oneLevelParenAssign(idxOp(1).Indices,b,false,true,sizeB(1));
catch ME
    throw(ME);
end
