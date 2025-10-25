function b = single(a)
%

%   Copyright 2006-2024 The MathWorks, Inc.

b = single(a.codes);
b(b == 0) = NaN;  % categorical.undefCode
