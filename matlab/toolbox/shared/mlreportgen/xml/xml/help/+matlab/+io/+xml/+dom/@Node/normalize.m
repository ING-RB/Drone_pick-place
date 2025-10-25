%normalize Normalize text content of a node
%    normalize(thisNode) removes empty text nodes from this node and
%    combines adjacent text nodes in a a single text node. This ensures that
%    the node has the same structure that it would have after saving and
%    reloading the document in which it resides.
%
%    See also matlab.io.xml.dom.Document.normalizeDocument

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.