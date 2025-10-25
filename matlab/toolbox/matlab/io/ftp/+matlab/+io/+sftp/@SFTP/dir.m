function varargout = dir(obj, input, options)
%DIR List directory on an SFTP server.
%   DIR(SFTP, DIRECTORY) lists the files in a directory. Pathnames and
%   wildcards may be used.
%
%   D = DIR(...) returns the results in an M-by-1
%   structure with the fields:
%       name    -- filename
%       date    -- modification date, datetime or datestr dependent on
%                  value of DatetimeType
%       bytes   -- number of bytes allocated to the file
%       isdir   -- 1 if name is a directory and 0 if not
%       datenum -- MATLAB serial date number
%
%   Name-Value Pairs:
%   -----------------------------------------------------------------------
%   "ParseOutput"       - When set to true returns a struct, otherwise
%                         returns a string with the raw output from the
%                         SFTP server.
%
%   Because SFTP servers do not return directory information in a standard
%   way, the last four fields in the structure may be empty or some items
%   may be missing.

% Copyright 2020-2021 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.sftp.SFTP
        input (1,1) string {mustBeNonmissing, mustBeNonempty} = ""
        options.ParseOutput (1,1) logical = true;
    end

    if nargout >= 1
        % get full struct listing when output struct is asked
        namesOnly = false;
    else
        namesOnly = true;
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    if contains(input, "*")
        % special branch for parsing input that contains wildcards
        [listing, folderOrFile, folderName, names] = parseWildcardInput(obj, ...
            input, namesOnly);
        if isempty(listing)
            nonExistentEntry = true;
        else
            nonExistentEntry = false;
        end
        isInputFile = false;
    else
        % non-wildcard branch
        % folderOrFile -- 0 means folder, 1 means file, -1 means not found
        [listing, folderOrFile, folderName, isInputFile, nonExistentEntry, ...
            names] = parseInput(obj, input, namesOnly);
    end

    if nonExistentEntry || (isempty(listing) && ~folderOrFile)
        % neither a file nor a folder, or an empty folder
        if nargout >= 1
            varargout{1} = [];
        else
            disp(' ');
            disp(' ');
        end
    end

    if ~isempty(listing) || isInputFile
        switch nargout
            case 0
                case0Parse(obj, options, namesOnly, listing);
            case {1, 2}
                if options.ParseOutput == true
                    % return struct as output
                    folderArray = repmat(string(folderName), numel(names), 1);
                else
                    % return string as output
                    folderArray = [];
                end
                listing = case12Parse(obj, options, namesOnly, folderArray, ...
                    listing, names);
                varargout{1} = listing;
        end
    end
    if nargout == 2
        varargout{2} = folderOrFile;
    end
end

function listing = case12Parse(obj, options, namesOnly, folderArray, listing, names)
    import matlab.io.ftp.parseDirListingForUnix
    import matlab.io.ftp.parseDirListingForWindows

    % get the full struct
    if options.ParseOutput == true
        % branch on whether a custom parsing function was supplied
        if obj.DirParserFcnSupplied == true
            listing = splitlines(listing);
            if isempty(listing{end})
                listing = listing(1:end-1);
            end
            listing = string(listing);
            listing = obj.DirParserFcn(listing, obj.ServerLocale, obj.DatetimeType);
        else
            % branch code based on whether remote OS is unix or
            % Windows
            if obj.ServerSystem == "unix"
                listing = parseDirListingForUnix(listing, 1, namesOnly, ...
                    obj.ServerSystem, obj.ServerLocale, obj.DatetimeType);
            elseif obj.ServerSystem == "Windows"
                listing = parseDirListingForWindows(listing, 1, namesOnly, ...
                    obj.ServerLocale, obj.DatetimeType);
            end
        end

        if ~isempty(listing)
            % add folder to dir struct output
            if ~isempty(folderArray)
                [listing(:).("folder")] = folderArray{:};
            end

            % replace symlinks
            listing = matlab.io.ftp.replaceSymlinks(listing, names);
        end
    else
        % sort the raw list output and return as string array
        listing = sortRawListOutput(listing, names);
    end
end

function case0Parse(obj, options, namesOnly, listing)
    import matlab.io.ftp.parseDirListingForUnix
    import matlab.io.ftp.parseDirListingForWindows
    import matlab.io.internal.ftp.convertListToColumns

    % display only names
    disp(' ');

    % branch on whether output required is a string or a struct
    if options.ParseOutput == true
        % branch code based on whether remote OS is Unix or Windows
        if obj.ServerSystem == "unix"
            % only names are needed, QNX parsing not required
            listing = parseDirListingForUnix(listing, 0, namesOnly, ...
                obj.ServerSystem, obj.ServerLocale, obj.DatetimeType);
        elseif obj.ServerSystem == "Windows"
            listing = parseDirListingForWindows(listing, 0, namesOnly, ...
                obj.ServerLocale, obj.DatetimeType);
        end

        % display the 
        if isscalar(listing) && isempty(listing.name)
            disp(char(listing.name));
        elseif ~isempty(listing)
            disp(convertListToColumns(char(listing.name)));
        end
    else
        % sort listing
        listing = string(splitlines(listing));
        listing(startsWith(listing, ".") | listing == "." | listing == "..") = [];
        listing = sort(listing);
        if ~isempty(listing)
            disp(convertListToColumns(char(listing)));
        end
    end
    disp(' ');
end

function tf = wildcardMatch(list, pattern)
    pattern = regexptranslate('escape', pattern);
    pattern = replace(pattern, "\*", ".*");
    pattern = regexpPattern(pattern);
    tf = matches(list, pattern) & list ~= "." & list ~= "..";
end

function listing = sortRawListOutput(listing, listNames)
    % return raw output string after sorting
    listing = string(splitlines(listing));
    if listing(end) == ""
        listing = listing(1:end-1);
    end

    % sort entries by name
    names = string(listNames);
    for iter = numel(listing) : -1 : 1
        indices = find(isspace(listing(iter)) == 1, 1, 'last');
        temp = listing{iter}(indices + 1 : end);
        if temp == "." || temp == ".." || startsWith(temp, ".")
            names(iter) = [];
            listing(iter) = [];
            continue;
        end
    end
    [names, origOrder] = sort(names);
    listing = listing(origOrder);
    listing(names == "") = [];
end

function [listing, folderOrFile, folderName, names] = parseWildcardInput(obj, ...
    input, namesOnly)
    % wildcard character is part of input
    % check that it only appears at the end of the path
    afterWC = extractAfter(input, "*");
    if contains(afterWC, "/")
        error(message("MATLAB:io:ftp:ftp:SFTPWildcardSupport"));
    end

    % get dir listing from containing folder
    [folderName, pattern, ext] = fileparts(input);
    pattern = pattern + ext;
    if folderName == ""
        folderName = obj.RemoteWorkingDirectory;
    end
    names = matlab.io.sftp.internal.matlab.dir(obj.Connection, ...
        folderName, struct("NamesOnly", true));

    % use the wildcard pattern matching utility to identify matches
    names = splitlines(names);
    if isempty(names{end})
        names = names(1:end-1);
    end
    wMatches = wildcardMatch(names, pattern);

    % if full struct is needed, call LIST again on the containing
    % folder and only keep the matching entries
    if ~namesOnly
        % get individual LIST output for each of the matched entries
        wildcardList = matlab.io.sftp.internal.matlab.dir(...
            obj.Connection, folderName, struct("NamesOnly", false));
        wildcardList = splitlines(wildcardList);
        if isempty(wildcardList{end})
            wildcardList = wildcardList(1:end-1);
        end
        listing = wildcardList(wMatches);
        if ~isscalar(listing)
            listing = join(listing, newline);
            listing = listing{1};
        end
    else
        listing = names(wMatches);
    end
    names = names(wMatches);
    folderOrFile = 1;
end

function [listing, folderOrFile, folderName, isInputFile, nonExistentEntry, names] = ...
    parseInput(obj, input, namesOnly)
    % get full path for input string
    folderName = matlab.io.ftp.internal.matlab.fullfile(obj.Connection, input);
    nonExistentEntry = false;
    names = [];

    % check whether input is a folder or a file
    folderExists = matlab.io.sftp.internal.matlab.isFolder(obj.Connection, folderName);
    listing = matlab.io.sftp.internal.matlab.dir(obj.Connection, ...
        folderName, struct("NamesOnly", namesOnly));

    if ~folderExists
        % not a folder, try if this is a file
        isInputFile = matlab.io.sftp.internal.matlab.isFile(obj.Connection, ...
            folderName);
        if ~isInputFile
            % non-existent entry
            folderOrFile = -1;
            if nargout == 1
                nonExistentEntry = true;
            else
                disp(' ');
            end
        else
            % this is a file, get LIST entry from containing folder and
            % then get the appropriate listing for this file
            folderOrFile = 1;
            [folderName, filename, ext] = fileparts(folderName);
            filename = [filename, ext];
            listing = matlab.io.sftp.internal.matlab.dir(obj.Connection, ...
                folderName, struct("NamesOnly", namesOnly));

            % split at newline into separate entries
            str = splitlines(listing);
            if isempty(str{end})
                str = str(1:end-1);
            end

            % get only the names -> we can use this to remove symbolic
            % links
            if ~namesOnly
                names = matlab.io.sftp.internal.matlab.dir(obj.Connection, ...
                    folderName, struct("NamesOnly", true));
                % split at newline into separate entries
                names = splitlines(names);
                if isempty(names{end})
                    names = names(1:end-1);
                end
            end

            % match to get the appropriate entries
            if namesOnly
                idx = matches(str, filename);
            else
                idx = matches(names, filename);
            end

            if any(idx)
                % found matches
                listing = str{idx == 1};
                names = names(idx);
            else
                % non-existent entry, code path for Windows SFTP servers
                folderOrFile = -1;
                isInputFile = false;
                listing = [];
                nonExistentEntry = true;
            end
        end
    else
        % this is a folder
        % get the names so we can remove '.' and '..'
        names = matlab.io.sftp.internal.matlab.dir(obj.Connection, ...
            folderName, struct("NamesOnly", true));

        isInputFile = false;
        folderOrFile = 0;

        % split LIST input at newline
        names = splitlines(names);
        if isempty(names{end})
            names = names(1:end-1);
        end

        % check if folder is empty
        if numel(names) == 2 && any(names{1} == [".", ".."]) && ...
                any(names{2} == [".", ".."])
            listing = [];
            nonExistentEntry = false;
        end
    end
end