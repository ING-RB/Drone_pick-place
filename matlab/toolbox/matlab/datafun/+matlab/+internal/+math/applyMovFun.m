function M = applyMovFun(functionName,functionHandle,hasBiasOption,omitNaNByDefault,A,k,varargin)
% applyMovFun Apply moving statistics function to data
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2024-2025 The MathWorks, Inc.

[k,dim,omitnan,endpoints,fillValue,samplePoints,dvars,replace,bias] = matlab.internal.math.parseMovOptions(A,k,hasBiasOption,omitNaNByDefault,varargin{:});
if istabular(A)
    if replace
        M = A;
        dvarsM = dvars;
    else
        M = A(:,dvars);
        dvarsM = 1:numel(dvars);
    end

    for ii = 1:numel(dvarsM)
        M.(dvarsM(ii)) = functionHandle(M.(dvarsM(ii)),k,dim,omitnan,bias,endpoints,fillValue,samplePoints{:});
    end

    if ~replace
        M = matlab.internal.math.appendDataVariables(A,M,functionName);
    end
else
    M = functionHandle(A,k,dim,omitnan,bias,endpoints,fillValue,samplePoints{:});
end
end