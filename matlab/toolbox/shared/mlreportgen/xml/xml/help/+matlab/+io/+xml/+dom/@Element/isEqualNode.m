%isEqualNode Check whether two elements are equal
%    tf = isEqualNode(thisElement,otherNode) returns true if this element 
%    is equal to the other node; otherwise, false. 
%        
%    This method tests for equality of nodes, not sameness (i.e., 
%    whether the two nodes are handles to the same object). Use the method
%    isSameNode to test for sameness. All nodes that are the same are
%    also equal, though the reverse may not be true.
%
%    This element equals the other node if the following conditions 
%    are satisfied:
%    
%        * The other node is an Element node
%        * The following string properties are equal: 
%
%           - tag name
%           - prefix
%           - local name
%           - namespace URI
%           - base URI.
%
%          String properties are equal if they have the same length and
%          are character-for-character identical.
%    
%    The following do not affect element equality:
%    
%        * The element's owner document
%        * Attribute values
%
%    Note that normalization can affect equality; to avoid this,
%    nodes should be normalized before being compared.
%
%    See also matlab.io.xml.dom.Node.normalize,
%    matlab.io.xml.dom.Node.isSameNode

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.