classdef XilinxListParser < matlab.io.internal.ftp.FTPListResultParser

    methods (Access=protected)
        function dirStruct = parseDirLines(~,lines, serverLocale, datetimeType)
            if startsWith(lines(1), "total")
                dirStruct = matlab.io.ftp.createBasicStruct(numel(lines)-1);
                startIndex = 2;
            else
                dirStruct = matlab.io.ftp.createBasicStruct(numel(lines));
                startIndex = 1;
            end

            structIndex = 1;
            for ii = startIndex : numel(lines)
                thisLine = lines(ii);

                parts = thisLine.split(whitespacePattern);
                isdir = parts(1).startsWith('d');
                bytes = double(parts(5));
                name = parts(end);
                dates = extractDateString(parts, serverLocale);

                dirStruct(structIndex).name = char(name);
                dirStruct(structIndex).isdir = isdir;
                dirStruct(structIndex).bytes = bytes;
                if datetimeType == "text"
                    dirStruct(structIndex).date = char(dates, "dd-MMM-uuuu HH:mm:ss", ...
                        serverLocale);
                else
                    dirStruct(structIndex).date = dates;
                end
                dirStruct(structIndex).datenum = datenum(dates); %#ok<*DATNM>
                structIndex = structIndex + 1;
            end
        end
    end
end

function date = extractDateString(parts, serverLocale)
    dash = "-";
    date = parts(7) + dash + parts(6);
    yearOrTime = parts(8);
    isTime = contains(yearOrTime,":");
    thisyear = year(datetime());
    date(isTime) = date(isTime) + dash + thisyear + " " + yearOrTime(isTime) + ":00";
    date(~isTime) = date(~isTime) + dash + yearOrTime(~isTime) + " 00:00:00";
    date = datetime(date, InputFormat="dd-MMM-uuuu HH:mm:ss", Locale=serverLocale);
    if date > datetime("now")
        % reduce year by 1
        date.Year = date.Year - 1;
    end
end

%   Copyright 2024 The MathWorks, Inc.
