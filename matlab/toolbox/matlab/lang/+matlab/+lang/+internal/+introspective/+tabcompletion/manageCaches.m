function result = manageCaches(cacheName, actionToPerform)
%MANAGECACHES - Manipulate the backend tab completion caches.
%
%   result = manageCaches(cacheName, actionToPerform)
%
%   cacheName: The name of the cache to manipulate. Valid cache names are:
%       "all", "purposeLine", "path", "functionRegistry"
% 
%   actionToPerform: The text action to perform on each cache. Valid actions:
%       "startup": Restore a cache to its expected state at MATLAB startup
%       "clear": Clear a cache
%       "populate": Populate a cache (when possible)
%                   
%   Example Inputs:
%       manageCaches all startup
%       manageCaches purposeLine clear
%       manageCaches path populate
%
%   result: Nonzero for success, zero for failure or no action taken

%   Copyright 2018-2020 The MathWorks, Inc. 

arguments
    cacheName string {mustBeMember(cacheName, ["all", "purposeLine", "path", "functionRegistry"])}
    actionToPerform string {mustBeMember(actionToPerform, ["clear", "populate", "startup"])}
end

result = builtin('_manageTabCompletionCaches', char(upper(cacheName)), char(upper(actionToPerform)));
end
