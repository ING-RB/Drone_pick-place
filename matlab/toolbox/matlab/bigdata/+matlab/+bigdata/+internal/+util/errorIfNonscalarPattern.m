function errorIfNonscalarPattern(datatype, varargin)
% Errors if any of the input arguments is a non-scalar pattern object.

%   Copyright 2023 The MathWorks, Inc.

nonscalarPattern = cellfun(@(x) isa(x, 'pattern') && ~isscalar(x), varargin);

if any(nonscalarPattern)
    throwAsCaller(MException(message("MATLAB:bigdata:array:PatternMustBeScalar", datatype)));
end
