function finalListing = parseDirListingForUnix(listing, numOuts, namesOnly, ...
    remoteSystem, serverLocale, datetimeType)
    %PARSEDIRLISTINGFORUNIX Parse LIST or NLST output from Unix FTP/SFTP servers

    % Copyright 2020-2024 The MathWorks, Inc.
    import matlab.io.ftp.createBasicStruct
    if isempty(listing)
        finalListing = [];
        return;
    end

    if nargin < 6
        datetimeType = "text";
    end

    tryOtherParsers = false;

    % Use textscan to parse the string into its constituent parts
    if numOuts
        % output struct is required
        if remoteSystem == "unix"
            if iscell(listing)
                listing = listing{1};
            end
            parts = textscan(listing, "%s%d%s%s%d%3c%d%s%[^\r\n]", ...
                "MultipleDelimsAsOne", true);
            if ~all(cellfun(@(x)size(x,1), parts))
                tryOtherParsers = true;
            else
                % get month name, day, year or time, and bytes
                monthName = string(parts{6});
                day = string(parts{7});
                yearOrTime = string(parts{8});
                names = parts{9};
                bytes = double(parts{5});
            end
        elseif remoteSystem == "QNX"
            % get month name, day, year or time, and bytes from QNX parser
            monthName = listing.MonthName;
            day = listing.Day;
            yearOrTime = listing.YearOrTime;
            names = listing.Names;
            bytes = listing.Bytes;
            parts = listing.Parts;
        end
    else
        % only names are required
        parts = splitlines(listing);
        if isempty(parts{end})
            parts = parts(1:end-1);
        end
        names = parts;
    end

    if tryOtherParsers
        % try parsing with other parsers
        [tf, finalListing] = tryNonUnixParsers(listing, serverLocale, datetimeType);
        if tf
            return;
        end
        % Try parsing out the name only
        finalListing = windowsNameOnlyParse(listing, numOuts);
        return;
    end

    cntr = 0;
    % pre-allocate the struct array for performance
    finalListing = createBasicStruct(numel(names));

    % sort names field
    [names, origOrder] = sort(names);

    % build up the output struct
    for ii = 1 : numel(names)
        if ~namesOnly && startsWith(parts{1}{origOrder(ii)}, 'n')
            % QNX servers might return entries with n in the permissions,
            % skip these entries
            continue;
        end

        if names{ii} == "." || names{ii} == ".." || startsWith(names{ii}, ".")
            continue;
        end

        cntr = cntr + 1;
        % get name of file or folder without path
        if namesOnly
            % listing contains full path, strip off foldernames
            if contains(names{ii}, "/")
                finalListing(cntr,1).name = reverse(extractBefore(...
                    reverse(names{ii}), "/"));
            else
                finalListing(cntr,1).name = names{ii};
            end
        else
            finalListing(cntr,1).name = names{ii};
        end

        if numOuts
            finalListing(cntr,1).bytes = bytes(origOrder(ii));
            finalListing(cntr,1).isdir = startsWith(parts{1}{origOrder(ii)}, 'd');
            yearAdded = contains(yearOrTime(origOrder(ii)), ":");

            if yearAdded
                % this is going to be a datetime with time
                % get current year
                currYear = string(year(datetime("today")));
                makeDate = day(origOrder(ii)) + "-" + monthName(origOrder(ii)) + ...
                    "-" + currYear + " " + yearOrTime(origOrder(ii)) + ":00";
            else
                % this is going to be a datetime without time
                makeDate = day(origOrder(ii)) + "-" + monthName(origOrder(ii)) + ...
                    "-" + yearOrTime(origOrder(ii)) + " 00:00:00";
            end

            try
                % Use DatetimeType to populate the date field
                thisDate = datetime(makeDate, "InputFormat", ...
                    "dd-MMM-yyyy HH:mm:ss", "Locale", serverLocale);
                if yearAdded && thisDate > datetime("now", "InputFormat", ...
                        "dd-MMM-yyyy HH:mm:ss", "Locale", serverLocale)
                    currYear = string(year(datetime("today"))-1);
                    makeDate = day(origOrder(ii)) + "-" + monthName(origOrder(ii)) + ...
                        "-" + currYear + " " + yearOrTime(origOrder(ii)) + ":00";
                    thisDate = datetime(makeDate, "InputFormat", ...
                        "dd-MMM-yyyy HH:mm:ss", "Locale", serverLocale);
                end
                if datetimeType == "text"
                    finalListing(cntr,1).date = char(thisDate, ...
                        "dd-MMM-yyyy HH:mm:ss", serverLocale);
                else
                    finalListing(cntr,1).date = thisDate;
                end
            catch
                error(message("MATLAB:io:ftp:ftp:UnableToParseListOutput"));
            end

            % Use datenum on the constructed datetime object to populate the
            % datenum field
            finalListing(cntr,1).datenum = datenum(thisDate); %#ok<*DATNM>
        end
    end

    if cntr > 0
        % remove the extra entries from the result struct
        finalListing(cntr+1:end,:) = [];
    elseif cntr == 0
        % no entries were found
        finalListing = [];
    end
end

function finalListing = windowsNameOnlyParse(listing, numOuts)
    if numOuts
        % non-Unix OS full listing required, parse differently
        S = splitlines(listing);
        if isempty(S{end})
            S = S(1:end-1);
        end
        % pre-allocate the struct array for performance
        finalListing = matlab.io.ftp.createBasicStruct(numel(S));
        iterVar = 0;
        for ii =  1 : numel(S)
            index = find(isspace(S{ii}) == 1, 1, 'last');
            if isempty(index) || S{ii}(index+1:end) == "." || ...
                    S{ii}(index+1:end) == ".."
                % splitlines creates an empty line at the end
                continue;
            end
            iterVar = iterVar + 1;
            finalListing(iterVar,1).name = S{ii}(index+1:end);
            finalListing(iterVar,1).isdir = [];
            finalListing(iterVar,1).bytes = [];
            finalListing(iterVar,1).date = [];
            finalListing(iterVar,1).datenum = [];
        end
    end
end

function [tf, finalListing] = tryNonUnixParsers(listing, serverLocale, datetimeType)
    % Try QNX parser
    parser = matlab.io.internal.ftp.QNXListParser;
    [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType);
    if tf
        return;
    end

    % Try Xilinx parser
    parser = matlab.io.internal.ftp.XilinxListParser;
    [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType);
    if tf
        return;
    end

    % Try NetWare parser
    parser = matlab.io.internal.ftp.NetWareListParser;
    [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType);
    if tf
        return;
    end

    % Try MultiNet parser
    parser = matlab.io.internal.ftp.MultiNetListParser;
    [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType);
    if tf
        return;
    end

    % Try NetPresenz parser
    parser = matlab.io.internal.ftp.NetPresenzListParser;
    [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType);
    if tf
        return;
    end

    % try NonMultiNet for VMS parser
    parser = matlab.io.internal.ftp.NonMultiNetVMSListParser;
    [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType);
    if tf
        return;
    end

    % try EPLF parser
    parser = matlab.io.internal.ftp.EPLFListParser;
    [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType);
    if tf
        return;
    end
end

function [tf, finalListing] = parseListingWithParser(listing, parser, serverLocale, datetimeType)
    finalListing = [];
    try
        finalListing = parser.parseDirOutput(listing, serverLocale, datetimeType);
    catch
    end
    tf = validateParsingResult(finalListing);
end

function tf = validateParsingResult(finalListing)
    tf = true;
    if isempty(finalListing)
        tf = false;
        return;
    end

    for ii = 1 : numel(finalListing)
        if isempty(finalListing(ii).name) || isempty(finalListing(ii).isdir) || ...
                isempty(finalListing(ii).bytes) || isempty(finalListing(ii).date)
            % not the correct parser, try next parser
            tf = false;
            return;
        end
    end
end
