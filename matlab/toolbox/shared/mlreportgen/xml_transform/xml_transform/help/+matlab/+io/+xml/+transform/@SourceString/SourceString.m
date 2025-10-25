%matlab.io.xml.transform.SourceString String source for a transform
%    source = SourceString(markup) creates a transform source containing 
%    a string of XML markup. The markup argument must be an instance of a
%    string scalar or character vector.
%
%    SourceString properties:
%       String - String containing XML markup
%
%   See also matlab.io.xml.transform.Transformer.transform

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %String String containing XML markup
     %    A string scalar or character array containing XML markup to be
     %    used as input to a document transformation.
     String;
end
%}