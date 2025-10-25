function varIndices = getVarOrRowLabelIndices(t,varSubscripts,allowEmptyRowLabels,patternMatchRowDimName)
%

% Translate the specified variable specification, which may include the row labels
% name, into var indices, with 0 indicating row labels. This is useful in cases
% where the var spec is an input arg to methods like sortrows or varfun, but is
% not appropriate for processing subscripts in parens/braces subscripting where
% the row labels name is never legal. The only way the row labels can be
% specified in a var spec is by name, never by numeric or logical var indices.

%   Copyright 2016-2024 The MathWorks, Inc.

% Check to see if we have var names (as opposed to indices or logical).
haveVarNames = matlab.internal.datatypes.isText(varSubscripts);

if haveVarNames % only way row labels can be specified
    % Separate out any names that specify the row labels from those that
    % specify data vars.
    isRowLabels = matches(varSubscripts,t.metaDim.labels{1});
    
    % Add the row labels to the list of vars in the output.
    rowLabelsIncluded = any(isRowLabels);
    if rowLabelsIncluded
        if t.rowDim.hasLabels || ((nargin > 2) && allowEmptyRowLabels)
            if isscalar(isRowLabels)
                % If it's only the row labels, return quickly. This also prevents a
                % char row vector from causing problems below.
                varIndices = 0;
                return
            end
            
            % Preallocate the outputs, data var elements to be overwritten later.
            varIndices = zeros(1,length(varSubscripts));
            
            isDataVar = ~isRowLabels;
            dataVarSubscripts = varSubscripts(isDataVar);
        else
            throwAsCaller(t.throwSubclassSpecificError('NoRowLabels'));
        end
    else
        dataVarSubscripts = varSubscripts;
    end
else
    rowLabelsIncluded = false;
    dataVarSubscripts = varSubscripts;
end

% Validate data var subscripts and translate them into numeric indices.
try
    dataVarIndices = t.varDim.subs2inds(dataVarSubscripts);
    patternMatchRowDimName = nargin > 3 && patternMatchRowDimName && isa(dataVarSubscripts,"pattern"); % allow matching subscript against row dimension name
    if patternMatchRowDimName && matches(t.metaDim.labels{1},dataVarSubscripts) % subscript matches row dimension name
        if t.rowDim.hasLabels || allowEmptyRowLabels
            dataVarIndices = [0 dataVarIndices];
        else
            throwAsCaller(t.throwSubclassSpecificError('NoRowLabels'));
        end
    end
catch ME
    if ME.identifier == "MATLAB:table:UnrecognizedVarName"
        rowDimName = t.metaDim.labels{1};
        defaultRowDimName = t.defaultDimNames{1};
        dataVarSubscripts = cellstr(dataVarSubscripts);
        if matches(defaultRowDimName,dataVarSubscripts)
            % Helpful error if an unrecognized var name specifies the default row
            % dim name 'Row'/'Time', but the actual row dim name has been renamed
            % to something other than the default.
            ME = t.throwSubclassSpecificError('RowDimNameNondefault',defaultRowDimName,rowDimName);
        elseif matches(rowDimName,dataVarSubscripts,"IgnoreCase",true)
            % Helpful error if an unrecognized var name is the row dim name, just
            % off by case.
            match = find(matches(dataVarSubscripts,rowDimName,"IgnoreCase", true),1);
            ME = t.throwSubclassSpecificError('RowDimNameCase',dataVarSubscripts{match},rowDimName);
        else
            [tf,loc] = ismember(lower(dataVarSubscripts),lower(t.varDim.labels));
            tf(ismember(dataVarSubscripts,t.varDim.labels)) = false;
            match = find(tf,1);
            if ~isempty(match)
                % Helpful error if an unrecognized var name is just off by case.
                attempt = dataVarSubscripts{match};
                actual = t.varDim.labels{loc(match)};
                ME = MException(message('MATLAB:table:UnrecognizedVarNameCase',attempt,actual));
            end
        end
    end
    throwAsCaller(ME);
end

% Add data vars to the list of vars in the output.
if rowLabelsIncluded
    varIndices(isDataVar) = dataVarIndices;
else
    varIndices = dataVarIndices;
end
