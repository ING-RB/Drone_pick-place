function d = diff(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

d = duration.fromMillis(datetimeDiff(a.data,varargin{:}));
