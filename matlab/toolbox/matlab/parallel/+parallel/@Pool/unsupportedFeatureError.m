function unsupportedFeatureError(~)
%

%   Copyright 2020 The MathWorks, Inc.

throwAsCaller(MException("parallel:lang:pool:UnsupportedFeature", ...
    message("MATLAB:parallel:pool:UnsupportedFeature")));

end
