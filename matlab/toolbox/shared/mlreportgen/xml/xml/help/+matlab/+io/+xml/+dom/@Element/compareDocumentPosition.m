%compareDocumentPosition Compare relative position of this element
%    posEnum = compareDocumentPosition(thisElem,otherNode) compares the
%    position in the document of thisElem with that of another node.
%    Returns a double value that encodes the position of the
%    other node relative to this element node. Use the following MATLAB
%    expression to decode the position result:
%
%    bitor(POS,POSITION_ENUM) == POS
%
%    where POS is the value returned by this method and POSITION_ENUM is
%    the value returned by one of the following element node methods:
%
%    DOCUMENT_POSITION_FOLLOWING    The other node follows this node.
%    DOCUMENT_POSITION_PRECEDING    The other node precedes this node
%    DOCUMENT_POSITION_CONTAINED_BY This element node contains the other 
%                                   node, which also follows this node.
%    DOCUMENT_POSITION_CONTAINS     The other node contains this element
%                                   node.The other node precedes this node.
%    DOCUMENT_POSITION_DISCONNECTED The two nodes are disconnected.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = Document("root");
%    root = getDocumentElement(d);
%    para = createElement(d,"para");
%    appendChild(root,para);
%    pos = compareDocumentPosition(para,root);
%    if bitor(pos,para.DOCUMENT_POSITION_CONTAINS) == pos
%       disp("root contains paragraph");
%    else
%       disp("root does not contain paragraph");
%    end

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.