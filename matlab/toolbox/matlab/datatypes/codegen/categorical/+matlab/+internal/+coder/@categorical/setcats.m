function b = setcats(a,rawnames) %#codegen
%SETCATS Set the categories of a categorical array.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.errorIf(nargout == 0,'MATLAB:categorical:NoLHS','SETCATS',',NEWCATEGORIES');

names = categorical.checkCategoryNames(rawnames,true);

bCodes = categorical.convertCodes(a.codes,a.categoryNames,names);
bCodes(bCodes > length(names)) = 0; % categorical.undefCode

b = categorical(matlab.internal.coder.datatypes.uninitialized);
b.isOrdinal = a.isOrdinal;
b.isProtected = a.isProtected;
b.codes = bCodes;
b.categoryNames = names;
end

