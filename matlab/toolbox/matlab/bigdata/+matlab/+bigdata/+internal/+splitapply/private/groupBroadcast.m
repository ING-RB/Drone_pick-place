function [groupKeys, varargout] = groupBroadcast(groupKeys, varargin)
%groupBroadcast Broadcast one or more variables that share the same set of group keys.
%
%
% Syntax:
%  [groupBroadcastX,groupBroadcastY,..] = flattenGroupedBroadcasts(groupKeys,groupedX,groupedY,..)
%
% Where:
%  - groupKeys is a column vector of group keys.
%  - Each of groupedX,groupedY,.. is a set of values, each row
%    corresponding to the group matching the same row of groupKeys.
%
% This exists to allow singleton expansion of results containing one slice
% per group. For example, the mean in splitapply(@(x) {x - mean(x)},tX,tG)
% will generate a grouped broadcast.

% Copyright 2017 The MathWorks, Inc.

import matlab.bigdata.internal.splitapply.GroupedBroadcast;

if isa(groupKeys, 'matlab.bigdata.internal.splitapply.GroupedBroadcast')
    varargout = varargin;
    return;
end
[groupKeys, varargin{:}] = canonicalizeGroups(groupKeys, varargin{:});

varargout = cell(size(varargin));
for ii = 1:numel(varargout)
    varargout{ii} = GroupedBroadcast(groupKeys, varargin{ii});
end
groupKeys = GroupedBroadcast(groupKeys, num2cell(groupKeys));