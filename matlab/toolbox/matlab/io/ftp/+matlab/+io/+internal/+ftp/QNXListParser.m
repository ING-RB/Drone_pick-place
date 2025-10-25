classdef QNXListParser < matlab.io.internal.ftp.FTPListResultParser

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
                bytes = double(parts(4));
                name = parts(end);

                dates = extractDateString(parts);
                dates = datetime(dates, ...
                    InputFormat="dd-MMM-uuuu HH:mm:ss", Locale=serverLocale);

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

function date = extractDateString(parts)
    dash = "-";
    date = parts(6) + dash + parts(5);
    yearOrTime = parts(7);
    isTime = contains(yearOrTime,":");
    thisyear = year(datetime());
    date(isTime) = date(isTime) + dash + thisyear + " " + yearOrTime(isTime) + ":00";
    date(~isTime) = date(~isTime) + dash + yearOrTime(~isTime) + " 00:00:00";
end

%   Copyright 2023-2024 The MathWorks, Inc.
