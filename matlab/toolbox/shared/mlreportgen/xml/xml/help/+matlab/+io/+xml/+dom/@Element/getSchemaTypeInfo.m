%getSchemaTypeInfo Get information about element's schema type
%    info = getSchemaTypeInfo(thisElem) returns a TypeInfo object that
%    specifies the name, namespace, and derivation of the schema type
%    that defines this element.
%
%    Note: The TypeInfo object returned by this method contains type
%    information only if the element contains schema type information. An
%    element contains schema information only if the parser that parsed the
%    document containing the element was configured to validate the
%    document against a schema and to save poast-validation schema
%    information (PSVI) in parsed elements and attributes.
%
%    See also matlab.io.xml.dom.TypeInfo,
%    matlab.io.xml.dom.ParserConfiguration

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.