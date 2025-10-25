classdef FunctionTypeDefinition < handle
    % FunctionTypeDefinition MATLAB definition of a function type
    % This class contains the MATLAB definition for a C++ function type present in the header
    % FunctionTypeDefinition properties:
    %   Description         - Description of the function type as provided by the publisher

    % Copyright 2020-2024 The MathWorks, Inc.
    properties(Access=public)
        Description         string
    end
    properties(SetAccess=private)
        CPPSignature    string
        MATLABName      string
    end
    properties(SetAccess=private, WeakHandle)
        DefiningLibrary clibgen.LibraryDefinition
    end
    properties(Access=private)
        FunctionTypeAnnotation   internal.mwAnnotation.FunctionTypeAnnotation
    end

    methods(Access=?clibgen.LibraryDefinition)
        function obj = FunctionTypeDefinition(libraryDef, cppSignature, mlName, functionTypeAnnotation, description)
            parser = inputParser;
            addRequired(parser, "LibraryDefinition", @(x) (isa(x, "clibgen.LibraryDefinition")));
            addRequired(parser, "CPPSignature",      @(x) validateattributes(x, {'char','string'},{'scalartext', 'nonempty'}));
            addRequired(parser, "MATLABName",        @(x)validateattributes(x, {'char','string'},{'scalartext', 'nonempty'}));
            addRequired(parser, "FunctionTypeAnnotation",  @(x) isa(x, "internal.mwAnnotation.FunctionTypeAnnotation"));
            addRequired(parser, "Description",       @(x) validateattributes(x, {'char','string'},{'scalartext'}));
            parser.KeepUnmatched = false;
            parse(parser, libraryDef, cppSignature, mlName, functionTypeAnnotation, description);
            obj.DefiningLibrary = libraryDef;
            obj.CPPSignature = cppSignature;
            obj.MATLABName = mlName;
            obj.FunctionTypeAnnotation = functionTypeAnnotation;
            obj.Description = description;
            obj.FunctionTypeAnnotation.name = obj.MATLABName; % for renaming support
        end

        function addToLibrary(obj)
            obj.FunctionTypeAnnotation.integrationStatus.inInterface = true;

            if (obj.FunctionTypeAnnotation.fcnTypeKind == internal.mwAnnotation.FunctionTypeKind.CFunctionPtr)
                matchingFunctionsMap = obj.DefiningLibrary.MatchingFunctionsForCFunctionPtr;
            else
                matchingFunctionsMap = obj.DefiningLibrary.MatchingFunctionsForStdFunction;
            end

            % find matching functions
            cppSignatureFcnType = string(obj.FunctionTypeAnnotation.cppSignatureFcnType);
            if not(matchingFunctionsMap.isKey(cppSignatureFcnType))
                matchingFcns = [];

                if (obj.FunctionTypeAnnotation.fcnTypeKind == internal.mwAnnotation.FunctionTypeKind.CFunctionPtr)
                    for fcnInfo = obj.DefiningLibrary.AvailableFunctionsMap.keys
                        fcnCppSignatures = obj.DefiningLibrary.AvailableFunctionsMap(fcnInfo{:});
                        % for overloads, more than one function is mapped to same MATLAB name, 
                        % in that case, iterate through all fcnCppSignatures to find the matching function
                        % for C function ptr
                        for fcnCppSignature = fcnCppSignatures
                            if (fcnCppSignature == cppSignatureFcnType)
                                if isempty(matchingFcns)
                                    matchingFcns = strcat("@",fcnInfo{:});
                                else
                                    matchingFcns(end+1) = strcat("@",fcnInfo{:});
                                end
                                break; % only one function cppSignature among the overloads can be a matching function
                            end
                        end
                    end
                else % find matching functions for std::function type
                    for fcnInfo = obj.DefiningLibrary.AvailableFunctionsMap.keys
                        fcnCppSignatures = obj.DefiningLibrary.AvailableFunctionsMap(fcnInfo{:});
                        % find matching function for std::function only if fcnInfo don't have overloads
                        if length(fcnCppSignatures) == 1 && (fcnCppSignatures == cppSignatureFcnType)
                            if isempty(matchingFcns)
                                matchingFcns = strcat("@",fcnInfo{:});
                            else
                                matchingFcns(end+1) = strcat("@",fcnInfo{:});
                            end
                        end
                    end
                end
                matchingFunctionsMap(cppSignatureFcnType) = matchingFcns;
            end

            % add matching functions to the annotation
            matchingFcns = matchingFunctionsMap(cppSignatureFcnType);
            obj.FunctionTypeAnnotation.matchingFunctions.clear;
            for matchingFcn = matchingFcns
                obj.FunctionTypeAnnotation.matchingFunctions.add(matchingFcn);
            end
        end
    end

    methods
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            obj.Description = desc;
            obj.FunctionTypeAnnotation.description = desc;%#ok<MCSUP>
        end
    end
end
