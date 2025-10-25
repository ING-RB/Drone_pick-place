function [b,idx] = topkrows(a,k,vars,sortMode,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.

if nargin < 3
    vars = a.metaDim.labels(1);
end

if nargin < 4
    [b,idx] = topkrows@tabular(a,k,vars);
else
    [b,idx] = topkrows@tabular(a,k,vars,sortMode,varargin{:});
end
