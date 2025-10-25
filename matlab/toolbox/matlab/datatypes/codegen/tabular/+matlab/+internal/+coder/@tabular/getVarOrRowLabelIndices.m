function varIndices = getVarOrRowLabelIndices(t,varSubscripts,allowEmptyRowLabels) %#codegen
% Translate the specified variable specification, which may include the row labels
% name, into var indices, with 0 indicating row labels. This is useful in cases
% where the var spec is an input arg to methods like sortrows or varfun, but is
% not appropriate for processing subscripts in parens/braces subscripting where
% the row labels name is never legal. The only way the row labels can be
% specified in a var spec is by name, never by numeric or logical var indices.

%   Copyright 2020 The MathWorks, Inc.

coder.extrinsic('matches');

coder.internal.assert(coder.internal.isConst(varSubscripts),'MATLAB:table:NonconstantVarIndex');

% Check to see if we have var names (as opposed to indices or logical).
haveVarNames = matlab.internal.coder.datatypes.isText(varSubscripts);

if haveVarNames % only way row labels can be specified
    % Separate out any names that specify the row labels from those that
    % specify data vars.
    isRowLabels = coder.const(matches(varSubscripts,t.metaDim.labels{1}));
    
    % Add the row labels to the list of vars in the output.
    rowLabelsIncluded = any(isRowLabels);
    if rowLabelsIncluded
        coder.internal.assert(t.rowDim.hasLabels || ((nargin > 2) && allowEmptyRowLabels),...
            'MATLAB:table:NoRowLabels');
        if isscalar(isRowLabels)
            % If it's only the row labels, return quickly. This also prevents a
            % char row vector from causing problems below.
            varIndices = 0;
            return
        end
        
        % Preallocate the outputs, data var elements to be overwritten later.
        varIndices = zeros(1,length(varSubscripts));
        
        isDataVar = ~isRowLabels;
        dataVarSubscripts = coder.const(subsrefParens(varSubscripts,{isDataVar}));
    else
        dataVarSubscripts = varSubscripts;
    end
else
    rowLabelsIncluded = false;
    dataVarSubscripts = varSubscripts;
end

% Validate data var subscripts and translate them into numeric indices.
dataVarIndices = t.varDim.subs2inds(dataVarSubscripts);

% Add data vars to the list of vars in the output.
if rowLabelsIncluded
    varIndices(isDataVar) = dataVarIndices;
else
    varIndices = dataVarIndices;
end
varIndices = coder.const(varIndices);
end

function C = subsrefParens(A,subs)
    coder.inline('always');
    coder.extrinsic('subsref','substruct');
    C = subsref(A,substruct('()',subs));
end
