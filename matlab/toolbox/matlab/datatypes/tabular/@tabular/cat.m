function t = cat(dim,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

if ~matlab.internal.datatypes.isScalarInt(dim,1,2)
    error(message('MATLAB:table:cat:InvalidDim'));
end

if dim == 1
    t = vertcat(varargin{:});
else
    t = horzcat(varargin{:});
end
