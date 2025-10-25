function finalListing = parseDirListingForWindows(listing, numOuts, ...
    namesOnly, serverLocale, datetimeType)
    %PARSEDIRLISTINGFORWINDOWS Parse LIST or NLST output from Windows FTP/SFTP servers

    % Copyright 2020-2024 The MathWorks, Inc.
    import matlab.io.ftp.createBasicStruct

    if nargin < 5
        datetimeType = "text";
    end

    if isempty(listing)
        finalListing = [];
        return;
    end

    % split lines and separate into files and folders
    S = splitlines(listing);
    if isempty(S{end})
        S(end) = [];
    end

    if namesOnly
        % only names are needed
        structSize = numel(S);
    else
        % Use textscan to parse the string into its constituent parts
        isDir = contains(S, "<DIR>");
        sDirs = S(isDir == 1);
        sFiles = S(isDir == 0);

        % combine files into a single cell and folders into a single cell
        numDirs = numel(sDirs);
        numFiles = numel(sFiles);
        sDirs = join(sDirs, newline);
        sFiles = join(sFiles, newline);

        % textscan on files and folders separately
        if ~isempty(sFiles) && ~isempty(sFiles{1})
            tFiles = textscan(sFiles{1}, "%s %s %s %[^\r\n]", numFiles);
            if ~all(cellfun(@(x)size(x,1), tFiles))
                error(message("MATLAB:io:ftp:ftp:UnableToParseListOutput"));
            end
            tFiles{3} = str2double(tFiles{3});
        else
            tFiles{1} = [];
        end
        if ~isempty(sDirs) && ~isempty(sDirs{1})
            tDirs = textscan(sDirs{1}, "%s %s <DIR> %[^\r\n]", numDirs);
            if ~all(cellfun(@(x)size(x,1), tDirs))
                error(message("MATLAB:io:ftp:ftp:UnableToParseListOutput"));
            end
        else
            tDirs{1} = [];
        end

        % get size for struct
        structSize = numel(tFiles{1}) + numel(tDirs{1});
    end

    % pre-allocate struct for full listing or simply return names
    finalListing = createBasicStruct(structSize);

    dirsCntr = 1;
    filesCntr = 1;
    structCntr = 1;
    increment = 0;
    for ii = 1 : structSize
        if namesOnly
            % only names are needed
            [~, filename, ext] = fileparts(S{ii});
            finalListing(ii,1).name = [filename, ext];
            continue;
        end

        if isDir(ii) && ~isempty(tDirs{1}) && ~isempty(tDirs{1}{dirsCntr})
            % add this folder to the output struct
            finalListing(structCntr,1).name = tDirs{1,3}{dirsCntr};
            if numOuts
                % all fields of output struct are required
                finalListing(structCntr,1).bytes = 0;
                finalListing(structCntr,1).isdir = true;
                try
                    makeDate = datetime([tDirs{1,1}{dirsCntr} ' ' ...
                        tDirs{1,2}{dirsCntr}], "InputFormat", ...
                        "MM-dd-yy hh:mmaa", "Locale", serverLocale);
                catch
                    error(message("MATLAB:io:ftp:ftp:UnableToParseListOutput"));
                end
            end
            dirsCntr = dirsCntr + 1;
            structCntr = structCntr + 1;
            increment = 1;
        elseif ~isempty(tFiles{1}) && ~isempty(tFiles{1}{filesCntr})
            % add this file to the output struct
            finalListing(structCntr,1).name = tFiles{1,4}{filesCntr};
            if numOuts
                % all fields of the output struct are required
                finalListing(structCntr,1).bytes = tFiles{1,3}(filesCntr);
                finalListing(structCntr,1).isdir = false;
                try
                    makeDate = datetime([tFiles{1,1}{filesCntr} ' ' ...
                        tFiles{1,2}{filesCntr}], "InputFormat", ...
                        "MM-dd-yy hh:mmaa", "Locale", serverLocale);
                catch
                    error(message("MATLAB:io:ftp:ftp:UnableToParseListOutput"));
                end
            end
            filesCntr = filesCntr + 1;
            structCntr = structCntr + 1;
            increment = 1;
        end

        if numOuts && increment
            % all fields of the output struct are required
            thisDate = datetime(makeDate, "InputFormat", "dd-MMM-yyyy HH:mm:ss");
            if datetimeType == "text"
                finalListing(structCntr-1,1).date = char(thisDate, ...
                    "dd-MMM-yyyy HH:mm:ss", serverLocale);
            else
                finalListing(structCntr-1,1).date = thisDate;
            end
            finalListing(structCntr-1,1).datenum = datenum(makeDate); %#ok<DATNM>
            increment = 0;
        end
    end
end
