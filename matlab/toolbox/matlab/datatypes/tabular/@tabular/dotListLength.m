function sz = dotListLength(t, idxOp, context)
%

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isColon

if isscalar(idxOp) % one level of subscripting on a table
    sz = 1; % table returns one array for dot
elseif context == matlab.mixin.util.IndexingContext.Assignment
    sz = 1; % table subsasgn only ever accepts one rhs value
elseif idxOp(end).Type == matlab.indexing.IndexingOperationType.Paren
    % This should never be called with parentheses as the last
    % subscript, but return 1 for that just in case
    sz = 1;
else % multiple subscripting levels
    try
        if strcmp(idxOp(1).Name, "Properties")
            if idxOp(2).Type == matlab.indexing.IndexingOperationType.Dot
                if length(idxOp) == 2 % t.Properties.PropertyName
                    sz = 1; % no need to validate the name, subsref will do that
                else % t.Properties.PropertyName...
                    [prop,trailingIdxOp,translatedIndices] = t.getProperty(idxOp(2:end));
                    if isempty(trailingIdxOp)
                        % No cascaded subscripting on the extracted property so
                        % the size would always be 1.
                        % Note that this could happen in two scenarios.
                        % 1. Referencing a "regular" tabular property like
                        % VariableNames, RowNames, etc.
                        % 2. Referencing a per-table or per-variable
                        % CustomProperty.
                        % Case 1. will not come here, it will be filtered out by
                        % the length(idxOp) == 2 check above, but Case 2. will
                        % be handled here.
                        sz = 1;
                    elseif isequal(translatedIndices,[])
                        % The next level in the subscripting expression did not
                        % require a translation. This could be due to one of the
                        % following reasons:
                        % - Next level is a dot
                        % - Next level is parens or braces but with numeric,
                        % logical or colon subscripts
                        % - The property does not allow named-subscripting (e.g. 
                        %   UserData, per-table CustomProperty, etc.)
                        % For this case, we simply call listLength on the
                        % property with the remainder of the subscripting
                        % expression.
                        sz = listLength(prop,trailingIdxOp,context);
                    else % Next level needed translation
                        % Convert the remainder of the indexing expression into
                        % a substruct, update the subs of the new first-level
                        % with the translated indices obtained from getProperty
                        % and call numArgumentsFromSubscript.
                        s = matlab.internal.indexing.convertIndexingOperationToSubstruct(trailingIdxOp);
                        s(1).subs = translatedIndices;
                        sz = numArgumentsFromSubscript(prop,s,context);
                    end
                end            
            else % t.Properties(...) or t.Properties{...}
                % t.Properties must always be followed by .PropName, so parens
                % or braces are always an error. Let t.Properties's
                % numArgumentsFromSubscripts throw the error.
                prop = t.getProperties(); 
                sz = listLength(prop,idxOp(2:end),context);
            end
        else
            intermediate = t.(idxOp(1)); % Calls dotReference
            % The first dot could be followed by parens or a brace that
            % might be using row labels inherited from t. Call listLengthRecurser
            % to handle the translation before calling intermediate's listLength
            % method.
            sz = t.listLengthRecurser(intermediate,idxOp(2:end),context);
        end
    catch ME
        throw(ME); 
    end
end
