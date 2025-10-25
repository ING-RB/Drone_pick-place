classdef EntityResolver
    %ENTITYRESOLVER Abstract base class for entity resolvers
    %   This class is intended to serve as a base class for deriving
    %   entity resolvers to be used to resolve entity references
    %   encountered by a parser while parsing an XML file or string. You
    %   cannot create an instance of this class because it is abstract.
    %
    %   See also matlab.io.xml.dom.ParserConfiguration,
    %   matlab.io.xml.dom.ResourceResolver
    %
    %   EntityResolver methods:
    %       resolveEntity - Resolve an entity reference
    %
    %   Example
    %
    %       classdef DocbookEntityResolver < matlab.io.xml.dom.EntityResolver
    %           %DOCBOOKENTITYRESOLVER Defines a DocBook external entity
    %           %   obj = DocbookEntityResolver(docDir) creates an entity
    %           %   resolver that resolves Docbook external entities for the 
    %           %   document that resides in docDir.                 
    %           methods              
    %               function res = resolveEntity(obj,ri)
    %                   %resolveEntity Resolve an entity
    %                   %   res = resolveEntity(obj,ri) resolves the external 
    %                   %   entity identified by the specified resource 
    %                   %   identifier.
    %                   import matlab.io.xml.dom.ResourceIdentifierType
    %                   if getResourceIdentifierType(ri) == ResourceIdentifierType.ExternalEntity                   
    %                       if  ri.SystemID == "http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd"
    %                           res = string(fullfile(matlabroot, ...
    %                            '\sys\namespace\docbook\v4\dtd\docbookx.dtd'));
    %                       else
    %                           res = ri.SystemID;
    %                       end
    %                    end
    %               end
    %           end
    %       end
    
    %    Copyright 2020 MathWorks, Inc.
    %    Built-in class
end

