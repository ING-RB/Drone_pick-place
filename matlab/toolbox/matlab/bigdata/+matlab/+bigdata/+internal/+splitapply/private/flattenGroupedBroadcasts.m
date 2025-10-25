function varargout = flattenGroupedBroadcasts(groupKeys, varargin)
%flattenGroupedBroadcasts Flatten one or more grouped broadcasts into the underlying data.
%
% Syntax:
%  [groupedX,groupedY,..] = flattenGroupedBroadcasts(groupKeys,groupBroadcastX,groupBroadcastY,..)
%
% Where:
%  - groupKeys is the column vector of group keys to align the output against.
%  - Each of groupBroadcast is a GroupBroadcast object.
%
% The output groupedX,groupedY,.. will correspond to the provided
% groupKeys. Each will be a cell column vector, with one cell per group,
% matching the groupKeys from the input.
%
% The reason this exists is because individual chunks might only care about
% some of the groups, whereas group broadcasts are required to know about
% all groups.

% Copyright 2017 The MathWorks, Inc.

varargout = cell(size(varargin));
for idx = 1:numel(varargin)
    [existsInBroadcast, keyIndices] = ismember(groupKeys, varargin{idx}.Keys);
    assert(all(existsInBroadcast), ...
        'Assertion failed: Received GroupedBroadcast is not complete.');
    varargout{idx} = varargin{idx}.Values(keyIndices);
end
