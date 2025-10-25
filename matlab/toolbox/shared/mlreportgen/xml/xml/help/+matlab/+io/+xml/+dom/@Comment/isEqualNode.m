%isEqualNode Check whether this comment equals another.
%    tf = isEqualNode(thisComment,otherNode) returns true if this comment 
%    is equal to the other comment; otherwise, false. 
%        
%    This method tests for equality of comments, not sameness (i.e.,
%    whether the two comments are handles to the same object). Use the
%    method isSameNode to test for sameness. All nodes that are the same
%    are also equal, though the reverse may not be true.
%
%    This comment equals the other comment if they have the same text
%    content.
%
%    matlab.io.xml.dom.Comment.isSameNode

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.