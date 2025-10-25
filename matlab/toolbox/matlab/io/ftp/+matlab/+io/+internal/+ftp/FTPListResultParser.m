classdef FTPListResultParser
% Interface for parser for FTP list results

    properties (Constant, Access=protected)
        RequiredFields = ["name", "isdir", "bytes", "date", "datenum"];
    end

    methods (Sealed)
        function dirStruct = parseDirOutput(parser, lines, serverLocale, datetimeType)
            arguments
                parser (1,1) matlab.io.internal.ftp.FTPListResultParser
                lines (1,:) string
                serverLocale (1,1) string
                datetimeType (1,1) string
            end

            lines = parser.ignoreLines(splitlines(lines));
            assert(isstring(lines),"IgnoreLines didn't return string as expected")

            % Call child class template-hook method
            try
                dirStruct = parser.parseDirLines(lines, serverLocale, datetimeType);
            catch
                error(message("MATLAB:io:ftp:ftp:UnableToParseListOutput"));
            end

            if ~all(isfield(dirStruct,parser.RequiredFields))
                error(...
                  "Results of parseDirLines for %s does not return all required fields: %s",...
                    class(parser),...
                    parser.RequiredFields)
            end

        end
    end

    methods (Access = protected)
        function lines = ignoreLines(~,lines)
            lines = removeBlankLines(lines);
        end
    end

    methods (Abstract, Access = protected)
        % Return the results of the list as a dir-struct
        dirStruct = parseDirLines(parser,lines, serverLocale);
    end

end

function lines = removeBlankLines(lines)
    lines(ismissing(lines) | strlength(strip(lines)) == 0) = [];
end
% Copyright 2023, The MathWorks, Inc.
