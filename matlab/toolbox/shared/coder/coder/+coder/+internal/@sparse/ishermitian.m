function tf = ishermitian(this, skewOption)
%MATLAB Code Generation Private Method

%   Copyright 2024 The MathWorks, Inc.
%#codegen

narginchk(1,2);
if nargin == 2
    coder.internal.prefer_const(skewOption);
    coder.internal.assert(coder.internal.isConst(skewOption), ...
        'Coder:toolbox:InputMustBeConstant','skewOption');
    isSkew = strcmpi(skewOption,'skew');
    isNonSkew = strcmpi(skewOption,'nonskew');
    coder.internal.assert(isSkew || isNonSkew, ...
        'MATLAB:isHermitian:inputFlag');
else
    isSkew = false;
end
tf = ismatrix(this) && (this.m == this.n);

if ~tf
    return
end

tf = sparseHermitianSymmetricKernel(this, isSkew, false);
end