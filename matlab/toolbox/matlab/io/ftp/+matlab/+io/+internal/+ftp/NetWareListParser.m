classdef NetWareListParser < matlab.io.internal.ftp.FTPListResultParser
    methods (Access=protected)
        function dirStruct = parseDirLines(~, lines, serverLocale, datetimeType)
            dirStruct = matlab.io.ftp.createBasicStruct(numel(lines));
            for i = 1 : numel(lines)
                thisLine = split(lines(i));
                name = thisLine(8);
                bytes = str2double(thisLine(4));
                bytes(isnan(bytes)) = 0;
                isdir = thisLine(1) == "d";

                currYear = string(year(datetime("today")));
                makeDate = thisLine(6) + "-" + thisLine(5) + ...
                    "-" + currYear + " " + thisLine(7) + ":00";
                dates = datetime(makeDate, InputFormat="dd-MMM-yyyy HH:mm:ss", ...
                    Locale=serverLocale);
                dirStruct(i).name = char(name);
                dirStruct(i).isdir = isdir;
                dirStruct(i).bytes = bytes;
                if datetimeType == "text"
                    dirStruct(i).date = char(dates, "dd-MMM-yyyy HH:mm:ss", ...
                        serverLocale);
                else
                    dirStruct(i).date = dates;
                end
                dirStruct(i).datenum = datenum(dates); %#ok<DATNM>
            end
        end
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
