function result = cat(dim, varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

try
    result = calendarDuration.catUtil(dim,false,varargin{:});
catch ME
    throw(ME);
end
