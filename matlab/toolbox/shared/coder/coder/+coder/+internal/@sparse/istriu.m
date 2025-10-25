function tf = istriu(this)
%MATLAB Code Generation Private Method

%   Copyright 2024 The MathWorks, Inc.
%#codegen
coder.inline('always')
narginchk(1,2);
coder.internal.assert(ismatrix(this),'MATLAB:bandwidth:inputMustBe2D');
coder.internal.assert(isfloat(this) || islogical(this), ...
    'MATLAB:bandwidth:inputType');

lw = sparseBandwidth(this);

tf = (lw == ZERO);
end