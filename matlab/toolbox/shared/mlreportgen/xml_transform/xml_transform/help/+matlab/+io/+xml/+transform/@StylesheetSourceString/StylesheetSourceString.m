%matlab.io.xml.transform.StylesheetSourceString String stylesheet source
%    source = SourceString(markup) creates a stylesheet source containing 
%    a string of XSL markup. The markup argument must be an instance of a
%    string scalar or character vector.
%
%    StylesheetSourceString properties:
%       String - String containing XSL markup
%
%   See also matlab.io.xml.transform.Transformer.transform,
%   matlab.io.xml.transform.Transformer.compileStylesheet

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %String String containing XSL markup
     %    A string scalar or character array containing XSL markup to be
     %    used as input to a document transformation.
     String;
end
%}