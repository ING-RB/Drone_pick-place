%matlab.io.xml.dom.ResourceIdentifier XML resource identifier
%   Identifies the type of resource to be identified by an entity
%   resolver.
%
%   ResourceIdentifier methods:
%       getLocator                - Get location of an entity reference
%       getResourceIdentifierType - get identifier type
%
%   ResourceIdentifier properties:
%       PublicID       - Resource public ID
%       SystemID       - Resource system ID
%       SchemaLocation - Resource schema location
%       Namespace      - Resource namespace
%       BaseURI        - Base URI of resource
%
%   See also matlab.io.xml.dom.EntityResolver

%   Copyright 2020-2021 MathWorks, Inc.
%   Built-in class

%{
properties
    %PublicID Public ID of resource to be resolved
    PublicID;

    %SystemID System ID of resource to be resolved
    SystemID;

    %SchemaLocation Location of schema with entities to be resolved
    SchemaLocation;

    %Namespace URI of namespace of entities to be resolved
    Namespace;

    %BaseURI Base URI of resource
    BaseURI;

end
%}

