function t2 = defaultarrayLike(sz,~,t,ascellstr)
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% This is called by matlab.internal.datatypes.defaultarrayLike. If that
% function becomes a public function on the path, then this method would
% be unhidden, and calling defaultarrayLike(myTabular) will dispatch to
% this method directly.

%DEFAULTARRAYLIKE Create a tabular like t containing null values
%   T2 = DEFAULTARRAYLIKE(SZ,'Like',T,ASCELLSTR) returns a tabular the same
%   class as T, with the specified height and the same number/type variables,
%   containing default values (per matlab.internal.datatypes.defaultarrayLike.
%   The second element of SZ is ignored.
%      table                  Row names (when present) copied, and padded with
%                             default as needed. All other properties copied.
%      timetable              Row times copied and padded with NaT as needed.
%                             All other properties copied.

%   Copyright 2022 The MathWorks, Inc.

if nargin < 4, ascellstr = true; end

t_height = t.rowDim.length;

t2 = t; % table->table, timetable->timetable
n = sz(1);

% Resize to the specified height.
if n < t_height
    t2.rowDim = t2.rowDim.shortenTo(n);
elseif n > t_height
    t2.rowDim = t2.rowDim.lengthenTo(n);
end

% Replace each var with a new one containing default values.
for j = 1:t2.varDim.length
    x = t2.data{j};
    szOut = size(x); szOut(1) = n;
    t2.data{j} = matlab.internal.datatypes.defaultarrayLike(szOut,'like',x,ascellstr);
end
