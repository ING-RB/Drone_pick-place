%matlab.io.xml.transform.StylesheetSourceDocument Stylesheet source document
%    source = StylesheetSourceDocument(doc) creates a stylesheet source
%    consisting of a matlab.io.xml.dom.Document.
%
%    StylesheetSourceDocument methods:
%       getSource - Get the document that this stylesheet source contains   
%
%    StylesheetSourceDocument properties:
%       Document - Document that this stylesheet source contains

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %Document Document contained by this stylesheet source
     %    Specifies the document contained by this stylesheet source.
     Document;
end
%}