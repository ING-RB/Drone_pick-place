function tf = issortedrows(a,vars,sortMode,varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

if nargin < 2
    vars = a.metaDim.labels(1);
end

if nargin < 3
    tf = issortedrows@tabular(a,vars);
else
    tf = issortedrows@tabular(a,vars,sortMode,varargin{:});
end
