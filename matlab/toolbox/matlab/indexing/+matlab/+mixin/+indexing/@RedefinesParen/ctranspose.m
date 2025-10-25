%CTRANSPOSE  Conjugate transpose
%   The default implementation of this method issues an error. This 
%   behavior can be overridden for classes that support conjugate
%   transpose.
%
%   See also transpose, reshape

%   Copyright 2020-2021 The MathWorks, Inc.

function B = ctranspose(obj) %#ok<STOUT>
    error(message("MATLAB:index:ctransposeNotSupported", class(obj)));
end
