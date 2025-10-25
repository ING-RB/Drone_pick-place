function dim = constNonSingletonDim(x)
%MATLAB Code Generation Private Function

%   Finds the first non-singleton or variable dimension of x. Returns 2
%   (ndims(x)) for scalars to match MATLAB in certain cases (e.g., HISTC,
%   FFT, IFFT). The result will be a constant. In most cases a call to this
%   function should be followed by an coder.internal.assert to generate an
%   error message if a variable length dimension takes on the length of 1,
%   since in that case MATLAB will select another dimension (unless the x
%   is scalar).

%   Copyright 2002-2019 The MathWorks, Inc.
%#codegen

if isempty(coder.target)
    if isscalar(x)
        dim = 2;
    else
        dim = find(size(x)~=1,1,'first');
    end
    return
end
coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
if issparse(x)
    if ~coder.internal.isConst(size(x,1)) || size(x,1) ~= 1
        dim = coder.internal.indexInt(1);
    else
        dim = coder.internal.indexInt(2);
    end
else
    dim = coder.const(local_const_nonsingleton_dim(x));
end

%--------------------------------------------------------------------------

function dim = local_const_nonsingleton_dim(x)
coder.internal.allowEnumInputs;
dim = 2;
for k = coder.unroll(1:coder.internal.ndims(x))
    if ~coder.internal.isConst(size(x,k)) || size(x,k) ~= 1
        dim = k;
        return
    end
end

%--------------------------------------------------------------------------
