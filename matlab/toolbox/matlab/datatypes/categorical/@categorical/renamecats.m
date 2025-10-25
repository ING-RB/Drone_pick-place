function a = renamecats(a,oldNames,newNames)
%

%   Copyright 2013-2024 The MathWorks, Inc.

if nargout == 0
    if nargin < 3
        error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEWNAMES'));
    else
        error(message('MATLAB:categorical:NoLHS',upper(mfilename),',OLDNAMES,NEWNAMES'));
    end
end

try
    oldNames = checkCategoryNames(oldNames,2); % error if duplicates
catch ME
    if ME.identifier == "MATLAB:categorical:InvalidNames" && isa(oldNames, "pattern") && matlab.internal.datatypes.isScalarText(newNames)
        ME = MException(message("MATLAB:categorical:renamecats:InvalidNamesPattern"));
        ME = addCorrection(ME, matlab.lang.correction.ReplaceIdentifierCorrection("renamecats", "mergecats"));
        throw(ME);
    else
        rethrow(ME);
    end
end

if nargin < 3
    newNames = oldNames; % shift inputs
    if length(newNames) ~= length(a.categoryNames)
        error(message('MATLAB:categorical:renamecats:IncorrectNumNames'));
    end
    a.categoryNames = newNames;
else
    newNames = checkCategoryNames(newNames,2); % error if duplicates
    if length(newNames) ~= length(oldNames)
        error(message('MATLAB:categorical:renamecats:IncorrectNumNamesPartial'));
    end
    [tf,locs] = ismember(oldNames,a.categoryNames);
    if ~all(tf)
        error(message('MATLAB:categorical:renamecats:InvalidNames'));
    end
    notlocs = true(size(a.categoryNames)); notlocs(locs) = false;
    tf = ismember(newNames,a.categoryNames(notlocs));
    if any(tf)
        i = find(tf,1,'first');
        error(message('MATLAB:categorical:renamecats:DuplicateNames',oldNames{i},newNames{i}));
    end
    a.categoryNames(locs) = newNames;
end
