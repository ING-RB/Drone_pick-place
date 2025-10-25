function rehashCache()
%   matlab.internal.regfwk.rehashCache() 
%   Calls "updateResources" on all cached metadata folders, to perform cache invalidation manually when required and reflect metadata changes immediately.
%
%
%   See also: matlab.internal.regfwk.updateResources

% Copyright 2023 The MathWorks, Inc.
% Calls a Built-in function.
matlab.internal.regfwk.rehashCacheImpl();