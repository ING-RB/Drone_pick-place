classdef ConstructorDefinition < handle & matlab.mixin.CustomDisplay
    % ConstructorDefinition MATLAB definition of a constructor of a class
    % This class contains the MATLAB definition for a C++ class constructor present in the header
    % ConstructorDefinition properties:
    %   Description         - Description of the constructor as provided by the publisher
    %   DetailedDescription - Detailed description of the constructor as provided by the publisher
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Access=public)
        Description             string
        DetailedDescription     string
    end
    properties(SetAccess=private)
        CPPSignature  string;
        Valid         logical = false;
    end
    properties(SetAccess=private, WeakHandle)
        DefiningClass clibgen.ClassDefinition
    end
    properties(Dependent, SetAccess=private)
        MATLABSignature string;
    end
    properties(GetAccess={?clibgen.MethodDefinition, ?clibgen.ClassDefinition})
        ConstructorInterface
    end
    properties(GetAccess={?clibgen.LibraryDefinition, ?clibgen.MethodDefinition, ?clibgen.ClassDefinition})
        CombinationCountMultipleMlTypes uint32
    end
    properties(GetAccess={?clibgen.MethodDefinition})
        Arguments            struct
        IsImplicit           logical
    end
    properties(Access={?clibgen.ClassDefinition,?clibgen.LibraryDefinition})
        NamesForValidation   struct;
        OpaqueTypesForValidation struct
    end
    properties(Access=?clibgen.internal.Accessor)
        InputDescriptions struct
    end
    properties(Access=?clibgen.internal.Accessor)
        ConstructorMATLABName  string
    end        
    properties(Access=?clibgen.LibraryDefinition)
         ArgAnnotations    internal.mwAnnotation.Argument
    end
    methods(Access=protected)
        function displayScalarObject(obj)
            try
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                h = sprintf("  " + className + " maps" + "\n\n" + "    C++:    " + obj.CPPSignature + ...
                    "\n" + "    to " + "\n" +                           "    MATLAB: ");
                validate(obj);
                mlSignature = obj.MATLABSignature; 
                for i= 1:numel(mlSignature)
                    if (i==numel(mlSignature))
                        h = h + mlSignature{i} ;
                    else
                        h = h + mlSignature{i} + sprintf( "\n            ");
                    end
                end
                argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(obj, obj.ConstructorInterface);
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
    
    methods(Access=?clibgen.ClassDefinition)
        function obj = ConstructorDefinition(classDef, CPPSig, ctorInterface, description, isImplicit, detailedDescription)
            obj.Valid = false;
            parser = inputParser;
            addRequired(parser, "ClassDefinition", @(x)(isa(x, "clibgen.ClassDefinition")));
            addRequired(parser, "CPPSignature",    @(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addRequired(parser, "CtorInterface",   @(x)(isa(x,"internal.cxxfe.ast.types.Method") || isa(x,"internal.mwAnnotation.FunctionAnnotation")));
            addRequired(parser, "Description",     @(x)validateattributes(x,{'char','string'},{'scalartext'}));
            addRequired(parser, "IsImplicit",      @(x)validateattributes(x,{'logical'},{'scalar'}));
            addParameter(parser, "DetailedDescription", "", @(x)validateattributes(x,{'char','string'},{'scalartext'}));
            parser.KeepUnmatched = false;
            parser.parse(classDef, CPPSig, ctorInterface, description, isImplicit);
            obj.ConstructorInterface = ctorInterface;
            obj.DefiningClass        = classDef;
            obj.CPPSignature         = CPPSig;
            if (isImplicit)
                annotationsArr = ctorInterface;
            else
                annotationsArr = ctorInterface.Annotations.toArray;
            end
            obj.ConstructorMATLABName = annotationsArr(1).name;
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
                clibgen.MethodDefinition.updateValidType(classDef.DefiningLibrary, obj.ArgAnnotations(i));
            end
            obj.IsImplicit = isImplicit;
            obj.Description = description;
            obj.DetailedDescription = detailedDescription;
            % for OpaqueTypeFunctionInfo
            opaqueTypeInfoAnnotation = annotationsArr.opaqueTypeInfo;
            if ~(isempty(opaqueTypeInfoAnnotation))
                obj.CombinationCountMultipleMlTypes = opaqueTypeInfoAnnotation.combinationCountMultipleMlTypes;
            else
                opaqueTypeInfoAnnotation = internal.mwAnnotation.OpaqueTypeFunctionInfo(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                obj.CombinationCountMultipleMlTypes = opaqueTypeInfoAnnotation.combinationCountMultipleMlTypes;
                annotationsArr.opaqueTypeInfo = opaqueTypeInfoAnnotation;
            end
        end
        
        function addConstructorToClass(obj)
            [transArgs, ~] = clibgen.internal.transformArgs(obj.Arguments, []);
            % For each argument, update annotation by adding shape, direction, isHidden and
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
                        if(dim.type == "parameter")
                            % If it is "nullTerminated", the data itself
                            % has the length.
                            if dim.value ~= "nullTerminated"
                                annotationDim = internal.mwAnnotation.VariableDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                                annotationDim.lengthVariableName = dim.value;
                                annotationDim.mwType = dim.MATLABType;
                                annotationDim.shape = clibgen.MethodDefinition.getShapeKind(dim.Shape);
                                annotationDim.storage = clibgen.MethodDefinition.getStorageKind(dim.Storage);
                                annotationDim.cppPosition = dim.CppPosition;
                            end
                        elseif(dim.type == "value")
                            annotationDim = internal.mwAnnotation.FixedDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                            annotationDim.value = dim.value;
                        end
                        argAnn.dimensions.add(annotationDim);
                    end
                end
            end
            if(obj.IsImplicit)
                constructorAnnotation = obj.ConstructorInterface;
            else
                constructorAnnotation = obj.ConstructorInterface.Annotations.toArray;
                %update PtKeys if there are multiple MLTypes
                clibgen.MethodDefinition.updatePtKeys(constructorAnnotation);
            end
            constructorAnnotation.integrationStatus.inInterface = true;
        end
    end
            
    methods(Access=public)
        function defineArgument(obj, name, mltype, varargin)
            try
                obj.Valid = false;
                parser = inputParser;
                addRequired(parser, "ConstructorDefinition", @(x) (isa(x, "clibgen.ConstructorDefinition")));
                addRequired(parser, "MATLABName",            @(x) clibgen.MethodDefinition.verifyMATLABName(x, true));
                addRequired(parser, "MATLABType",            @(x) validateattributes(x,{'char', 'string'},{'vector'}));
                addParameter(parser,"Description", "",       @(x)validateattributes(x, {'char','string'},{'scalartext'}));
                addParameter(parser, "AddTrailingSingletons", false, @(x) validateattributes(x, {'logical'},{'scalar'}))
                parser.parse(obj, name, mltype);
                numvarargin = numel(varargin);
                argAnnotation = [];
                % Get the argument annotation and position
                for annotation = obj.ArgAnnotations
                    if strcmp(annotation.name, name)
                        argAnnotation = annotation;
                        argPos = argAnnotation.cppPosition;
                        break;
                    end
                end
                if not(obj.IsImplicit)
                    args = obj.ConstructorInterface.Params.toArray;
                    argType = args(argPos).Type;
                end
                isVoidPtr = clibgen.MethodDefinition.isVoidPtrType(argAnnotation.cppType);
                isComplex = argAnnotation.isComplex;
                % Add mlType if needed
                if (isVoidPtr)
                    clibgen.MethodDefinition.verifyVoidPtr(obj, mltype, name, argAnnotation,...
                        obj.DefiningClass.DefiningLibrary, argPos);
                else
                    %check if the MLType contains a list for non-void* input
                    if (class(mltype) == "string" && (numel(mltype) > 1))
                        error(message('MATLAB:CPP:InvalidMATLABTypeForNonVoidPtrArgument',name));
                    end
                    validMlTypes = argAnnotation.validTypes.toArray;
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
    
                argument.MATLABName = string(name);
                argument.MATLABType = string(parser.Results.MATLABType);
                argument.Description = "";
                argument.ReleaseOnCall = false;
                argument.AddTrailingSingletons = false;
                % Get description option from name value pair varargin
                % search from the end.
                % name = varargin{ind-1} 
                % value = varargin{ind}
                offset = 0;
                if (numvarargin >= 2)
                    for ind =numvarargin:-2:2
                        %Switch case for matching parameter for the name-value pairs.
                        switch(string(varargin{ind-1}))
                            case {"Description", "ReleaseOnCall", "NumElementsInBuffer", "AddTrailingSingletons"}
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
                        if(argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer || ...
                            argAnnotation.storage==internal.mwAnnotation.StorageKind.Array)
                            error(message('MATLAB:CPP:ShapeAbsent', name));
                        end
                        if(obj.IsImplicit)
                            if not(varargin{1}=="input")
                                error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input"));
                            end
                        else
                            clibgen.MethodDefinition.verifyDirection(varargin{1}, argAnnotation, argType, "constructor");
                        end
                        argument.Direction = string(varargin{1});
                        argument.Shape = argAnnotation.shape;
                    case 2
                        if(obj.IsImplicit)
                            if not(varargin{1}=="input")
                                error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input"));
                            end
                            if not(varargin{2}==1)
                                error(message('MATLAB:CPP:InvalidShapeForRefAndValue'));
                            end
                        else
                            if ((clibgen.MethodDefinition.isFundamental(argType) && ~clibgen.MethodDefinition.isString(argAnnotation.mwType)) || ...
                                (isVoidPtr && clibgen.MethodDefinition.isFundamentalMlType(argAnnotation.mwType))) && ...
                               (varargin{1}=="output" || varargin{1}=="inputoutput") && ...
                               (argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer || ...
                               argAnnotation.storage==internal.mwAnnotation.StorageKind.Array)
                                % For constructors, "output", "inputoutput" is not allowed for fundamental pointers/arrays
                                % and void* inputs with mwType specified as fundamental mltypes
                                % for rest of the scenarios, direction verification is same across constructors, methods, functions
    
                                if isVoidPtr
                                    error(message('MATLAB:CPP:InvalidDirectionForVoidPtrInputInCtor', varargin{1}));
                                else
                                    validMlTypes = argAnnotation.validTypes.toArray;
                                    for mlType = validMlTypes
                                        if string(mlType).startsWith("clib.array")
                                            clibArrayType = string(mlType);
                                            break;
                                        end
                                    end
                                    error(message('MATLAB:CPP:InvalidDirectionForConstructor', varargin{1}, clibArrayType));
                                end
                            else
                                clibgen.MethodDefinition.verifyDirection(varargin{1}, argAnnotation, argType, "constructor");
                            end
                            clibgen.MethodDefinition.verifyShape(obj.ConstructorInterface, argAnnotation, varargin{2}, argType, false);
                        end
                        argument.Direction = string(varargin{1});
                        argument.Shape     = varargin{2};
                    otherwise
                        error(message('MATLAB:maxrhs'));
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
                        case "NumElementsInBuffer"
                            % "output" "string" is already errored out above
                            error(message('MATLAB:CPP:BufferSizeNotAllowed'));
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
    
                % Update the arguments
                for i = 1:numel(obj.Arguments)
                    if(obj.Arguments(i).MATLABName == name)
                        obj.Arguments(i).MATLABName = argument.MATLABName;
                        obj.Arguments(i).MATLABType = argument.MATLABType;
                        obj.Arguments(i).Direction = argument.Direction;
                        obj.Arguments(i).Shape = argument.Shape;
                        obj.Arguments(i).IsDefined = true;
                        obj.Arguments(i).Description = argument.Description;
                        obj.Arguments(i).ReleaseOnCall = argument.ReleaseOnCall;
                        obj.Arguments(i).AddTrailingSingletons = argument.AddTrailingSingletons;
                        obj.InputDescriptions(i).Position = argPos;
                        obj.InputDescriptions(i).Name = argument.MATLABName;
                        obj.InputDescriptions(i).Description = argument.Description;
                        break;
                    end
                end
                % Set names for global validation
                if not(obj.IsImplicit)
                    if (class(mltype) == "string" && (numel(mltype) > 1))
                        for i = 1: numel(mltype)
                            obj.NamesForValidation(end+1).argPos = argPos;
                            obj.NamesForValidation(end).className = mltype(i);
                            obj.NamesForValidation(end).hasMultipleMlTypes = true;
                        end
                    elseif  isVoidPtr && ~clibgen.MethodDefinition.isFundamentalMlType(argAnnotation.mwType)
                        obj.NamesForValidation(end+1).argPos = argPos;
                        obj.NamesForValidation(end).className = mltype;
                        obj.NamesForValidation(end).hasMultipleMlTypes = false;
                    elseif not(clibgen.MethodDefinition.isFundamental(argType)) && ...
                        not(mltype=="string") && ~(isVoidPtr) && ~(isComplex)
                        obj.NamesForValidation(end+1).argPos = argPos;
                        obj.NamesForValidation(end).className = mltype;
                        obj.NamesForValidation(end).hasMultipleMlTypes = false;
                    end
                end
            catch ME
                throw(ME);
            end
        end
        
        
        function validate(obj)
            if not (obj.Valid == true)                
                % Make sure all arguments are defined
                for arg = obj.Arguments
                    if not(arg.IsDefined)
                        error(message('MATLAB:CPP:UndefinedArgument',arg.MATLABName));
                    end
                end              
                obj.Valid = true;                                    
            end
        end
    end
    
    methods
        function sig = get.MATLABSignature(obj)
            validate(obj);
            [transArgs, transOut] = clibgen.internal.transformArgs(obj.Arguments, []);
            sig = clibgen.internal.computeMATLABSignature(obj.DefiningClass.MATLABName,...
                transArgs, transOut, obj.CombinationCountMultipleMlTypes);
        end
        
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            obj.Description = desc;
            if (obj.IsImplicit)%#ok<MCSUP>
                annotationsArr = obj.ConstructorInterface;%#ok<MCSUP>
            else
                annotationsArr = obj.ConstructorInterface.Annotations.toArray;%#ok<MCSUP>
            end
            annotationsArr(1).description = desc;
        end

        function set.DetailedDescription(obj, details)
            validateattributes(details,{'char','string'},{'scalartext'});
            obj.DetailedDescription = details;
            if (obj.IsImplicit)%#ok<MCSUP>
                annotationsArr = obj.ConstructorInterface;%#ok<MCSUP>
            else
                annotationsArr = obj.ConstructorInterface.Annotations.toArray;%#ok<MCSUP>
            end
            annotationsArr(1).detailedDescription = details;
        end
    end
    
    methods(Access=?clibgen.LibraryDefinition)
        function needsValidation = needsGlobalValidation(obj)
            needsValidation = ~isempty(obj.NamesForValidation);
        end

        function needsValidation = needsAdditionalOpaqueValidation(obj)
            needsValidation = ~isempty(obj.OpaqueTypesForValidation);
        end 

        function mlName = getMATLABName(obj)
            mlName = obj.DefiningClass.MATLABName;
        end
    end
    
    methods(Static, Access={?clibgen.ClassDefinition,...
            ?clibgen.LibraryDefinition})
        % Returns a vector of input arg pointers whose MLTYPE is
        %   specified as MATLAB opaque type within same scope/
        % definitionObj: ContructorDefinition object
        % interfaceObj: ConstructorInterface object
        function args = getOpaqueTypesWithinScopeUsedAsArgs(definitionObj, interfaceObj, className, argPos)
            annotationsArr =interfaceObj.Annotations.toArray;
            argNumel = numel(annotationsArr.inputs.toArray);
            args = [];
            inputArgAnnotations = annotationsArr.inputs.toArray;
            % Add args that have opaqueType as input within scope
            for i = 1:argNumel
                if clibgen.MethodDefinition.isVoidPtrType(inputArgAnnotations(i).cppType)
                    try
                        % Test if MlType is within scope of class itself
                        mlTypesNumel = numel(definitionObj.Arguments(i).MATLABType);
                        for j = 1:mlTypesNumel
                            mlType = definitionObj.Arguments(i).MATLABType(j);
                            if startsWith(mlType, className)
                                args = [args definitionObj.Arguments(i).MATLABType(j)];
                            end
                        end
                    catch
                    end
                end
            end
        end
    end
end
