classdef MethodDefinition < handle & matlab.mixin.CustomDisplay
    % MethodDefinition MATLAB definition of a class method
    % This class contains the MATLAB definition for a C++ class member function present in the header
    % MethodDefinition properties:
    %   Description - Description of the method as provided by the publisher
    %   DetailedDescription - Detailed description of the method as provided by the publisher
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Access=public)
        Description         string
        DetailedDescription string
    end
    properties(SetAccess=private)
        CPPSignature      string
        Valid             logical = false
    end
    properties(SetAccess=private, WeakHandle)
        DefiningClass clibgen.ClassDefinition
    end    
    properties(Dependent, SetAccess=private)
        MATLABSignature   string
    end
    properties(GetAccess=?clibgen.LibraryDefinition)
        Arguments         struct
        MlTypesForValidation struct
    end
    properties(GetAccess= {?clibgen.ClassDefinition})
        CombinationCountMultipleMlTypes uint32
    end
    properties(SetAccess=?clibgen.LibraryDefinition,GetAccess={?clibgen.internal.Accessor, ?clibgen.LibraryDefinition})
        Output            struct
        OutputAnnotation  internal.mwAnnotation.Argument
    end
    
    properties(Access=?clibgen.LibraryDefinition)
         ArgAnnotations    internal.mwAnnotation.Argument
    end

    properties(Constant, Access={?clibgen.ConstructorDefinition,?clibgen.FunctionDefinition, ...
            ?clibgen.PropertyDefinition, ?clibgen.ClassDefinition})
        ShapeValues = containers.Map({'array','nullTerminated','scalar','undefined'},{internal.mwAnnotation.ShapeKind.Array,...
            internal.mwAnnotation.ShapeKind.NullTerminated,internal.mwAnnotation.ShapeKind.Scalar,...
            internal.mwAnnotation.ShapeKind.Undefined});
        DirectionValues = containers.Map({'input','output','inputoutput','undefined'},{internal.mwAnnotation.DirectionKind.In, ...
            internal.mwAnnotation.DirectionKind.Out,internal.mwAnnotation.DirectionKind.InOut, ...
            internal.mwAnnotation.DirectionKind.Undefined});
    end
    properties(Access={?clibgen.ClassDefinition,?clibgen.LibraryDefinition})
        NamesForValidation    struct
        OpaqueTypesForValidation struct
    end    
    properties(Access=?clibgen.internal.Accessor)
        InputDescriptions   struct
        OutputDescription   string
    end
    properties(SetAccess=private)
        MATLABName          string
        TemplateUniqueName  string
    end
    properties(GetAccess={?clibgen.LibraryDefinition, ?clibgen.ClassDefinition}, SetAccess={?clibgen.ClassDefinition})
        MethodInterface   internal.cxxfe.ast.types.Method
    end
    methods(Static, Access={?clibgen.ConstructorDefinition,?clibgen.FunctionDefinition, ?clibgen.PropertyDefinition, ?clibgen.ClassDefinition, ?clibgen.LibraryDefinition})
        function retVal = makeUIMlType(mlType)
            if strncmp('char', mlType, 4)
                retVal = 'char';
            elseif strncmp('string', mlType, 6)
                retVal = 'string';
            else
                retVal = mlType;
            end
        end
        
        function retVal = convertUIMlTypeArray(mlTypes)
            retVal = cellfun(@clibgen.MethodDefinition.makeUIMlType, mlTypes, 'UniformOutput', false);
        end

        function retVal = isString(mlType)
            retVal = (clibgen.MethodDefinition.makeUIMlType(mlType) == "string");
        end
        
        function retVal = isFundamental(paramType)
            uType = internal.cxxfe.ast.types.Type.getUnderlyingType(paramType);
            retVal = (uType.isIntegerType || uType.isBooleanType || uType.isFloatType);
        end

        % Function checks if the specified MlType for void* is of fundamental type
        function retVal = isFundamentalMlType(mwType)
            retVal = ismember(mwType, clibgen.LibraryDefinition.fundamentalMlTypeCppTypeMap.keys);
        end

        % Function to get cppType for the specified MLType corresponding to void*
        function cppType = getCppTypeForFundamentalMlType(mwType)
            cppType =  clibgen.LibraryDefinition.fundamentalMlTypeCppTypeMap(mwType);
        end

        %Function returns true if input Argument is Double Pointer 
        function retVal = isDoublePointer(paramType)
            srInnerType = internal.cxxfe.ast.types.Type.skipTyperefs(paramType);
            if srInnerType.isPointerType
                srInnerPtrType = internal.cxxfe.ast.types.Type.skipTyperefs(srInnerType.Type);
                retVal = srInnerPtrType.isPointerType;
            else
                retVal = false;
            end
        end
        
        %Function returns true and the inner type if input Argument is Double Pointer 
        function [retVal, innerType] = innerTypeInDoublePointer(paramType)
            srInnerType = internal.cxxfe.ast.types.Type.skipTyperefs(paramType);
            if srInnerType.isPointerType
                srInnerPtrType = internal.cxxfe.ast.types.Type.skipTyperefs(srInnerType.Type);
                retVal = srInnerPtrType.isPointerType;
            else
                retVal = false;
            end
            if retVal
                innerType = internal.cxxfe.ast.types.Type.skipTyperefs(srInnerPtrType.Type);
            else
                innerType = NaN;
            end
        end
        
        function retVal = isCharacterType(paramType)
            uType = internal.cxxfe.ast.types.Type.getUnderlyingType(paramType);
            if uType.isIntegerType
                retVal = uType.Kind==internal.cxxfe.ast.types.IntegerKind.Char || ...
                    uType.Kind==internal.cxxfe.ast.types.IntegerKind.Wchar || ...
                    uType.Kind==internal.cxxfe.ast.types.IntegerKind.Char16 || ...
                    uType.Kind==internal.cxxfe.ast.types.IntegerKind.Char32;
            else
                retVal = false;
            end
        end

        function valid = verifyMATLABName(mlname, argname) %#ok<*INUSL>
            if(~argname)
                % Check simple name for validity
                mlKeywords = [ "break", "case", "catch", "classdef", "continue", "else", "elseif", "end", "for", "function", "global", "if", "otherwise", "parfor", "persistent", "return", "spmd", "switch", "try", "while"];
                valid = matlab.lang.makeValidName(mlname) == mlname && ~any(strcmp(mlKeywords, string(mlname)));
            else
                valid = false;
                if ischar(mlname) && ~isempty(mlname) && any(~isspace(string(mlname))) || ...
                        isStringScalar(mlname) && ~ismissing(mlname) && mlname ~= "" && mlname==strtrim(mlname)
                    valid = true;
                end
            end
            if ~valid
                error(message('MATLAB:CPP:InvalidName'));
            end
        end

        function verifyDirection(direction, argAnnotation, argType, methodType)
            validateattributes(direction,{'char','string'},{'scalartext'});
            if not(direction=="input" || direction=="output" || direction =="inputoutput")
                error(message('MATLAB:CPP:InvalidArgumentDirection'));
            end            
            if any(strcmp(argAnnotation.mwType, ["string", "string16", "string32"]))
                % C++ char array with fixed size can only be "output"
                % "string"
                if ~isempty(argAnnotation.dimensions.toArray()) && direction ~= "output"...
                        && ~contains(argAnnotation.cppType, "PtrArr")
                    error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "output" ));
                end
                % cannot return value from constructor
                if methodType == "constructor" && direction ~= "input"
                    error(message('MATLAB:CPP:OutputArgInConstructor', direction, argAnnotation.name));
                end
            end
            if(direction~="input")
                % Direction 
                if(argAnnotation.storage==internal.mwAnnotation.StorageKind.SharedPtr)
                    % Direction for std::shared_ptr value types must be "input"
                    if(argAnnotation.outerStorage(1)==internal.mwAnnotation.StorageKind.Value)
                        error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input" ));
                    elseif(argAnnotation.outerStorage(1)==internal.mwAnnotation.StorageKind.Reference)
                            % Reference to const std::shared_ptr types must be "input"
                            if((not(isempty(argAnnotation.outerConstness.toArray)) && argAnnotation.outerConstness(1)))
                                error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input" ));
                            % Reference to std::shared_ptr types must be "inputoutput"
                            elseif(direction=="output")
                                error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "inputoutput" ));
                            end
                    end
                % Direction for Value types must be "input"
                elseif(argAnnotation.storage==internal.mwAnnotation.StorageKind.Value)
                    error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input" ));
                    % For const data, direction must always be "input" 
                    % For const Object Double Pointer Direction output should be
                    % output
                elseif(argAnnotation.isConstData && ~clibgen.MethodDefinition.isDoublePointer(argType))
                    error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input"));
                    % Direction for char * "string" cannot be "inputoutput"
                elseif(clibgen.MethodDefinition.isFundamental(argType) && clibgen.MethodDefinition.isString(argAnnotation.mwType) && ...
                        direction == "inputoutput")
                    error(message('MATLAB:CPP:InvalidDirectionForString', argAnnotation.name));
                    % Direction for reference to non-fundamental type can be "input" only
                    % for pointer to non-fundamental must be "input" either
                    % it is a scalar or a C++ array
                    % It also includes void* which are configured as non-fundamental type.
                elseif(~clibgen.MethodDefinition.isFundamental(argType) && ~clibgen.MethodDefinition.isString(argAnnotation.mwType) && ...
                        (argAnnotation.storage==internal.mwAnnotation.StorageKind.Reference || ...
                        argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer) && ...
                        ~clibgen.MethodDefinition.isDoublePointer(argType) && ...
                        ~clibgen.MethodDefinition.isFundamentalMlType(argAnnotation.mwType) && ...
                        ~(argAnnotation.isComplex) && not(argAnnotation.mwType=="struct"))
                    error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input"));
                    % if mwType start with clib.array,
                elseif(startsWith(argAnnotation.mwType, "clib.array."))
                    error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, "input"));
                end
            end

			%Direction for double pointer object type can be "output" only
            [isDoublePointer, innerType] = clibgen.MethodDefinition.innerTypeInDoublePointer(argType);
            if isDoublePointer
                if clibgen.MethodDefinition.isCharacterType(innerType)
                    allowedDirection = "input";
                else
                    allowedDirection = "output";
                end
                if direction~=allowedDirection
                    error(message('MATLAB:CPP:InvalidDirectionValue', argAnnotation.name, allowedDirection));
                end
            end
        end
                
        function [result, argExists, argTypeValid] = isValidArgDim(funcType, dimName)
            dimName = string(dimName);
            ann = funcType.Annotations(1);
            params = funcType.Params.toArray();
            inputs = ann.inputs.toArray();
            argExists = false;
            argTypeValid = false;
            arg = inputs(arrayfun(@(x) strcmp(x.name, dimName), inputs));
            if not(isempty(arg))
                argExists = true;
                cpos = arg.cppPosition;
                param = params(cpos);
                if(isa(internal.cxxfe.ast.types.Type.getUnderlyingType(param.Type), 'internal.cxxfe.ast.types.IntegerType'))
                    if arg.storage==internal.mwAnnotation.StorageKind.Value || ...
                        (arg.storage==internal.mwAnnotation.StorageKind.Reference && arg.isConstData)
                        result = true;
                        argTypeValid = true;
                        return;
                    end
                end
            end
            result = false;
          end
         
        function [result, argExists, argTypeValid, isMethodDim, isIntegerTypeDim, isStaticDim] = validateAndStoreDims(obj, dimName, isStaticMethod)
            dimName = string(dimName);
            methType = obj.MethodInterface;
            ann = methType.Annotations(1);
            params = methType.Params.toArray();
            inputs = ann.inputs.toArray();
            argExists = false;
            argTypeValid = false;
            isIntegerTypeDim = false;
            isStaticDim = false;
            isMethodDim = false;
            arg = inputs(arrayfun(@(x) strcmp(x.name, dimName), inputs));
             if not(isempty(arg))
                cpos = arg.cppPosition;
                param = params(cpos);
                argExists = true; 
                if(isa(internal.cxxfe.ast.types.Type.getUnderlyingType(param.Type), 'internal.cxxfe.ast.types.IntegerType'))
                    if arg.storage==internal.mwAnnotation.StorageKind.Value || ...
                        (arg.storage==internal.mwAnnotation.StorageKind.Reference && arg.isConstData)
                        result = true;
                        argTypeValid = true;
                        return;
                    end
                end
             else
                 [~,isNumeric] = str2num(dimName);
                 if (~isNumeric)
                     [result,cppPosition,mwType,isMethodDim, dimExists,isIntegerTypeDim,isStaticDim] = clibgen.PropertyDefinition.isValidMethodOrMemberDim(obj.DefiningClass.ClassInterface,dimName, isStaticMethod);
                     if result
                        obj.Output.MemberOrMethodDims(end+1).dimName = dimName;
                        obj.Output.MemberOrMethodDims(end).cppPosition =cppPosition;
                        obj.Output.MemberOrMethodDims(end).mwType = mwType;
                        obj.Output.MemberOrMethodDims(end).storage = obj.Output.Storage;
                        if ~isMethodDim
                            obj.Output.MemberOrMethodDims(end).dimType = "DataMember";
                        else
                            obj.Output.MemberOrMethodDims(end).dimType = "Method";
                        end
                        return;
                     end
                     argExists = dimExists;
                 end
             end
             result = false;
        end        

        function valid = verifyShape(obj, argAnnotation, shape, argType, isMethodOutput)
            if(isnumeric(shape))
                validateattributes(shape, {'numeric'}, {'vector', 'integer', 'positive'});
            elseif ~((isstring(shape) || ischar(shape) || iscell(shape)))
                error(message('MATLAB:CPP:InvalidArgumentShape'));
            end
            if((ischar(shape) && ~isvector(shape)) || (isstring(shape) && any(ismissing(shape))) ||...
                    (isstring(shape) && any(shape == "")))
                error(message('MATLAB:CPP:InvalidArgumentShape'));
            end
            if (iscell(shape))
                if not(all(cellfun(@(x)(isStringScalar(x) || (ischar(x) && isvector(x))||  ...
                        isscalar(x)), shape)))
                    error(message('MATLAB:CPP:NonScalarDimsNotSupported'));
                elseif isempty(shape)
                    error(message('MATLAB:CPP:UnspecifiedShape'));
                end
            end
            
            if(ischar(shape))
                shape = string(shape);
            end
            isStaticMethod = false;
            if isMethodOutput
                isStaticMethod = (obj.MethodInterface.StorageClass == internal.cxxfe.ast.StorageClassKind.Static);
            end
            
            % Throw an exception if the shape vector contains a size that
            % is not 1 for reference and value types
            if(argAnnotation.storage==internal.mwAnnotation.StorageKind.Value || ...
                    argAnnotation.storage==internal.mwAnnotation.StorageKind.Reference)
                if not(isscalar(shape) && isnumeric(shape) && shape==1)                    
                    error(message('MATLAB:CPP:InvalidShapeForRefAndValue'));
                end
            elseif(argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer)
                % Shape for void* configured as a class type can only be scalar
                if( ~startsWith(argAnnotation.mwType, "clib.array.") && ...
                        (argType.Type.Name == "void" && ~clibgen.MethodDefinition.isFundamentalMlType(argAnnotation.mwType)))
                    if not(isscalar(shape) && isnumeric(shape) && shape==1) % shape needs to be a value of 1
                        error(message('MATLAB:CPP:NoArraySupportForType', argAnnotation.mwType));
                    end
                end
                % Pointer to a class type can only be scalar
                if(~clibgen.MethodDefinition.isFundamental(argType) && ...
                        ~startsWith(argAnnotation.mwType, "clib.array.") &&...
                        startsWith(argAnnotation.mwType, "clib.") &&...
                        (argType.Type.Name ~= "void") && not(argAnnotation.mwType=="struct"))
                    if not(isscalar(shape) && isnumeric(shape) && shape==1) % shape needs to be a value of 1
                        error(message('MATLAB:CPP:NoArraySupportForType', argAnnotation.mwType));
                    end
                end
                if clibgen.MethodDefinition.isString(argAnnotation.mwType)
                    if clibgen.MethodDefinition.isDoublePointer(argType)
                        % If this argument is a array of strings,
                        % the shape must be [numOfString ,"nullTerminated"]
                        if iscell(shape(end))
                            dimension = shape{end};
                        else
                            dimension = shape(end);
                        end
                        if ~strcmp("nullTerminated", dimension)
                            error(message('MATLAB:CPP:CStringArrayLastDimension'));
                        end
                        switch numel(shape)
                            case 2
                                if iscell(shape(1))
                                    dimension = shape{1};
                                else
                                    dimension = shape(1);
                                end
                                if (ischar(dimension) || isstring(dimension))
                                    result = false;
                                    if isMethodOutput
                                        result  =  clibgen.MethodDefinition.validateAndStoreDims(obj, dimension, isStaticMethod);
                                    else
                                        result =  clibgen.MethodDefinition.isValidArgDim(obj, dimension);
                                    end
                                    if not(result)
                                        if ~iscell(shape) && ~isStringScalar(shape) && ~isnan(str2double(dimension)) % numeric dimension specified in a string array
                                            error(message('MATLAB:CPP:InvalidShapeParamNumericString'));
                                        else
                                            error(message('MATLAB:CPP:InvalidArgumentNameShape', dimension, argAnnotation.name));
                                        end
                                    end
                                elseif isnumeric(dimension)
                                    % Fixed dim
                                    if not(dimension > 0)
                                        error(message('MATLAB:CPP:InvalidNumericShapeValue'));
                                    end
                                else
                                % Invalid shape element
                                    error(message('MATLAB:CPP:InvalidArgumentShape'));
                                end
                            otherwise
                                error(message('MATLAB:CPP:CStringArrayDimensions'));
                        end
                        
                    elseif not(isstring(shape) && isscalar(shape) && shape == "nullTerminated")
                        % If this argument is a string and it is not array to string,
                        %  then the only acceptable shape is "nullTerminated"
                        error(message('MATLAB:CPP:InvalidCStringShape'));
                    end
                else
                    % Non-string type, all dims must be fixed width or strings with valid
                    % argument names
                    if((ischar(shape)||isstring(shape)) && isscalar(shape) && shape == "nullTerminated")
                        error(message("MATLAB:CPP:InvalidShapeString",shape));
                    end
                    numericShapeAlreadyFound = false;
                    for dim = shape
                        if(iscell(dim))
                            dimension = dim{1};
                        else
                            dimension = dim;
                        end
                        if (ischar(dimension) || isstring(dimension))
                            % Variable dim
                            if(numericShapeAlreadyFound)
                                % Cannot have a variable dim after a fixed
                                % dim
                                error(message('MATLAB:CPP:InvalidShapeParamAfterVal'));
                            end
                            result = 0;
                            foundArg = 0;
                            argTypeValid = 0;
                            isMethodDim = false;
                            isIntegerTypeDim = false;
                            isStaticDim = false;
                            if isMethodOutput
                                 [overallResult, foundArg, argTypeValid,isMethodDim, isIntegerTypeDim, isStaticDim]  =  clibgen.MethodDefinition.validateAndStoreDims(obj, dimension, isStaticMethod);
                            else
                                 [overallResult, foundArg, argTypeValid] =  clibgen.MethodDefinition.isValidArgDim(obj, dimension);
                            end
                            if not(overallResult)
                                if ~iscell(shape) && ~isStringScalar(shape) && ~isnan(str2double(dimension)) % numeric dimension specified in a string array
                                    error(message('MATLAB:CPP:InvalidShapeParamNumericString'));
                                elseif isStringScalar(shape) && ~isnan(str2double(shape))
                                    error(message('MATLAB:CPP:InvalidArgumentShapeQuotedNumeric', dimension));
                                elseif iscell(shape) && isStringScalar(dimension) && ~isnan(str2double(dimension))
                                    error(message('MATLAB:CPP:InvalidArgumentShapeQuotedNumeric', dimension));
                                elseif ~foundArg
                                    error(message('MATLAB:CPP:InvalidArgumentShapeArgNotFound', dimension, argAnnotation.name));
                                elseif ~argTypeValid
                                    if isStaticMethod
                                        if ~isIntegerTypeDim && isMethodDim
                                            error(message('MATLAB:CPP:InvalidMethodAsShape', dimension,message('MATLAB:CPP:ShapeForStaticDims').getString));
                                        elseif ~isIntegerTypeDim && ~isMethodDim
                                            error(message('MATLAB:CPP:InvalidPropAsShape', dimension,message('MATLAB:CPP:ShapeForStaticDims').getString));
                                        elseif ~isStaticDim
                                            error(message('MATLAB:CPP:InvalidShapeForStaticMeth',dimension,obj.MATLABName));
                                        else
                                            error(message('MATLAB:CPP:InvalidMethodWithInputsAsShape',dimension,message('MATLAB:CPP:ShapeForStaticDims').getString));
                                        end  
                                    else
                                        if isStaticDim
                                            error(message('MATLAB:CPP:InvalidShapeForNonStaticMeth',dimension,obj.MATLABName));
                                        else
                                            error(message('MATLAB:CPP:InvalidArgumentNameShape',dimension, argAnnotation.name));
                                        end
                                    end
                                end
                            end
                        elseif isnumeric(dimension)
                            % Fixed dim
                            numericShapeAlreadyFound = true;
                            if not(dimension > 0)
                                error(message('MATLAB:CPP:InvalidNumericShapeValue'));
                            end
                        else
                            % Invalid shape element
                            error(message('MATLAB:CPP:InvalidArgumentShape'));
                        end
                    end
                end
            elseif(argAnnotation.storage==internal.mwAnnotation.StorageKind.Array)
                % if element type is pointer, it must be char * []
                if argType.Type.isPointerType
                    if iscell(shape(end))
                        dimension = shape{end};
                    else
                        dimension = shape(end);
                    end
                    if ~strcmp("nullTerminated", dimension)
                        error(message('MATLAB:CPP:CStringArrayLastDimension'));
                    end
                    if numel(shape) == 1
                        shape = 1;
                    else
                        shape = shape(1:end-1);
                    end
                end
                if not(isempty(argAnnotation.dimensions.toArray))
                    % Shape must be equal to the number of boxes in the array
                    if not(numel(shape) == argAnnotation.boxes)
                        error(message('MATLAB:CPP:InvalidArrayShapeNum', argAnnotation.name));
                    end
                    % If MLTYPE is string and the C++ argument is the fixed
                    % size array, the shape must be "nullTerminated"
                    if any(strcmp(argAnnotation.mwType, ["string", "string16", "string32"]))
                        if ~strcmp(shape(1), "nullTerminated") && ~contains(argAnnotation.cppType, "PtrArr")
                            error(message('MATLAB:CPP:InvalidCStringShape'));
                        end
                    else                    
                        % If shape is already present, make sure it's the same                      
                        for i = 1:numel(argAnnotation.dimensions.toArray)
                            if(iscell(shape))                      
                                dimVal = shape{i};
                            else
                                dimVal = shape(i);
                            end
                            if strcmp(dimVal, "nullTerminated")
                                error(message("MATLAB:CPP:InvalidShapeString",dimVal));
                            elseif not(isequal(dimVal, argAnnotation.dimensions(i).value))
                                error(message('MATLAB:CPP:InvalidArrayShapeValue',string(i),string(argAnnotation.dimensions(i).value)));
                            end
                        end
                    end
                else
                    if(ischar(shape))
                        shape = string(shape);
                    end
                    % Shape not predefined         
                    % Must be equal to the number of boxes in the array when the #boxes are greater than 1.
                    % ["d1","d2"] shape is supported for 1D boxed arrays.
                    if argAnnotation.boxes>1 && not(numel(shape) == argAnnotation.boxes)                        
                        error(message('MATLAB:CPP:InvalidArrayShapeNum', argAnnotation.name));
                    end

                    if ~argType.Type.isPointerType && any(strcmp(argAnnotation.mwType, ["string", "string16", "string32"]))
                        % This is the shape for char [] (NOT char *[]) and
                        % MLTYPE is 'string'. Must be "nullTerminated".
                        if ~strcmp(shape, "nullTerminated")
                            error(message('MATLAB:CPP:InvalidCStringShape'));
                        end
                    else
                        % All strings must be valid argument names
                        numericShapeAlreadyFound = false;
                        for dim = shape
                            if(iscell(dim))
                                dimension = dim{1};
                            else
                                dimension = dim;
                            end
                            if (ischar(dimension) || isstring(dimension))
                                % Variable dimension
                                if(numericShapeAlreadyFound)
                                    % Cannot have a variable dimension after a fixed
                                    % dimension
                                    error(message('MATLAB:CPP:InvalidShapeParamAfterVal'));
                                end
                                result = false;
                                if isMethodOutput
                                    result  =  clibgen.MethodDefinition.validateAndStoreDims(obj, dimension, isStaticMethod);
                                else
                                    result =  clibgen.MethodDefinition.isValidArgDim(obj, dimension);
                                end
                                if not(result)
                                    if ~iscell(shape) && ~isStringScalar(shape) && ~isnan(str2double(dimension)) % numeric dimension specified in a string array
                                        error(message('MATLAB:CPP:InvalidShapeParamNumericString'));
                                    else
                                        error(message('MATLAB:CPP:InvalidArgumentNameShape', dimension, argAnnotation.name));
                                    end
                                end
                            elseif isnumeric(dimension)
                                % Fixed dimension
                                numericShapeAlreadyFound = true;
                                if not(dimension > 0)
                                    error(message('MATLAB:CPP:InvalidNumericShapeValue'));
                                end
                            else
                                % Invalid shape element
                                error(message('MATLAB:CPP:InvalidArgumentShape'));
                            end
                        end
                    end
                end   
            elseif(argAnnotation.storage==internal.mwAnnotation.StorageKind.Vector)
                if not(isscalar(shape) && isnumeric(shape) && shape==1)         
                    error(message('MATLAB:CPP:InvalidShapeForVector'));
                end
            end
            valid = true;
        end
        
        function verifyNumElementsInBuffer(funcType, argAnnotation, bufferSize)
            cppParameterDims = argAnnotation.dimensions.toArray();
            try
                if ~isempty(cppParameterDims)
                    if ~isnumeric(bufferSize) || cppParameterDims(1).value ~= bufferSize
                        % if the C++ parameter is a fixed size array, the value of
                        % NumElementsInBuffer must be the same the size.
                            error(message('MATLAB:CPP:InvalidArrayBufferSizeValue', cppParameterDims(1).value));
                    end
                elseif isnumeric(bufferSize)
                    validateattributes(bufferSize, {'numeric'}, {'scalar', 'integer', 'positive'});
                elseif (isstring(bufferSize) && isscalar(bufferSize)) ||...
                        (ischar(bufferSize) && isvector(bufferSize))
                    [isValidDim, argExists] = clibgen.MethodDefinition.isValidArgDim(funcType, bufferSize);
                    if ~isValidDim
                        if argExists
                            % Argument exists; Must be invalid type
                            error(message('MATLAB:CPP:InvalidArgumentTypeBufferSize', bufferSize));
                        else
                            if isnan(str2double(bufferSize))
                                error(message('MATLAB:CPP:InvalidArgumentNameBufferSize', bufferSize));
                            else
                                error(message('MATLAB:CPP:BufferSizeValueInQuote', bufferSize));
                            end
                        end
                    end
                else
                    error(message('MATLAB:CPP:InvalidBufferSize'));
                end
            catch ME
                throwAsCaller(ME);
            end
        end

        function shapeKind = getShapeKind(shape)
            switch(shape)
                case "array"
                    shapeKind = internal.mwAnnotation.ShapeKind.Array;
                case "nullTerminated"
                    shapeKind = internal.mwAnnotation.ShapeKind.NullTerminated;
                case "scalar"
                    shapeKind = internal.mwAnnotation.ShapeKind.Scalar;
                case "undefined"
                    shapeKind = internal.mwAnnotation.ShapeKind.Undefined;
            end
        end
        
        function storageKind = getStorageKind(storage)
            switch(storage)
                case "reference"
                    storageKind = internal.mwAnnotation.StorageKind.Reference;
                case "value"
                    storageKind = internal.mwAnnotation.StorageKind.Value;
                case "array"
                    storageKind = internal.mwAnnotation.StorageKind.Array;
                case "pointer"
                    storageKind = internal.mwAnnotation.StorageKind.Pointer;
            end
        end
        
        function dimKind = getDimensionKind(dimType)
            switch(dimType)
                case "DataMember"
                    dimKind = internal.mwAnnotation.DimensionKind.DataMember;
                case "Method"
                    dimKind = internal.mwAnnotation.DimensionKind.Method;
                case "Parameter"
                    dimKind = internal.mwAnnotation.DimensionKind.Parameter;
            end
        end
        
        function updateValidType(libdef, argAnnotation)
           if(libdef.RenamingMap.isKey(argAnnotation.mwType))
               argAnnotation.validTypes(1) = ...
                   libdef.RenamingMap(argAnnotation.mwType);
           end
        end
        
        function result = isVoidPtrType(cppType)
            if strcmp(cppType, '[void]Ptr') || strcmp(cppType, '[void]ConstPtr') || strcmp(cppType, '[void]PtrConst') || strcmp(cppType, '[void]ConstPtrConst')
                result = true;
            else
                result = false;
            end
        end

        function result = isCharacterPointerNullTerminatedString(cppType,storage,mwType,shape)
            if contains(cppType,'char') && storage == internal.mwAnnotation.StorageKind.Pointer ...
                    && mwType == "string" && shape == "nullTerminated"
                result = true;
            else
                result = false;
            end
        end

        function result = isDoubleVoidPtrType(cppType)
            if strcmp(cppType, '[void]PtrPtr') || strcmp(cppType, '[void]ConstPtrPtr') ...
                    || strcmp(cppType, '[void]PtrPtrConst') ...
                    || strcmp(cppType, '[void]ConstPtrPtrConst')
                result = true;
            else
                result = false;
            end
        end
        
        function updatePtKeys(funcAnnotation)
            %generate multiple ptKeys for Function if more than one
            %MLType is specified for any plain void* argument

            %Clear the obsolete ptKeys list from previous build
            funcAnnotation.opaqueTypeInfo.ptKeys.clear;
            combinationCountMultipleMlTypes = funcAnnotation(1).opaqueTypeInfo.combinationCountMultipleMlTypes;
            if (combinationCountMultipleMlTypes > 1)
                for i = 1: combinationCountMultipleMlTypes
                    funcAnnotation.opaqueTypeInfo.ptKeys(end+1) = funcAnnotation.ptKey + "_" + i;
                end
            end
        end
        
        function verifyVoidPtr(fcn, mltype, name, argAnnotation, defLib, argPos)
            try
                isTypedef = false;
                opaqueTypeInfo = argAnnotation.opaqueTypeInfo;
                if ~(isempty(opaqueTypeInfo))
                    isTypedef = opaqueTypeInfo.isTypedef;
                end
                validMlTypes = argAnnotation.validTypes.toArray;
                validMlTypesToShow = clibgen.MethodDefinition.convertUIMlTypeArray(validMlTypes);
                isMlTypeList = (numel(mltype) > 1);
                % check for multiple MLTypes for plain void*
                if isMlTypeList && ~isTypedef
                    %List of MLTypes should be unique
                    if numel(mltype)~=numel(unique(mltype))
                        error(message('MATLAB:CPP:DuplicateMATLABTypeForVoidPtrArgument',name));
                    end
                    if (isempty(opaqueTypeInfo))
                        opaqueTypeInfo = internal.mwAnnotation.OpaqueTypeArgumentInfo(defLib.LibraryInterface.Model);
                    end
                    for i = 1:numel(mltype)
                        mlTypeName = mltype(i);
                        if ((clibgen.MethodDefinition.isFundamentalMlType(mlTypeName)) || (strcmp(mlTypeName,'string'))...
                                || (startsWith(mlTypeName, strcat("clib.array.",defLib.PackageName, "."))) ...
                                || (~startsWith(mlTypeName, strcat("clib.",defLib.PackageName, "."))))
                            error(message('MATLAB:CPP:InvalidMLTypeForVoidPtrArgument', name, message('MATLAB:CPP:ErrorMessageVoidPtrInputWithoutTypedef').getString));
                        elseif (startsWith(mlTypeName, strcat("clib.",defLib.PackageName, ".")))
                            opaqueTypeInfo.mwTypeNames(end+1) = mlTypeName;
                        end
                    end
                    argAnnotation.mwType = mltype(end);
                    argAnnotation.opaqueTypeInfo = opaqueTypeInfo;
                    if isa(fcn, "clibgen.FunctionDefinition")
                        fcnAnnotations = fcn.FunctionInterface.Annotations.toArray;
                    elseif isa(fcn, "clibgen.MethodDefinition")
                        fcnAnnotations = fcn.MethodInterface.Annotations.toArray;
                    elseif  isa(fcn, "clibgen.ConstructorDefinition")
                        fcnAnnotations = fcn.ConstructorInterface.Annotations.toArray;
                    end
                    
                    fcnAnnotations.opaqueTypeInfo.combinationCountMultipleMlTypes = fcnAnnotations.opaqueTypeInfo.combinationCountMultipleMlTypes * (numel(mltype));
                    if (isa(fcn, "clibgen.FunctionDefinition") && argPos == 1 && fcnAnnotations.opaqueTypeInfo.combinationCountMultipleMlTypes > 1)
                        for i = 1:fcnAnnotations.opaqueTypeInfo.combinationCountMultipleMlTypes
                            fcnAnnotations.opaqueTypeInfo.isDeleteFcnForMwTypes(i) = false;
                        end
                    end
                    fcn.CombinationCountMultipleMlTypes = fcnAnnotations.opaqueTypeInfo.combinationCountMultipleMlTypes;
                    %list of MLTypes not allowed for typedef void* input
                elseif isMlTypeList && isTypedef
                    error(message('MATLAB:CPP:InvalidMATLABTypeForNonVoidPtrArgument',name));
                else
                    if(strcmp(mltype,'string'))
                        error(message('MATLAB:CPP:InvalidArgumentTypeStringForVoid',name, strcat('clib.array.',defLib.PackageName,'.Char')));
                    end
                    isFundamentalMlType = clibgen.MethodDefinition.isFundamentalMlType(mltype);
                    % check if the specified MLType is of fundamental type
                    if isFundamentalMlType
                        % determining cppType/mlType for void* argument
                        argAnnotation.cppType = clibgen.MethodDefinition.getCppTypeForFundamentalMlType(mltype);
                        argAnnotation.mwType = mltype;
                        % void* argument is of valid typedef type
                    elseif ~isempty(validMlTypesToShow)
                        [found, ~] = ismember(mltype, validMlTypesToShow);
                        % check mltype is not in list of ValidMLTypes, check if it is class type or clib array type
                        if (~found && ~startsWith(mltype, strcat("clib.",defLib.PackageName, ".")) && ~startsWith(mltype, strcat("clib.array.",defLib.PackageName, ".")))
                            error(message('MATLAB:CPP:InvalidMLTypeForVoidPtrArgument', name, message('MATLAB:CPP:ErrorMessageVoidPtrInputTypedefIncludeTypedef', string(validMlTypesToShow)).getString));
                        end
                        argAnnotation.mwType = mltype;
                        % void* doesn't have a typedef
                    elseif ~isTypedef
                        if (~startsWith(mltype, strcat("clib.",defLib.PackageName, ".")) && (~startsWith(mltype, strcat("clib.array.",defLib.PackageName, "."))))
                            error(message('MATLAB:CPP:InvalidMLTypeForVoidPtrArgument', name, message('MATLAB:CPP:ErrorMessageVoidPtrInputWithoutTypedef').getString));
                        else
                            argAnnotation.mwType = mltype;
                        end
                        %typedef void* argument that doesn't have output of that typedef
                    elseif isempty(validMlTypesToShow) && isTypedef
                        if (~startsWith(mltype, strcat("clib.",defLib.PackageName, ".")) && (~startsWith(mltype, strcat("clib.array.",defLib.PackageName, ".")))) % void* typedef doesnt have an output
                            error(message('MATLAB:CPP:InvalidMLTypeForVoidPtrArgument',name, message('MATLAB:CPP:ErrorMessageVoidPtrInputTypedef').getString));
                        else
                            argAnnotation.mwType = mltype;
                        end
                    end
                end
            catch ME
                throwAsCaller(ME);
            end

        end
        
        function verifyVoidDoublePtr(obj, mltype, name, argAnnotation, defLib)
            validMlTypes = argAnnotation.validTypes.toArray;
            validMlTypesToShow = clibgen.MethodDefinition.convertUIMlTypeArray(validMlTypes);
            isTypedef = false;
            opaqueTypeInfo = argAnnotation.opaqueTypeInfo;
            if ~(isempty(opaqueTypeInfo))
                isTypedef = opaqueTypeInfo.isTypedef;
            end
            if ~isempty(validMlTypesToShow)
                [found, location] = ismember(mltype, validMlTypesToShow);
                if ~found
                    if(numel(validMlTypesToShow)==1)
                        error(message('MATLAB:CPP:InvalidMLTypeForVoidPtrArgument',name,string(validMlTypesToShow)));
                    end
                end
                argAnnotation.mwType = validMlTypes{location};
                % verifying MlType for plain void*
            elseif ~isTypedef
                if ~startsWith(mltype, strcat("clib.",defLib.PackageName, "."))
                    error(message('MATLAB:CPP:InvalidMLTypeForVoidPtrArgument',name,message('MATLAB:CPP:ErrMsgVoidPtrOutputWithoutTypedef').getString));
                else
                    argAnnotation.mwType = mltype;
                end
            end
        end
    end
    
    methods(Static, Access={?clibgen.ConstructorDefinition, ?clibgen.ClassDefinition,...
            ?clibgen.FunctionDefinition, ?clibgen.LibraryDefinition})
        % Returns a vector of input arg pointers/arrays whose MLTYPE is
        %   specified as MATLAB fundamental type.
        % definitionObj: ContructorDefinition, MethodDefinition, or FunctionDefinition object
        % interfaceObj: ConstructorInterface, MethodInterface, or FunctionInterface object
        function args = getFundamentalInputPointers(definitionObj, interfaceObj)
            annotationsArr =interfaceObj.Annotations.toArray;
            argNumel = numel(annotationsArr.inputs.toArray);
            args = [];
            inputArgAnnotations = annotationsArr.inputs.toArray;
            % Add args that ML fundamental pointer
            for i = 1:argNumel
                if clibgen.MethodDefinition.isFundamental(interfaceObj.Params(i).Type)&&...
                    (inputArgAnnotations(i).storage ==internal.mwAnnotation.StorageKind.Pointer||...
                    inputArgAnnotations(i).storage==internal.mwAnnotation.StorageKind.Array)
                    try
                        % Test if type is numeric, logical, or char
                        val = eval(definitionObj.Arguments(i).MATLABType + "(0)");
                        if isnumeric(val) || islogical(val) || ischar(val)
                            args = [args definitionObj.Arguments(i).MATLABType];
                        end
                    catch
                    end
                end
            end
        end
    end
    
    methods(Access=private)
        function annotationDim = convertDimensionInfo(obj, dim)
            if(dim.type == "parameter")
                annotationDim = internal.mwAnnotation.VariableDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                annotationDim.lengthVariableName = dim.value;
                annotationDim.cppPosition = dim.CppPosition;
                annotationDim.mwType = dim.MATLABType;
                annotationDim.shape = clibgen.MethodDefinition.getShapeKind(dim.Shape);
                annotationDim.storage = clibgen.MethodDefinition.getStorageKind(dim.Storage);
            elseif(dim.type == "value")
                annotationDim = internal.mwAnnotation.FixedDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                annotationDim.value = dim.value;
            end
        end
    end

    methods(Access=protected)
        function displayScalarObject(obj)
            try
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                h = sprintf("  " + className + " maps" + "\n\n" +       "    C++:    " + obj.CPPSignature + ...
                    "\n" + "    to " + "\n" +                           "    MATLAB: ");
                validate(obj);
                mlSignature = obj.MATLABSignature; 
                for i= 1:numel(mlSignature)
                    if (i==numel(mlSignature))
                        h = h + mlSignature{i} ;
                    else
                        h = h + mlSignature{i} + sprintf( "\n            ") ;
                    end
                end
                argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(obj, obj.MethodInterface);
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
        function obj = MethodDefinition(classDef,CPPSignature,methodInterface,description,detailedDescription,mlName,templateUniqName)
            %   METHODDEF = METHODDEFINITION(CLASSDEF,CPPSIGNATURE,METHODINTERFACE,DESCRIPTION,DETAILEDDESCRIPTION,MLNAME,TEMPLATEUNIQNAME)
            %   returns a METHODDEFINITION object with C++ Signature
            %   CPPSIGNATURE and MATLAB name MLNAME. MEHODINERFACE provides an
            %   interface to the function metadata.
            %   This constructor can only be called inside the class
            %   clibgen.ClassDefinition.
            
            try
                obj.Valid = false;
                p = inputParser;
                addRequired(p,'classDefintion', @(x)(isa(x,"clibgen.ClassDefinition")));
                addRequired(p,'CPPSignature',   @(x)validateattributes(x, {'char','string'},{'scalartext'}));
                addRequired(p,'methodInterface',@(x)(isa(x,"internal.cxxfe.ast.types.Method")));
                addRequired(p,'Description',    @(x)validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,'DetailedDescription',"",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,'mlName',"",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,'templateUniqueName',"",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                p.KeepUnmatched = false;
                parse(p,classDef, CPPSignature,methodInterface,description);
                obj.DefiningClass = classDef;
                obj.MethodInterface = methodInterface;
                obj.CPPSignature = CPPSignature;
                annotationsArr = obj.MethodInterface.Annotations.toArray;
                obj.MATLABName = annotationsArr(1).name;
                % Use mlName supplied if it is not empty and different
                % than the annotated value
                if ((mlName~="") && ~strcmp(mlName,obj.MATLABName))
                    try
                        obj.verifyMATLABName(mlName, false);
                    catch
                        error(message("MATLAB:CPP:InvalidNewMATLABName", mlName, ...
                            obj.MATLABName, 'MATLABName'));
                    end
                    % Ensure MATLABName does not match the TemplateUniqueName
                    % when overload is possible
                    if ~isempty(annotationsArr(1).templateInstantiation)
                        uniqueName = annotationsArr(1).templateInstantiation.templateUniqueName;
                        if ((templateUniqName~="") && ~strcmp(templateUniqName,uniqueName))
                            uniqueName = templateUniqName;
                        end
                        if (annotationsArr(1).templateInstantiation.isOverloadPossible && ...
                                strcmp(mlName,uniqueName))
                            error(message("MATLAB:CPP:NewNameAlreadyExists", 'MATLABName', mlName, ...
                                'TemplateUniqueName'));
                        end
                    end
                    obj.MATLABName = mlName;
                    annotationsArr(1).name = obj.MATLABName;
                end
                % Check if template instantiation of a method
                if ~isempty(annotationsArr(1).templateInstantiation)
                    obj.TemplateUniqueName = annotationsArr(1).templateInstantiation.templateUniqueName;
                    % Use templateUniqName supplied if it is not empty and different
                    % than the annotated value
                    if ((templateUniqName~="") && ~strcmp(templateUniqName,obj.TemplateUniqueName))
                        try
                            obj.verifyMATLABName(templateUniqName, false);
                        catch
                            error(message("MATLAB:CPP:InvalidNewMATLABName", templateUniqName, ...
                                obj.TemplateUniqueName, 'TemplateUniqueName'));
                        end
                        % Ensure TemplateUniqueName does not match the MATLABName
                        % when overload is possible
                        uniqueName = obj.MATLABName;
                        if ((mlName~="") && ~strcmp(mlName,obj.MATLABName))
                            uniqueName = mlName;
                        end
                        if (annotationsArr(1).templateInstantiation.isOverloadPossible && ...
                                strcmp(templateUniqName,uniqueName))
                            error(message("MATLAB:CPP:NewNameAlreadyExists", 'TemplateUniqueName', ...
                                mlName, 'MATLABName'));
                        end
                        obj.TemplateUniqueName = templateUniqName;
                        annotationsArr(1).templateInstantiation.templateUniqueName = obj.TemplateUniqueName;
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
                    if not(clibgen.MethodDefinition.isFundamental(methodInterface.Params(i).Type))                    
                        clibgen.MethodDefinition.updateValidType(classDef.DefiningLibrary, obj.ArgAnnotations(i));
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
                    obj.Output(1).DimAdded = false;
                    obj.Output(1).CppPosition = obj.OutputAnnotation.cppPosition;
                    obj.Output(1).MemberOrMethodDims = {};
                    if not(isempty(obj.OutputAnnotation.description))
                        obj.Output(1).Description = obj.OutputAnnotation.description;
                    end
                    if not(clibgen.MethodDefinition.isFundamental(methodInterface.Type.RetType))
                        clibgen.MethodDefinition.updateValidType(classDef.DefiningLibrary, obj.OutputAnnotation);
                    end
                end
                
                obj.Description = description;
                obj.DetailedDescription = detailedDescription;
                opaqueTypeInfoAnnotation = annotationsArr.opaqueTypeInfo;
                if ~(isempty(opaqueTypeInfoAnnotation))
                    obj.CombinationCountMultipleMlTypes = opaqueTypeInfoAnnotation.combinationCountMultipleMlTypes;
                else
                    opaqueTypeInfoAnnotation = internal.mwAnnotation.OpaqueTypeFunctionInfo(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                    obj.CombinationCountMultipleMlTypes = opaqueTypeInfoAnnotation.combinationCountMultipleMlTypes;
                    annotationsArr.opaqueTypeInfo = opaqueTypeInfoAnnotation;
                end
            catch ME
                throw(ME);
            end
        end
        
        function addMethodToClass(obj)
            [transArgs, transOut] = clibgen.internal.transformArgs(obj.Arguments, obj.Output);
            % For each argument, update annotation by adding shape, direction, isHidden and
            % dimensions
            for i = 1:numel(transArgs)
                argAnn = obj.ArgAnnotations(i); % Annotations for this argument
                argAnn.shape = obj.ShapeValues(transArgs(i).Shape);
                argAnn.direction = obj.DirectionValues(transArgs(i).Direction);
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
                obj.OutputAnnotation.shape = obj.ShapeValues(transOut.Shape);
                obj.OutputAnnotation.direction = obj.DirectionValues(transOut.Direction);
                obj.OutputAnnotation.isHidden = transOut.IsHidden;
                %Populate dimensions
                if(obj.OutputAnnotation.shape == internal.mwAnnotation.ShapeKind.Array)
                    obj.OutputAnnotation.dimensions.clear;
                    for dim = transOut.dimensions
                        if(dim.type == "parameter")
                            annotationDim = internal.mwAnnotation.VariableDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                            annotationDim.lengthVariableName = dim.value;
                            annotationDim.cppPosition = dim.CppPosition;
                            annotationDim.mwType = dim.MATLABType;
                            annotationDim.dimKind = obj.getDimensionKind(dim.DimType);
                            annotationDim.storage = obj.getStorageKind(dim.Storage);
                            if annotationDim.dimKind ~= internal.mwAnnotation.DimensionKind.Parameter
                                annotationDim.shape  = obj.OutputAnnotation.shape;
                            else
                                annotationDim.shape = obj.getShapeKind(dim.Shape);  
                            end
                            % set  SetAccess for data members to Private if
                            % used as dimension
                            if (obj.getDimensionKind(dim.DimType) == internal.mwAnnotation.DimensionKind.DataMember)
                                classType = obj.DefiningClass.ClassInterface;
                                props = classType.Members.toArray;
                                dimProp = props(arrayfun(@(x) strcmp(x.Name, dim.value), props));
                                if not(isempty(dimProp))
                                    if not(isempty(dimProp.Annotations))
                                        dimProp.Annotations(1).isSettable = false;
                                    end
                                end
                            end  
                        elseif(dim.type == "value")
                            annotationDim = internal.mwAnnotation.FixedDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                            annotationDim.value = dim.value;
                        end
                        obj.OutputAnnotation.dimensions.add(annotationDim);
                    end
                end
            end
            methodAnnotations = obj.MethodInterface.Annotations.toArray;
            methodAnnotations(1).integrationStatus.inInterface = true;
            %update PtKeys if there are multiple MLTypes
            clibgen.MethodDefinition.updatePtKeys(methodAnnotations(1));
        end
    end
    
    methods(Access=public)
        function defineArgument(obj, name, mltype, varargin)
            try
                obj.Valid = false;
                p = inputParser;
                addRequired(p,"MethodDefinition", @(x)(isa(x, "clibgen.MethodDefinition")));
                addRequired(p,"MATLABName",       @(x)obj.verifyMATLABName(x, true));
                addRequired(p,"MATLABType",       @(x)validateattributes(x,{'char', 'string'},{'vector'}));
                addParameter(p,"Description","",  @(x)validateattributes(x, {'char','string'},{'scalartext'}));
                addParameter(p, "AddTrailingSingletons", false, @(x) validateattributes(x, {'logical'},{'scalar'}))
                parse(p, obj, name, mltype);
                numvarargin = numel(varargin);
                name = string(name);
                mltype = string(mltype);
                argAnnotation = [];
                for annotation = obj.ArgAnnotations
                    if(annotation.name == name)
                        argAnnotation = annotation;
                        argPos = argAnnotation.cppPosition;
                    end
                end
                if(isempty(argAnnotation))
                    error(message("MATLAB:CPP:ArgumentNotFound",name,obj.CPPSignature));
                end
                args = obj.MethodInterface.Params.toArray;
                argType = args(argPos).Type;
                isVoidPtr = clibgen.MethodDefinition.isVoidPtrType(argAnnotation.cppType);
                isDoubleVoidPtr = clibgen.MethodDefinition.isDoubleVoidPtrType(argAnnotation.cppType);
                isComplex = argAnnotation.isComplex;
                validMlTypes = argAnnotation.validTypes.toArray;
                % Add mlType if needed
                if (isVoidPtr)
                    clibgen.MethodDefinition.verifyVoidPtr(obj, mltype, name, argAnnotation,...
                        obj.DefiningClass.DefiningLibrary, argPos);
                elseif (isDoubleVoidPtr)
                    clibgen.MethodDefinition.verifyVoidDoublePtr(obj, mltype, name, ...
                        argAnnotation, obj.DefiningClass.DefiningLibrary);
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
    
                argument.MATLABName = string(name);
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
                        if(argAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer || ...
                            argAnnotation.storage==internal.mwAnnotation.StorageKind.Array)
                            error(message('MATLAB:CPP:ShapeAbsent', name));
                        end
                        obj.verifyDirection(varargin{1}, argAnnotation, argType, "method");
                        argument.Direction = string(varargin{1});
                        argument.Shape = argAnnotation.shape;
                    case 2
                        obj.verifyDirection(varargin{1}, argAnnotation, argType, "method");
                        argument.Direction = string(varargin{1});
                        shape = convertCharsToStrings(varargin{2});
                        obj.verifyShape(obj.MethodInterface, argAnnotation, shape, argType, false);
                        argument.Shape = varargin{2};
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
                            clibgen.MethodDefinition.verifyNumElementsInBuffer(obj.MethodInterface, argAnnotation, bufferSize);
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
                                if(isa(varargin{ind}, 'clibgen.FunctionDefinition'))
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
    
                % No errors. Find and update argument
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
                addRequired(p, "MethodDefinition", @(x)(isa(x, "clibgen.MethodDefinition")));
                addRequired(p,"MATLABName", @(x)obj.verifyMATLABName(x, true));
                addRequired(p,"MATLABType", @(x)validateattributes(x,{'char', 'string'},{'scalartext'}));
                addParameter(p,'Description',"", @(x)validateattributes(x, {'char','string'},{'scalartext'}));
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
                outputType = obj.MethodInterface.Type.RetType;
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
                elseif isVoidPtr && ~isTypedef
                    if ~startsWith(mltype, strcat("clib.",obj.DefiningClass.DefiningLibrary.PackageName, "."))
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
                        obj.verifyShape(obj, obj.OutputAnnotation, varargin{1}, outputType, true);
                        obj.Output.Shape = varargin{1};
                    case 2
                        % Error - 3rd argument must be "Shape", followed by N-V
                        % pair for "DeleteFcn"
                        error(message('MATLAB:CPP:IncorrectInputs', 'defineOutput'));
                    case 3
                        % Shape and DeleteFcn are provided
                        obj.verifyShape(obj, obj.OutputAnnotation, varargin{1}, outputType, true);
                        obj.Output.Shape = varargin{1};
                        isNullTermString = clibgen.MethodDefinition.isCharacterPointerNullTerminatedString(obj.OutputAnnotation.cppType, ...
                            obj.OutputAnnotation.storage, obj.Output.MATLABType, obj.Output.Shape);
                        if(varargin{2}=="DeleteFcn")
                            % DeleteFcn not supported for const objects
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
                if not(obj.isFundamental(outputType)) && not(mltype=="string") && ~(obj.OutputAnnotation.isComplex)
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
    
    methods
        function sig = get.MATLABSignature(obj)
            validate(obj);
            [transArgs, transOut] = clibgen.internal.transformArgs(obj.Arguments, obj.Output);
            sig = clibgen.internal.computeMATLABSignature(obj.MATLABName,...
                transArgs, transOut, obj.CombinationCountMultipleMlTypes);
        end
        
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            obj.Description = desc;
            annotationsArr = obj.MethodInterface.Annotations.toArray;%#ok<MCSUP>
            annotationsArr(1).description = desc;
        end
        
        function set.DetailedDescription(obj, details)
            validateattributes(details,{'char','string'},{'scalartext'});
            obj.DetailedDescription = details;
            annotationsArr = obj.MethodInterface.Annotations.toArray;%#ok<MCSUP>
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
        function needsValidation = needsMltypeStructValidation(obj)
            needsValidation = ~isempty(obj.MlTypesForValidation);
        end
        function mlName = getMATLABName(obj)
            mlName = obj.MATLABName;
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
end
