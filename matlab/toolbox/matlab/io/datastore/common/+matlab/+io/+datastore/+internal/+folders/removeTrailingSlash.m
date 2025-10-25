function folders = removeTrailingSlash(folders)
%   Removes the trailing slash from any input folder names. This
%   function expects a list of fully resolved folder names as input.

%   Copyright 2019 The MathWorks, Inc.

% Account for the possibility of empty inputs.
    if isempty(folders)
        return;
    end

    % Use a platform-specific path separator for local paths.
    localSeparator = filesep;
    remoteSeparator = '/'; % Always use '/' for remote paths.

    % Understand which paths are local and which are remote.
    isRemotePath = matlab.io.internal.vfs.validators.isIRI(folders);

    % Find all local and remote paths to be sliced.
    endsWithRemoteSeparator = endsWith(folders, remoteSeparator) & isRemotePath;
    endsWithLocalSeparator = endsWith(folders, localSeparator) & ~isRemotePath;
    endsWithSeparator = endsWithRemoteSeparator | endsWithLocalSeparator;

    % Avoid removing the last character from root folders on POSIX-compatible systems.
    isRootPOSIXFolder = ismember(folders, ["/", "hdfs:/", "hdfs:///"]);

    % Remove the last character from paths that need slicing.
    pathsToBeSliced = endsWithSeparator & ~isRootPOSIXFolder;
    for index = 1:numel(folders)
        if pathsToBeSliced(index)
            folders{index} = folders{index}(1:end-1);
        end
    end
end
