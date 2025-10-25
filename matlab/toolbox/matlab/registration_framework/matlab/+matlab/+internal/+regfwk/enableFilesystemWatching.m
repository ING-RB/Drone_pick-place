function enableFilesystemWatching()
% enableFilesystemWatching Enables filesystem watching for metadata changes for resources folders
%   matlab.internal.regfwk.enableFilesystemWatching() 
%   Enables the filesystem watcher service to be setup to track for metadata folder changes and trigger automatic notifications to reflect these changes.
%
%
%   See also: matlab.internal.regfwk.updateResources

% Copyright 2023 The MathWorks, Inc.
% Calls a Built-in function.
matlab.internal.regfwk.enableFilesystemWatchingImpl();