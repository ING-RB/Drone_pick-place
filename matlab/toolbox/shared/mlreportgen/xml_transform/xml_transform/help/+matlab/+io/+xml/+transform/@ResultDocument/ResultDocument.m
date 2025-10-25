%matlab.io.xml.transform.ResultDocument Document result of transform
%    result = ResultDocument() creates a container for storing the result
%    of a transform as a matlab.io.xml.dom.Document.
%
%    ResultDocument methods:
%       getResult - Get the document that results from a transform   
%
%    Result properties:
%       Document - Document that results from a transform
%
%   See also matlab.io.xml.transform.Transformer.transform

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %Document Document contained by this transform result
     %    Specifies the document that a transform operation stores in
     %    this object as the result of a transformation.
     Document;
end
%}