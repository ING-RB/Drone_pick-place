%matlab.io.xml.dom.Attr Attribute of an XML DOM element
%    An Attr object represents an attribute of an XML DOM element.
%    
%    Attr methods:
%        cloneNode               - Copy this attribute node
%        compareDocumentPosition - Get relative position of this node
%        getBaseURI              - Get base URI
%        getLength               - Get number of child nodes
%        getLocalName            - Get attribute's local name
%        getNextSibling          - Returns an empty node
%        getName                 - Get attribute name
%        getNamespaceURI         - Get namespace URI for attribute
%        getNodeName             - Get node name of this attribute
%        getNodeType             - Get node type of this attribute node
%        getNodeTypeName         - Get type name of this attribute node
%        getNodeValue            - Get node value of this attribute
%        getOwnerElement         - get element that owns this attribute
%        getOwnerDocument        - Get document that owns this attribute
%        getParentNode           - Returns an empty node
%        getPositionTypeName     - Get name of a position type
%        getPrefix               - Get the prefix of an attribute name
%        getPreviousSibling      - Returns an empty node
%        getSchemaTypeInfo       - Get schema type information
%        getSpecified            - Whether attribute value is specified
%        getTextContent          - Get value of this attribute
%        getValue                - Get value of this attribute
%        isEqualNode             - Whether this node equals another
%        isID                    - Whether this attribute is an ID
%        isSameNode              - Whether a node is this node
%        lookupNamespaceURI      - Find namespace associated with prefix
%        lookupPrefix            - Find prefix associated with namespace
%        setNodeValue            - Set node value of this attribute
%        setTextContent          - Set text content of this attribute
%        setValue                - Set value of this attribute
%
%    Attr properties:
%        IsID  - Whether this attribute is an ID attribute
%        Name  - Name of this attribute           
%        Value - Value of this attribute

%    Copyright 2020-2021 MathWorks, Inc.

%{
properties
     %IsID Whether this attribute is an ID attribute
     %    The value of this property is true if this attribute is an ID
     %    attribute.
     IsID;

     %Name Name of this attribute
     %    Name of this attribute specified as a character vector
     Name;

     %Value Value of this attribute
     %    Value of this attribute specified as a character vector
     Value;
end
%}