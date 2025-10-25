classdef AppParserErrorHandler < matlab.io.xml.dom.ParseErrorHandler
    %APPPARSERERRORHANDLER Extracts error line number location when parsing plain-text files

%   Copyright 2024 The MathWorks, Inc.

    properties
        Errors
        Filepath
    end

    methods
        function obj = AppParserErrorHandler(filepath)
            obj@matlab.io.xml.dom.ParseErrorHandler();
            obj.Filepath = filepath;
        end

        function keepParsing = handleError(obj, err)
            import matlab.io.xml.dom.*

            index = numel(obj.Errors) + 1;
            severity = getSeverity(err);

            obj.Errors(index).Severity = severity;
            obj.Errors(index).Message = err.Message;

            loc = getLocation(err);
            obj.Errors(index).Location.FilePath = obj.Filepath;
            obj.Errors(index).Location.LineNo = loc.LineNumber;
            obj.Errors(index).Location.ColNo = loc.ColumnNumber;

            if strcmp(severity, "FatalError")
                keepParsing = false;
            else
                keepParsing = true;
            end
        end
    end
end
