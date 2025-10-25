%matlab.io.xml.dom.Text Text in an XML document
%    A Text object represents the text content of an XML DOM element.
%    
%    Text methods:
%        appendData                  - Append characters
%        cloneNode                   - Copy this text node
%        compareDocumentPosition     - Get relative position of this text
%        deleteData                  - Delete characters
%        getBaseURI                  - Get base URI
%        getData                     - Get characters
%        getLength                   - Get number of characters
%        getNextSibling              - Get node that follows this text
%        getNodeName                 - Get node name of this text node
%        getNodeType                 - Get node type of this text node
%        getNodeTypeName             - Get type name of this text node
%        getPositionTypeName         - Get name of a text position type
%        getNodeValue                - Get node value of this text node
%        getOwnerDocument            - Get document that created this text node
%        getParentNode               - Get parent of this text node
%        getPositionTypeName         - Get name of a position type
%        getPreviousSibling          - Get node previous to this text
%        getTextContent              - Get content of this text node
%        insertData                  - Insert characters
%        isEqualNode                 - Whether this text node equals another
%        isSameNode                  - Whether a node is this node
%        replaceData                 - Replace characters in this text node
%        setData                     - Set text node to specified data
%        setNodeValue                - Set node value of this text node
%        setTextContent              - Set text content of this text node
%        splitText                   - Splits text node into two
%        substringData               - Extracts text from this text node
%
%    Text properties:
%        Length                   - Number of characters in this node
%        TextContent              - Content of this text node

%    Copyright 2020-2021 MathWorks, Inc.

%{
properties
     %Length Number of characters in text
     %    The value of this property is a double that specifies the 
     %    number of characters in this node's text content.
     Length;

     %TextContent Text content of this node
     %    This property specifies the text content of this node as a
     %    character vector.
     TextContent;
end
%}