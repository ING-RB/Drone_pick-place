%getXMLStandalone Check standalone status of a document
%    tf = getXMLStandalone(thisDoc) returns true if this document has been
%    declared to be standalone. A standalone declaration causes a parser to
%    ignore markup declarations in the document's DTD. You can use an XML
%    declaration in an XML file to declare a document to be standalone.
%    You can also use a document's setXMLStandalone method to declare
%    a document to be standalone.
%
%    See also matlab.io.xml.dom.Document.setXMLStandalone

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.