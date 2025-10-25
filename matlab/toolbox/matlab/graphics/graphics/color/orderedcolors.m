function out = orderedcolors(name)
%

%   Copyright 2022 The MathWorks, Inc.

try
   out = matlab.graphics.internal.colorOrderValues(name);
catch e
   throw(e);
end
end