function [var,varargout] = translateAndForwardReference(t, var, idxOp)
%

% TRANSLATEANDFORWARDREFERENCE Helper to facilitate row labels translation
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
% translateAndForwardReference handles the subscripting expression that start
% with one of these.

indices = [];
isTranslated = false;
type = [];

% If the current level is not a dot and the the Indices contain row labels, then
% translate those into numeric indices.
if idxOp(1).Type ~= matlab.indexing.IndexingOperationType.Dot
    rowLabels = idxOp(1).Indices{1};
    if ~(isnumeric(rowLabels) || islogical(rowLabels) || isColon(rowLabels))
        indices = t.translateRowLabels(var, idxOp(1).Indices);
        isTranslated = true;
        type = idxOp(1).Type;
    end
end

% translateAndForwardReference's output args are defined as [var,varargout] so
% the nargout==1 case can avoid varargout, although that adds complexity to the
% nargout==0 case. See detailed comments in parenReference.

if ~isTranslated
    % If no translation is required, then we can simply forward the entire
    % subscripting expression to var. This branch would handle the following
    % syntax:
    % - var.Field
    % - var(numericRowIndices,...)
    % - var{numericRowIndices,...}
    % Each of this could be followed by any other subscripting that is allowed
    % by var.
    if nargout == 1
        var = var.(idxOp);
    elseif nargout > 1
        [var, varargout{1:nargout-1}] = var.(idxOp);
    else % nargout == 0
        % Let varargout bump magic capture either one output or zero
        % outputs. See detailed comments in parenReference.
        [varargout{1:nargout}] = var.(idxOp);

        if isempty(varargout)
            % There is nothing to return, remove the first output arg.
            clear var
        else
            % Shift the return value into the first output arg.
            var = varargout{1};
            varargout = {}; % never any additional values
        end
    end
elseif type == matlab.indexing.IndexingOperationType.Paren
    % If translation is required and the current level is paren, then use paren
    % indexing followed by the special forwarding syntax, to forward the
    % translated indices and the remainder of the indexing expression to var.
    % This branch would handle the following syntax:
    % - var(rowLabels,...)
    % This could be followed by any other subscripting that is allowed by var.
    if nargout == 1
        % Forwarding an empty IndexingOperation results in an error, hence we
        % need separate branches for scalar and non-scalar idxOp.
        if isscalar(idxOp)
            var = var(indices{:});
        else
            var = var(indices{:}).(idxOp(2:end));
        end
    elseif nargout > 1
        if isscalar(idxOp)
            [var, varargout{1:nargout-1}] = var(indices{:});
        else
            [var, varargout{1:nargout-1}] = var(indices{:}).(idxOp(2:end));
        end
    else % nargout == 0
        % Let varargout bump magic capture either one output or zero
        % outputs. See detailed comments in parenReference.
        if isscalar(idxOp)
            [varargout{1:nargout}] = var(indices{:});
        else
            [varargout{1:nargout}] = var(indices{:}).(idxOp(2:end));
        end

        if isempty(varargout)
            % There is nothing to return, remove the first output arg.
            clear var
        else
            % Shift the return value into the first output arg.
            var = varargout{1};
            varargout = {}; % never any additional values
        end
    end
else % Brace
    % If translation is required and the current level is brace, then use brace
    % indexing followed by the special forwarding syntax, to forward the
    % translated indices and the remainder of the indexing expression to var.
    % This branch would handle the following syntax:
    % - var{rowLabels,...}
    % This could be followed by any other subscripting that is allowed by var.
    if nargout == 1
        % Forwarding an empty IndexingOperation results in an error, hence we
        % need separate branches for scalar and non-scalar idxOp.
        if isscalar(idxOp)
            var = var{indices{:}};
        else
            var = var{indices{:}}.(idxOp(2:end));
        end
    elseif nargout > 1
        if isscalar(idxOp)
            [var, varargout{1:nargout-1}] = var{indices{:}};
        else
            [var, varargout{1:nargout-1}] = var{indices{:}}.(idxOp(2:end));
        end
    else % nargout == 0
        % Let varargout bump magic capture either one output or zero
        % outputs. See detailed comments in parenReference.
        if isscalar(idxOp)
            [varargout{1:nargout}] = var{indices{:}};
        else
            [varargout{1:nargout}] = var{indices{:}}.(idxOp(2:end));
        end

        if isempty(varargout)
            % There is nothing to return, remove the first output arg.
            clear var
        else
            % Shift the return value into the first output arg.
            var = varargout{1};
            varargout = {}; % never any additional values
        end
    end
end
