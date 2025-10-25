%renameNode Rename an element or attribute
%    renamedNode = renameNode(thisDoc,node,namespaceURI,name) renames and
%    returns the specified node. The node argument must specify an Element
%    or Attr node. The renamed node has the name specified by the name
%    argument, which may be a string or character array, and may include a
%    prefix. The namespaceURI argument may be a string scalar or character
%    vector. If it is not empty, the renamed node resides in the
%    namespace that it specifies.
%
%    See also matlab.io.xml.dom.Element, matlab.io.xml.dom.Attr

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.