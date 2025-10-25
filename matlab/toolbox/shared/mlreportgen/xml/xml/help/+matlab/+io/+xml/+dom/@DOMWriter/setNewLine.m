%setNewLine Specify character to start a new line in serialized output
%    setNewLine(thisWriter,newLine) specifies character or characters to
%    start a new line in serialized output. Valid values for the new
%    line argument are
%
%        ''                 - line feed (default)
%        newline            - line feed
%        char(13)           - carriage return
%        [char(13) newline] - carriage return followed by line feed
%
%    See matlab.io.xml.dom.DOMWriter.getNewLine

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.