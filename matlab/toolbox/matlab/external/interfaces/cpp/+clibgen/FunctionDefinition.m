classdef FunctionDefinition < handle & matlab.mixin.CustomDisplay
    % FunctionDefinition MATLAB definition of a function
    % This class contains the MATLAB definition for a C++ function present in the header
    % FunctionDefinition properties:
    %   Description         - Description of the non-member function as provided by the publisher
    %   DetailedDescription - Detailed description of the non-member function as provided by the publisher

    % Copyright 2018-2024 The MathWorks, Inc.

    properties(Access=public)
        Description         string
        DetailedDescription string
    end
    properties(SetAccess=private)
        CPPSignature      string
        Valid             logical = false
        MATLABName        string
        TemplateUniqueName  string
    end
    properties(SetAccess=private, WeakHandle)
        DefiningLibrary clibgen.LibraryDefinition
    end
    properties(Dependent, SetAccess=private)
        MATLABSignature   string
    end
    properties(GetAccess={?clibgen.LibraryDefinition,?clibgen.MethodDefinition} )
        FunctionInterface   internal.cxxfe.ast.Function
        CombinationCountMultipleMlTypes uint32
    end
    properties(Access=?clibgen.LibraryDefinition)
        NamesForValidation    struct
        MlTypesForValidation struct
        ArgAnnotations      internal.mwAnnotation.Argument
        OutputAnnotation  internal.mwAnnotation.Argument
        OpaqueTypesForValidation struct
    end
    properties(SetAccess=?clibgen.LibraryDefinition,GetAccess={?clibgen.internal.Accessor,...
            ?clibgen.LibraryDefinition, ?clibgen.MethodDefinition})
        Arguments         struct
        Output            struct
    end
    properties(Access=?clibgen.internal.Accessor)
        InputDescriptions struct
        OutputDescription string
    end

    methods(Access=private)
        function annotationDim = convertDimensionInfo(obj, dim)
            if(dim.type == "parameter")
                annotationDim = internal.mwAnnotation.VariableDimension(obj.DefiningLibrary.LibraryInterface.Model);
                annotationDim.lengthVariableName = dim.value;
                annotationDim.cppPosition = dim.CppPosition;
                annotationDim.mwType = dim.MATLABType;
                annotationDim.shape = clibgen.MethodDefinition.getShapeKind(dim.Shape);
                annotationDim.storage = clibgen.MethodDefinition.getStorageKind(dim.Storage);
            elseif(dim.type == "value")
                annotationDim = internal.mwAnnotation.FixedDimension(obj.DefiningLibrary.LibraryInterface.Model);
                annotationDim.value = dim.value;
            end
        end

        function valid = verifyMATLABName(obj, mlname, argname) %#ok<*INUSL>
            valid = true;
            validateattributes(mlname,{'char','string'},{'scalartext', 'nonempty'});
            if ~argname
                splitname = split(string(mlname),'.');
                valid = all(matlab.lang.makeValidName(splitname(1:end)) == splitname);
                if(~valid)
                    error(message('MATLAB:CPP:InvalidName'));
                end
            end
        end
    end
    methods(Access=protected)
        function displayScalarObject(obj)
            try
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                h = sprintf("  " + className + " maps" + "\n\n" + "    C++:    " + obj.CPPSignature + ...
                    "\n" + "    to " + "\n" +                   "    MATLAB: ");
                validate(obj);
                mlSignature = obj.MATLABSignature;
                for i= 1:numel(mlSignature)
                    if (i==numel(mlSignature))
                        h = h + mlSignature{i} ;
                    else
                        h = h + mlSignature{i} + sprintf( "\n            ") ;
                    end
                end
                argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(obj, obj.FunctionInterface);
                if numel(argsFundamental) > 0
                    h = sprintf(h + "\n") + clibgen.LibraryDefinition.formNotNullableNote("      ", argsFundamental);
                end
                disp(h);
            catch ex
                disp(h + "[]");
                fprintf("\n   The function is not valid. " + ex.message + "\n" );
            end
        end
    end
    methods(Access=?clibgen.LibraryDefinition)
        function obj = FunctionDefinition(libraryDef,CPPSignature,functionInterface,mlName,description,detailedDescription,templateUniqName)
            %FunctionDefinition constructor
            %   FCNDEF = FUNCTIONDEFINITION(LIBDEF,CPPSIGNATURE,FUNCTIONINTERFACE,MLNAME,DESCRIPTION,DETAILEDDESCRIPTION,TEMPLATEUNIQNAME)
            %   returns a FUNCTIONDEFINITION object  with C++ Signature CPPSIGNATURE
            %   and MATLAB name MLNAME. FUNCTIONINTERFACE provides an interface
            %   to the function metadata.

            %   This constructor can only be called inside the class
            %   clibgen.LibraryDefinition.
            p = inputParser;
            addRequired(p,'LibraryDefinition',@(x)(isa(x,"clibgen.LibraryDefinition")));
            addRequired(p,'CPPSignature',@(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addRequired(p,'FunctionInterface',@(x)(isa(x,"internal.cxxfe.ast.Function")));
            addRequired(p,'mlName',@(x)verifyMATLABName(obj, x, false));
            addRequired(p,'Description', @(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addParameter(p,'DetailedDescription',"",@(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addParameter(p,'templateUniqName',"",@(x)verifyMATLABName(obj, x, false));
            p.KeepUnmatched = false;
            parse(p,libraryDef,CPPSignature,functionInterface,mlName,description);
            obj.DefiningLibrary    = p.Results.LibraryDefinition;
            obj.FunctionInterface  = functionInterface;
            obj.CPPSignature       = p.Results.CPPSignature;
            obj.MATLABName         = p.Results.mlName;
            annotationsArr = obj.FunctionInterface.Annotations.toArray;
            % Use mlName supplied if it is not empty and different
            % than the annotated value
            if((mlName~="") && ~strcmp(mlName,obj.MATLABName))
                obj.MATLABName = mlName;
                annotationsArr.name = obj.MATLABName;
            end
            % Check if template instantiation of a function
            if ~isempty(annotationsArr.templateInstantiation)
                obj.TemplateUniqueName = annotationsArr.templateInstantiation.templateUniqueName;
                % Use templateUniqName supplied if it is not empty and different
                % than the annotated value
                if((templateUniqName~="") && ~strcmp(templateUniqName,obj.TemplateUniqueName))
                    obj.TemplateUniqueName = templateUniqName;
                    annotationsArr.templateInstantiation.templateUniqueName = obj.TemplateUniqueName;
                end
            end

            % Create input arguments
            obj.ArgAnnotations = annotationsArr.inputs.toArray;

            for i = 1:numel(obj.ArgAnnotations)
                obj.Arguments(i).MATLABName = obj.ArgAnnotations(i).name;
                obj.Arguments(i).MATLABType = obj.ArgAnnotations(i).mwType;
                obj.Arguments(i).cppType = obj.ArgAnnotations(i).cppType;
                obj.Arguments(i).Shape = obj.ArgAnnotations(i).shape;
                obj.Arguments(i).Direction = obj.ArgAnnotations(i).direction;
                obj.Arguments(i).IsDefined = false;
                obj.Arguments(i).Storage = lower(string(obj.ArgAnnotations(i).storage));
                obj.Arguments(i).IsHidden = false;
                obj.Arguments(i).CppPosition = obj.ArgAnnotations(i).cppPosition;
                obj.Arguments(i).Description = "";
                if not(isempty(obj.ArgAnnotations(i).description))
                    obj.Arguments(i).Description = obj.ArgAnnotations(i).description;
                end
                if not(clibgen.MethodDefinition.isFundamental(functionInterface.Params(i).Type))
                    clibgen.MethodDefinition.updateValidType(obj.DefiningLibrary, obj.ArgAnnotations(i));
                end
            end

            % Create output arguments
            obj.OutputAnnotation = annotationsArr.outputs.toArray;
            if not(isempty(obj.OutputAnnotation))
                obj.Output(1).MATLABName = obj.OutputAnnotation.name;
                obj.Output(1).MATLABType = obj.OutputAnnotation.mwType;
                obj.Output(1).Shape = obj.OutputAnnotation.shape;
                obj.Output(1).Direction = obj.OutputAnnotation.direction;
                obj.Output(1).IsDefined = false;
                obj.Output(1).Storage = lower(string(obj.OutputAnnotation.storage));
                obj.Output(1).IsHidden = false;
                obj.Output(1).Description = "";
                if not(isempty(obj.OutputAnnotation.description))
                    obj.Output(1).Description = obj.OutputAnnotation.description;
                end
                if not(clibgen.MethodDefinition.isFundamental(functionInterface.Type.RetType))
                    clibgen.MethodDefinition.updateValidType(obj.DefiningLibrary, obj.OutputAnnotation);
                end
            end
            obj.Description        = description;
            obj.DetailedDescription = detailedDescription;
            opaqueTypeInfoAnnotation = annotationsArr.opaqueTypeInfo;
            if ~(isempty(opaqueTypeInfoAnnotation))
                obj.CombinationCountMultipleMlTypes = opaqueTypeInfoAnnotation.combinationCountMultipleMlTypes;
            else
                opaqueTypeInfoAnnotation = internal.mwAnnotation.OpaqueTypeFunctionInfo(obj.DefiningLibrary.LibraryInterface.Model);
                obj.CombinationCountMultipleMlTypes = opaqueTypeInfoAnnotation.combinationCountMultipleMlTypes;
                annotationsArr.opaqueTypeInfo = opaqueTypeInfoAnnotation;
            end
        end
        function updateDeletePTKey(obj, deletePTKey)
            obj.OutputAnnotation.isOwned = true;
            obj.OutputAnnotation.deleteFcn = deletePTKey;
        end

        function updateArgumentDeletePTKey(obj, deletePTKey, pos)
            obj.ArgAnnotations(pos).isOwned = true;
            obj.ArgAnnotations(pos).deleteFcn = deletePTKey;
        end
    end
    methods
        function defineArgument(obj, name, mltype, varargin)
            try
                obj.Valid = false;
                p = inputParser;
                addRequired(p,"FunctionDefinition", @(x)(isa(x, "clibgen.FunctionDefinition")));
                addRequired(p,"MATLABName",         @(x)verifyMATLABName(obj, x, true));
                addRequired(p,"MATLABType",         @(x)validateattributes(x,{'char', 'string'},{'vector'}));
                addParameter(p,"Description","",    @(x)validateattributes(x, {'char','string'},{'scalartext'}));
                addParameter(p, "AddTrailingSingletons", false, @(x) validateattributes(x, {'logical'},{'scalar'}))
                parse(p,obj, name, mltype);
                numvarargin = numel(varargin);
                argAnnotation = [];
                name = string(name);
                for annotation = obj.ArgAnnotations
                    if(annotation.name == name)
                        argAnnotation = annotation;
                        argPos = argAnnotation.cppPosition;
                    end
                end
                if(isempty(argAnnotation))
                    error(message("MATLAB:CPP:ArgumentNotFound",name,obj.CPPSignature));
                end
                args = obj.FunctionInterface.Params.toArray;
                argType = args(argPos).Type;
                isVoidPtr = clibgen.MethodDefinition.isVoidPtrType(argAnnotation.cppType);
                isDoubleVoidPtr = clibgen.MethodDefinition.isDoubleVoidPtrType(argAnnotation.cppType);
                isComplex = argAnnotation.isComplex;
                validMlTypes = argAnnotation.validTypes.toArray;
                % Add mlType if needed
                if (isVoidPtr)
                    clibgen.MethodDefinition.verifyVoidPtr(obj, mltype, name, argAnnotation,...
                        obj.DefiningLibrary, argPos);
                elseif (isDoubleVoidPtr)
                    clibgen.MethodDefinition.verifyVoidDoublePtr(obj, mltype, name, ...
                        argAnnotation, obj.DefiningLibrary);
                else
                    %check if the MLType contains a list for non-void* input
                    if (class(mltype) == "string" && (numel(mltype) > 1))
                        error(message('MATLAB:CPP:InvalidMATLABTypeForNonVoidPtrArgument',name));
                    end
                    validMlTypesToShow = clibgen.MethodDefinition.convertUIMlTypeArray(validMlTypes);
                    [found, location] = ismember(mltype, validMlTypesToShow);
                    if ~found
                        if(numel(validMlTypesToShow)==1)
                            error(message('MATLAB:CPP:InvalidArgumentType',name,string(validMlTypesToShow)));
                        else
                            error(message('MATLAB:CPP:InvalidArgumentTypeMultiple',name,join(string(validMlTypesToShow),""", """)))
                        end
                    end
                    argAnnotation.mwType = validMlTypes{location};
                end
    
                argument.MATLABName = name;
                argument.MATLABType = string(p.Results.MATLABType);
                argument.ReleaseOnCall = false;
                argument.Description = "";
                argument.AddTrailingSingletons = false;
    
                obj.Arguments(argPos).DeleteFcnPair = [];
    
                % Get description, releaseOnCall options from name value pair varargin
                % search from the end.
                offset = 0;
                if (numvarargin >= 2)
                    for ind=numvarargin:-2:2
                        %Switch case for matching parameter for the name-value pairs.
                        switch string(varargin{ind-1})
                            case {"Description", "ReleaseOnCall", "NumElementsInBuffer", ...
                                    "DeleteFcn", "AddTrailingSingletons"}
                                offset = offset + 2;
                            otherwise
                                if(ind>2)
                                    %This must be an unmatched parameter
                                    error(message('MATLAB:InputParser:UnmatchedParameter', string(varargin{ind-1}), ...
                                        "For a list of valid name-value pair arguments, see the documentation for defineArgument."));
                                else
                                    % All the name-value pairs have been counted.
                                    break;
                                end
                        end
                    end
                end
    
                % process positional arguments
                switch(numvarargin - offset)
                    case 0
                        if not(argAnnotation.storage==internal.mwAnnotation.StorageKind.Value) && ...
                                not(argAnnotation.storage==internal.mwAnnotation.StorageKind.SharedPtr && ...
                                argAnnotation.outerStorage(1)==internal.mwAnnotation.StorageKind.Value) && ...
                                not(argAnnotation.storage==internal.mwAnnotation.StorageKind.Vector) && ...
                                not(argAnnotation.storage==internal.mwAnnotation.StorageKind.CFunctionPtr) && ...
                                not(argAnnotation.storage==internal.mwAnnotation.StorageKind.StdFunction)
                            error(message('MATLAB:CPP:DirectionAbsent', name));
                        end
                        argument.Direction = "input";
                        argument.Shape = argAnnotation.shape;
                    case 1
                        if(argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer|| ...
                                argAnnotation.storage==internal.mwAnnotation.StorageKind.Array)
                            error(message('MATLAB:CPP:ShapeAbsent', name));
                        end
                        clibgen.MethodDefinition.verifyDirection(varargin{1}, argAnnotation, argType, "function");
                        argument.Direction = string(varargin{1});
                        argument.Shape = argAnnotation.shape;
                    case 2
                        clibgen.MethodDefinition.verifyDirection(varargin{1}, argAnnotation, argType, "function");
                        argument.Direction = string(varargin{1});
                        clibgen.MethodDefinition.verifyShape(obj.FunctionInterface, argAnnotation, varargin{2}, argType, false);
                        argument.Shape = convertCharsToStrings(varargin{2});
                end
    
                % process name-value pairs
                for ind=(numvarargin - offset + 1):2:numvarargin
                    %Switch case to handle the name-value pairs. Each case
                    %handles 1 name-value supplied as input.
                    switch(string(varargin{ind}))
                        case "Description"
                            %Set Description
                            argument.Description = string(varargin{ind+1});
                            argAnnotation.description = argument.Description;
                        case "ReleaseOnCall"
                            % Set ReleaseOnCall
                            validateattributes(varargin{ind+1},{'logical'},{'scalar'});
                            argument.ReleaseOnCall = varargin{ind+1};
                            argAnnotation.releaseOnCall = varargin{ind+1};
                            if ((not(argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer || ...
                                    argAnnotation.storage==internal.mwAnnotation.StorageKind.Reference) || ...
                                    clibgen.MethodDefinition.isFundamental(argType))  && ...
                                    argument.ReleaseOnCall)
                                error(message('MATLAB:CPP:CannotReleaseValue', argument.MATLABName));
                            end
                            %Disallow ReleaseOnCall for void** and obj**
                            %scalar output
                            if(argument.Direction == "output" && ...
                                    argument.ReleaseOnCall == true)
                                error(message('MATLAB:CPP:CannotSpecifyReleaseOnCall', argument.MATLABName));
                            end
                        case "NumElementsInBuffer"
                            if argument.Direction ~= "output" || ...
                                    argument.MATLABType ~= "string"
                                error(message('MATLAB:CPP:BufferSizeNotAllowed'));
                            end
                            bufferSize = varargin{ind+1};
                            clibgen.MethodDefinition.verifyNumElementsInBuffer(obj.FunctionInterface, argAnnotation, bufferSize);
                            argument.BufferSize = convertCharsToStrings(bufferSize);
                        case "DeleteFcn"
                            if (argAnnotation.isConstData)
                                error(message('MATLAB:CPP:CannotDeleteConst'));
                            end
                            % Allow DeleteFcn only for void** and obj**
                            % arguments
                            if(clibgen.MethodDefinition.isDoublePointer(argType) && (isDoubleVoidPtr || isStructType(argType.Type.Type)))
                                validateattributes(varargin{ind+1},{'clibgen.FunctionDefinition','char','string'},{'nonempty'} );
                                deleteFcnName = varargin{ind+1};
                                if(isa(varargin{ind+1}, 'clibgen.FunctionDefinition'))
                                    deleteFcnName = varargin{ind+1}.CPPSignature;
                                else
                                    deleteFcnName = string(varargin{ind+1});
                                end
                                obj.Arguments(argPos).DeleteFcnPair = deleteFcnName;
                                % For mltype="struct", store the validMlTypes
                                if and(~isempty(validMlTypes),find(contains(validMlTypes,"struct")))
                                    index = 2;
                                    for matlabType = validMlTypes
                                        obj.Arguments(argPos).DeleteFcnPair(index) = string(matlabType);
                                        index = index + 1;
                                    end
                                else
                                    obj.Arguments(argPos).DeleteFcnPair(2) = string(mltype);
                                end
                            else
                                error(message('MATLAB:CPP:CannotSpecifyDeleteFcnForArgument'));
                            end

                        case "AddTrailingSingletons"
                            validateattributes(varargin{ind+1},{'logical'},{'scalar'});
                            argument.AddTrailingSingletons = varargin{ind+1};
                            argAnnotation.addTrailingSingletons = argument.AddTrailingSingletons;
                            if (argument.AddTrailingSingletons && not(argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer || ...
                                    argAnnotation.storage==internal.mwAnnotation.StorageKind.Array || ...
                                    argAnnotation.storage==internal.mwAnnotation.StorageKind.Vector ) ) || ...
                                    (argument.AddTrailingSingletons && contains(argument.MATLABType, "clib.array"))

                                %error if trailingSingletons n-v is added for a Reference,
                                %Value, SharedPtr, CFunctionPtr, StdFunctionPtr
                                %Or
                                %Error if trailingSingletons are used for clibArray
                                error(message('MATLAB:CPP:CannotSpecifyAddTrailingDimensions'))
                            end
                    end
                end
    
                % check if required N-V pair is given for C-string
                if argument.Direction == "output" && argument.MATLABType == "string" && ...
                        ~startsWith(argAnnotation.cppType, "[std::") && ~isfield(argument, 'BufferSize')
                    error(message('MATLAB:CPP:BufferSizeAbsent', argument.MATLABName));
                end
    
                for i = 1:numel(obj.Arguments)
                    if(obj.Arguments(i).MATLABName == name)
                        obj.Arguments(i).MATLABName = argument.MATLABName;
                        obj.Arguments(i).MATLABType = argument.MATLABType;
                        obj.Arguments(i).Direction = argument.Direction;
                        obj.Arguments(i).Shape = argument.Shape;
                        obj.Arguments(i).ReleaseOnCall = argument.ReleaseOnCall;
                        obj.Arguments(i).AddTrailingSingletons = argument.AddTrailingSingletons;
                        obj.Arguments(i).IsDefined = true;
                        obj.Arguments(i).Description = argument.Description;
                        if isfield(argument, 'BufferSize')
                            obj.Arguments(i).BufferSize = argument.BufferSize;
                        end
                        obj.InputDescriptions(i).Position = argPos;
                        obj.InputDescriptions(i).Name = argument.MATLABName;
                        obj.InputDescriptions(i).Description = argument.Description;
                        break;
                    end
                end

                % Set names for global validation
                if mltype == "struct"
                    clibScalarMwType = string(validMlTypes(1));
                    if strfind(clibScalarMwType,"clib.array") == 1
                        clibScalarMwType = "clib." + extractAfter(clibScalarMwType,11);
                    end
                    % MATLAB stores MlType of clibScalar type from validMlTypes
                    % if user updates MlType as "struct" and validates if
                    % struct is POD or NonPOD during validation. MlType as
                    % "struct" is not allowed for NonPOD structs.
                    if isempty(obj.MlTypesForValidation) || ~any(find([obj.MlTypesForValidation.mlType] == clibScalarMwType))
                        % end+1 increments the MlTypesForValidation size by
                        % 1 and adds the data. 
                        obj.MlTypesForValidation(end+1).mlType = clibScalarMwType;
                        obj.MlTypesForValidation(end).argPos = argPos;
                    end
                elseif (class(mltype) == "string" && (numel(mltype) > 1))
                    for i = 1: numel(mltype)
                        obj.NamesForValidation(end+1).argPos = argPos;
                        obj.NamesForValidation(end).className = mltype(i);
                        obj.NamesForValidation(end).hasMultipleMlTypes = true;
                    end
                elseif (isVoidPtr && ~clibgen.MethodDefinition.isFundamentalMlType(argAnnotation.mwType))
                    obj.NamesForValidation(end+1).argPos = argPos;
                    obj.NamesForValidation(end).className = argAnnotation.mwType;
                    obj.NamesForValidation(end).hasMultipleMlTypes = false;
                elseif not(clibgen.MethodDefinition.isFundamental(argType)) && ...
                        not(mltype=="string") && ~(isVoidPtr) && ~(isComplex)
                    obj.NamesForValidation(end+1).argPos = argPos;
                    obj.NamesForValidation(end).className = mltype;
                    obj.NamesForValidation(end).hasMultipleMlTypes = false;
                end
            catch ME
                throw(ME);
            end
        end

        function defineOutput(obj,name,mltype,varargin)
            try
                obj.Valid = false;
                p = inputParser;
                addRequired(p,"FunctionDefinition", @(x)(isa(x, "clibgen.FunctionDefinition")));
                addRequired(p,"MATLABName",         @(x)verifyMATLABName(obj,x, true));
                addRequired(p,"MATLABType",         @(x)validateattributes(x,{'char', 'string'},{'scalartext'}));
                addParameter(p,'Description',"",    @(x)validateattributes(x, {'char','string'},{'scalartext'}));
                parse(p, obj, name, mltype);
                numvarargin = numel(varargin);
    
                if(isempty(obj.OutputAnnotation))
                    error(message("MATLAB:CPP:NoReturnType",obj.MATLABName));
                end
    
                if(isempty(name))
                    error(message("MATLAB:CPP:EmptyMlName",obj.OutputAnnotation.name));
                elseif ~strcmp(name, obj.OutputAnnotation.name)
                    error(message("MATLAB:CPP:ReturnTypeNameMismatch",obj.OutputAnnotation.name));
                end
    
                outputType = obj.FunctionInterface.Type.RetType;
                isVoidPtr = clibgen.MethodDefinition.isVoidPtrType(obj.OutputAnnotation.cppType);
                isTypedef = false;
                validMlTypes = obj.OutputAnnotation.validTypes.toArray;
                if ~(isempty(obj.OutputAnnotation.opaqueTypeInfo))
                    opaqueTypeInfo = obj.OutputAnnotation.opaqueTypeInfo;
                    isTypedef = opaqueTypeInfo.isTypedef;
                end
                % Add mlType if needed
                validMlTypesToShow = clibgen.MethodDefinition.convertUIMlTypeArray(validMlTypes);
                if ~isempty(validMlTypesToShow)
                    [found, location] = ismember(mltype, validMlTypesToShow);
                    if ~found
                        if(numel(validMlTypesToShow)==1)
                            error(message('MATLAB:CPP:InvalidOutputType',obj.MATLABName,string(validMlTypesToShow)));
                        else
                            error(message('MATLAB:CPP:InvalidOutputTypeMultiple',obj.MATLABName,join(string(validMlTypesToShow),""", """)))
                        end
                    end
                    obj.OutputAnnotation.mwType = validMlTypes{location};
                    % verifying MlType for plain void*
                elseif isVoidPtr && ~isTypedef
                    if ~startsWith(mltype, strcat("clib.",obj.DefiningLibrary.PackageName, "."))
                        error(message('MATLAB:CPP:InvalidOutputTypeForVoidPtr',obj.MATLABName));
                    else
                        obj.OutputAnnotation.mwType = mltype;
                    end
                end
                obj.Output.MATLABName = string(p.Results.MATLABName);
                obj.Output.MATLABType = string(p.Results.MATLABType);
                obj.Output.DeleteFcnPair = [];
                obj.Output.Description = "";
    
                descparamoffset = 0;
                if (numvarargin >= 2)
                    if (varargin{numvarargin-1}=="Description")
                        obj.Output.Description = string(varargin{numvarargin});
                        obj.OutputAnnotation.description = obj.Output.Description;
                        obj.OutputDescription = obj.Output.Description;
                        descparamoffset = 2;
                    end
                end
                switch(numvarargin - descparamoffset)
                    case 0
                        if(obj.OutputAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer)
                            error(message('MATLAB:CPP:ShapeAbsent', name));
                        end
                        obj.Output.Shape = obj.OutputAnnotation.shape;
                    case 1
                        % Shape is provided
                        clibgen.MethodDefinition.verifyShape(obj.FunctionInterface, obj.OutputAnnotation, varargin{1}, outputType, false);
                        obj.Output.Shape = varargin{1};
                    case 2
                        % Error - 3rd argument must be "Shape", followed by N-V
                        % pair for "DeleteFcn"
                        error(message('MATLAB:CPP:IncorrectInputs', 'defineOutput'));
                    case 3
                        % Shape and DeleteFcn are provided
                        clibgen.MethodDefinition.verifyShape(obj.FunctionInterface, obj.OutputAnnotation, varargin{1}, outputType, false);
                        obj.Output.Shape = varargin{1};
                        isNullTermString = clibgen.MethodDefinition.isCharacterPointerNullTerminatedString(obj.OutputAnnotation.cppType, ...
                            obj.OutputAnnotation.storage, obj.Output.MATLABType, obj.Output.Shape);
                        if(varargin{2}=="DeleteFcn")
                            % DeleteFcn specified only for const objects
                            % i.e. non fundamental types then error out
                            if (obj.OutputAnnotation.isConstData && ~isNullTermString && ~clibgen.MethodDefinition.isFundamentalMlType(mltype) && (mltype ~= "struct"))
                                error(message('MATLAB:CPP:CannotDeleteConst'));
                            end
                            if(obj.OutputAnnotation.storage==internal.mwAnnotation.StorageKind.Value || ...
                                    obj.OutputAnnotation.storage==internal.mwAnnotation.StorageKind.Array || ...
                                    obj.OutputAnnotation.storage==internal.mwAnnotation.StorageKind.SharedPtr || ...
                                    startsWith(obj.OutputAnnotation.mwType, "clib.array."))
                                error(message('MATLAB:CPP:CannotSpecifyDeleteFcn'));
                            end
                            % Set DeleteFcn
                            validateattributes(varargin{3},{'clibgen.FunctionDefinition','char','string'},{'nonempty'} );
                            deleteFcnName = varargin{3};
                            if(isa(varargin{3}, 'clibgen.FunctionDefinition'))
                                deleteFcnName = varargin{3}.CPPSignature;
                            else
                                deleteFcnName = string(varargin{3});
                            end
                            obj.Output.DeleteFcnPair = deleteFcnName;
                            % For mltype="struct", store the validMlTypes
                            if and(~isempty(validMlTypes),find(contains(validMlTypes,"struct")))
                                index = 2;
                                for matlabType = validMlTypes
                                    obj.Output.DeleteFcnPair(index) = string(matlabType);
                                    index = index + 1;
                                end
                            else
                                obj.Output.DeleteFcnPair(2) = string(mltype);
                            end
                        else
                            error(message('MATLAB:InputParser:UnmatchedParameter', varargin{2}, ...
                                "For a list of valid name-value pair arguments, see the documentation for defineOutput."));
                        end
                    otherwise
                        error(message('MATLAB:maxrhs'));
                end
    
                % No errors, update the argument
                obj.Output.Direction = "output";
                obj.Output.IsDefined = true;
                % Set default mwtype (user defined) for global validation
                if mltype == "struct"
                    clibScalarMwType = string(validMlTypes(1));
                    if strfind(clibScalarMwType,"clib.array") == 1
                        clibScalarMwType = "clib." + extractAfter(clibScalarMwType,11);
                    end
                    % MATLAB stores MlType of clibScalar type from validMlTypes
                    % if user updates MlType as "struct" and validates if
                    % struct is POD or NonPOD during validation. MlType as
                    % "struct" is not allowed for NonPOD structs.
                    if isempty(obj.MlTypesForValidation) || ~any(find([obj.MlTypesForValidation.mlType] == clibScalarMwType))
                        % end+1 increments the MlTypesForValidation size by
                        % 1 and adds the data. 
                        obj.MlTypesForValidation(end+1).mlType = clibScalarMwType;
                        obj.MlTypesForValidation(end).argPos = 0;
                    end
                end
                % Set names for global validation
                if not(clibgen.MethodDefinition.isFundamental(outputType)) && not(mltype=="string") && ~(obj.OutputAnnotation.isComplex) && not(mltype=="struct")
                    obj.NamesForValidation(end+1).className = mltype;
                    obj.NamesForValidation(end).argPos = 0;
                    obj.NamesForValidation(end).hasMultipleMlTypes = false;
                end
            catch ME
                throw(ME);
            end
        end

        function validate(obj)
            if not (obj.Valid == true)
                try
                    % Make sure all arguments are defined
                    for arg = obj.Arguments
                        if not(arg.IsDefined)
                            error(message('MATLAB:CPP:UndefinedArgument',arg.MATLABName));
                        end
                    end
                    if not(isempty(obj.Output)) && not(obj.Output.IsDefined)
                        error(message('MATLAB:CPP:UndefinedOutput'));
                    end
                    obj.Valid = true;
                catch ME
                    throwAsCaller(ME);
                end
            end
        end

    end

    methods(Access=?clibgen.LibraryDefinition)
        function needsValidation = needsGlobalValidation(obj)
            needsValidation = ~isempty(obj.NamesForValidation);
        end
        function needsValidation = needsAdditionalOpaqueValidation(obj)
            needsValidation = ~isempty(obj.OpaqueTypesForValidation);
        end
        function needsValidation = needsMltypeStructValidation(obj)
            needsValidation = ~isempty(obj.MlTypesForValidation);
        end
        function addToLibrary(obj)
            [transArgs, transOut] = clibgen.internal.transformArgs(obj.Arguments, obj.Output);
            % For each argument update annotation by adding shape, direction, isHidden and
            % dimensions
            for i = 1:numel(transArgs)
                argAnn = obj.ArgAnnotations(i); % Annotations for this argument
                argAnn.shape = clibgen.MethodDefinition.ShapeValues(transArgs(i).Shape);
                argAnn.direction = clibgen.MethodDefinition.DirectionValues(transArgs(i).Direction);
                argAnn.isHidden = transArgs(i).IsHidden;
                %Populate dimensions
                if(argAnn.shape == internal.mwAnnotation.ShapeKind.Array)
                    argAnn.dimensions.clear;
                    for dim = transArgs(i).dimensions
                        % If it is "nullTerminated", the data itself
                        % has the length.
                        if dim.type ~= "parameter" || dim.value ~= "nullTerminated"
                            argAnn.dimensions.add(obj.convertDimensionInfo(dim));
                        end
                    end
                end
                if isfield(transArgs(i), 'BufferSize') && ~isempty(transArgs(i).BufferSize)
                    dim = transArgs(i).BufferSize;
                    argAnn.bufferSize = obj.convertDimensionInfo(dim);
                end
            end
            if not(isempty(transOut))
                obj.OutputAnnotation.shape = clibgen.MethodDefinition.ShapeValues(transOut.Shape);
                obj.OutputAnnotation.direction = clibgen.MethodDefinition.DirectionValues(transOut.Direction);
                obj.OutputAnnotation.isHidden = transOut.IsHidden;
                %Populate dimensions
                if(obj.OutputAnnotation.shape == internal.mwAnnotation.ShapeKind.Array)
                    obj.OutputAnnotation.dimensions.clear;
                    for dim = transOut.dimensions
                        obj.OutputAnnotation.dimensions.add(obj.convertDimensionInfo(dim));
                    end
                end
            end
            functionAnnotations = obj.FunctionInterface.Annotations.toArray;
            functionAnnotations.integrationStatus.inInterface = true;
            %update PtKeys if there are multiple MLTypes
            clibgen.MethodDefinition.updatePtKeys(functionAnnotations);

            % update inInterface field for all owning scope except the
            % compilation unit which has mwMetadata annotations and not
            % ScopeAnnotation
            parent = obj.FunctionInterface.OwningScope;
            while (~isempty(parent) && ~isa(parent,"internal.cxxfe.ast.source.CompilationUnit"))
                scopeAnnotations = parent.Annotations.toArray;
                scopeAnnotations(1).integrationStatus.inInterface = true;
                parent = parent.Parent();
            end
        end
        function name = getMATLABName(obj)
            name = obj.MATLABName;
        end
    end
    methods
        function sig = get.MATLABSignature(obj)
            validate(obj);
            [transArgs, transOut] = clibgen.internal.transformArgs(obj.Arguments, obj.Output);
            sig = clibgen.internal.computeMATLABSignature(obj.MATLABName, ...
                transArgs, transOut, obj.CombinationCountMultipleMlTypes);
        end
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            obj.Description = desc;
            annotationsArr = obj.FunctionInterface.Annotations.toArray;%#ok<MCSUP>
            annotationsArr(1).description = desc;
        end
        function set.DetailedDescription(obj, details)
            validateattributes(details,{'char','string'},{'scalartext'});
            obj.DetailedDescription = details;
            annotationsArr = obj.FunctionInterface.Annotations.toArray;%#ok<MCSUP>
            annotationsArr(1).detailedDescription = details;
        end
    end
end
