%matlab.io.xml.dom.DocumentFragment Defines a group of document nodes
%   A DocumentFragment node serves as a container for a group of document
%   nodes. Appending a document fragment to another node appends the
%   fragment's children but not the fragment itself. Similarly inserting
%   a fragment inserts the children but not the fragment. A fragment does
%   not need to be well-formed XML. For example, a fragment can contain
%   multiple top-level nodes or a single text node.
%
%   DocumentFragment methods:
%       appendChild               - Append child to this fragment
%       child                     - Get child at one-based index
%       cloneNode                 - Copy this fragment
%       compareDocumentPosition   - Compare fragment's position
%       getAttributes             - Get fragment's attributes
%       getChildNodes             - Get fragment's children
%       getChildren               - Get array of fragment's children
%       getFirstChild             - Get fragment's first child
%       getLastChild              - Get fragment's last child
%       getLength                 - Get number of fragment's child nodes
%       getLocalName              - Get unqualified name of node
%       getNamespaceURI           - Get node namespace URI
%       getNextSibling            - Get fragment's next sibling
%       getNodeName               - Get fragment's node name
%       getNodeType               - Get fragment's node type
%       getNodeValue              - Get fragment's node value
%       getOwnerDocument          - Get fragment's owner document
%       getParentNode             - Get fragment's parent
%       getPrefix                 - Get fragment name's prefix
%       getPreviousSibling        - Get previous sibling
%       getTextContent            - Get fragment's text content
%       hasAttributes             - Whether fragment has attributes
%       hasChildNodes             - Whether fragment has children
%       insertBefore              - Insert a node in this fragment
%       isDefaultNamespace        - Whether namespace is fragment default
%       isEqualNode               - Whether fragment equals another node
%       isSameNode                - Whether fragment is same as other node
%       item                      - Get child at zero-based index 
%       lookupNamespaceURI        - Find namespace URI for prefix
%       lookupPrefix              - Find prefix for namespace
%       normalize                 - Normalize fragment
%       removeChild               - Remove fragment child
%       replaceChild              - Replace fragment child
%       setNodeValue              - Set fragment's node value
%       setPrefix                 - Set fragment name's prefix
%       setTextContent            - Set fragment's text content
%
%    DocumentFragment properties:
%       Children                       - Children of this node 
%       TextContent                    - Text content of node

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %TextContent Text content of this fragment
     %    This read-only property contains the concatenated textual 
     %    content of this fragment's children.
     TextContent;

     %Children Children of this fragment
     %    The value of this read-only property is a vector of this
     %    fragment's children
     Children;

end
%}