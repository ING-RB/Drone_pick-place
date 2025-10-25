%matlab.io.xml.transform.SourceFile Source file for a transform
%    source = SourceFile(path) creates a transform source containing
%    the path to an XML file to be used as input to a document 
%    transformation. The path must be an instance of a string scalar or
%    character vector.
%
%    SourceFile properties:
%       Path - Path of the XML file referenced by this source
%
%   See also matlab.io.xml.transform.Transformer.transform

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %Path Path of source XML file
     %    Specifies the local file system path of an XML file to be used
     %    as input to a document transformation.
     Path;
end
%}