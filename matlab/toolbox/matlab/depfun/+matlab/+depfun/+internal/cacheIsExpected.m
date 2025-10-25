function [e, w] = cacheIsExpected(varargin)
% cacheIsExpected caches results of ISEXPECTED for reuse (higher performance)
%
% ie = cacheIsExpected(file)
%
%   cacheIsExpected
%     Clear the cache (by creating a new, empty one).

%   Copyright 2012-2020 The MathWorks, Inc.

persistent isExpectedCache

if nargin == 0
    isExpectedCache = containers.Map('KeyType', 'char', ...
                                     'ValueType','any');
elseif nargin == 1
        isExpectedCache = [isExpectedCache; varargin{1}];
else
    Schema = varargin{1};
    Target = varargin{2};
    file = varargin{3};
    if ischar(file)
        file = {file};
    end
    
    num_files = numel(file);
    e = false(1,num_files);
    w(1:num_files) = struct('identifier', '', 'message', '', 'rule', '');
    
    hasKey = isKey(isExpectedCache, file);
    cachedIdx = find(hasKey);
    cached = file(hasKey);
    unknownIdx = find(~hasKey);
    unknown = file(unknownIdx);
    
    if ~isempty(cached)
        cachedVals = cell2mat(values(isExpectedCache, cached));
        e(cachedIdx) = [cachedVals.expeto];
        w(cachedIdx) = [cachedVals.why];
    end
    
    if ~isempty(unknown)
        [ue, uw] = isExpected(Schema, Target, unknown);
        
        if ~isempty(uw)
            e(unknownIdx(ue)) = true;
            w(unknownIdx(ue)) = uw(ue);
        end
        
        ce = num2cell(e(unknownIdx));
        cw = num2cell(w(unknownIdx));
        ie(numel(unknown)) = struct;
        [ie.expeto] = ce{:};
        [ie.why] = cw{:};

        for k = 1:numel(unknown)
            isExpectedCache(unknown{k}) = ie(k);
        end
    end
end

% LocalWords:  ISEXPECTED
