function assertCompatibleDims(x, y)
%MATLAB Code Generation Private Function
%
%   Asserts that the sizes of x and y are compatible
%   whether implicit expansion is enabled or disabled.

%   Copyright 2021 The MathWorks, Inc.
%#codegen
coder.internal.implicitExpansionBuiltin; % always inherit setting from caller
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
if coder.internal.isImplicitExpansionSupported
    coder.internal.assert(coder.internal.isImplicitExpansionCompatible(x, y), 'MATLAB:sizeDimensionsMustMatch');
else
    coder.internal.assert(coder.internal.scalexpCompatible(x, y), 'MATLAB:dimagree');
end