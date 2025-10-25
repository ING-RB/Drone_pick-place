function parfevalError(aPool, method)
%

%   Copyright 2019-2024 The MathWorks, Inc.

if ~isscalar(aPool) || ~isa(aPool, 'parallel.Pool')
    throwAsCaller(MException(message(...
        'MATLAB:parallel:pool:ScalarPoolRequired', method)));
elseif ~isvalid(aPool)
    throwAsCaller(MException(message('MATLAB:class:InvalidHandle')));
else
    try
        aPool.unsupportedFeatureError();
    catch err
        throwAsCaller(err);
    end
end
end
