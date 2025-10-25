function t = dotAssign(t, varName, rhs)   %#codegen
%DOTASSIGN Subscripted assignment to a table using dot notation

%   Copyright 2019-2021 The MathWorks, Inc.

coder.extrinsic('matlab.internal.coder.datatypes.scanLabels');

t_nrows = t.rowDimLength();
t_nvars = t.varDim.length;

coder.internal.assert(coder.internal.isConst(varName), 'MATLAB:table:NonconstantVarIndex');

% Translate variable (column) name into an index. Avoid overhead of
% t.varDim.subs2inds as much as possible in this simple case.
%varName = convertStringsToChars(s(1).subs);
if isnumeric(varName)
    % Allow t.(i) where i is an integer
    varIndex = varName;
    coder.internal.assert(matlab.internal.datatypes.isScalarInt(varName,1), ...
        'MATLAB:table:IllegalVarIndex');
    coder.internal.assert(varIndex <= t_nvars, t.varDim.AssignmentOutOfRangeExceptionID);
else
    coder.internal.assert(ischar(varName) && (isrow(varName) || isequal(varName,'')),...
        'MATLAB:table:IllegalVarSubscript'); % isCharString(varName)
    
    % handle .Properties first
    if strcmp(varName,'Properties')
        t = setProperties(t,rhs);
        return
    end
    
    %varIndex = find(strcmp(varName,t.varDim.labels));
    varIndex = coder.const(matlab.internal.coder.datatypes.scanLabels(varName,t.varDim.labels));
    %isNewVar = false; % assume for now, update below
    if varIndex == 0
        coder.internal.errorIf(t.varDim.checkReservedNames(varName), ...
            'MATLAB:table:InvalidPropertyAssignment',varName);
        
        % Modifying row names is not supported for tables but supported for
        % timetables
        matchesFirstDim = strcmp(varName,t.metaDim.labels{1});
        if matchesFirstDim
            coder.internal.errorIf(t.rowDim.constantLabels && matchesFirstDim, ...
                'MATLAB:table:UnsupportedPropertyChange', 'RowNames');
        else
            % If it's the vars dimension name, assign to t{:,:}.
            coder.internal.assert(strcmp(varName,t.metaDim.labels{2}), ...
                t.varDim.UnrecognizedAssignmentLabelExceptionID, varName);
            varIndex = -1;
        end
    end
end

coder.internal.assert(size(rhs,1) == t_nrows, 'MATLAB:table:RowDimensionMismatch');

var_j = rhs;

if varIndex > 0
    t.data{varIndex} = var_j;
elseif varIndex == 0
    t.rowDim = t.rowDim.setLabels(var_j, [], t_nrows);
else % varIndex == -1
    t = braceAssign(t, var_j, ':', ':');
end
