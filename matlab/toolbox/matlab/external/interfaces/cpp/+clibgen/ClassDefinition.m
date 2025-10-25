classdef ClassDefinition < handle & matlab.mixin.CustomDisplay
    % ClassDefinition MATLAB definition of a C++ class
    % This class contains the MATLAB definition for a C++ class present in the header
    % ClassDefinition properties:
    %   Description         - Description of the class as provided by the publisher
    %   MATLABName          - Name of the C++ class in MATLAB
    %   CPPName             - Name of the class in C++ header
    %   Methods             - Public Methods present in the C++ class
    %   Constructors        - Public Constructors present in the C++ class
    %   Properties          - Public Data Members present in the C++ class
    %   DefiningLibrary     - Library containing the class
    %   DetailedDescription - Detailed description of the class as provided by the publisher
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Access=public)
        Description         string
        DetailedDescription string
        cppStructType       internal.mwAnnotation.StructConvType
    end
    properties(GetAccess={?clibgen.PropertyDefinition, ?clibgen.MethodDefinition})
        ClassInterface         internal.cxxfe.ast.types.StructType
    end
    properties(SetAccess=private)
        MATLABName      string
        CPPName         string
        Methods         clibgen.MethodDefinition
        Constructors    clibgen.ConstructorDefinition
        Properties      clibgen.PropertyDefinition
    end
    properties(SetAccess=private, WeakHandle)
        DefiningLibrary clibgen.LibraryDefinition
    end
    methods(Access=private)
        function valid = verifyMethod(obj, cppsignature)
            validateattributes(cppsignature,{'char','string'},{'scalartext','nonempty'});
            if(strlength(cppsignature)==0)
                error(message('MATLAB:expectedNonempty'));
            end
            % Error out if an attempt is made to add the same method again
            if(~isempty(obj.Methods.findobj('CPPSignature', cppsignature)))
                error(message('MATLAB:CPP:FunctionExists', cppsignature));
            end
            valid = true;
        end
        
        function valid = verifyConstructor(obj, cppsignature)
            validateattributes(cppsignature,{'char','string'},{'scalartext'});
            % Error out if an attempt is made to add the same method again
            if(~isempty(obj.Constructors.findobj('CPPSignature', cppsignature)))
                error(message('MATLAB:CPP:FunctionExists', cppsignature));
            end
            valid = true;
        end
        
        function valid = verifyProperty(obj, propertyname)
            validateattributes(propertyname,{'char','string'},{'scalartext'});
            % Method must not be added twice
            if(~isempty(obj.Properties.findobj('CPPName', propertyname)))
                error(message('MATLAB:CPP:PropertyExists', propertyname));
            end
            valid = true;
        end

        function srBaseType = getBaseType(~, type)
            srType = internal.cxxfe.ast.types.Type.skipTyperefs(type);
            if srType.isPointerType || srType.isArrayType
                srBaseType = internal.cxxfe.ast.types.Type.skipTyperefs(srType.Type);
            else
                srBaseType = srType;
            end
        end
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            try
                className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                h = sprintf("  " + className + " which maps C++ Class " + obj.CPPName + ...
                    "\n" + "                  to MATLAB " + obj.summary);
                disp(h);
            catch ex
                disp(h + "[]");
                fprintf("\n   The function is not valid. " + ex.message + "\n" );
            end
        end
    end
    
    methods(Access=?clibgen.LibraryDefinition)
        function obj = ClassDefinition(libraryDef, CPPName, classInterface, mlName, description, detailedDescription, structConvType)
            %ClassDefinition constructor
            %   CLSDEF = CLASSDEFINITION(LIBDEF,CPPNAME,CLASSINTERFACE,MLNAME,DESCRIPTION,DETAILEDDESCRIPTION)
            %   returns a CLASSDEFINITION object C++ name CPPNAME and
            %   MATLAB name MLNAME. The CLASSINTERFACE provides an interface
            %   to the class metadata.
            %   This constructor can only be called inside the class
            %   clibgen.LibraryDefinition.
            p = inputParser;
            addRequired(p,'libraryDefintion',@(x)(isa(x,"clibgen.LibraryDefinition")));
            addRequired(p,'CPPName',@(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addRequired(p,'classInterface',@(x)(isa(x,"internal.cxxfe.ast.types.StructType")));
            addRequired(p,'mlname', @(x)validateattributes(x, {'char','string'},{'scalartext', 'nonempty'}));
            addRequired(p,'Description', @(x)validateattributes(x, {'char','string'},{'scalartext'}));
            addParameter(p,'DetailedDescription',"",@(x)validateattributes(x, {'char','string'},{'scalartext'}));
            p.KeepUnmatched = false;
            parse(p,libraryDef,CPPName,classInterface,mlName,description);
            obj.DefiningLibrary = libraryDef;
            obj.ClassInterface = classInterface;
            obj.CPPName = string(CPPName);
            obj.MATLABName = string(mlName);
            obj.Description = description;
            obj.DetailedDescription = detailedDescription;
            obj.cppStructType = structConvType;
        end
        
        function addToLibrary(obj,classArrays)
            for ctor = obj.Constructors
                addConstructorToClass(ctor);
            end
            for method = obj.Methods
                addMethodToClass(method);
            end
            classAnnotations = obj.ClassInterface.Annotations.toArray;
            for prop = obj.Properties
                addPropertyToClass(prop, classAnnotations(1));
            end

            classAnnotations(1).integrationStatus.inInterface = true;
            classAnnotations(1).name = obj.MATLABName;
            classAnnotations(1).cppStructType = obj.cppStructType;
            if (ismember(obj.MATLABName, classArrays))
                classAnnotations(1).needArray = true;
            end

            % update inInterface field for all owning scope except the
            % compilation unit which has mwMetadata annotations and not
            % ScopeAnnotation
            parent = obj.ClassInterface.OwningScope;
            while (~isempty(parent) && ~isa(parent,"internal.cxxfe.ast.source.CompilationUnit"))
                scopeAnnotations = parent.Annotations.toArray;
                scopeAnnotations(1).integrationStatus.inInterface = true;
                parent = parent.Parent();
            end
        end

        function isStructNonPOD = validateIfClassIsNonPOD(obj)
            isStructNonPOD = false;
            % checks if the class is nonpod or all the properties in the
            % class is not defined then return nonpod
            if obj.cppStructType == internal.mwAnnotation.StructConvType.NonPOD || ...
                length(obj.Properties) ~= length(obj.ClassInterface.Members.toArray)
                isStructNonPOD = true;
                return;
            end
            % If a method is defined as shape for any of the
            % property then the class becomes nonpod
            for prop = obj.Properties
                if prop.checkIfMethodDefinedAsShape
                    isStructNonPOD = true;
                    return;
                end
            end
        end

        % Returns scalar MwType if input is of array type
        % if input = clib.array.lib.MyStruct, output = clib.lib.MyStruct
        function clibScalarMwType  = getClibScalarMwType(obj,clibMwType)
            clibScalarMwType = clibMwType;
            if strfind(clibScalarMwType,"clib.array") == 1
                clibScalarMwType = "clib." + extractAfter(clibScalarMwType,11);
            end
        end

        function [isStructNonPOD, visitedStructs] =  updatePODStatusHelper(obj, parentStructs, visitedStructs)
            % Initial parsing of the header file determines if a struct is
            % a POD, PotentialPOD or NonPOD.
            isStructNonPOD = false;
            % If the class is already visited then return
            if numEntries(visitedStructs) && isKey(visitedStructs,obj.MATLABName)
                if obj.cppStructType == internal.mwAnnotation.StructConvType.NonPOD
                    isStructNonPOD = true;
                end
                return;
            end
            % If the struct is POD or PotentialPOD, see if all the 
            % data members are fully defined and not removed to mark
            % the struct as POD and methods should not be defined as shape 
            isStructNonPOD = obj.validateIfClassIsNonPOD;
            % Validate user defined data members of the struct to verify 
            % if it is POD or PotentialPOD
            if ~isStructNonPOD
                parentStructs = [parentStructs obj.MATLABName];
                for dataMem = obj.Properties
                    % checks if the data member is of struct type
                    if ~dataMem.isStructType
                        continue;
                    end
                    clsIndex = int32.empty;
                    allClasses = obj.DefiningLibrary.Classes;
                    % Iterate through all classes to get the index of the
                    % matching user defined data member type
                    for index = 1:length(allClasses)
                        if allClasses(index).MATLABName == obj.getClibScalarMwType(dataMem.MATLABType)
                            clsIndex = index;
                            break;
                        end
                    end
                    if isempty(clsIndex)
                        continue;
                    end
                    clsInterface = allClasses(clsIndex);
                    if clsInterface.cppStructType == internal.mwAnnotation.StructConvType.NonPOD
                        isStructNonPOD = true;
                        break;
                    end
                    % structs with circular reference will be treated as NonPOD.
                    if find(ismember(parentStructs,clsInterface.MATLABName))
                        isStructNonPOD = true; % cycle exists
                        break;
                    end
                    [isStructNonPOD, visitedStructs] =  updatePODStatusHelper(clsInterface, parentStructs, visitedStructs);
                    if isStructNonPOD
                        break;
                    end
                end
            end
            % store the mltype of visited class and its pod status in
            % the dictionary
            if isStructNonPOD
                obj.cppStructType = internal.mwAnnotation.StructConvType.NonPOD;
                visitedStructs = insert(visitedStructs,obj.MATLABName,false);
            elseif obj.cppStructType == internal.mwAnnotation.StructConvType.PotentialPOD || ...
                    obj.cppStructType == internal.mwAnnotation.StructConvType.POD
                obj.cppStructType = internal.mwAnnotation.StructConvType.POD;
                visitedStructs = insert(visitedStructs,obj.MATLABName,true);
            end
        end

        % Function that updates the pod status of the class or struct
        function visitedClasses = updatePODStatus(obj, visitedClasses)
            [~,visitedClasses] = obj.updatePODStatusHelper(string([]),visitedClasses);
        end

        function summaryStr = summary(obj, ~)
            switch(nargin)
                case 1
                    % Show the MATLAB summary of all properties,
                    % constructors and methods
                    summaryStr = sprintf("Class " + obj.MATLABName + "\n");
                    firstCons = true;
                    if(isempty(obj.Constructors))
                        summaryStr =  sprintf(summaryStr + "\n  No Constructors defined\n");
                    else
                        for cons = obj.Constructors
                            try
                                validate(cons);
                                if(firstCons)
                                    summaryStr = sprintf(summaryStr + "\n  Constructors:\n");
                                    firstCons = false;
                                end
                                mlSignatures = cons.MATLABSignature; 
                                %loop through mlSignatures if multiple 
                                %MLSignatures are generated for plain void*
                                %argument
                                for i= 1:numel(mlSignatures)
                                    summaryStr = sprintf(summaryStr + "    " + mlSignatures{i} + "\n");
                                end
                                argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(cons, obj.getMethodType(cons.CPPSignature));
                                if numel(argsFundamental) > 0
                                    summaryStr = summaryStr + clibgen.LibraryDefinition.formNotNullableNote("      ", argsFundamental);
                                end
                                % add note for void* defined within same scope                                
                                opaqueTypesWithinScopeUsedAsArgs = clibgen.ConstructorDefinition.getOpaqueTypesWithinScopeUsedAsArgs(cons, obj.getMethodType(cons.CPPSignature), obj.MATLABName);
                                if numel(opaqueTypesWithinScopeUsedAsArgs) > 0
                                    summaryStr = summaryStr + clibgen.LibraryDefinition.formOpaqueTypeConstructionNote("      ", obj.MATLABName, opaqueTypesWithinScopeUsedAsArgs);
                                end
                            catch
                                % Do nothing if an exception is thrown, move to the next constructor
                            end
                        end
                    end
                    firstMeth = true;
                    if(isempty(obj.Methods))
                        summaryStr =  sprintf(summaryStr + "\n  No Methods defined\n");
                    else
                        for meth = obj.Methods
                            try
                                validate(meth);
                                if(firstMeth)
                                    summaryStr = sprintf(summaryStr + "\n  Methods:\n");
                                    firstMeth = false;
                                end
                                mlSignatures = meth.MATLABSignature;
                                %loop through mlSignatures if multiple 
                                %MLSignatures are generated for plain void*
                                %argument
                                for i= 1:numel(mlSignatures)
                                    summaryStr = sprintf(summaryStr + "    " + mlSignatures{i} + "\n");
                                end
                                argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(meth, obj.getMethodType(meth.CPPSignature));
                                if numel(argsFundamental) > 0
                                    summaryStr = summaryStr + clibgen.LibraryDefinition.formNotNullableNote("      ", argsFundamental);
                                end
                            catch
                                % Do nothing if an exception is thrown, move to the next methods
                            end
                        end
                    end
                    firstProp = true;
                    if(isempty(obj.Properties))
                        summaryStr =  sprintf(summaryStr + "\n  No Properties defined\n");
                    else
                        for prop = obj.Properties
                            try
                                if(firstProp)
                                    summaryStr = sprintf(summaryStr + "  Properties:\n");
                                    firstProp = false;
                                end
                                summaryStr = sprintf(summaryStr + "    " + prop.MATLABType + " " + ...
                                    prop.CPPName + "\n");
                            catch
                                % Do nothing if an exception is thrown, move to the next properties
                            end
                        end
                    end
                case 2
                    % call is summary(obj, 'mapping')
                    summaryStr = sprintf("\nC++:    Class " + obj.CPPName + "\n");
                    summaryStr = sprintf(summaryStr + "MATLAB: Class " + obj.MATLABName + "\n");
                    firstCons  = true;
                    for cons = obj.Constructors
                        try
                            validate(cons);
                            if(firstCons)
                                summaryStr = sprintf(summaryStr + "\n  Constructors:\n");
                                firstCons = false;
                            end
                            summaryStr = sprintf(summaryStr + "    C++:    " + cons.CPPSignature + "\n");
                            summaryStr = sprintf(summaryStr + "    MATLAB: " + cons.MATLABSignature + "\n");
                            argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(cons, obj.getMethodType(cons.CPPSignature));
                            if numel(argsFundamental) > 0
                                summaryStr = summaryStr + clibgen.LibraryDefinition.formNotNullableNote("      ", argsFundamental);
                            end
                            % add note for void* defined within same scope                                
                            opaqueTypesWithinScopeUsedAsArgs = clibgen.ConstructorDefinition.getOpaqueTypesWithinScopeUsedAsArgs(cons, obj.getMethodType(cons.CPPSignature), obj.MATLABName);
                            if numel(opaqueTypesWithinScopeUsedAsArgs) > 0
                                summaryStr = summaryStr + clibgen.LibraryDefinition.formOpaqueTypeConstructionNote("      ", obj.MATLABName, opaqueTypesWithinScopeUsedAsArgs);
                            end
                        catch
                        end
                    end
                    firstMeth = true;
                    for meth = obj.Methods
                        try
                            validate(meth);
                            if(firstMeth)
                                summaryStr = sprintf(summaryStr + "  Methods:\n");
                                firstMeth = false;
                            end
                            summaryStr = sprintf(summaryStr + "    C++:     " + meth.CPPSignature + "\n");
                            summaryStr = sprintf(summaryStr + "    MATLAB: " + meth.MATLABSignature + "\n");
                            argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(meth, obj.getMethodType(meth.CPPSignature));
                            if numel(argsFundamental) > 0
                                summaryStr = summaryStr + clibgen.LibraryDefinition.formNotNullableNote("      ", argsFundamental);
                            end
                        catch
                        end
                    end
            end
        end
        
        function validateMLSignatures(obj)
            MethMLSignatures = [];
            for meth = obj.Methods
                mlSignature = meth.MATLABSignature;
                % with void* input configured as multiple MLTypes,
                % multiple signatures would be generated else
                % for other cases single signature is generated
                for i =1:numel(mlSignature)
                    % Get the method name and input arguments by trimming
                    % the return type. For example, Change the full ML
                    % signature from:
                    %   "complex double clib.demo.foo(complex double)"
                    % To:
                    %   "clib.demo.foo(complex double)"
                    spaceIndexes = strfind(extractBefore(mlSignature(i), '('), ' ');
                    mlInputSignature = mlSignature(i);
                    if ~isempty(spaceIndexes)
                        mlInputSignature = extractAfter(mlSignature(i), spaceIndexes(end));
                    end
                    idx = find(strcmp(MethMLSignatures, mlInputSignature), 1);
                    if ~isempty(idx)
                        error(message('MATLAB:CPP:MLSignatureOverload', ...
                            'method', meth.CPPSignature, obj.Methods(idx).CPPSignature));
                    end
                    MethMLSignatures = [MethMLSignatures mlInputSignature];
                end
            end
            CtorMLSignatures = [];
            for ctor = obj.Constructors
                mlSignature = ctor.MATLABSignature;
                % with void* input configured as multiple MLTypes,
                % multiple signatures would be generated else
                % for other cases single signature is generated
                for i =1:numel(mlSignature)
                    % No need to trim the return type for constructors
                    mlInputSignature = mlSignature(i);
                    idx = find(strcmp(CtorMLSignatures, mlInputSignature), 1);
                    if ~isempty(idx)
                        error(message('MATLAB:CPP:MLSignatureOverload', ...
                            'method', ctor.CPPSignature, obj.Constructors(idx).CPPSignature));
                    end
                    CtorMLSignatures = [CtorMLSignatures mlInputSignature];
                end
            end
        end
        function methType = getMethodType(obj, CPPSignature)
            methType = [];
            for meth = obj.ClassInterface.Methods.toArray
                annotationArr = meth.Annotations.toArray;
                if(~isempty(annotationArr) && annotationArr(1).cppSignature == CPPSignature)
                    %Check to make sure not Inaccessible, OutOfScope or Unsupported
                    if clibgen.ClassDefinition.isSupported(annotationArr(1))
                        methType = meth;
                    end
                    return;
                end
            end
        end
        function [constructorType, isImplicit] = getConstructorType(obj, CPPSignature)
            % Check to see if implicit constructor
            classAnnotations = obj.ClassInterface.Annotations.toArray;
            isImplicit = false;
            implicitConstructors = classAnnotations(1).implicitConstructors.toArray;
            for constructor = implicitConstructors
               if( constructor.cppSignature == CPPSignature)
                   constructorType = constructor;
                   isImplicit = true;
                   return;
               end
            end         
            % Search all methods for this constructor
            constructorType = obj.getMethodType(CPPSignature);
        end        
        function propType = getProperty(obj, propName)
            propType = [];
            for prop = obj.ClassInterface.Members.toArray
                if(prop.Name == propName)
                    propType = prop;
                    break;
                end
            end            
        end
    end
    
    methods(Static)
       function supported = isSupported(annotation)
            supported = (annotation.integrationStatus.definitionStatus == internal.mwAnnotation.DefinitionStatus.FullySpecified || ...
                         annotation.integrationStatus.definitionStatus == internal.mwAnnotation.DefinitionStatus.PartiallySpecified);
        end
 
    end
    
    methods(Access=public)
        function ctordef = addConstructor(obj, CPPSignature, varargin)
            %ADDCONSTRUCTOR Adds a C++ method to the class definition
            %   CONSTRUCTORDEF = ADDCONSTRUCTOR(CLASSDEFINITION,CPPSIGNATURE,VARARGIN)
            %   returns a CONSTRUCTORDEFINITION object with C++ signature CPPSIGNATURE
            
            try
                p = inputParser;
                addRequired(p, 'CPPSignature',  @(x)verifyConstructor(obj,x));
                addParameter(p,"Description","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"DetailedDescription","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                p.KeepUnmatched = false;
                parse(p,CPPSignature,varargin{:});
                %Get the method metadata interface from the library interface
                [constructorType, isImplicit] = obj.getConstructorType(string(CPPSignature));
                if(isempty(constructorType))
                    error(message("MATLAB:CPP:MethodNotFound", CPPSignature, obj.CPPName));
                end
                % Implicit constructors do not need check for support
                if not(isImplicit)
                    if not((constructorType.SpecialKind==internal.cxxfe.ast.SpecialFunctionKind.Constructor || ...
                            constructorType.SpecialKind==internal.cxxfe.ast.SpecialFunctionKind.CopyConstructor))
                        error(message("MATLAB:CPP:InvalidConstructorCall", CPPSignature));
                    end
                    %Check to make sure not Inaccessible, OutOfScope or Unsupported
                    constructorAnnotation = constructorType.Annotations.toArray;
                    if not(clibgen.ClassDefinition.isSupported(constructorAnnotation(1)))
                        error(message('MATLAB:CPP:FunctionNotSupported', constructorAnnotation.cppSignature));
                    end
                else
                    constructorAnnotation = constructorType;               
                end
                % ensure the constructor name is the same as the MATLAB class
                simpleClassName = obj.MATLABName.split(".");
                simpleClassName = simpleClassName(end);
                constructorAnnotation.name = simpleClassName;
                
                parsedResults = p.Results;
                ctordef = clibgen.ConstructorDefinition(obj, parsedResults.CPPSignature,....
                    constructorType, parsedResults.Description, isImplicit, parsedResults.DetailedDescription);
                obj.Constructors(end+1) = ctordef;
            catch ME
                throw(ME);
            end            
        end
        
        function methdef = addMethod(obj, CPPSignature, varargin)
            %ADDMETHOD Adds a C++ method to the class definition
            %   METHDEF = ADDMETHOD(CLASSDEFINITION,CPPSIGNATURE,VARARGIN)
            %   returns a METHODDEFINITION object with C++ signature CPPSIGNATURE

            try
                p = inputParser;
                addRequired(p,'CPPSignature',@(x)verifyMethod(obj,x));
                addParameter(p,"Description","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"DetailedDescription","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"MATLABName","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"TemplateUniqueName","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                p.KeepUnmatched = false;
                parse(p,CPPSignature,varargin{:});
                %Get the method metadata interface from the library interface
                methodType = obj.getMethodType(string(CPPSignature));            
                if (string(CPPSignature) == "") || (isempty(methodType))
                    error(message("MATLAB:CPP:MethodNotFound", CPPSignature, obj.CPPName));
                end
                if (methodType.SpecialKind==internal.cxxfe.ast.SpecialFunctionKind.Constructor || ...
                        methodType.SpecialKind==internal.cxxfe.ast.SpecialFunctionKind.CopyConstructor)
                    error(message("MATLAB:CPP:InvalidMethodCall", CPPSignature));
                end
                %Check to make sure not Inaccessible, OutOfScope or Unsupported   
                methodAnnotation = methodType.Annotations.toArray;                       
                if not(clibgen.ClassDefinition.isSupported(methodAnnotation(1)))
                    error(message('MATLAB:CPP:FunctionNotSupported', methodAnnotation.cppSignature));
                end            
                parsedResults = p.Results;
                methdef = clibgen.MethodDefinition(obj, parsedResults.CPPSignature,....
                    methodType, parsedResults.Description, parsedResults.DetailedDescription,...
                    parsedResults.MATLABName, parsedResults.TemplateUniqueName);
                obj.Methods(end+1) = methdef;
            catch ME
                throw(ME);
            end
        end
        
        function propdef = addProperty(obj, cppName, mlType, varargin)
            %ADDPROPERTY Adds a C++ property to the class definition
            %   PROPDEF = ADDPROPERTY(CLASSDEFINITION,CPPNAME,MATLABTYPE,VARARGIN)
            %   returns a PROPERTYDEFINITION object for the C++ property CPPNAME
            %   and MATLAB type MATLABTYPE.
            
            try
                p = inputParser;
                addRequired(p,"Name",@(x)verifyProperty(obj,x));
                addRequired(p,"MlType", @(x)validateattributes(x, {'char','string'},{'scalartext'}));
                p.KeepUnmatched = false;
                parse(p,cppName,mlType);
                numvarargin = numel(varargin);
                %Get the method metadata interface from the library interface
                propertyInterface = obj.getProperty(string(p.Results.Name));
                if(isempty(propertyInterface))
                    error(message("MATLAB:CPP:PropertyDoesNotExist", cppName));
                end
                propertyAnnotation = propertyInterface.Annotations(1);
                if(propertyAnnotation.integrationStatus.definitionStatus ~= internal.mwAnnotation.DefinitionStatus.FullySpecified ...
                   && propertyAnnotation.integrationStatus.definitionStatus ~= internal.mwAnnotation.DefinitionStatus.PartiallySpecified)
                    error(message("MATLAB:CPP:PropertyDoesNotExist", cppName));
                end
                % Update valid MATLAB type, in case it has been renamed
                if not(clibgen.MethodDefinition.isFundamental(propertyInterface.Type))
                    clibgen.MethodDefinition.updateValidType(obj.DefiningLibrary, propertyAnnotation);
                end
                % Add mlType if needed
                validMlTypes = propertyAnnotation.validTypes.toArray;
                if isempty(validMlTypes) % for R2019b and older
                    if (propertyAnnotation.mwType ~= mlType)
                        error(message("MATLAB:CPP:InvalidPropertyType", mlType, propertyAnnotation.mwType));
                    end
                else
                    validMlTypesToShow = clibgen.MethodDefinition.convertUIMlTypeArray(validMlTypes);
                    [found, location] = ismember(mlType, validMlTypesToShow);
                    if ~found
                        if(numel(validMlTypesToShow)==1)
                            error(message('MATLAB:CPP:InvalidPropertyType',mlType,string(validMlTypesToShow)));
                        else
                            error(message('MATLAB:CPP:InvalidPropertyTypeMultiple',mlType,join(string(validMlTypesToShow),""", """)))
                        end
                    end
                    propertyAnnotation.mwType = validMlTypes{location};
                end
                prop.MATLABName = string(p.Results.Name);
                prop.MATLABType = string(p.Results.MlType);
    
                switch(numvarargin)
                    case 0
                        if(propertyAnnotation.storage==internal.mwAnnotation.StorageKind.Pointer|| ...
                                propertyAnnotation.storage==internal.mwAnnotation.StorageKind.Array)
                            error(message('MATLAB:CPP:PropertyShapeAbsent', prop.MATLABName));
                        end
                        prop.Shape = propertyAnnotation.shape;
                        prop.Description = "";
                        prop.DetailedDescription = "";
                    case 1
                        clibgen.PropertyDefinition.verifyShape(obj.ClassInterface, propertyAnnotation, varargin{1}, propertyInterface.Type, prop.MATLABName);
                        prop.Shape = varargin{1};
                        prop.Description = "";
                        prop.DetailedDescription = "";
                    case 2
                        p = inputParser;
                        addParameter(p,"Description","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                        parse(p,varargin{1:end});
                        prop.Description = p.Results.Description;
                        clibgen.PropertyDefinition.verifyShape(obj.ClassInterface, propertyAnnotation, 1, propertyInterface.Type, prop.MATLABName);
                        prop.Shape = propertyAnnotation.shape;
                        prop.DetailedDescription = "";
                    case 3
                        clibgen.PropertyDefinition.verifyShape(obj.ClassInterface, propertyAnnotation, varargin{1}, propertyInterface.Type, prop.MATLABName);
                        prop.Shape = varargin{1};
                        p = inputParser;
                        addParameter(p,"Description","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                        parse(p,varargin{2:end});
                        prop.Description = p.Results.Description;
                        prop.DetailedDescription = "";
                    case 4
                        p = inputParser;
                        addParameter(p,"Description","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                        addParameter(p,"DetailedDescription","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                        parse(p,varargin{1:end});
                        prop.Description = p.Results.Description;
                        prop.DetailedDescription = p.Results.DetailedDescription;
                        clibgen.PropertyDefinition.verifyShape(obj.ClassInterface, propertyAnnotation, 1, propertyInterface.Type, prop.MATLABName);
                        prop.Shape = propertyAnnotation.shape;
                    case 5
                        clibgen.PropertyDefinition.verifyShape(obj.ClassInterface, propertyAnnotation, varargin{1}, propertyInterface.Type, prop.MATLABName);
                        prop.Shape = varargin{1};
                        p = inputParser;
                        addParameter(p,"Description","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                        addParameter(p,"DetailedDescription","",@(x) validateattributes(x,{'char','string'},{'scalartext'}));
                        parse(p,varargin{2:end});
                        prop.Description = p.Results.Description;
                        prop.DetailedDescription = p.Results.DetailedDescription;
                    otherwise
                        error(message('MATLAB:maxrhs'));
                end
                propdef = clibgen.PropertyDefinition(obj, prop.MATLABName, ...
                     propertyInterface, prop.MATLABType, prop.Shape, prop.Description, prop.DetailedDescription);
                obj.Properties(end+1) = propdef;
            catch ME
                throw(ME);
            end
        end
    end
    
    methods
        function set.Description(obj, desc)
            validateattributes(desc,{'char','string'},{'scalartext'});
            obj.Description = desc;
            annotations = obj.ClassInterface.Annotations.toArray;
            annotations(1).description = desc; 
        end

        function set.DetailedDescription(obj, details)
            validateattributes(details,{'char','string'},{'scalartext'});
            obj.DetailedDescription = details;
            annotations = obj.ClassInterface.Annotations.toArray;
            annotations(1).detailedDescription = details; 
        end
    end
end
