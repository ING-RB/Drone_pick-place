function tf = issortedrows(a,vars,sortMode,varargin) %#codegen
%ISSORTEDROWS TRUE for a sorted timetable.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(vars,sortMode,varargin);

if nargin < 2
    vars = a.metaDim.labels{1};
end

if nargin < 3
    tf = issortedrows@matlab.internal.coder.tabular(a,vars);
else
    tf = issortedrows@matlab.internal.coder.tabular(a,vars,sortMode,varargin{:});
end
