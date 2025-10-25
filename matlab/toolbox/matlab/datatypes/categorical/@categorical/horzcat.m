function a = horzcat(varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

try
    a = categorical.catUtil(2,true,varargin{:});
catch ME
    throw(ME);
end
