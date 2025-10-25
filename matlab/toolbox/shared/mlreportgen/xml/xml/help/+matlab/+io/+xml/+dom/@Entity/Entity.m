%matlab.io.xml.dom.Entity Entity defined by document type
%   Represents an XML entity. An XML entity is document content that has a
%   name and is defined by a document type definition associated
%   with a document.
%
%   Entity methods:
%       getInputEncoding - Get input encoding
%       getNodeName      - Get entity name
%       getNotationName  - Get name of file entity notation
%       getPublicID      - Get public ID of entity source
%       getSystemID      - Get location of entity source
%       getXMLEncoding   - Get entity's declared encoding
%       getXMLVersion    - Get entity's declared XML version
%
%    Entity properties:
%       InputEncoding - Encoding of entity source document
%       PublicID      - Public ID of entity source document
%       SystemID      - Location of entity source document
%       XMLEncoding   - Encoding specified by source XML declaration
%       XMLVersion    - XML version specified by source XML declaration
%
%    Note: an entity object inherits node methods and properties that do
%    not apply to entities and hence are ineffective or throw errors. Use
%    only entity methods and properties defined in this help file.
%
%    See also matlab.io.xml.dom.DocumentType

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %InputEncoding Encoding used to parse an XML file entity
     %    This read-only property specifies the encoding used to parse the
     %    XML file specified by this entity.
     InputEncoding;

     %PublicID Public ID of entity's source document
     %    This read-only property is set to the public ID specified by
     %    the document type declaration from which this entity was parsed.
     PublicID;

     %SystemID System ID (location) of entity source
     %    This read-only property is set to the location specified by
     %    the document type declaration from which this entity was 
     %    parsed.
     SystemID;

     %XMLEncoding Encoding specified by XML declaration
     %    This read-only property is set to the encoding specified by
     %    the source file's XML declaration.
     XMLEncoding;

     %XMLVersion XML version specified by XML declaration
     %    This read-only property specifies the version of XML used by
     %    the source file from which this entity was parsed.
     XMLVersion;

end
%}