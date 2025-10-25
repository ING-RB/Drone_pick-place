function checkTableVariableNames(names, dimNames, numVars)
%CHECKTABLEVARIABLENAMES Helper function that checks the provided names are
%valid and contain no duplicates.

% Copyright 2016-2020 The MathWorks, Inc.

names = names(:)';
if ~matlab.internal.datatypes.isText(names, true) || any(names == "")
    throwAsCaller(MException(message('MATLAB:table:InvalidVarNames')));
end

% We need to error out here because we are calling ismember on dimNames
% later.
if ~matlab.internal.datatypes.isText(dimNames, true)
    throwAsCaller(MException(message('MATLAB:table:InvalidDimNames')));
end

matlab.internal.tabular.validateVariableNameLength(names,'MATLAB:table:VariableNameLengthMax');

isUniqueName = strcmp(names, matlab.lang.makeUniqueStrings(names));
if any(~isUniqueName)
    idx = find(~isUniqueName, 1, 'first');
    throwAsCaller(MException(message('MATLAB:table:DuplicateVarNames', names{idx})));
end

if nargin >= 2
    isDimName = ismember(names, dimNames);
    if any(isDimName)
        throwAsCaller(MException(message('MATLAB:table:DuplicateDimNamesVarNames', names{find(isDimName, 1)})));
    end
end

if nargin >= 3 && ~isnan(numVars) && numel(names) ~= numVars
    throwAsCaller(MException(message('MATLAB:table:IncorrectNumberOfVarNames')));
end
