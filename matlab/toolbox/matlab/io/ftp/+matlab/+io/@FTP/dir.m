function varargout = dir(obj, folderName, options)
%DIR List directory on an FTP server.
%   DIR(FTP,DIRECTORY) lists the files in a directory. Pathnames and
%   wildcards may be used.
%
%   D = DIR(...) returns the results in an M-by-1
%   structure with the fields:
%       name    -- filename
%       date    -- modification date
%       bytes   -- number of bytes allocated to the file
%       isdir   -- 1 if name is a directory and 0 if not
%       datenum -- MATLAB serial date number
%
%   Name-Value Pairs:
%   -----------------------------------------------------------------------
%   "ParseOutput"       - When set to true returns a struct, otherwise
%                         returns a string with the raw output from the
%                         FTP server.
%
%   Because FTP servers do not return directory information in a standard way,
%   the last four fields in the structure may be empty or some items may
%   be missing.

% Copyright 2020-2021 The MathWorks, Inc.

    arguments
        obj (1,1) matlab.io.FTP
        folderName (1,1) string {mustBeNonmissing, mustBeNonempty} = ""

        % Name-value pair inputs.
        options.ParseOutput (1,1) logical = true
    end

    if nargout >= 1
        % get full struct listing when output struct is asked
        namesOnly = false;
    else
        namesOnly = true;
    end

    % Verify that connection was set up correctly
    verifyConnection(obj);

    [listing, fileFoundAt] = callDirWithOptions(obj, folderName, namesOnly);
    if isempty(listing)
        % server might only return names, use NLST to get names
        [listing, fileFoundAt] = callDirWithOptions(obj, folderName, true);
        if ~isempty(listing)
            varargout{1} = namesOnlyParse(listing, 1);
        else
            % non-existent entry
            if nargout >= 1
                varargout{1} = [];
            else
                disp(' ');
            end
            fileFoundAt = -1;
        end
    else
        if fileFoundAt == -1
            % non-existent entry
            if nargout >= 1
                varargout{1} = [];
            else
                disp(' ');
            end
        elseif fileFoundAt >= 0
            switch nargout
              case 0
                  case0Parse(obj, options, listing, namesOnly);
              case {1, 2}
                  varargout{1} = case12Parse(obj, options, listing, ...
                      namesOnly, folderName);
            end
        end
    end
    if nargout == 2
        varargout{2} = fileFoundAt;
    end
end

function finalListing = namesOnlyParse(listing, numOuts)
    if numOuts
        % create a full listing with only the name field populated.
        S = splitlines(listing);
        if isempty(S{end})
            S = S(1:end-1);
        end

        % remove hidden files
        idx = cellfun(@(entry)startsWith(entry, "."), S);
        S(idx) = [];

        % sort entries
        S = sort(S);

        % pre-allocate the struct array for performance
        finalListing = matlab.io.ftp.createBasicStruct(numel(S));
        for ii =  1 : numel(S)
            finalListing(ii,1).name = S{ii};
            finalListing(ii,1).isdir = [];
            finalListing(ii,1).bytes = [];
            finalListing(ii,1).date = [];
            finalListing(ii,1).datenum = [];
        end
    end
end

function case0Parse(obj, options, listing, namesOnly)
    import matlab.io.ftp.parseDirListingForUnix
    import matlab.io.ftp.parseDirListingForWindows
    import matlab.io.internal.ftp.convertListToColumns
    % display only names
    disp(' ');
    if options.ParseOutput == true
        % branch code based on whether remote OS is Unix, Windows, or
        % QNX server
        if obj.System == "QNX" || obj.System == "unix"
            % only names are needed, QNX parsing not required
            listing = parseDirListingForUnix(listing, 0, namesOnly, ...
                obj.System, obj.ServerLocale);
        elseif obj.System == "Windows"
            listing = parseDirListingForWindows(listing, 0, namesOnly, ...
                obj.ServerLocale);
        end

        if ~isempty(listing)
            disp(convertListToColumns(char(listing.name)));
        end
    else
        % sort listing
        listing = string(splitlines(listing));
        listing(startsWith(listing, ".") | listing == "." | ...
            listing == "..") = [];
        if ~isempty(listing)
            disp(convertListToColumns(char(listing)));
        end
    end
    disp(' ');
end

function listing = case12Parse(obj, options, listing, namesOnly, folderName)
    import matlab.io.ftp.parseDirListingForQNX
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
            listing = obj.DirParserFcn(listing, obj.ServerLocale);
        else
            % branch code based on whether remote OS is unix, QNX, or
            % Windows
            if obj.System == "QNX"
                listing = parseDirListingForQNX(listing, namesOnly);
                % pass results of QNX parsing to Unix parser to put
                % together final struct
                listing = parseDirListingForUnix(listing, 1, namesOnly, ...
                    obj.System, obj.ServerLocale);
            elseif obj.System == "unix"
                listing = parseDirListingForUnix(listing, 1, namesOnly, ...
                    obj.System, obj.ServerLocale);
            elseif obj.System == "Windows"
                listing = parseDirListingForWindows(listing, 1, namesOnly, ...
                    obj.ServerLocale);
            end
        end

        % get the names only to replace the symlinks
        names = callDirWithOptions(obj, folderName, true);
        names = splitlines(names);
        if isempty(names{end})
            names = names(1:end-1);
        end
        % replace symlinks
        if ~isempty(listing)
            listing = matlab.io.ftp.replaceSymlinks(listing, names);
        end
    else
        % return the raw list output as a string array
        listing = string(splitlines(listing));
        if listing(end) == ""
            listing = listing(1:end-1);
        end
    end
end