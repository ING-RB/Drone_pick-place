function x = str2num(s)
%

%   Copyright 1984-2023 The MathWorks, Inc.

x = str2num(fromOpaque(s));

function z = fromOpaque(x)
z=x;

if isjava(z)
  z = char(z);
end

if isa(z,'opaque')
 error(message('MATLAB:str2num:CannotConvertClass', class( x )));
end
