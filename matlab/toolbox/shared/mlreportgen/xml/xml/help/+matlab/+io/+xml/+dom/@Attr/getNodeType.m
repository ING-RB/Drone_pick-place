%getNodeType Get the node type of this attribute
%    type = getNodeType(thisNode) returns 2, a value used by XML APIs to
%    indicate that a node is an attribute node.
%
%    Note: this method is provided for backward compatibility with 
%    existing MATLAB code originally based on the Java API for XML
%    Processing (JAXP). Use isa in new MATLAB code to determine node type.
%
%    See also isa

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.