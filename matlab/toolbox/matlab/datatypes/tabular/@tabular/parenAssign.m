function t = parenAssign(t,idxOp,b)
%

% PARENASSIGN Subscripted assignment into a table using parens.
%   T(I,J) = B assigns the contents of the table B to a subset of the rows
%   and variables in the table T.  I and J are positive integers, vectors
%   of positive integers, row/variable names, string/cell arrays containing one
%   or more row/variable names, or logical vectors.  The assignment does not
%   use row names, variable names, or any other properties of B to modify
%   properties of T; however properties of T are extended with default
%   values if the assignment expands the number of rows or variables in T.
%   Elements of B are assigned into T by position, not by matching names.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.lang.internal.move % Avoid unsharing of shared-data copy across function call boundary

% '()' is assignment to a subset of a table.  Only dot subscripting
% may follow. One level deep deletion (so deleting rows or variables from a
% table) will be handled by parenDelete, however, deletion at deeper levels is
% treated as assignment and is handled here.

try
    creating = isnumeric(t) && isequal(t,[]);

    if creating
        t = b.cloneAsEmpty;
    end
    
    if numel(idxOp(1).Indices) ~= t.metaDim.length
        tabular.throwNDSubscriptError(numel(idxOp(1).Indices))
    end
    
    if ~isscalar(idxOp)
        switch idxOp(2).Type
        case matlab.indexing.IndexingOperationType.Paren
            error(message('MATLAB:table:InvalidSubscriptExpr'));
        case matlab.indexing.IndexingOperationType.Brace
            error(message('MATLAB:table:InvalidSubscriptExpr'));
        case matlab.indexing.IndexingOperationType.Dot
            if creating
                error(message('MATLAB:table:InvalidSubscriptExpr'));
            end
            
            % Syntax:  t(rowIndices,varIndices).name = b
            % Syntax:  t(rowIndices,varIndices).name(...) = b
            % Syntax:  t(rowIndices,varIndices).name{...} = b
            % Syntax:  t(rowIndices,varIndices).name.field = b
            %
            % Assignment into a variable of a subarray.
            %
            % This may also be followed by deeper levels of subscripting.
            %
            % t(rowIndices,varIndices) must refer to rows and vars that exist, and
            % the .name assignment can't add rows or refer to a new variable.  This
            % is to prevent cases where the indexing beyond t(rowIndices,varIndices)
            % refers to things that are new relative to that subarray, but which
            % already exist in t itself.  So, cannot grow the table by an assignment
            % like this.
            %
            % This can be deletion, but it must be "inside" a variable, and not
            % change the size of t(rowIndices,varIndices).
            
            % Get the subarray, do the dot-variable assignment on that.
            try
                % this creates a shared-copy reference to the referenced subarray
                % and leads to memory copying (i.e. unsharing) when the subarray
                % is assigned into. In theory, since the updated subarray is
                % subsequentyly assigned back into t, this should be done
                % in-place (i.e. no memory copy); in practice, this
                % optimization is viable as it is not possible to eliminate the
                % original shared-copy reference on the subarray.
                c = t.parenReference(idxOp(1));
            catch ME
                outOfRangeIDs = ["MATLAB:table:RowIndexOutOfRange" "MATLAB:table:UnrecognizedRowName" ...
                                 "MATLAB:table:VarIndexOutOfRange" "MATLAB:table:UnrecognizedVarName"];
                matlab.internal.datatypes.throwInstead(ME,outOfRangeIDs,"MATLAB:table:InvalidExpansion")
            end
            
            % Assigning to .Properties of a subarray is not allowed.
            if strcmp(idxOp(2).Name, "Properties")
                error(message('MATLAB:table:PropertiesAssignmentToSubarray'));
            end
            
            % Check numeric before builtin to short-circuit for performance and
            % to distinguish between '' and [].
            nestedDeleting = isnumeric(b) && builtin('_isEmptySqrBrktLiteral',b);   
            cSize = size(c);
            % c is a subset of the original table t that would retain the row
            % label information from t. Hence, unlike brace and dot, parenAssign
            % would not require any special treatment before forwarding the
            % assignment to c.
            c.(idxOp(2:end)) = b;
            
            % Changing the size of the subarray -- growing it by assignment or
            % deleting part of it -- is not allowed.
            if ~isequal(size(c),cSize)
                if nestedDeleting
                    error(message('MATLAB:table:EmptyAssignmentToSubarrayVar'));
                else
                    error(message('MATLAB:table:InvalidExpansion'));
                end
            end
            
            % Now let the simple () subscripting code handle assignment of the updated
            % subarray back into the original array.
            b = c;
            idxOp = idxOp(1);
        end
    end
    
    % Call oneLevelParenAssign to do the final assignment into the original table.
    t = move(t).oneLevelParenAssign(idxOp(1).Indices,b,creating,false);
catch ME
    throw(ME);
end
