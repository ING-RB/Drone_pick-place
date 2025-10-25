classdef EPLFListParser < matlab.io.internal.ftp.FTPListResultParser

    methods (Access=protected)
        function dirStruct = parseDirLines(~, lines, serverLocale, datetimeType)
            % Split at whitespace to separate path name from rest of the
            % facts
            dirStruct = matlab.io.ftp.createBasicStruct(numel(lines));
            for i = 1 : numel(lines)
                parts = lines(i).split(whitespacePattern);
                name = parts(2);

                % Get the part between ",m" and the following "," -> last
                % modified date
                lastModifiedAndSize = extractAfter(parts(1), ",m");
                lastModified = extractBefore(lastModifiedAndSize, ",");

                % Get the part between ",s" and the following "," -> size
                sizeInBytes = extractBefore(extractAfter(lastModifiedAndSize, ",s"), ",");
                if ismissing(lastModified) && ismissing(sizeInBytes)
                    error(message("MATLAB:io:ftp:ftp:UnableToParseListOutput"));
                end
                bytes = str2double(sizeInBytes);
                bytes(isnan(bytes)) = 0;

                % Unclear how this format represents folders, returning false
                % for now
                isdir = false(size(sizeInBytes, 1), 1);

                dates = datetime(str2double(lastModified), ConvertFrom="posix", ...
                    TimeZone="UTC");
                dateNums = datenum(dates); %#ok<DATNM>

                dirStruct(i).name = char(name);
                dirStruct(i).isdir = isdir;
                dirStruct(i).bytes = bytes;
                if datetimeType == "text"
                    dirStruct(i).date = char(dates, "dd-MMM-uuuu HH:mm:ss", serverLocale);
                else
                    dirStruct(i).date = dates;
                end
                dirStruct(i).datenum = dateNums;
            end
        end
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
