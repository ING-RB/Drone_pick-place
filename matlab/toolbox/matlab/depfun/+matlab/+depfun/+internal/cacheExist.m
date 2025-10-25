function ex = cacheExist(varargin)
% cacheExist caches results of EXIST for reuse (higher performance)
% Since the answer may vary depending on the input TYPE, cache both the
% type and value. Recompute the answer every time the type changes.
%
% Name may be a cell array of names, in which case simply iterate over the
% cell array.
%
% ex = cacheExist(name, [type])
%
%   cacheExist()
%     Clear the cache (by creating a new, empty one).
%
% Cache a structure with fields 'type' and 'value'.

%   Copyright 2012-2020 The MathWorks, Inc.

persistent existCache

if nargin == 2
    name = varargin{1};
    type = varargin{2};
    % Make sure name input is cell array.
    if ~iscell(name), name = { name }; end
    ex = existCache.get(name, type);
elseif nargin == 3
    name = varargin{1};
    type = varargin{2};
    value = varargin{3};
    if ~iscell(name), name = { name }; end
    if ~iscell(type), type = {type }; end
    if ~iscell(value), value = { value }; end
     
    if numel(type) ~= numel(name)
        newType = cell(1, numel(name));
        newType(:) = {type{1}};
        type = newType;
    end

    existCache.preload(name, type, value);
elseif nargin == 0
    % Clear cache.
    existCache = matlab.depfun.internal.ExistCache;
end
