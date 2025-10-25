%getElementsByTagNameNS Get elements in an element by namespace tag name
%    list = getElementsByTagNameNS(thisElem,namespaceURI,localName) returns 
%    a NodeList object listing elements that are descendants of this 
%    element and that match the specified namespace URI and local name. 
%    The string "*" matches all namespace URIs and local names. The 
%    elements are listed in the order that they would be encountered in a 
%    traversal of the document tree containing this element, starting with
%    this element.
%
%    See also matlab.io.xml.dom.NodeList, 
%    matlab.io.xml.dom.Element.getElementsByTagName  

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.