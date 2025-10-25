%matlab.io.xml.dom.ParseErrorLocator Specify location of a parse error
%   An instance of this class specifies the location of a parse error
%   an XML file.  
%
%    ParseErrorLocator properties:
%       ByteOffset   - Byte offset of error
%       CharOffset   - UTF16 character offset of error
%       ColumnNumber - Column number of error
%       FilePath     - Path of file containing error
%       LineNumber   - Line number of error
%
%    See also matlab.io.xml.dom.ParseError

%    Copyright 2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %ByteOffset Byte offset of error
     %   Offset of the error in bytes from the beginning of the markup
     ByteOffset;

     %CharOffset UTF-16 character offset of the error
     CharOffset;

     %ColumnNumber Column number of the error
     %   Offset of the error in characters from the beginning of a line
     ColumnNumber;

     %FilePath Path of file containing the error
     %    This property is empty if a string is being parsed.
     FilePath;

     %LineNumber Line number of the error
     %    Offset in lines of the error from the beginning of the markup
     LineNumber;

end
%}