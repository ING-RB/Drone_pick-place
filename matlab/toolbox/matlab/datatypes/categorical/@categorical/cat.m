function a = cat(dim,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

try
    a = categorical.catUtil(dim,false,varargin{:});
catch ME
    throw(ME);
end
