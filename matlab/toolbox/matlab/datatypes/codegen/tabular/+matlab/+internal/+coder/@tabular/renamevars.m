function t = renamevars(t,varsToRename,newnames) %#codegen
%RENAMEVARS Rename variables in table or timetable.

%   Copyright 2020-2021 The MathWorks, Inc.
narginchk(3,3);
coder.internal.errorIf(nargout==0,'MATLAB:table:renamevars:NoLHS');
coder.internal.assert(coder.internal.isConst(newnames),'MATLAB:table:renamevars:NewVarNamesMustBeConstant');
coder.internal.assert(matlab.internal.coder.datatypes.isText(newnames),'MATLAB:table:renamevars:NamesNotText');

coder.extrinsic('replace','matlab.internal.coder.datatypes.cellstr_parenReference','any','matches');

coder.internal.errorIf(coder.internal.isConst(varsToRename) && matlab.internal.coder.datatypes.isScalarText(varsToRename) && coder.const(any(coder.const(matches(varsToRename, t.metaDim.labels)))),'MATLAB:table:renamevars:RenameDim');

% Need to pass t.data to subs2inds if vars is a vartype rather than relying
% on setLabels to do subs2inds.
subsType = matlab.internal.coder.tabular.private.tabularDimension.subsType.reference;
[varsToRenameInds,q] = sort(coder.const(t.varDim.subs2inds(varsToRename,subsType,t.data)));

varnames = coder.const(t.varDim.labels);
oldnames = coder.const(matlab.internal.coder.datatypes.cellstr_parenReference(coder.const(varnames),coder.const(varsToRenameInds)));

if matlab.internal.coder.datatypes.isScalarText(newnames)
    if ischar(newnames)
        newnamesProcessed = {newnames};
    else
        newnamesProcessed = cellstr(newnames);
    end
elseif numel(q) == numel(newnames)
    newnamesProcessed = coder.const(matlab.internal.coder.datatypes.cellstr_parenReference(coder.const(newnames),coder.const(q)));
else
    newnamesProcessed = newnames;
end

coder.internal.errorIf(numel(oldnames) ~= numel(newnamesProcessed),'MATLAB:table:renamevars:NumNamesMismatch');

numVars = numel(varnames);
allnames = cell(1,numVars);
if ~isempty(varsToRenameInds) && ( ~isempty(newnames) || ~isempty(varsToRename))
    j = numel(varsToRenameInds);
    coder.unroll();
    for i = numVars:-1:1
        if i == varsToRenameInds(j)
           
            allnames{i} = newnamesProcessed{j};
            if j > 1
                j = j-1;
            end
        else
            allnames{i} = varnames{i};
        end
    end
else
    allnames = varnames;
end

t_varDim = t.varDim.createLike(t.varDim.length,allnames);
t_varDim = t_varDim.moveProps(t.varDim,1:t.varDim.length,1:t_varDim.length);
t = t.updateTabularProperties(t_varDim,[],[],[]);

% Check for conflicts between the new VariableNames and the existing
% DimensionNames. For backwards compatibility, a table will modify
% DimensionNames and warn, while a timetable will error.
t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);