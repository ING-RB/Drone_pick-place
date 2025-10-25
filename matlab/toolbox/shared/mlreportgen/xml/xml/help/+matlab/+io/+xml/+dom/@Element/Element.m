%matlab.io.xml.dom.Element Element of an XML document
%    An Element object is an in-memory representation of an XML markup tag.
%    
%    Element methods:
%        appendChild               - Append a child to this element
%        cloneNode                 - Copy this element
%        compareDocumentPosition   - Get relative position of this element
%        getAttribute              - Get attribute value
%        getAttributeNode          - Get attribute object
%        getAttributeNodeNS        - Get attribute object by qualifed name
%        getAttributeNS            - Get attribute value by qualified name
%        getAttributes             - Get attributes of this element
%        getBaseURI                - Get base URI of this element
%        getChildElementCount      - Get number of elements in this element
%        getChildNodes             - Get children of the element
%        getChildren               - Get array of element's children
%        getChildren               - Get element's children
%        getElementsByTagName      - Get element children by tag name
%        getElementsByTagNameNS    - Get element children by qualified name
%        getFirstChild             - Get first child node of this element
%        getFirstElementChild      - Get first child element of this element
%        getLastChild              - Get last child node of this element 
%        getLastElementChild       - Get last child element of this element
%        getLocalName              - Get local name of this element
%        getNamespaceURI           - Get namespace containing this element
%        getNextSibling            - Get node that follows this node
%        getNextElementSibling     - Get element that follows this element
%        getNodeIndex              - Get element node index
%        getNodeName               - Get node name of element
%        getNodeType               - Get node type of element
%        getNodeTypeName           - Get type name of element node
%        getPositionTypeName       - Get name of an element position type
%        getNodeValue              - Get node value of element
%        getOwnerDocument          - Get document that owns this element
%        getParentNode             - Get parent of element
%        getPositionTypeName       - Get name of a position type
%        getPrefix                 - Get prefix of element name
%        getPreviousSibling        - Get previous node
%        getPreviousElementSibling - Get preceding element
%        getSchemaTypeInfo         - Get schema-defined element type
%        getTagName                - Get element tag name
%        getTextContent            - Get element text content
%        hasAttribute              - Whether element has an attribute
%        hasAttributeNS            - Whether element has a namespaced attribute
%        hasAttributes             - Whether element has attributes
%        hasChildNodes             - Whether element has children
%        isDefaultNamespace        - Whether namespace is element's default namespace
%        isEqualNode               - Whether this element equals another
%        isSameNode                - Whether this element is the same as another
%        lookupNamespaceURI        - Search element for a prefix namespace
%        lookupPrefix              - Search element for a namespace prefix 
%        normalize                 - Normalize this element
%        removeAttribute           - Remove attribute by name
%        removeAttributeNode       - Remove attribute by object
%        removeAttributeNS         - Remove attribute by namespace
%        removeChild               - Remove a child of this element
%        replaceChild              - Replace a child of this element
%        setAttribute              - Set value of existing attribute
%        setAttributeNode          - Add or replace attribute
%        setAttributeNodeNS        - Add or replace attribute with namespace
%        setAttributeNS            - Set value of existing namespaced attribute
%        setIDAttribute            - Designate attribute as an ID
%        setIDAttributeNode        - Designate attribute object as an ID
%        setIDAttributeNS          - Designate namespaced attribute as an ID
%        setNodeValue              - Set node value of this element
%        setTextContent            - Set text content of this element
%
%    Element properties:
%        Children      - Children of this element
%        HasAttributes - Whether this element has attributes
%        TagName       - Tag name of this element
%        TextContent   - Text content of this element

%    Copyright 2020-2021 MathWorks, Inc.

%{
properties
     %TagName Tag name of this element
     %    The value of this read-only property is a character vector that
     %    designates the tag name of this element.
     TagName;

     %HasAttributes Whether this node has attributes
     %    This read-only property is set to true (1) if this element has
     %    attributes.
     HasAttributes;
end
%}