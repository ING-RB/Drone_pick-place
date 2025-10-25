%matlab.io.xml.dom.Parser Defines an XML markup parser
%   parser = Parser() creates an XML markup parser. Use the parser's
%   Configuration property to specify parse options.
%
%   Parser methods:
%       parseFile   - Parse a file
%       parseString - Parse a string
%
%    Parser properties:
%       Configuration - Parse options
%
%    See also matlab.io.xml.dom.ParserConfiguration

%    Copyright 2020 Mathworks, Inc.
%    Built-in class

%{
properties
     %Configuration Parser configuration
     %    The value of this read-only property is an object that specifies
     %    parser options. Although the property is read-only, you can 
     %    change the parser options that it specifies.
     %    
     %    See also matlab.io.xml.dom.ParserConfiguration
     Configuration;
end
%}