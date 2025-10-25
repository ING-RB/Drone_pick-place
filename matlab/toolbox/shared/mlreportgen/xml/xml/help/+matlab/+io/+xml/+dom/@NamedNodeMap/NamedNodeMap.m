%matlab.io.xml.dom.NamedNodeMap Set of document nodes with names
%    A NamedNodeMap object contains a set of nodes having names. An object
%    of this type is returned by the getAttributes method of an Element
%    object. You cannot create an instance of a NamedNodeMap yourself.
%
%    Note. Adding or removing an attribute from an element updates the
%    element's named node map. Similarly, adding or removing an attribute
%    from a named node map updates the corresponding element.
%    
%    NamedNodeMap methods:
%        getLength      - Get number of items in list
%        item           - Get a NamedNodeMap item at a zero-based index
%        node           - Get a NamedNodeMap item at a one-based index
%        getNamedItem   - Get an item using its name
%        getNamedItemNS - Get an item having a prefixed name
%        setNamedItem   - Add an item using its name
%        setNamedItemNS - Add an item having a prefixed name
%
%    NamedNodeMap properties:
%        Length       - Number of items in the list
%
%    See also matlab.io.xml.dom.Element.getAttributes

%    Copyright 2020-2021 MathWorks, Inc.

%{
properties
     %Length Number of items in named node list
     Length;
end
%}