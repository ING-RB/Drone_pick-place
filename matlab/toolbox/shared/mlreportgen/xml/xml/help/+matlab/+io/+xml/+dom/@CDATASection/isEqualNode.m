%isEqualNode Check whether this CDATA section equals another.
%    tf = isEqualNode(thisCDATASection,otherNode) returns true if this
%    CDATA section is equal to the other CDATA section; otherwise, false.
%        
%    This method tests for equality of CDATA sections, not sameness (i.e.,
%    whether the two CDATA sections are handles to the same object). Use
%    the method isSameNode to test for sameness. All nodes that are the
%    same are also equal, though the reverse may not be true.
%
%    This CDATA section equals the other CDATA section if they have the
%    same content.
%
%    matlab.io.xml.dom.CDATASection.isSameNode

%    Copyright 2021 MathWorks, Inc.
%    Built-in function.