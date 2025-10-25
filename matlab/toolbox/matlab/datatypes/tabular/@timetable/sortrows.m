function [b,idx] = sortrows(a,vars,sortMode,varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

if nargin < 2
    vars = a.metaDim.labels(1);
end

if nargin < 3
    [b,idx] = sortrows@tabular(a,vars);
else
    [b,idx] = sortrows@tabular(a,vars,sortMode,varargin{:});
end
