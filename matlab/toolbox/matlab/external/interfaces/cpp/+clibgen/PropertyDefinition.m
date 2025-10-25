classdef PropertyDefinition < handle
    % PropertyDefinition MATLAB definition of a public property of C++ class
    % This class contains the MATLAB definition for public properties of C++ class present in the header
    % PropertyDefinition properties:
    %   Description - Description of the public property as provided by the publisher
    %   DetailedDescription - Detailed description of the public property as provided by the publisher
    
    % Copyright 2018-2024 The MathWorks, Inc.

    properties(Access=public)
        Description         string
        DetailedDescription string
    end    
    properties(SetAccess=private)
        CPPName    string
        MATLABType string
        Shape
    end
    properties(SetAccess=private, WeakHandle)
        DefiningClass clibgen.ClassDefinition
    end
    properties(Access=private)
        PropertyInterface internal.cxxfe.ast.types.Member
    end
    methods(Access=?clibgen.ClassDefinition)
        function obj = PropertyDefinition(classDef, cppName, propertyInterface, mlType, shape, description, detailedDescription)
            %   PROPERTYDEF = PROPERTYDEFINITION(CLASSDEF,CPPNAME,PROPERTYINTERFACE,MLNAME,SHAPE,DESCRIPTION,DETAILEDDESCRIPTION)
            %   returns a PROPERTYDEFINITION object with C++ Name CPPNAME
            %   and MATLAB name MLNAME. PROPERTYINTERFACE provides an
            %   interface to the function metadata.
            %   This constructor can only be called inside the class
            %   clibgen.ClassDefinition.
            
            obj.DefiningClass = classDef;
            obj.CPPName = cppName;
            obj.MATLABType = mlType;
            obj.PropertyInterface = propertyInterface;
            obj.Shape = shape;
            obj.Description = description;
            obj.DetailedDescription = detailedDescription;
        end

        % Function returns true if method is defined as shape 
        function isMethodDefinedAsShape = checkIfMethodDefinedAsShape(obj)
            isMethodDefinedAsShape = false;
            if ~isempty(obj.DefiningClass.Methods)
                if find([obj.DefiningClass.Methods.MATLABName] == string(obj.Shape))
                    isMethodDefinedAsShape = true;
                    return;
                end
            end
        end

        function addPropertyToClass(obj, classAnnotations)
            propertyAnnotations = obj.PropertyInterface.Annotations.toArray;
            prop.Shape = obj.Shape;
            prop.Storage = lower(string(propertyAnnotations(1).storage));
            prop.MATLABType = obj.MATLABType;
            modifiedProp = clibgen.internal.modifyShape(prop);
            propertyAnnotations(1).shape = clibgen.MethodDefinition.ShapeValues(modifiedProp.Shape);
            % add dimensions for array property
            if propertyAnnotations(1).shape == internal.mwAnnotation.ShapeKind.Array
                dimensions = clibgen.internal.getDimensions(prop);
                propertyAnnotations(1).dimensions.clear;
                for dim = dimensions
                    if(dim.type == "parameter")
                        annotationDim = internal.mwAnnotation.VariableDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                        annotationDim.lengthVariableName = dim.value;
                        % find property that is used as dimension in shape
                        props = obj.DefiningClass.ClassInterface.Members.toArray;
                        dimProp = props(arrayfun(@(x) strcmp(x.Name, dim.value), props));
                        if not(isempty(dimProp))
                            if not(isempty(dimProp.Annotations))
                                % Make the property used as dimension
                                dimProp.Annotations(1).isSettable = false;
                                dimProp.Annotations(1).isDefinedAsShape = true;
                                annotationDim.cppPosition = dimProp.Annotations(1).cppPosition;
                                annotationDim.mwType = dimProp.Annotations(1).mwType;
                                annotationDim.dimKind = internal.mwAnnotation.DimensionKind.DataMember;
                            end
                        else
                            % find method that is used as dimension in shape
                            methods = obj.DefiningClass.ClassInterface.Methods.toArray;
                            methodDim = methods(arrayfun(@(x) strcmp(x.Name, dim.value), methods));
                            methodAnno = methodDim(arrayfun(@(x) isempty(x.Annotations(1).inputs.toArray), methodDim));
                            methodRetOutput  = methodAnno.Annotations(1).outputs.toArray;
                            annotationDim.cppPosition = methodAnno.Annotations(1).cppPosition;
                            annotationDim.mwType = methodRetOutput.mwType;
                            annotationDim.dimKind = internal.mwAnnotation.DimensionKind.Method;
                            classAnnotations(1).cppStructType = internal.mwAnnotation.StructConvType.NonPOD;
                        end
                        annotationDim.shape = internal.mwAnnotation.ShapeKind.Scalar;
                        annotationDim.storage = internal.mwAnnotation.StorageKind.Value;
                    elseif(dim.type == "value")
                        annotationDim = internal.mwAnnotation.FixedDimension(obj.DefiningClass.DefiningLibrary.LibraryInterface.Model);
                        annotationDim.value = dim.value;
                    end
                    propertyAnnotations(1).dimensions.add(annotationDim);
                end
            end
            propertyAnnotations(1).integrationStatus.inInterface = true;
        end
    end
    methods(Static, Access={?clibgen.ClassDefinition, ?clibgen.PropertyDefinition, ?clibgen.MethodDefinition})
        function verifyShape(classType, propertyAnnotation, shape, propertyType, propName)
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
            
            % Throw an exception if the shape vector contains a size that
            % is not 1 for value type
            if(propertyAnnotation.storage==internal.mwAnnotation.StorageKind.Value)
                if not(isscalar(shape) && isnumeric(shape) && shape==1)                    
                    error(message('MATLAB:CPP:InvalidPropertyShapeScalar', propName));
                end
            elseif(propertyAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer)
                % Pointer to a class type can only be scalar
                if(~clibgen.MethodDefinition.isFundamental(propertyType) && ...
                        ~startsWith(propertyAnnotation.mwType, "clib.array."))
                    if not(isscalar(shape) && isnumeric(shape) && shape==1) % shape needs to be a value of 1
                        error(message('MATLAB:CPP:NoArraySupportForType', clibgen.MethodDefinition.makeUIMlType(propertyAnnotation.mwType)));
                    end
                end
                % If this property is a string, then the only
                % acceptable shape is "nullTerminated"
                if(clibgen.MethodDefinition.makeUIMlType(propertyAnnotation.mwType) == "string")
                    if not(isstring(shape) && isscalar(shape) && shape == "nullTerminated")
                        error(message('MATLAB:CPP:InvalidCStringShape'));
                    end
                else
                    % Non-string type, all dims must be fixed width or strings with valid
                    % property names
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
                                error(message('MATLAB:CPP:InvalidShapePropAfterVal'));
                            end
                            props = classType.Members.toArray;
                            propInterface = props(arrayfun(@(x) strcmp(x.Name, propName), props));
                            isStaticProp = (propInterface.StorageClass == internal.cxxfe.ast.StorageClassKind.Static);
                            [result,~,~,isMethodDim,dimExists,isIntegerTypeDim,isStaticDim] = clibgen.PropertyDefinition.isValidMethodOrMemberDim(classType, dimension, isStaticProp);
                            if ~result
                                if ~iscell(shape) && ~isStringScalar(shape) && ~isnan(str2double(dimension)) % numeric dimension specified in a string array
                                    error(message('MATLAB:CPP:InvalidShapePropNumericString'));
                                else
                                    if isStaticProp
                                        if ~dimExists
                                            error(message('MATLAB:CPP:ShapeNotFoundForProp', dimension,message('MATLAB:CPP:ShapeForStaticDims').getString));
                                        elseif isMethodDim && ~isIntegerTypeDim
                                            error(message('MATLAB:CPP:InvalidMethodAsShape', dimension,message('MATLAB:CPP:ShapeForStaticDims').getString));
                                        elseif ~isMethodDim && ~isIntegerTypeDim
                                            error(message('MATLAB:CPP:InvalidPropAsShape', dimension,message('MATLAB:CPP:ShapeForStaticDims').getString));
                                        elseif ~isStaticDim
                                            error(message('MATLAB:CPP:InvalidShapeForStaticProp',dimension,propName));
                                        else
                                            error(message('MATLAB:CPP:InvalidMethodWithInputsAsShape',dimension,message('MATLAB:CPP:ShapeForStaticDims').getString));
                                        end
                                    else
                                        if ~dimExists
                                            error(message('MATLAB:CPP:ShapeNotFoundForProp', dimension,message('MATLAB:CPP:ShapeForNonStaticDims').getString));
                                        elseif isMethodDim && ~isIntegerTypeDim
                                            error(message('MATLAB:CPP:InvalidMethodAsShape', dimension,message('MATLAB:CPP:ShapeForNonStaticDims').getString));
                                        elseif ~isIntegerTypeDim
                                            error(message('MATLAB:CPP:InvalidPropAsShape', dimension,message('MATLAB:CPP:ShapeForNonStaticDims').getString));
                                        elseif isStaticDim
                                            error(message('MATLAB:CPP:InvalidShapeForNonStaticProp',dimension,propName));
                                        else
                                            error(message('MATLAB:CPP:InvalidMethodWithInputsAsShape',dimension,message('MATLAB:CPP:ShapeForNonStaticDims').getString));
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
            elseif(propertyAnnotation.storage==internal.mwAnnotation.StorageKind.Array)
                % Shape must be equal to the number of boxes in the array
                boxes = numel(propertyAnnotation.dimensions.toArray);
                if not(numel(shape) == boxes)                        
                    error(message('MATLAB:CPP:InvalidArrayShapeNum', propName));
                end
                % If shape is already present, make sure it's the same                      
                for i = 1:numel(propertyAnnotation.dimensions.toArray)
                    if(iscell(shape))                      
                        dimVal = shape{i};
                    else
                        dimVal = shape(i);
                    end
                    if not(isequal(dimVal, propertyAnnotation.dimensions(i).value))
                        error(message('MATLAB:CPP:InvalidArrayShapeValue',string(i),string(propertyAnnotation.dimensions(i).value)));
                    end
                end
            elseif(propertyAnnotation.storage==internal.mwAnnotation.StorageKind.Vector)
                if not(isscalar(shape) && isnumeric(shape) && shape==1)
                    error(message('MATLAB:CPP:InvalidShapeForVector'));
                end
            end
        end
        function [result, cppPosition, mwType, isMethodDim, dimExists, isIntegerTypeDim, isStaticDim] = isValidMethodOrMemberDim(classType, dimName, isStatic)
            dimName = string(dimName);
            % get property
            props = classType.Members.toArray;
            dimProp = props(arrayfun(@(x) strcmp(x.Name, dimName), props));
            cppPosition = 0;
            mwType = '';
            isMethodDim = false;
            dimExists = false;
            isIntegerTypeDim = false;
            isStaticDim = false;
            if not(isempty(dimProp))
                if not(isempty(dimProp.Annotations))
                    dimPropAnnot = dimProp.Annotations(1);
                    dimPropType = dimProp.Type;
                    dimExists = true;
                    if isa(internal.cxxfe.ast.types.Type.getUnderlyingType(dimPropType), 'internal.cxxfe.ast.types.IntegerType')
                       isIntegerTypeDim = true;
                    end
                    if dimProp.StorageClass == internal.cxxfe.ast.StorageClassKind.Static
                       isStaticDim = true;
                    end
                    if (dimPropAnnot.integrationStatus.definitionStatus == internal.mwAnnotation.DefinitionStatus.FullySpecified &&...
                        isIntegerTypeDim && dimPropAnnot.storage == internal.mwAnnotation.StorageKind.Value && ...
                        dimProp.Access == internal.cxxfe.ast.types.AccessSpecifierKind.Public && ((isStatic && isStaticDim) || (~isStatic && ~isStaticDim)))
                        % property type should be of public integer type, value type
                        % For non-static member, dimensions should be
                        % non-static and viceversa
                        result = true;
                        cppPosition = dimPropAnnot.cppPosition;
                        mwType = dimPropAnnot.mwType;
                        return;
                    end
                end
            else
                methods = classType.Methods.toArray;
                methodDim = methods(arrayfun(@(x) strcmp(x.Name, dimName), methods));
                for index =  1:length(methodDim)
                    if not(isempty(methodDim(index).Annotations))
                        methodDimAnnot = methodDim(index).Annotations(1);
                        methodDimRetType = methodDim(index).Type.RetType;
                        inputArguments = methodDimAnnot.inputs.toArray;
                        dimExists = true;
                        isMethodDim = true;
                        if isa(internal.cxxfe.ast.types.Type.getUnderlyingType(methodDimRetType), 'internal.cxxfe.ast.types.IntegerType')
                            isIntegerTypeDim = true;
                        end
                        if methodDim(index).StorageClass == internal.cxxfe.ast.StorageClassKind.Static
                           isStaticDim = true;
                        end
                        if (methodDimAnnot.integrationStatus.definitionStatus == internal.mwAnnotation.DefinitionStatus.FullySpecified &&...
                               isIntegerTypeDim && methodDim(index).Access == internal.cxxfe.ast.types.AccessSpecifierKind.Public && ...
                                isempty(inputArguments) && ((isStatic && isStaticDim) || (~isStatic && ~isStaticDim)))
                            % Method type should be of public integer
                            % type with zero input arguments
                            % For non-static method, dimensions should be
                            % non-static and viceversa
                            result = true;
                            cppPosition = methodDimAnnot.cppPosition;
                            methodOutput = methodDimAnnot.outputs.toArray;
                            mwType = methodOutput.mwType;
                            return;
                        end
                    end
                end
            end
            result = false;
        end
    end
    methods(Access=public)
        function fundamental = isFundamental(obj)
            fundamental = clibgen.MethodDefinition.isFundamental(obj.PropertyInterface.Type);
        end
        function struct = isStructType(obj)
            uType = internal.cxxfe.ast.types.Type.getUnderlyingType(obj.PropertyInterface.Type);
            struct = isStructType(uType);
        end
    end
    methods
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            annotations = obj.PropertyInterface.Annotations.toArray;%#ok<MCSUP>
            annotations(1).description = desc;
            obj.Description = desc;
        end

        function set.DetailedDescription(obj, details)
            validateattributes(details,{'char','string'},{'scalartext'});
            annotations = obj.PropertyInterface.Annotations.toArray;%#ok<MCSUP>
            annotations(1).detailedDescription = details;
            obj.DetailedDescription = details;
        end
    end
end
