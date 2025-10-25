%compareDocumentPosition Compare relative position of this text node
%    posEnum = compareDocumentPosition(textNode,otherNode) compares the
%    position in the document of this text node with that of another node.
%    Returns a double value that encodes the position of the
%    other node relative to this text node. Use the following MATLAB
%    expression to decode the position result:
%
%    bitor(POS,POSITION_ENUM) == POS
%
%    where POS is the value returned by this method and POSITION_ENUM is
%    the value returned by one of the following text node methods:
%
%    DOCUMENT_POSITION_FOLLOWING    The other node follows this node.
%    DOCUMENT_POSITION_PRECEDING    The other node precedes this node
%    DOCUMENT_POSITION_CONTAINED_BY This text node contains the other 
%                                   node, which also follows this node.
%    DOCUMENT_POSITION_CONTAINS     The other node contains this text
%                                   node.The other node precedes this node.
%    DOCUMENT_POSITION_DISCONNECTED The two nodes are disconnected.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = Document("root");
%    root = getDocumentElement(d);
%    text = createTextNode(d,"Hello");
%    appendChild(root,text);
%    pos = compareDocumentPosition(text,root);
%    if bitor(pos,text.DOCUMENT_POSITION_CONTAINS) == pos
%       disp("root contains text");
%    else
%       disp("root does not contain text");
%    end

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.