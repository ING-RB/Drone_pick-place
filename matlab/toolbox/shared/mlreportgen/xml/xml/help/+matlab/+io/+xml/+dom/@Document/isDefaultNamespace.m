%isDefaultNamespace Check whether a namespace is the default
%    tf = isDefaultNamespace(thisDoc,namespaceURI) returns true if the
%    namespace specified by namespaceURI is this document's default
%    namespace.
%
%    Note: a default namespace is a namespace declared without a prefix.
%    All the document's children whose names lack a prefix belong to the
%    default workspace. You can use the
%    Document(namespaceURI,qualifiedName) constructor to declare a default
%    namespace for a document's root element.
%
%    Example
%
%    import matlab.io.xml.dom.*
%    nsURI = "http://my.namespace.org/mybook";
%    d = Document(nsURI,'book');
%    if isDefaultNamespace(d,nsURI)
%        fprintf('"%s" is the default workspace for this document\n',nsURI);
%    end



%    Copyright 2020 MathWorks, Inc.
%    Built-in function.