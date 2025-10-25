classdef OpaqueTypeDefinition < handle & matlab.mixin.CustomDisplay
    % OpaqueTypeDefinition MATLAB definition of a C++ opaque type
    % This class contains the MATLAB definition for a C++ opaque type present in the header
    % OpaqueTypeDefinition properties:
    %   Description         - Description of the opaque type as provided by the publisher
    %   MATLABName          - Name of the C++ opaque type in MATLAB
    %   CPPSignature        - C++ signature of the opaque type in C++ header
    %   DefiningLibrary     - Library containing the opaque type
    %   DetailedDescription - Detailed description of the opaque type as provided by the publisher
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties(Access=public)
        Description         string
        DetailedDescription string
    end
    properties(SetAccess=private)
        MATLABName      string
        CPPSignature         string
    end
    properties(SetAccess=private, WeakHandle)
        DefiningLibrary clibgen.LibraryDefinition
    end
    properties(Access=?clibgen.LibraryDefinition)
        OpaqueTypeInterface         internal.mwAnnotation.OpaqueTypeAnnotation
    end
    methods(Access=?clibgen.LibraryDefinition)
        function obj = OpaqueTypeDefinition(libraryDef, CPPSignature, opaqueTypeInterface, mlName, description, detailedDescription)
            p = inputParser;
            addRequired(p,'libraryDefintion',@(x)(isa(x,"clibgen.LibraryDefinition")));
            addRequired(p,'CPPSignature',@(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addRequired(p,'mlname', @(x)validateattributes(x, {'char','string'},{'scalartext', 'nonempty'}));
            addRequired(p,'Description', @(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addParameter(p,'DetailedDescription',"",@(x)validateattributes(x, {'char','string'},{'scalartext'}));
            p.KeepUnmatched = false;
            parse(p,libraryDef,CPPSignature,mlName,description);
            obj.DefiningLibrary = libraryDef;
            obj.CPPSignature = string(CPPSignature);
            obj.OpaqueTypeInterface = opaqueTypeInterface;
            obj.MATLABName = string(mlName);
            obj.Description = description;
            obj.DetailedDescription = detailedDescription;
        end
    end
    
    methods
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            obj.Description = desc;
            obj.OpaqueTypeInterface.opaqueTypeData.description = desc;
        end

        function set.DetailedDescription(obj, details)
            validateattributes(details,{'char','string'},{'scalartext'});
            obj.DetailedDescription = details;
            obj.OpaqueTypeInterface.opaqueTypeData.detailedDescription = details; 
        end
    end
end
