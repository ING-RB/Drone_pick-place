function completions = generatePathCompletion(ftpobj, path, completeFolders, completeFiles, timeout)
%matlab.io.internal.ftp.completion    Return a list of completions for the input path.

% Copyright 2020 The MathWorks, Inc.

    arguments
        ftpobj          (1, 1) matlab.io.FTP;
        path            (1, 1) string = ftpobj.RemoteWorkingDirectory;
        completeFolders (1, 1) logical = true; % Complete folder names by default.
        completeFiles   (1, 1) logical = true; % Complete file names by default.
        timeout         (1, 1) double = 10000;  % Timeout for the dir listing, 10 seconds by default.
    end

    % If the path doesn't contain a slash, the user is requesting a completion for the
    % current working folder.
    %
    %     tm<TAB -> tmp/ (completed from dir(ftpobj, ""))
    %
    % But if the path contains a slash, then the user is requesting a completion for the
    % parent of the absolute/relative folder they have typed so far:
    %
    %     tmp/tmpDi<TAB -> tmp/tmpDir (completed from dir(ftpobj, "tmp/") listing)
    %     /mathworks/h<TAB -> /mathworks/home (completed from dir(ftpobj, "/mathworks/") listing)
    %
    % Therefore branch based on whether the path contains slashes or not. Get the parent
    % folders listing if the input path contains a slash.
    if contains(path, "/")
        % Add a trailing slash to make sure that this is treated as a folder name by dir.
        path = addTrailingSlash(fileparts(path));
    else
        % Just perform dir on the CWD.
        path = "";
    end
    % Set the timeout for this dir request.
    ftpobj.setTimeout(timeout);
    c = onCleanup(@() ftpobj.setTimeout(0)); % Clean up by setting the timeout back to inf.
    listing = dir(ftpobj, path);

    if isempty(listing)
        % No matches, return early.
        listing = [];
        return;
    end
    listing = struct2table(listing, "AsArray", true);
    completions = string(listing.name);

    % Only do the isdir logic if we have all the file/folder info from dir.
    if islogical(listing.isdir)
        completions = filterCompletions(completions, listing.isdir, completeFolders, completeFiles);
    end

    % Convert to a path relative to the input path.
    completions = makeRelativePath(path, completions);
end

function str = addTrailingSlash(str)
    hasTrailingSlash = endsWith(str, "/");
    str(~hasTrailingSlash) = str(~hasTrailingSlash) + "/";
end

function listing = makeRelativePath(path, listing)
    folder = fileparts(path);
    if strlength(folder) == 0
        % Relative to the current folder, no need to prepend path.
        return;
    else
        listing = addTrailingSlash(folder) + listing;
    end
end

function completions = filterCompletions(completions, isdir, completeFolders, completeFiles)
    % Add trailing slash to folder names, to distinguish between files and folders
    % in the tab-completion display.
    completions(isdir) = addTrailingSlash(completions(isdir));

    % Remove all folder names if not requested. Used by rename and delete's completion.
    if ~completeFolders
        completions(isdir, :) = [];
    end

    % Remove all file names if not requested. Used by cd and rmdir's completion.
    if ~completeFiles
        completions(~isdir, :) = [];
    end
end
