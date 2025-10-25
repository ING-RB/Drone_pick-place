function t = renamevars(t,vars,newnames)
%

%   Copyright 2019-2024 The MathWorks, Inc.

import matlab.internal.datatypes.throwInstead

if nargout == 0
    error(message('MATLAB:table:renamevars:NoLHS'));
end

% Need to pass t.data to subs2inds if vars is a vartype rather than relying
% on setLabels to do subs2inds.
subsType = matlab.internal.tabular.private.tabularDimension.subsType_reference;
try
    vars = t.subs2inds(vars,'varDim',subsType);
catch ME
    if matlab.internal.datatypes.isScalarText(vars) && any(matches(vars, t.metaDim.labels)) % one dim name
        error(message('MATLAB:table:renamevars:RenameDim'))
    end
    throwInstead(ME,'MATLAB:table:InvalidVarSubscript','MATLAB:table:renamevars:InvalidVarSubscript')
end
try
    t.varDim = t.varDim.setLabels(newnames,vars);
catch ME
    if ~matlab.internal.datatypes.isText(newnames)
        error(message('MATLAB:table:renamevars:NamesNotText'));
    end
    % setLabels would not do any implicit expansion, so if it throws
    % MATLAB:table:DuplicateVarNames error, then either the newnames contained
    % duplicates or they conflicted with existing var names. In that case we do
    % not need to do any additional checks and simply throw the same error.
    % However, if the number of var indices and newnames did not match, then
    % catch that error and throw a renamevars specific error message.
    throwInstead(ME,{'MATLAB:table:IncorrectNumberOfVarNamesPartial'},'MATLAB:table:renamevars:NumNamesMismatch')
end
% Check for conflicts between the new VariableNames and the existing
% DimensionNames. For backwards compatibility, a table will modify
% DimensionNames and warn, while a timetable will error.
t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
