function b = mergevars(a,varsToMerge,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

% Avoid unsharing of shared-data copy across function call boundary
import matlab.lang.internal.move

pnames = {'NewVariableName', 'MergeAsTable'};
dflts =  {                  []       false};
[mergedVarName,asTable,supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});

asTable = matlab.internal.datatypes.validateLogical(asTable,'MergeAsTable');

varsToMerge = a.varDim.subs2inds(varsToMerge);

% Special case an empty list of varsToMerge
if isempty(varsToMerge)
    b = a;
    return
end

if asTable
    newvar = a(:,varsToMerge);
    if isa(newvar,'timetable') %avoid ending up with a timetable-in-a-timetable
        newvar = timetable2table(newvar,'ConvertRowTimes',false);
    end
    newvar = newvar.setDescription(newvar.arrayPropsDflts.Description);
    newvar = newvar.setUserData(newvar.arrayPropsDflts.UserData);
    newvar.arrayProps.TableCustomProperties = struct; % Clear per-table CustomProperties from inner table.
else % ~asTable
    try
        newvar = a.extractData(varsToMerge);
    catch extractME
        ME = MException(message('MATLAB:table:mergevars:ExtractDataIncompatibleTypeError'));
        ME = ME.addCause(extractME);
        throw(ME);
    end
end

if supplied.NewVariableName
    if ~matlab.internal.datatypes.isScalarText(mergedVarName,false) % not char vector or string or is ''
        error(message('MATLAB:table:mergevars:InvalidNewVarName'));
    else % For consistency with default-created var name.
        mergedVarName = {convertStringsToChars(mergedVarName)};
    end
    varsToMerge = unique(varsToMerge,'stable');
else
    % calculate position where merged vars will go
    pos = varsToMerge(1);
    % Uniquify varsToMerge to avoid double-counting duplicates listed in varsToMerge.
    % We've already gotten them multiple times for the merged data, just
    % need to avoid it in indexing.
    varsToMerge = unique(varsToMerge,'stable');
    pos = pos - nnz(varsToMerge < pos);
    mergedVarName = a.varDim.dfltLabels(pos);
    % Make sure default name does not conflict with remaining var names or dim names.
    remainingVarNames = a.varDim.labels;
    remainingVarNames(varsToMerge) = [];
    mergedVarName = matlab.lang.makeUniqueStrings(mergedVarName, [remainingVarNames,a.metaDim.labels], namelengthmax);
end

% Merged var is added in place of 1st of varsToMerge.
% Explicitly call dotAssign to always dispatch to subscripting code, even
% when the variable name matches an internal tabular property/method.
b = move(a).dotAssign(varsToMerge(1),newvar);
% Delete the other varsToMerge so they don't get involved in name disambiguation.
delVars = varsToMerge;
delVars(1) = [];
b = b.removevars(delVars);
% Figure out new index of the merged variable based on the number of
% deleted vars that were to the left of it.
newVarInd = varsToMerge(1) - nnz(delVars < varsToMerge(1));
if supplied.NewVariableName
    % Detect conflicts between the user-provided new var name and the original dim names.
    b.metaDim = b.metaDim.checkAgainstVarLabels(mergedVarName,'error');
end
b.varDim = b.varDim.setLabels(mergedVarName,newVarInd);
% Clear outdated outer per-variable metadata for newvar
b.varDim = b.varDim.assignInto(b.varDim.createLike(1,mergedVarName),newVarInd);
