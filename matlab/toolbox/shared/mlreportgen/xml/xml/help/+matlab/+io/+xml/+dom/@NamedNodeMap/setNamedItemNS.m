%setNamedItemNS Add a namespaced node to a named node map
%    node = setNamedItemNS(thisNodeMap,node) adds a namespaced node
%    to thisNodeMap. This method also adds the namespaced node to the node
%    from which this map was created. This method throws an error if the
%    node to be added belongs to another node.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    d = parseString(Parser,'<person><name/><addr/></person>');
%    person = getDocumentElement(d);
%    name = getFirstChild(person);
%    nnm = getAttributes(name);
%    attr = createAttributeNS(d,'foo','a:age');
%    setNodeValue(attr,'21');
%    setNamedItem(nnm,attr);

%    Copyright 2021 MathWorks, Inc.
%    Built-in function.