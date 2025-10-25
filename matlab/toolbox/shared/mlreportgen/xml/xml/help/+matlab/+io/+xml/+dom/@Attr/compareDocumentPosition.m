%compareDocumentPosition Compare relative position of this node
%    posEnum = compareDocumentPosition(attrNode,otherNode) compares the
%    position in the document of this attribute with that of another node.
%    Returns a double value that encodes the position of the
%    other node relative to this attribute node. Use the following MATLAB
%    expression to decode the position result:
%
%    bitor(POS,POSITION_ENUM) == POS
%
%    where POS is the value returned by this method and POSITION_ENUM is
%    the value returned by one of the following attribute methods:
%
%    DOCUMENT_POSITION_FOLLOWING    The other node follows this node.
%    DOCUMENT_POSITION_PRECEDING    The other node precedes this node.
%    DOCUMENT_POSITION_CONTAINED_BY The attribute node contains the other 
%                                   node, which also follows this node.
%    DOCUMENT_POSITION_CONTAINS     The other node contains this attribute
%                                   node.The other node precedes this node.
%    DOCUMENT_POSITION_DISCONNECTED The two nodes are disconnected. 
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = Document('root');
%    root = getDocumentElement(d);
%    setAttribute(root,"Color","red");
%    a = getAttributeNode(root,"Color");
%    pos = compareDocumentPosition(a,root);
%    if bitor(pos,a.DOCUMENT_POSITION_CONTAINS) == pos
%        disp("root contains color attribute");
%    else
%        disp("root does not contain color attribute");
%    end

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.