%matlab.io.xml.dom.DocumentType Defines a document type.
%   A document's getDoctype method returns an object of this type if 
%   the document was created by a parser from XML markup that contains
%   a document type definition (DTD).
%
%   Note: a document type object inherits node methods and properties that
%   do not apply to document types and hence are ineffective or throw
%   errors. Use only documented document type methods and properties with
%   document type objects.
%
%   DocumentType methods:
%       getName           - Get the DTD name
%       getEntities       - Get entities defined by DTD
%       getNotations      - Get DTD notations
%       getPublicID       - Get public ID of document type
%       getSystemID       - Get system ID of document type
%       getInternalSubset - Return locally defined entities and notations
%
%   DocumentType properties:
%       Name           - DTD name
%       PublicID       - DTD public ID
%       SystemID       - DTD system ID
%       InternalSubset - Locally defined entities and notations

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %Name Document type name
     Name;

     %PublicID Public ID of document type
     PublicID;
     
     %PublicID System ID of document type
     SystemID;
     
     %InternalSubset Entities defined in document DTD expression
     InternalSubset;

end
%}