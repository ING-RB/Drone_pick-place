
%PARSEERRORHANDLER Abstract base class for parse error handlers
%   This class is intended to serve as a base class for deriving
%   handlers to be used to handle XML markup errors that a parser
%   encounters while parsing an XML file or string. You
%   cannot create an instance of this class because it is abstract.
%
%   ParseErrorHandler methods:
%       handleError - Handle a parse error
%
%   Example
%
%   classdef MyParseErrorHandler < matlab.io.xml.dom.ParseErrorHandler
%
%        properties
%           Errors
%        end
%
%        methods
%           function cont = handleError(obj,error)
%                import matlab.io.xml.dom.*
%                idx = numel(obj.Errors) + 1;
%                severity = getSeverity(error);
%                obj.Errors(idx).Severity = severity;
%                obj.Errors(idx).Message = error.Message;
%                loc = getLocation(error);
%                obj.Errors(idx).Location.FilePath = loc.FilePath;
%                obj.Errors(idx).Location.LineNo = loc.LineNumber;
%                obj.Errors(idx).Location.ColNo = loc.ColumnNumber;
%                if severity == "FatalError"
%                    cont = false; % Halt parsing.
%                else
%                    cont = true; % Continue parsing.
%                end
%            end
%        end
%    end
%
%   To use a handler derived from this class, assign the handler to
%   the ErrorHandler property of a parser's configuration, for example,
%
%   p = matlab.io.xml.dom.Parser;
%   h = MyParseErrorHandler;
%   p.Configuration.ErrorHandler = h;
%
%   See also matlab.io.xml.dom.ParserConfiguration

%    Copyright 2021 MathWorks, Inc.
%    Built-in class


