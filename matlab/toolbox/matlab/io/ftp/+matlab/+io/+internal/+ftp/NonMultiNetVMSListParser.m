classdef NonMultiNetVMSListParser < matlab.io.internal.ftp.FTPListResultParser
    methods (Access = protected)
        function dirStruct = parseDirLines(~, lines, serverLocale, datetimeType)
            dirStruct = matlab.io.ftp.createBasicStruct(numel(lines));
            for i = 1 : numel(lines)
                thisLine = split(lines);
                nameWoExt = split(thisLine(1), ".");
                name = split(thisLine(1), ";");
                name = name(1);
                filesAndFolders = split(nameWoExt, ".");
                isdir = filesAndFolders(2) == "DIR";
                name(isdir) = extractBefore(name(isdir), ".DIR");
                bytes = NaN;
                dates = datetime(thisLine(3) + " " + thisLine(4), ...
                    InputFormat="dd-MMM-yyyy HH:mm:ss", Locale=serverLocale);

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
