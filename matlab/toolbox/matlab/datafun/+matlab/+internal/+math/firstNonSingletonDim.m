function dim = firstNonSingletonDim(x)
%firstNonSingletonDim Return the index of the first non-singleton
%dimension. 
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
% Given an input Array x, returns the index of the first non-singleton
% dimension of the array.  If x is a scalar returns the the second index in
% accordance with functions that apply padding such as fft.

%   Copyright 2022 The MathWorks, Inc.

    dim = 2;
    
    if ~isscalar(x)
        for k = 1:ndims(x)
            s = size(x,k);
            if s ~= 1
                dim = k;
                break
            end
        end
    end
end


