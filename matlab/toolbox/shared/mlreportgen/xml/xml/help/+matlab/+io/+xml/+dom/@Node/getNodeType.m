%getNodeType Get the type of this node
%    type = getNodeType(thisNode) returns an integer value that indicates
%    the type of this node. The integer value is equal to one of the
%    following hidden properties of this node:
%
%    ATTRIBUTE_NODE
%    CDATSA_SECTION_NODE
%    COMMENT_NODE
%    DOCUMENT_NODE
%    DOCUMENT_FRAGMENT_NODE
%    DOCUMENT_TYPE_NODE
%    ELEMENT_NODE
%    ENTITY_NODE
%    ENTITY_REFERENCE_NODE
%    NOTATION_NODE
%    PROCESSING_INSTRUCTION_NODE
%    TEXT_NODE
%
%    Use the hidden properties to determine the type of this node.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = Document('book');
%    node = getDocumentElement(d);
%    if getNodeType(node) == node.ELEMENT_NODE
%        fprintf('%s is an element.\n',getNodeName(node));
%    end
%
%    Note: this method is provided for backward compatibility with 
%    existing MATLAB code originally based on the Java API for XML
%    Processing (JAXP). Use isa in new MATLAB code to determine node type.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = Document('book');
%    node = getDocumentElement(d);
%    if isa(node,'matlab.io.xml.dom.Element')
%        fprintf('%s is an element.\n',getNodeName(node));
%    end   
%
%    See also isa

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.