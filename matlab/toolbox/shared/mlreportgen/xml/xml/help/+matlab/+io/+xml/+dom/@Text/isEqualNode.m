%isEqualNode Check whether this text node equals another.
%    tf = isEqualNode(thisText,otherNode) returns true if this text node 
%    is equal to the other text node; otherwise, false. 
%        
%    This method tests for equality of text nodes, not sameness (i.e., 
%    whether the two text nodes are handles to the same object). Use the method
%    isSameNode to test for sameness. All nodes that are the same are
%    also equal, though the reverse may not be true.
%
%    This text node equals the other text node if they have the same 
%    content.
%
%    matlab.io.xml.dom.Text.isSameNode

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.