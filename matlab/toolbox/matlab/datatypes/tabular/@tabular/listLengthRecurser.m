function sz = listLengthRecurser(t,var,idxOp,context)
%

% LISTLENGTHRECURSER Helper for the tabular list length methods to handle row
% label translation.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isColon

% When subscripting into a tabular using dot or brace, the result of the first
% level would no longer have the row label information. However, if the first
% level is followed by another brace or paren, then we still allow subscripting
% using the row labels on the second level. So the row labels at the second
% level need to be converted into numeric indices before calling listLength on
% the result of the first level. Since matlab.indexing.IndexingOperation does
% not allow modifying the internal Indices property, we have this helper to
% correctly handle each of the cases below. 

if isa(var, 'tabular')
    % If the result of the first level is itself a tabular, then we might have
    % to call listLenghtRecurser again to handle row label translation for the
    % level after that, since the internal tabular might also have its own row
    % labels.
    if isscalar(idxOp)
        % One level of dot, brace or paren subscripting on tabulars always
        % returns a single output.
        sz = 1;
    elseif idxOp(1).Type == matlab.indexing.IndexingOperationType.Dot
        % Dot indexing does not use row labels, so no translation is required.
        % Directly call dotListLength for this case.
        sz = dotListLength(var,idxOp,context);
    else % brace or paren followed by other kinds of subscripting
        indices = idxOp(1).Indices;
        if isnumeric(indices{1}) || islogical(indices{1}) || isColon(indices{1})
            % Indices do not contain row labels, so no translation is required.
            % Since the next level could be a brace or a paren, call listLength
            % to correctly dispatch to the appropriate tabular *ListLength method.
            sz = listLength(var,idxOp,context);
        else
            % Indices contain row labels, so translate them into numeric indices
            % and then do the actual indexing to get the intermediate value.
            indices = t.translateRowLabels(1,idxOp(1).Indices);
            if idxOp(1).Type == matlab.indexing.IndexingOperationType.Brace
                intermediate = var{indices{:}};
            else % Paren
                intermediate = var(indices{:});
            end
            % Since the current level is a tabular, the level after that might
            % be using row labels from var and might also require translation,
            % so call listLengthRecurser on the intermediate value to handle
            % that case appropriately.
            sz = listLengthRecurser(var,intermediate,idxOp(2:end),context);
        end
    end
else % current level is not a tabular
    % If the current level is not a tabular, then we cannot be sure if breaking
    % up a subscripting expression is safe to do. So if such a case requires row
    % label translation, then first convert the IndexingOperation into a
    % substruct, do the row label translation and update the substruct before
    % calling var's numArgumentsFromSubscript. If row label translation is not
    % required, we can directly call listLength.
    if (idxOp(1).Type ~= matlab.indexing.IndexingOperationType.Dot)
        rowLabels = idxOp(1).Indices{1};
        if ~(isnumeric(rowLabels) || islogical(rowLabels) || isColon(rowLabels))
            s = matlab.internal.indexing.convertIndexingOperationToSubstruct(idxOp);
            s(1).subs = t.translateRowLabels(1,s(1).subs);
            sz = numArgumentsFromSubscript(var,s,context);
            return;
        end
    end
    sz = listLength(var,idxOp,context);
end
