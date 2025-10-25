function b = lengthenVar(a,n)
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

% Add new rows without touching any vars.

% This is called by matlab.internal.datatypes.lengthenVar. If that function
% becomes a public function on the path, then this method would be
% unhidden, and calling lengthenVar(myTabular) will dispatch to this method
% directly.

%   Copyright 2022 The MathWorks, Inc.
b = a;
if n <= height(a)
    return
end

b.rowDim = b.rowDim.lengthenTo(n);

% Lengthen each var in b with its default contents.
for j = 1:b.varDim.length
    b.data{j} = matlab.internal.datatypes.lengthenVar(b.data{j},n);
end
