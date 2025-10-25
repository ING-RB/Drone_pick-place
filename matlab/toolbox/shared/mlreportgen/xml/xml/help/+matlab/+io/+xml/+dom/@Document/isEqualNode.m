%isEqualNode Check whether a document equals another node
%    tf = isEqualNode(thisDoc,otherNode) returns true if the other node 
%    is a document, has the same base URI, and has an equal subtree. 
%        
%    This method tests for equality of documents, not sameness (i.e.,
%    whether  the two documents are handles to the same object). Use the
%    method isSameNode to test for sameness. All nodes that are the same
%    are also equal, although the reverse may not be true.
%
%    Note that normalization can affect equality; to avoid this,
%    documents should be normalized before being compared.
%
%    See also matlab.io.xml.dom.Node.normalize, 
%    matlab.io.xml.dom.Node.normalizeDocument, 
%    matlab.io.xml.dom.Node.IsSameNode 

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.