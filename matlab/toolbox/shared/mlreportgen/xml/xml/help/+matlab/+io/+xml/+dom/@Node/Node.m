%matlab.io.xml.dom.Node Defines a node of an XML document
%   The W3C XML DocumentObject Model (DOM) defines an XML
%   document as a tree of nodes of various types. This class defines
%   methods and properties common to all node types. You can invoke these
%   methods on instances of specific types of nodes, such as Element
%   or Text nodes.
%
%   Node methods:
%       appendChild               - Append child to this node
%       cloneNode                 - Copy this node
%       compareDocumentPosition   - Compare node's position
%       getAttributes             - Get node's attributes
%       getChildNodes             - Get node's children
%       getChildren               - Get array of node's children
%       getChildren               - Get node's children
%       getFirstChild             - Get node's first child
%       getLastChild              - Get node's last child
%       getLength                 - Get number of node child nodes
%       getLocalName              - Get unqualified name of node
%       getNamespaceURI           - Get node namespace URI
%       getNextSibling            - Get node's next sibling
%       getNodeName               - Get node's node name
%       getNodeType               - Get node's node type
%       getNodeValue              - Get node's node value
%       getOwnerDocument          - Get node's owner document
%       getParentNode             - Get node's parent
%       getPositionTypeName       - Get name of a position type
%       getPrefix                 - Get node name's prefix
%       getPreviousSibling        - Get previous sibling
%       getTextContent            - Get node's text content
%       hasAttributes             - Whether node has attributes
%       hasChildNodes             - Whether node has children
%       insertBefore              - Insert a node in this node
%       isDefaultNamespace        - Whether namespace is node default
%       isEqualNode               - Whether this node equals another
%       isSameNode                - Whether node is same as other node
%       lookupNamespaceURI        - Find namespace URI for prefix
%       lookupPrefix              - Find prefix for namespace
%       normalize                 - Normalize node
%       removeChild               - Remove node child
%       replaceChild              - Replace node child
%       setNodeValue              - Set node's node value
%       setPrefix                 - Set node name's prefix
%       setTextContent            - Set node's text content
%
%    Node properties:
%       Children                       - Children of this node 
%       TextContent                    - Text content of node

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %TextContent Text content of this node
     %    This read-only property contains the concatenated textual 
     %    content of this node and its  children.
     TextContent;

     %Children Children of this node
     %    The value of this read-only property is a vector of this
     %    node's children
     Children;

end
%}