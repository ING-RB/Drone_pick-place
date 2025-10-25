function [b,varargout] = braceReference(t,idxOp)
%

% BRACEREFERENCE Subscripted reference into a table using braces.
%   B = T{I,J} returns an array B created as the horizontal concatenation
%   of the table variables specified by J, containing only those rows
%   specified by I.  BRACEREFERENCE throws an error if the types of the variables
%   are not compatible for concatenation.  I and J are positive integers,
%   vectors of positive integers, row/variable names, cell arrays
%   containing one or more row/variable names, or logical vectors.  T{I,J}
%   may also be followed by further subscripting as supported by the
%   variable.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isColon

% '{}' is a reference to the contents of a subset of a table.  If no
% subscripting follows, return those contents as a single array of whatever
% type they are.  Any sort of subscripting may follow.
try      
    if numel(idxOp(1).Indices) ~= t.metaDim.length
        tabular.throwNDSubscriptError(numel(idxOp(1).Indices))
    end
    
    % Translate row labels into indices (leaves logical and ':' alone)
    [rowIndices,numRowIndices] = t.subs2inds(idxOp(1).Indices{1},'rowDim');
    
    % Translate variable (column) names into indices (translates logical and ':')
    varIndices = t.subs2inds(idxOp(1).Indices{2},'varDim',matlab.internal.tabular.private.tabularDimension.subsType_reference);
    
    % Extract the specified variables as a single array.
    if isscalar(varIndices)
        b = t.data{varIndices};
    else
        b = t.extractData(varIndices);
    end
    
    % Retain only the specified rows.
    if isa(b,'tabular') || ismatrix(b)
        b = b(rowIndices,:); % without using reshape, may not have one
    else
        % The contents could have any number of dims.  Treat it as 2D to get
        % the necessary row, and then reshape to its original dims.
        outSz = size(b); outSz(1) = numRowIndices;
        b = reshape(b(rowIndices,:), outSz);
    end
    
    if isscalar(idxOp)
        % If there's no additional subscripting, return the table contents.
        if nargout > 1
            % Output of table brace subscripting will always be scalar
            error(message('MATLAB:table:TooManyOutputsBracesIndexing'));
        end
    else
        idxOp = idxOp(2:end);
        % Let b's subsref handle any remaining additional subscripting.  This may
        % return a comma-separated list when the cascaded subscripts resolve to
        % multiple things, so ask for and assign to as many outputs as we're
        % given. That is the number of outputs on the LHS of the original expression,
        % or if there was no LHS, it comes from numArgumentsFromSubscript.
        % braceReference's output args are defined as [b,varargout] so the nargout==1
        % case can avoid varargout, although that adds complexity to the nargout==0
        % case. See detailed comments in parenReference.
        %
        % Also the first brace could be followed by parens or another brace that
        % might be using row labels inherited from t. Since b would not know
        % anything about the row labels, call translateAndForwardReference to
        % translate these row labels to numeric indices before forwarding the
        % subscripting expression.
        if nargout == 1
            b = t.translateAndForwardReference(b, idxOp);
        elseif nargout > 1
            [b,varargout{1:nargout-1}] = t.translateAndForwardReference(b, idxOp); 
        else % nargout == 0
            % Let varargout bump magic capture either one output or zero
            % outputs. See detailed comments in parenReference.
            [varargout{1:nargout}] = t.translateAndForwardReference(b, idxOp);
            if isempty(varargout)
                % There is nothing to return, remove the first output arg.
                clear b
            else
                % Shift the return value into the first output arg.
                b = varargout{1};
                varargout = {}; % never any additional values
            end
        end
    end
catch ME
    throw(ME); 
end
