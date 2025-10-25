function var = translateAndForwardAssign(t, var, idxOp, rhs)
%

% TRANSLATEANDFORWARDASSIGN Helper to facilitate row labels translation
% before forwarding a subscripting expression.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isColon

% When subscripting into a tabular using dot or brace, the result would no
% longer have the row label information. However, if the first level is followed
% by another brace or paren, then we still allow subscripting using the row
% labels. So the row labels need to be converted into numeric indices before
% forwarding the subscripting expression to the result of the first level. Since
% matlab.indexing.IndexingOperation does not allow modifying the internal
% Indices property, we have this helper that uses the special forwarding syntax
% to correctly handle each of the cases below.

% Here var would either be a variable obtained from dot subscripting on a parent
% table or it is a homogeneous array spanning over multiple rows and variables
% obtained from brace subscripting on a parent table. So var would be obtained
% by one of the following subscripting expression:
%  - var = t.Var
%  - var = t{rows,vars}
% translateAndForwardAssign handles the subscripting expression that start
% with one of these.

if idxOp(1).Type == matlab.indexing.IndexingOperationType.Dot
    % If the current level is dot, then it does not use row labels as indices, and
    % hence no translation is required. Directly forward the entire expression. 
    % This branch would handle the following syntax:
    % - var.Field = rhs
    % The current level could also be followed by other kinds of subscripting,
    % as long as var allows that.
    var.(idxOp) = rhs;
else % Brace, Paren or ParenDelete
    % If the current level is a brace or a paren, then it might be using row
    % labels as indices and hence might require translation.
    rowLabels = idxOp(1).Indices{1};
    if (isnumeric(rowLabels) || islogical(rowLabels) || isColon(rowLabels))
        % No row labels, so no translation required. Directly forward the
        % entire expression.
        % This branch would handle the following syntax:
        % - var(numericRowIndices,...) = rhs
        % - var{numericRowIndices,...} = rhs
        % The current level could also be followed by other kinds of subscripting,
        % as long as var allows that.
        var.(idxOp) = rhs;
    else
        % We are using row labels, so first do the translation, and then use the
        % special forwarding syntax to forward the assignment expression to
        % var's appropriate subscripting method.
        % This branch would handle the following syntax:
        % - var(rowLabels,...) = rhs
        % - var{rowLabels,...} = rhs
        % - var(rowLabels,...) = []
        % The current level could also be followed by other kinds of subscripting,
        % as long as var allows that.
        indices = t.translateRowLabels(var, idxOp(1).Indices);
        if idxOp(1).Type == matlab.indexing.IndexingOperationType.Paren
            % Forwarding an empty IndexingOperation results in an error, hence we
            % need separate branches for scalar and non-scalar idxOp.
            if isscalar(idxOp)
                var(indices{:}) = rhs;
            else
                var(indices{:}).(idxOp(2:end)) = rhs;
            end
        elseif idxOp(1).Type == matlab.indexing.IndexingOperationType.Brace
            if isscalar(idxOp)
                var{indices{:}} = rhs;
            else
                var{indices{:}}.(idxOp(2:end)) = rhs;
            end
        else % ParenDelete
            if isscalar(idxOp)
                var(indices{:}) = [];
            else
                var(indices{:}).(idxOp(2:end)) = [];
            end
        end
    end
end
