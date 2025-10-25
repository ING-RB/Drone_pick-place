function t = cacheMtree(varargin)
% cacheMtree Cache results of MTREE for reuse (higher performance)
%
% t = cacheMtree(file)
%    Return an MTREE for file. Create one and store it in the cache if
%    one is not available.
% t = cacheMtree(file, mtree)
%     Preload mtree cache
%
%   cacheMtree()
%     Clear the cache (by creating a new, empty one).

%   Copyright 2012-2020 The MathWorks, Inc.

persistent mtreeCache

t = [];
if nargin == 0
    mtreeCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
else
    % If input is file name, construct mtree and return the constructed
    % tree
    if ischar(varargin{1})
        file = varargin{1};
        if isKey(mtreeCache, file)
            t = mtreeCache(file);
        else
            if ~matlab.depfun.internal.cacheExist(file, 'file')
                error(message('MATLAB:depfun:req:NameNotFound', file))
            end

            t = mtree(file, '-file', '-com');

            % G886633: Stop the analysis when there are syntax errors in M-code
            mterr = mtfind(t, 'Kind', 'ERR');
            if ~isempty(mterr)
                error(message('MATLAB:depfun:req:BadSyntax', file, string(mterr)))
            end

            mtreeCache(file) = t;
        end
    else
        mtreeCache = [mtreeCache; varargin{1}];
    end
end

% LocalWords:  Preload
