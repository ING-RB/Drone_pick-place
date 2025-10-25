%matlab.io.xml.transform.SourceDocument Source document for a transform
%    source = SourceDocument(doc) creates a transform source consisting
%    of a matlab.io.xml.dom.Document.
%
%    SourceDocument methods:
%       getSource - Get the document that this transform source contains   
%
%    Source properties:
%       Document - Document that this transform source contains
%
%   See also matlab.io.xml.transform.Transformer.transform

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %Document Document contained by this transform source
     %    Specifies the document contained by this transform source.
     Document;
end
%}