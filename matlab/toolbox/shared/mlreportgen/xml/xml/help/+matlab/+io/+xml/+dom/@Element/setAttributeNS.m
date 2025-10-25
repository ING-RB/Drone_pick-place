%setAttributeNS Set value of an element attribute by namespace name
%    setAttributeNS(thisElem,namespaceURI,localName,value) adds an attribute
%    with the specified namespace URI, local name, and value to this
%    element if this element does not already contain an attribute with the
%    specified name. If this element already has an attribute with the
%    specified namespace URI and local name, this method sets the value of
%    the existing attribute to the specified value. The namespace URI,
%    local name, and value arguments must be strings.
%   
%    Note: This method treats the value as CDATA, i.e., it ignores markup
%    text, including entity references, in the value string.  To set an
%    attribute to a value that includes an entity reference, such as an
%    ampersand character entity reference (&amp;), create an Attr node
%    with the value. Then, use setAttributeNodeNS to add the Attr node to
%    this element.
%
%    See also matlab.io.xml.dom.Element.getAttributeNS, 
%    matlab.io.xml.dom.Element.setAttribute, 
%    matlab.io.xml.dom.Element.setAttributeNode, 
%    matlab.io.xml.dom.Element.setAttributeNodeNS  

%    Copyright 2020-2023 MathWorks, Inc.
%    Built-in function.