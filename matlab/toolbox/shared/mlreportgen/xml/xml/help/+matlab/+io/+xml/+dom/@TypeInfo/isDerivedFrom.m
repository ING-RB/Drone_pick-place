%isDerivedFrom Whether this type is derived from another type
%    tf = isDerivedFrom(thisTypeInfo,otherTypeNamespace,otherTypeName, ...
%    derivationMethod) returns true if another type with the specified 
%    namespace and name is derived from this type by the specified
%    derivation method. The derivation method argument is a double value
%    that indicates the derivation method. The argument must be one of 
%    the values returned by the TypeInfo static methods:
%
%        * matlab.io.xml.dom.TypeInfo.DERIVATION_RESTRICTION
%        * matlab.io.xml.dom.TypeInfo.DERIVATION_EXTENSION
%        * matlab.io.xml.dom.TypeInfo.DERIVATION_UNION
%        * matlab.io.xml.dom.TypeInfo.DERIVATION_LIST
%
%    See also matlab.io.xml.dom.TypeInfo

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.