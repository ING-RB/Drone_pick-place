function w = cacheWhich(names, pth)
% cacheWhich caches results of WHICH for reuse (higher performance)
%
% Three valid signatures:
%
%   w = cacheWhich(name)
%       Look up name in the cache. If name isn't found, call WHICH and store
%       the result in the cache.
%
%   cacheWhich(name, pth)
%       Preload the cache, binding name to path.
%
%   cacheWhich()
%       Clear the cache (by creating a new, empty one).

%   Copyright 2012-2020 The MathWorks, Inc.

persistent whichCache

    if nargin == 1
        % Make sure name argument is cell array.
        vectorized = iscell(names);
        if ~vectorized, names = { names }; end

        w = whichCache.get(names);

        % If input was not vectorized, return scalar.
        if ~vectorized, w = w{1}; end
    elseif nargin == 2
        % Preload the cache. Make sure name and pth are cell arrays.
        if ~iscell(names), names = { names }; end
        if ~iscell(pth), pth = { pth }; end
        whichCache.preload(names, pth);
    elseif nargin == 0
        if isempty(whichCache) || nargout == 0
            % Clear cache.
            whichCache = matlab.depfun.internal.WhichCache;
        end
        if nargout == 1
            w = whichCache.size();
        end
    end
end

% LocalWords:  pth Preload
