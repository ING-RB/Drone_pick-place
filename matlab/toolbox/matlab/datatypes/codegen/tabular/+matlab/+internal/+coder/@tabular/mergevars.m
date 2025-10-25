function b = mergevars(a,varsToMerge,varargin) %#codegen
%MERGEVARS Combine table or timetable variables into a multi-column
%variable.

%   Copyright 2020-2021 The MathWorks, Inc.

coder.extrinsic('matlab.lang.makeUniqueStrings', 'namelengthmax','setdiff','matlab.internal.coder.datatypes.cellstr_parenReference')


pnames = {'NewVariableName', 'MergeAsTable'};
poptions = struct( ...
    'CaseSensitivity',false, ...
    'PartialMatching','unique', ...
    'StructExpand',false);

supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});
if supplied.NewVariableName
mergedVarName = convertStringsToChars(coder.internal.getParameterValue(supplied.NewVariableName, '', varargin{:}));
% variable names must be constant
coder.internal.assert(coder.internal.isConst(mergedVarName), ...
    'MATLAB:table:mergevars:ParamMustBeConstant','NewVariableName');
end

asTable = coder.internal.getParameterValue(supplied.MergeAsTable, false, varargin{:});

% MergeAsTable must be constant
if supplied.MergeAsTable
   coder.internal.assert(coder.internal.isConst(asTable), ...
       'MATLAB:table:mergevars:ParamMustBeConstant','MergeAsTable');
end

asTable = matlab.internal.coder.datatypes.validateLogical(asTable,'MergeAsTable');

varsToMergeInds = sort(a.varDim.subs2inds(varsToMerge));

% Special case an empty list of varsToMerge
if isempty(varsToMergeInds)
    b = a;
    return
end

if asTable
    newvarRaw = a.parenReference(':',varsToMerge);
    if isa(newvarRaw,'timetable') %avoid ending up with a timetable-in-a-timetable
        newvar = timetable2table(newvarRaw,'ConvertRowTimes',false);
    else
        newvar = newvarRaw;
    end
     defaultprops = newvar.arrayPropsDflts;
     
     newvar = newvar.updateTabularProperties([],[],[],defaultprops,[]);
  
else % ~asTable
        newvar = a.extractData(varsToMerge);

end

if supplied.NewVariableName
    % not char vector or string or is ''
    coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(mergedVarName,false),'MATLAB:table:mergevars:InvalidNewVarName')
    
    % For consistency with default-created var name.
    mergedVarNameTemp = {(mergedVarName)};
    
   % varsToMerge = unique(varsToMerge,'stable');
else
    % calculate position where merged vars will go
    pos = varsToMergeInds(1);
    % Uniquify varsToMerge to avoid double-counting duplicates listed in varsToMerge.
    % We've already gotten them multiple times for the merged data, just
    % need to avoid it in indexing.
  %  varsToMergeInds = unique(varsToMergeInds,'stable');
    pos = pos - nnz(varsToMergeInds < pos);
    mergedVarName = a.varDim.dfltLabels(pos);
    mergedVarNameTemp = {[mergedVarName{:},'_new']};
    % Make sure default name does not conflict with remaining var names or dim names.
    originalVarNames = a.varDim.labels;
    remainingVarNames = coder.const(matlab.internal.coder.datatypes.cellstr_parenReference(originalVarNames,coder.const(setdiff(1:numel(originalVarNames),varsToMergeInds)))); %originalVarNames(varsToMerge) = [];
    mergedVarName = coder.const(matlab.lang.makeUniqueStrings(mergedVarName, matlab.internal.coder.datatypes.cellvec_concat(remainingVarNames,a.metaDim.labels), namelengthmax));
    mergedVarNameTemp = coder.const(matlab.lang.makeUniqueStrings(mergedVarNameTemp, matlab.internal.coder.datatypes.cellvec_concat(remainingVarNames,a.metaDim.labels), namelengthmax));

end

% Merged var is added in place of 1st of varsToMerge.

b = addvars(a,newvar,'Before',varsToMergeInds(1),'NewVariableName',mergedVarNameTemp); %a.dotAssign(varsToMergeInds(1),newvar);

% Delete the other varsToMerge so they don't get involved in name disambiguation.
delVars = varsToMergeInds+1;

b = b.removevars(delVars);
b = renamevars(b,mergedVarNameTemp,mergedVarName);

% Figure out new index of the merged variable based on the number of
% deleted vars that were to the left of it.
%newVarInd = varsToMergeInds(1) - nnz(varsToMergeInds(2:end) < varsToMergeInds(1));
if supplied.NewVariableName
    % Detect conflicts between the user-provided new var name and the original dim names.
    b.metaDim = b.metaDim.checkAgainstVarLabels(mergedVarName,'error');
end


