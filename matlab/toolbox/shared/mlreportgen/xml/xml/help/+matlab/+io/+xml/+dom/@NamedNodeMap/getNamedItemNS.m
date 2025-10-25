%getNamedItemNS Get a named node map item specified by a prefixed name
%    node = getNamedItemNS(thisNodeMap,uri,name) returns the item
%    specified by a name residing in the namespace specified by the uri
%    input argument. The name argument specifies the local (unprefixed)
%    name of hte node.
%
%    Example
%
%    d = parseString(Parser,'<block xmlns:a="foo" a:color="red"/>');
%    e = getDocumentElement(d);
%    nnm = getAttributes(e);            
%    attr = getNamedItemNS(nnm,'foo','color');

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.