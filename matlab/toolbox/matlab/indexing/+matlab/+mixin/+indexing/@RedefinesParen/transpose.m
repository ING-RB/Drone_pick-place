%TRANSPOSE  transpose
%   The default implementation of this method issues an error. This 
%   behavior can be overridden for classes that support transpose.
%
%   See also ctranspose, reshape

%   Copyright 2020-2021 The MathWorks, Inc.

function B = transpose(obj) %#ok<STOUT>
    error(message("MATLAB:index:transposeNotSupported", class(obj)));
end
