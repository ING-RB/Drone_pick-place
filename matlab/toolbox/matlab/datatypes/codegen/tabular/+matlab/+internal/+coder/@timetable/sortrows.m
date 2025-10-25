function [b,idx] = sortrows(a,vars,sortMode,varargin) %#codegen
%SORTROWS Sort rows of a timetable.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(vars,sortMode,varargin);

if nargin < 2
    vars = a.metaDim.labels{1};
end

if nargin < 3
    [b,idx] = sortrows@matlab.internal.coder.tabular(a,vars);
else
    [b,idx] = sortrows@matlab.internal.coder.tabular(a,vars,sortMode,varargin{:});
end
