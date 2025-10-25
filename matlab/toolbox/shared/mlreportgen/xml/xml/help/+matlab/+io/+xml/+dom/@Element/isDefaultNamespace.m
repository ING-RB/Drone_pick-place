%isDefaultNamespace Check whether a namespace is the default
%    tf = isDefaultNamespace(thisElem,namespaceURI) returns true if the
%    namespace specified by namespaceURI is this element's default
%    namespace.
%
%    Note: a default namespace is an element namespace declared without a 
%    prefix. The element and all its children whose names lack a prefix 
%    belong to the default namespace. Use setAttributeNS to declare a
%    default namespace for an element. You can use the 
%    Document(namespaceURI,qualifiedName) constructor
%    to declare a default namespace for a document's root element.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    nsURI = "http://my.namespace.org/mybook";
%    d = Document(nsURI,'book');
%    book = getDocumentElement(d);
%    if isDefaultNamespace(book,nsURI)
%        fprintf('"%s" is the default workspace for this document\n',nsURI);
%    end
%
%    See also matlab.io.xml.dom.Element.setAttributeNS, 
%    matlab.io.xml.dom.Document


%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.