%getElementsByTagNameNS Gets elements of a document by namespace tag name
%    list = getElementsByTagNameNS(thisDoc,namespaceURI,localName) returns
%    a NodeList object listing the elements in this document that match the
%    specified URI and local name. The elements are listed in the order in
%    which they occur in the document. The string "*" or character array
%    '*' matches any URI or local name. The node list returned by this
%    method is live: it is updated immediately to reflect changes in the
%    document's element content.
%
%    See also matlab.io.xml.dom.Element, 
%    matlab.io.xml.dom.NodeList

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.