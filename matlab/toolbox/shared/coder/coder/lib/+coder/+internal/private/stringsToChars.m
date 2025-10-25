function y = stringsToChars(x)
%MATLAB Code Generation Private Function
%
%   Casts strings to char in a constant cell array X.
%   Does not trim entries.

%   Copyright 2021 The MathWorks, Inc.
%#codegen

coder.internal.prefer_const(x);
nx = coder.internal.indexInt(numel(x));
y = cell(1,nx);
coder.unroll;
for k = 1:nx
    if isstring(x{k})
        y{k} = char(x{k});
    else
        y{k} = x{k};
    end
end
