function t = setDescription(t,newDescr)
%

%SETDESCRIPTION Set table Description property.

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText

newDescr = convertStringsToChars(newDescr);
if ~isScalarText(newDescr)
    error(message('MATLAB:table:InvalidDescription'));
elseif isempty(newDescr)
    t.arrayProps.Description = '';
else
    t.arrayProps.Description = newDescr;
end
