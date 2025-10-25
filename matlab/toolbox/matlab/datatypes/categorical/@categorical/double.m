function b = double(a)
%

%   Copyright 2006-2024 The MathWorks, Inc.

b = double(a.codes);
b(b == 0) = NaN; %categorical.undefCode
