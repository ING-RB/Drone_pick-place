function [lower, upper] = bandwidth(this, flag)
%MATLAB Code Generation Private Method

%   Copyright 2024 The MathWorks, Inc.
%#codegen
coder.inline('always')
narginchk(1,2);
coder.internal.assert(ismatrix(this),'MATLAB:bandwidth:inputMustBe2D');
coder.internal.assert(isfloat(this) || islogical(this), ...
    'MATLAB:bandwidth:inputType');

if nargin == 1
    upperFlag = false;
    lowerFlag = nargout <= 1;
else
    coder.internal.prefer_const(flag);
    coder.internal.assert(nargout <= 1,'MATLAB:maxlhs');
    coder.internal.assert(coder.internal.isConst(flag), ...
        'Coder:toolbox:InputMustBeConstant','type');
    upperFlag = strcmpi(flag,'upper');
    lowerFlag = strcmpi(flag,'lower');
    coder.internal.assert(upperFlag || lowerFlag, ...
        'MATLAB:bandwidth:unknownArgument');
end

[lw, uw] = sparseBandwidth(this);

if upperFlag
    lower = double(uw);
else
    lower = double(lw);
    if ~lowerFlag
        upper = double(uw);
    end
end
end