%RESHAPE  Reshape object
%   The default implementation of this method issues an error. This 
%   behavior can be overridden for classes that support reshape.
%
%   See also ctranspose, transpose

%   Copyright 2020-2021 The MathWorks, Inc.

function B = reshape(obj, varargin) %#ok<STOUT>
    error(message("MATLAB:index:reshapeNotSupported", class(obj)));
end
