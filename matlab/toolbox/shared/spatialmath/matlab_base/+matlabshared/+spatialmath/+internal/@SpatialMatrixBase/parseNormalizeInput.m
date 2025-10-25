function method = parseNormalizeInput(varargin)
%This method is for internal use only. It may be removed in the future.

%parseNormalizeInput Parses the input to the normalize function
%   METHOD = parseNormalizeInput(VARARGIN) parses the arguments provided to
%   normalize, VARARGIN, and returns the chosen normalization method in
%   METHOD. METHOD is a string in ["quaternion", "svd", "cross"]

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Default method is 'quaternion'
    methodChar = 'quaternion';

    if nargin > 0
        % Parse name-value pairs (if they are specified)
        parser = robotics.core.internal.NameValueParser({'Method'}, {methodChar});
        parse(parser, varargin{:});
        methodChar = parameterValue(parser, 'Method');
        method = string(validatestring(methodChar, ...
                                       matlabshared.spatialmath.internal.SpatialMatrixBase.ValidNormalizationMethods, ...
                                       "normalize", "Method"));
    else
        method = string(methodChar);
    end
end
