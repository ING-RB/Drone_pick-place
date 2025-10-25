function [b,varargout] = dotReference(t,idxOp)
%

% DOTREFERENCE Subscripted reference for a table.
%   B = T.VAR, T.(VARNAME), or T.(VARINDEX) returns a table variable.  VAR
%   is a variable name literal, VARNAME is a character variable containing
%   a variable name, or VARINDEX is a positive integer.  T.VAR, T.(VARNAME),
%   or T.(VARINDEX) may also be followed by further subscripting as supported
%   by the variable.  In particular, T.VAR(ROWNAMES,...), T.VAR{ROWNAMES,...},
%   etc. (when supported by VAR) provide subscripting into a table variable
%   using row names.
%
%   P = T.PROPERTIES.PROPERTYNAME returns a table property.  PROPERTYNAME is
%   'RowNames', 'VariableNames', 'Description', 'VariableDescriptions',
%   'VariableUnits', 'DimensionNames', or 'UserData'.  T.PROPERTIES.PROPERTYNAME
%   may also be followed by further subscripting as supported by the property.

% Copyright 2021-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isColon
import matlab.internal.datatypes.isScalarInt
import matlab.internal.datatypes.tryThrowIllegalDotMethodError
import matlab.lang.correction.ReplaceIdentifierCorrection

% '.' is a reference to a table variable or property.  Any sort of
% subscripting may follow.  Row labels for cascaded () or {} subscripting on
% a variable are inherited from the table.

% This method handles RHS subscripting expressions such as
%    t.Var
%    t.Var.Field
%    t.Var{rowindices} or t.Var{rowindices,...}
%    t.Var{rownames}   or t.Var{rownames,...}
% or their dynamic var name versions, and also when there is deeper subscripting such as
%    t.Var.Field[anything else]
%    t.Var{...}[anything else]

try
    
    if ~isa(idxOp,'matlab.indexing.IndexingOperation')
        % Internal tabular methods can call dotReference directly by specifying the
        % varName as the second argument. Convert that into a struct with Type
        % and Name fields so we do not need to special case for that in the code
        % below.
        tempIdxOp.Type = matlab.indexing.IndexingOperationType.Dot;
        tempIdxOp.Name = idxOp;
        idxOp = tempIdxOp;
    end
    varName = idxOp(1).Name;
    if isnumeric(varName)
        % Allow t.(i) where i is an integer
        varIndex = varName;
        if ~isScalarInt(varIndex,1)
            error(message('MATLAB:table:IllegalVarIndex'));
        elseif varIndex > t.varDim.length
            error(message('MATLAB:table:VarIndexOutOfRange'));
        end
    elseif (isstring(varName) && isscalar(varName)) ...
        || (ischar(varName) && (isrow(varName) || isequal(varName,''))) % isScalarText(varName)
        % Translate variable (column) name into an index. Avoid overhead of
        % t.varDim.subs2inds in this simple case.
        varIndex = find(matches(t.varDim.labels,varName));
        if isempty(varIndex)
            % If there's no such var, it may be a reference to the 'Properties'
            % (virtual) property.  Handle those, but disallow references to
            % any property directly. Check this first as a failsafe against
            % shadowing .Properties by a dimension name.
            if varName == "Properties"
                if isscalar(idxOp)
                    if nargout < 2
                        b = t.getProperties;
                    else
                        nargoutchk(0,1);
                    end
                else
                    try
                        % First of all, call getProperty to get the referenced
                        % property and the trailing part of the indexing
                        % operation (if present).
                        [prop, trailingIdxOp, translatedIndices] = t.getProperty(idxOp(2:end));
                        
                        if isempty(trailingIdxOp)
                            % If there is no cascaded subscripting into the
                            % property, then return the property.
                            b = prop;
                            nargoutchk(0,1); % Error if > 1 nargout
                        else
                            % If there's cascaded subscripting into the property, let the
                            % property's subsref handle the reference. This may result in
                            % a comma-separated list, so ask for and assign to as many
                            % outputs as we're given. That is the number of outputs on
                            % the LHS of the original expression, or if there was no LHS,
                            % it comes from numArgumentsFromSubscript.

                            % dotReference's output args are defined as [b,varargout] so the nargout==1
                            % case can avoid varargout, although that adds complexity to the nargout==0
                            % case. See detailed comments in parenReference.
                            if nargout == 1
                                b = forwardReference(prop, trailingIdxOp, translatedIndices);
                            elseif nargout > 1
                                [b,varargout{1:nargout-1}] = forwardReference(prop, trailingIdxOp, translatedIndices);
                            else % nargout == 0
                                % Let varargout bump magic capture either one output or zero
                                % outputs. See detailed comments in parenReference.
                                [varargout{1:nargout}] = forwardReference(prop, trailingIdxOp, translatedIndices);
                                if ~isempty(varargout)
                                    % Shift the return value into the first output arg.
                                    b = varargout{1};
                                    varargout = {}; % never any additional values
                                end
                            end
                        end
                    catch ME
                        if ME.identifier == "MATLAB:table:UnknownProperty"
                            propName = idxOp(2).Name;
                            match = find(matches(t.propertyNames,propName,"IgnoreCase",true),1);
                            if ~isempty(match) % a property name, but with wrong case
                                match = t.propertyNames{match};
                                throw(MException(message('MATLAB:table:UnknownPropertyCase',propName,match)) ...
                                	.addCorrection(ReplaceIdentifierCorrection(propName,match)));
                            else
                                throw(ME);
                            end
                        else
                            throw(ME);
                        end
                    end
                end
                return
            elseif matches(varName,t.metaDim.labels{1})
                % If it's the row dimension name, return the row labels
                varIndex = 0;
            elseif matches(varName,t.metaDim.labels{2})
                % If it's the vars dimension name, return t{:,:}. Deeper subscripting
                % is not supported, use explicit braces for that.
                if ~isscalar(idxOp)
                    error(message('MATLAB:table:NestedSubscriptingWithDotVariables',t.metaDim.labels{2}));
                end
                varIndex = -1;
            elseif matches(varName,'Properties',"IgnoreCase", true) % .Properties, but with wrong case
                throw(MException(message('MATLAB:table:UnrecognizedVarNamePropertiesCase',varName)) ...
                	.addCorrection(ReplaceIdentifierCorrection(varName, 'Properties')));
            else
                match = find(matches(t.propertyNames,varName,"IgnoreCase", true),1);
                if ~isempty(match)
                    match = t.propertyNames{match};
                    if matches(varName,match) % a valid property name
                        throw(MException(message('MATLAB:table:IllegalPropertyReference',varName)) ...
                            .addCorrection(ReplaceIdentifierCorrection(varName, append('Properties.', match))));
                    else % a property name, but with wrong case
                        throw(MException(message('MATLAB:table:IllegalPropertyReferenceCase',varName,match)) ...
                            .addCorrection(ReplaceIdentifierCorrection(varName, append('Properties.', match))));
                    end
                else
                    match = find(matches(t.varDim.labels,varName,"IgnoreCase",true),1);
                    if ~isempty(match) % an existing variable name
                        match = t.varDim.labels{match};
                        throw(MException(message('MATLAB:table:UnrecognizedVarNameCase',varName,match)) ...
                            .addCorrection(ReplaceIdentifierCorrection(varName,match)));
                    elseif matches(varName,t.metaDim.labels{1},'IgnoreCase',true) % the row dimension name
                        throw(MException(message('MATLAB:table:RowDimNameCase',varName,t.metaDim.labels{1})) ...
                            .addCorrection(ReplaceIdentifierCorrection(varName,t.metaDim.labels{1})));
                    elseif matches(varName,t.metaDim.labels{2},'IgnoreCase',true) && isscalar(idxOp) % the variables dimension name
                        throw(MException(message('MATLAB:table:VariablesDimNameCase',varName,t.metaDim.labels{2})) ...
                        	.addCorrection(ReplaceIdentifierCorrection(varName,t.metaDim.labels{2})));
                    elseif matches(t.defaultDimNames{1},varName) % trying to access row labels by default name
                        throw(t.throwSubclassSpecificError('RowDimNameNondefault',varName,t.metaDim.labels{1}) ...
                        	.addCorrection(ReplaceIdentifierCorrection(varName,t.metaDim.labels{1})));
                    elseif matches(t.defaultDimNames{2},varName) % trying to access variables by default name
                        throw(MException(message('MATLAB:table:VariablesDimNameNondefault',varName,t.metaDim.labels{2})) ...
                            .addCorrection(ReplaceIdentifierCorrection(varName,t.metaDim.labels{2})));
                    else
                        tryThrowIllegalDotMethodError(t,varName,'MethodsWithNoCorrection',t.methodsWithNonTabularFirstArgument,'MessageCatalog','MATLAB:table');
                        error(message('MATLAB:table:UnrecognizedVarName',varName));
                    end
                end
            end
        end
    else
        error(message('MATLAB:table:IllegalVarSubscript'));
    end
    
    if varIndex > 0
        b = t.data{varIndex};
    elseif varIndex == 0
        b = t.rowDim.labels;
    else % varIndex == -1
        b = t.extractData(1:t.varDim.length);
    end
    
    if isscalar(idxOp)
        % If there's no additional subscripting, return the table variable.
        if nargout > 1
            nargoutchk(0,1);
        end
    else
        idxOp = idxOp(2:end);
        
        % Now let the variable's subsref handle the remaining subscripts in things
        % like t.name(...) or  t.name{...} or t.name.property. This may return a
        % comma-separated list, so ask for and assign to as many outputs as we're
        % given. That is the number of outputs on the LHS of the original expression,
        % or if there was no LHS, it comes from numArgumentsFromSubscript.
        % The first dot could be followed by parens or a brace that might be
        % using row labels inherited from t. Call translateAndForwardReference
        % to handle the translation before forwarding the subscripting
        % expression.
        %
        % dotReference's output args are defined as [b,varargout] so the nargout==1
        % case can avoid varargout, although that adds complexity to the nargout==0
        % case. See detailed comments in parenReference.
        if nargout == 1
            b = t.translateAndForwardReference(b, idxOp);
        elseif nargout > 1
            [b,varargout{1:nargout-1}] = t.translateAndForwardReference(b, idxOp); 
        else % nargout == 0
            % Let varargout bump magic capture either one output or zero
            % outputs. See detailed comments in parenReference.
            [varargout{1:nargout}] = t.translateAndForwardReference(b, idxOp); % call it just for error handling
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


function [varargout] = forwardReference(p,idxOp,translatedIndices)
% Local helper to forward an indexing operation with or without translated
% indices.
idxOpType = idxOp(1).Type;
if isequal(translatedIndices,[]) % || idxOpType == matlab.indexing.IndexingOperationType.Dot
    [varargout{1:nargout}] = p.(idxOp);
elseif idxOpType == matlab.indexing.IndexingOperationType.Brace
    if isscalar(idxOp)
        [varargout{1:nargout}] = p{translatedIndices{:}};
    else
        [varargout{1:nargout}] = p{translatedIndices{:}}.(idxOp(2:end));
    end
else % Paren
    if isscalar(idxOp)
        [varargout{1:nargout}] = p(translatedIndices{:});
    else
        [varargout{1:nargout}] = p(translatedIndices{:}).(idxOp(2:end));
    end
end
