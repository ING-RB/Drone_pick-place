function fmt = verifyInputFormat(fmt)
%VERIFYINPUTFORMAT Validate duration input format.

%   Copyright 2017-2020 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText

if isScalarText(fmt,false)
    t = split(fmt,'.');
    if ~matches(t(1),["dd:hh:mm:ss" "hh:mm:ss" "mm:ss" "hh:mm"]) ...
       || (~isscalar(t) && ~(all(t{2}=='S') && strlength(t(2)) < 10)) % Optional fractional seconds up to 9S's
       throwAsCaller(MException(message('MATLAB:duration:UnrecognizedInputFormat',fmt)));
    end
else
   throwAsCaller(MException(message('MATLAB:duration:InvalidInputFormat')));
end

fmt = char(fmt);

