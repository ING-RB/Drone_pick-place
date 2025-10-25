function disableFilesystemWatching()
% disableFilesystemWatching Disables filesystem watching for metadata changes for resources folders
%
%   matlab.internal.regfwk.disableFilesystemWatching() 
%   Disables the filesystem watcher service preventing automatic notifications for metadata file updates.
%
%
%   See also: matlab.internal.regfwk.updateResources

% Copyright 2023 The MathWorks, Inc.
% Calls a Built-in function.
matlab.internal.regfwk.disableFilesystemWatchingImpl();