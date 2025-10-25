function a = setcats(a,names)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEWCATEGORIES'));
end

names = checkCategoryNames(names,true);

a.codes = convertCodes(a.codes,a.categoryNames,names);
a.codes(a.codes > length(names)) = 0; % categorical.undefCode
a.categoryNames = names;
end

