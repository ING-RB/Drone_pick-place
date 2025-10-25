%matlab.io.xml.transform.ResultFile File result of a transform
%    result = ResultFile(path) creates a result object that specifies the
%    location at which to store a file containing the serialized result of
%    a document transformation. The path must be an instance of a string
%    scalar or character vector.
%
%    ResultFile properties:
%       Path - Path of the file containing the result of a transformation
%
%   See also matlab.io.xml.transform.Transformer.transform

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %Path Path of file containing result of a transformation
     %    A string scalar that specifies the local file system path of  a
     %    file containing the result of a document transformation.
     Path;
end
%}