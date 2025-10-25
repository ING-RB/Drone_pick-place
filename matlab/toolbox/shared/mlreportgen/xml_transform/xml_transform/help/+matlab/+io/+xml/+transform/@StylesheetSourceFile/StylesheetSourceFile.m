%matlab.io.xml.transform.StylesheetSourceFile Stylesheet file
%    source = StylesheetSourceFile(path) creates a stylesheet source
%    containing the path to an XML file to be used as a stylesheet. The
%    path must be an instance of a string scalar or character vector.
%
%    StylesheetSourceFile properties:
%       Path - Path of the XML file referenced by this source
%
%   See also matlab.io.xml.transform.Transformer.transform

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %Path Path of style XML file
     %    Specifies the local file system path of an XML file to be used
     %    as a stylesheet for a document transformation.
     Path;
end
%}