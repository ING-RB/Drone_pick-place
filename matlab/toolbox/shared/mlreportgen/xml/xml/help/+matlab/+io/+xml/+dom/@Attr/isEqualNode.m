%isEqualNode Check whether this attribute node equals another.
%    tf = isEqualNode(thisAttr,otherNode) returns true if this attribute 
%    is equal to the other node; otherwise, false. 
%        
%    This method tests for equality of attribute nodes, not sameness (i.e.,
%    whether the two attribute nodes are handles to the same object). Use
%    the method isSameNode to test for sameness. All nodes that are the
%    same are also equal, though the reverse may not be true.
%
%    matlab.io.xml.dom.Attr.isSameNode

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.