%createAttributeNS Create an attribute in a namespace
%    attr = createAttributeNS(thisDoc,namespaceURI,qualifiedName) creates
%    an attribute with the specified qualified name in the specified
%    namespace. This method returns an Attr object with the following
%    values returned by property getter functions:
%
%    Getter             Returns
%    ----------------------------------------------------------------------
%    getNodeName        qualified name
%    getNamespaceURI    namespaceURI
%    getPrefix          prefix, extracted from qualified name, 
%                       or null if there is no prefix
%    getLocalName       local name, extracted from qualified name
%    getName            qualified name
%    getNodeValue       empty string
%
%    See also matlab.io.xml.dom.Attr, 
%    matlab.io.xml.dom.Document.createAttributeNS

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.