%matlab.io.xml.dom.Notation Document type notation
%   Defines a notation included in a document type definition (DTD). A
%   notation defines the format of an image file or other file that is
%   included in a document but is not parsed. A notation can also provide a
%   formal definition of a target of a processing instruction included in
%   a document that conforms to the document type. Notations are intended
%   to facilitate processing of instances of the document type.
%
%   Notation methods:
%       getNodeName    - Get notation name
%       getPublicID    - Get notation public ID
%       getSystemID    - Get notation system ID
%
%    Notation properties:
%       PublicID      - Public ID of notation
%       SystemID      - System ID of notation
%
%    Note: a notation object inherits node methods and properties that do
%    not apply to notations and hence are ineffective or throw errors. Use
%    only notation methods and properties defined in this help file.
%
%    See also matlab.io.xml.dom.Entity

%    Copyright 2020 MathWorks, Inc.
%    Built-in class

%{
properties
     %PublicID Public ID of notation
     PublicID;

     %SystemID System ID of notation
     SystemID;

end
%}