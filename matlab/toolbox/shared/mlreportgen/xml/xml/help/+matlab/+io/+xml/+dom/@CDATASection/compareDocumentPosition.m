%compareDocumentPosition Compare relative position of this CDATASection node
%    posEnum = compareDocumentPosition(CDATASection,otherNode) compares the
%    position in the document of this CDATASection node with that of
%    another node. Returns a double value that encodes the position of the
%    other node relative to this section node. Use the following MATLAB
%    expression to decode the position result:
%
%    bitor(POS,POSITION_ENUM) == POS
%
%    where POS is the value returned by this method and POSITION_ENUM is
%    the value returned by one of the following CDATASection node methods:
%
%    DOCUMENT_POSITION_FOLLOWING    The other node follows this node.
%    DOCUMENT_POSITION_PRECEDING    The other node precedes this node
%    DOCUMENT_POSITION_CONTAINED_BY This section node contains the other 
%                                   node, which also follows this node.
%    DOCUMENT_POSITION_CONTAINS     The other node contains this
%                                   node.The other node precedes this node.
%    DOCUMENT_POSITION_DISCONNECTED The two nodes are disconnected.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = Document("root");
%    root = getDocumentElement(d);
%    cds = createCDATASection(d,'x > 1 | x < 2');
%    appendChild(root,cds);
%    pos = compareDocumentPosition(cds,root);
%    if bitor(pos,cds.DOCUMENT_POSITION_CONTAINS) == pos
%       disp("root contains CDATA section");
%    else
%       disp("root does not contain CDATA section");
%    end

%    Copyright 2021 MathWorks, Inc.
%    Built-in function.