%PARSEERROR Specifies information about an XML markup parse error
%   A MAXP parser creates an instance of this class when it encounters
%   an error in the XML markup that it is parsing and passes the
%   instance to the error handler registered with the parser. The
%   error instance specifies information about the error.
%
%   ParseError methods:
%       getLocation    - Get location of the error in the markup
%       getSeverity    - Get severity of the error
%
%   ParseError properties:
%       Message          - Get error description
%
%   See also matlab.io.xml.dom.ParseErrorHandler.handleError

%    Copyright 2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %Message Error description
     %    This read-only property describes the error that occurred.
     Message;
end
%}



