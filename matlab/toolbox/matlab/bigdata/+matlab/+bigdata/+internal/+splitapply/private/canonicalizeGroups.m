function [groupKeys, varargout] = canonicalizeGroups(groupKeys, varargin)
%canonicalizeGroups Ensure that a set of groups are stored with group keys
% in unique and sorted order. This will merge group content as required.
%
% Syntax:
%  [groupKeys,groupedX,groupedY,..] = canonicalizeGroups(groupKeys,groupedX,groupedY,..)
%
% Where:
%  - groupKeys is a column vector of group keys. After canonicalization,
%    this will be unique and sorted.
%  - Each of groupedX,groupedY,.. is a set of grouped content. Each is
%    either a cell array of grouped data, one cell per group key, or a
%    numeric count of number of slices in each group. After
%    canonicalization, each will match the new group keys.

% Copyright 2017 The MathWorks, Inc.

[groupKeys, ~, keyIndices] = unique(groupKeys);
if numel(keyIndices) == numel(groupKeys) && issorted(keyIndices)
    % No further work required as group keys were already in canonical
    % form, i.e. unique and sorted.
    varargout = varargin;
    return;
end

varargout = cell(size(varargin));
for ii = 1:numel(varargin)
    if isnumeric(varargin{ii})
        % Numeric arrays are group counts, which must be accumulated.
        varargout{ii} = splitapply(@sum, varargin{ii}, keyIndices);
    elseif iscell(varargin{ii})
        % Cell arrays are actual chunks of data, here we only merge said
        % chunks of data that correspond to the same group.
        varargout{ii} = splitapply(@iMergeCells, varargin{ii}, keyIndices);
    else
        % Everything else is assumed to be a broadcasted array.
        varargout{ii} = varargin{ii};
    end
end
end

function x = iMergeCells(x)
% Merge a vector of cells together, emitting a single cell containing all
% of the data.
import matlab.bigdata.internal.util.vertcatCellContents;
x = {vertcatCellContents(x)};
end
