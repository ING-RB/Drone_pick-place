function t = setDescription(t,newDescr)  %#codegen
%SETDESCRIPTION Set table Description property.

%   Copyright 2019 The MathWorks, Inc.

%newDescr = convertStringsToChars(newDescr);
coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(newDescr),...
    'MATLAB:table:InvalidDescription');
if isempty(newDescr)
    t.arrayProps.Description = char(zeros(1,0));
else
    t.arrayProps.Description = newDescr;
end
