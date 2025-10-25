function dim = nonSingletonDim(x)
%MATLAB Code Generation Private Function

%   Finds the first non-singleton dimension of x. Returns 2 (ndims(x)) for
%   scalars to match MATLAB in certain cases (e.g., HISTC, FFT, IFFT).
%
%   Note that coder.internal.nonSingletonDim(x) will not be a constant for
%   variable-length column vectors because DIM = 2 when length(X) == 1, but
%   DIM = 1, otherwise. Use coder.internal.preferConstNonSingletonDim(x)
%   when it would be appropriate to return DIM = 1 regardless of the length
%   of a variable-length column vector.

%   Copyright 2002-2019 The MathWorks, Inc.
%#codegen

coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
ONE = coder.internal.indexInt(1);
dim = coder.internal.indexInt(2);
if coder.internal.isConst(isrow(x)) && isrow(x)
    % DIM = 2 is correct and should be a constant output.
else
    for k = coder.unroll(ONE:coder.internal.ndims(x))
        if size(x,k) ~= 1
            dim = k;
            return
        end
    end
end