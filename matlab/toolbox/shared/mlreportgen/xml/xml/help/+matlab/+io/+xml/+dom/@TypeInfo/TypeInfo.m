%matlab.io.xml.dom.TypeInfo Information on a schema type
%   An instance of this class specifies the name, namespace, and 
%   derivation of an element or attribute type defined by a schema.
%
%   TypeInfo methods:
%       getTypeName      - Get name of schema type
%       getTypeNamespace - Get namespace of schema type
%       isDerivedFrom    - Whether this type is derived from another type
%
%    TypeInfo properties:
%       TypeName      - Name of this schema type
%       TypeNamespace - Namespace of this schema type
%
%    See also matlab.io.xml.dom.Element.getSchemaTypeInfo,
%    matlab.io.xml.dom.Attr.getSchemaTypeInfo

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %TypeName Name of this type
     %    The value of this read-only property is a character vector that
     %    specifies the name of this type.
     TypeName;

     %TypeNamespace Namespace of this type
     %    The value of this read-only property is a character vector that
     %    specifies the namespace of this type.
     TypeNamespace;
end
%}