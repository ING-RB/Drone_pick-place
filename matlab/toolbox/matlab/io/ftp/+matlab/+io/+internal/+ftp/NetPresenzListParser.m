classdef NetPresenzListParser < matlab.io.internal.ftp.FTPListResultParser
    methods (Access = protected)
        function dirStruct = parseDirLines(~, lines, serverLocale, datetimeType)
            dirStruct = matlab.io.ftp.createBasicStruct(numel(lines));
            for ii = 1 : numel(lines)
                thisLine = split(lines(ii));
                if startsWith(thisLine(1), "d")
                    % folder case
                    dates = datetime(thisLine(5) + "-" + thisLine(4) + "-" + thisLine(6), ...
                        InputFormat="dd-MMM-yyyy", Locale=serverLocale);
                    name = thisLine(end);
                    isdir = true;
                    bytes = nan;
                else
                    % file case
                    name = thisLine(end);
                    isdir = false;
                    dates = datetime(thisLine(6) + "-" + thisLine(5) + "-" + thisLine(7), ...
                        InputFormat="dd-MMM-yyyy", Locale=serverLocale);
                    bytes = str2double(thisLine(2));
                end

                dirStruct(ii).name = char(name);
                dirStruct(ii).isdir = isdir;
                dirStruct(ii).bytes = bytes;
                if datetimeType == "text"
                    dirStruct(ii).date = char(dates, "dd-MMM-yyyy HH:mm:ss", ...
                        serverLocale);
                else
                    dirStruct(ii).date = dates;
                end
                dirStruct(ii).datenum = datenum(dates); %#ok<*DATNM>
            end
        end
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
