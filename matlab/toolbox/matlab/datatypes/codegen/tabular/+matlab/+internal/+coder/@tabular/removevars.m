function b = removevars(a,vars) %#codegen
%REMOVEVARS Delete variables from table or timetable.

%   Copyright 2020 The MathWorks, Inc.

if nargin < 2
    b = a; % Nothing needs to be moved
else
    % VARS must be constant
    coder.internal.assert(coder.internal.isConst(vars),'MATLAB:table:NonconstantVarIndex');
    
    if isempty(vars)
        coder.internal.errorIf(ischar(vars),'MATLAB:table:InvalidVarName'); % VARS cannot be empty char
        b = a;
    elseif islogical(vars)
        coder.internal.assert(length(vars)==a.varDim.length,'MATLAB:table:VarIndexOutOfRange')
        b = parenReference(a,':',~vars);
    else
        if ischar(vars)
            vars = a.varDim.subs2inds(vars);
        else % make sure non-char VARS is vector
            coder.internal.errorIf(isa(vars,'vartype'),'MATLAB:table:addmovevars:VartypeInvalidVars');
            vars = a.varDim.subs2inds(reshape(vars,numel(vars),1));
        end
        
        % Force compile-time subscripting with VARS to delegate validity
        % check and erroring to tabular/parenReference
        vars = matlab.internal.coder.datatypes.unique(vars);
        if coder.ignoreConst(false) 
            parenReference(a,':',vars);
        end
        
        % Return sub-table corresponding to setdiff of all indices & VARS
        b = parenReference(a, ':', coder.const(feval('setdiff', 1:a.varDim.length, vars)) );
    end
end