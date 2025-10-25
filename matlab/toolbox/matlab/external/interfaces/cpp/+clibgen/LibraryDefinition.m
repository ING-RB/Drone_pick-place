classdef LibraryDefinition < handle
    % LibraryDefinition MATLAB definition for a library
    % This class contains the MATLAB definition for a C++ library
    % LibraryDefinition properties:
    %   OutputFolder - Folder where the interface library will be generated
    %   Libraries    - Libraries to be used while generating interface
    %   IncludePath  - Include paths for libraries
    
    % Copyright 2018-2024 The Mathworks, Inc.
    
    properties(Access=public)
        OutputFolder     string
        Libraries        string
        IncludePath      string
        SupportingSourceFiles      string
        CLinkage         logical
        AdditionalCompilerFlags    (1,:) string
        AdditionalLinkerFlags      (1,:) string
        Verbose          logical
        RootPaths        (1,1) dictionary
    end
    properties(SetAccess=private,Dependent)
        InterfaceName    string
    end
    properties(SetAccess=private)
        HeaderFiles      string
        Classes          clibgen.ClassDefinition
        Functions        clibgen.FunctionDefinition
        Enumerations     clibgen.EnumDefinition
        DefinedMacros    string
        UndefinedMacros  string
        OpaqueTypes      clibgen.OpaqueTypeDefinition
        FunctionTypes    clibgen.FunctionTypeDefinition
    end
    properties(SetAccess=private,Hidden=true,Dependent)
        LibrariesAbsolute               string
        IncludePathAbsolute             string
        OutputFolderAbsolute            string
        SupportingSourceFilesAbsolute   string
    end
    properties(Access=private,Hidden=true,Dependent)
        HeaderFilesAbsolute    string
    end
    properties(Access=private)
        Valid            logical =false
        SeparateProcess  string
        FundamentalArrays   string
        ClassArrays         string
        ClassesThatNeedArray     string
        AddFundamentalArray string
        UserDefinedOpaqueTypes clibgen.OpaqueTypeDefinition
        cppWrapperNames string
        additionalCompilerFlagsPassedtoParser (1,:) string
        FunctionCppSigToASTMap containers.Map
    end
    properties(Hidden, SetAccess=private)
        PackageName      string
    end
    properties(Access={?clibgen.OpaqueTypeDefinition, ?clibgen.FunctionDefinition})
        OpaqueTypeNames  string
    end
    properties(Access={?clibgen.FunctionDefinition, ?clibgen.ClassDefinition,...
            ?clibgen.MethodDefinition, ?clibgen.ConstructorDefinition, ?clibgen.PropertyDefinition,...
            ?clibgen.OpaqueTypeDefinition, ?clibgen.FunctionTypeDefinition})
        LibraryInterface
        RenamingMap      containers.Map
    end
    properties(Constant,Hidden=true, Access={?clibgen.FunctionDefinition, ?clibgen.ClassDefinition,...
            ?clibgen.MethodDefinition, ?clibgen.ConstructorDefinition})
         % Map of fundamentalMlTypeCppTypeMap contains
         % key - Fundamental MATLAB Type
         % value - corresponding cpp Type
         fundamentalMlTypeCppTypeMap = containers.Map({'int8','int16','int32','int64', 'uint8','uint16',...
             'uint32','uint64','single','double','logical','char'} ,{'int8_t', 'int16_t','int32_t','int64_t',...
             'uint8_t','uint16_t','uint32_t','uint64_t','float','double','bool','char16_t'});

         % Map of clibArrFundamentalMlTypeMlElemTypeMap contains
         % key - Fundamental clib array MATLAB Type
         % value - corresponding MATLAB element Type
         clibArrFundamentalMlTypeMlElemTypeMap = containers.Map({'Char','SignedChar','UnsignedChar','Short',...
             'UnsignedShort','Int','UnsignedInt','Long','UnsignedLong','LongLong','UnsignedLongLong', 'Float', 'Double','Bool'}, ...
             {'int8','int8', 'uint8','int16', 'uint16', 'int32', 'uint32', 'int32', 'uint32','int64', 'uint64','single','double','logical'});

         % Map of clibArrFundamentalMlTypeCppTypeMap contains
         % key - Fundamental clib array MATLAB Type
         % value - corresponding cpp Type
         clibArrFundamentalMlTypeCppTypeMap = containers.Map({'Char','SignedChar','UnsignedChar','Short',...
             'UnsignedShort','Int','UnsignedInt','Long','UnsignedLong','LongLong','UnsignedLongLong', 'Float', 'Double','Bool'}, ...
             {'char','signed char','unsigned char','short','unsigned short', 'int', 'unsigned int', 'long',...
             'unsigned long', 'long long', 'unsigned long long','float','double','bool'});
    end
    properties(Access={?clibgen.FunctionTypeDefinition})
        MatchingFunctionsForCFunctionPtr containers.Map
        MatchingFunctionsForStdFunction  containers.Map
        AvailableFunctionsMap            containers.Map
    end
    methods
        function set.OutputFolder(obj, folder)
            validateattributes(folder, {'string'}, {'scalartext'});
            obj.OutputFolder = folder;
        end

        function set.Libraries(obj, libs)
            arrayfun(@(x) validateattributes(x, {'string'}, {'scalartext'}), libs);
            obj.Libraries = libs;
        end

        function set.SupportingSourceFiles(obj, sourceFiles)
            arrayfun(@(x) validateattributes(x, {'string'}, {'scalartext'}), sourceFiles);
            if ~isempty(obj.SupportingSourceFiles)
                obj.validateSourceFile(sourceFiles);
            end
            obj.SupportingSourceFiles = sourceFiles;
        end

        function set.IncludePath(obj, paths)
            arrayfun(@(x) validateattributes(x, {'string'}, {'scalartext'}), paths);
            obj.IncludePath = paths;
        end

        function set.RootPaths(obj, paths)
            validateattributes(paths, {'dictionary'}, {'scalar'});
            obj.RootPaths = paths;
        end

        function set.CLinkage(obj, cLinkage)
            validateattributes(cLinkage, {'logical'},{'scalar'});
            obj.CLinkage = cLinkage;
        end

        function paths = get.LibrariesAbsolute(obj)
            paths = obj.getAbsolutePaths(obj.Libraries);
        end
        function paths = get.IncludePathAbsolute(obj)
            paths = obj.getAbsolutePaths(obj.IncludePath);
        end
        function paths = get.OutputFolderAbsolute(obj)
            paths = obj.getAbsolutePaths(obj.OutputFolder);
        end
        function paths = get.SupportingSourceFilesAbsolute(obj)
            paths = obj.getAbsolutePaths(obj.SupportingSourceFiles);
        end
        function paths = get.HeaderFilesAbsolute(obj)
            paths = obj.getAbsolutePaths(obj.HeaderFiles);
        end
    end

    methods(Static, Access={?clibgen.ClassDefinition, ?clibgen.ConstructorDefinition,...
            ?clibgen.FunctionDefinition, ?clibgen.MethodDefinition})
        function note = formNotNullableNote(offset, argsFundamental)
            argsUnique = unique(argsFundamental,'stable');
            argsList = strjoin(argsUnique, '/');
            note = sprintf( offset + "<strong>Note:</strong> '" + argsList + "' used as MLTYPE for C++ pointer argument.\n" + ...
                            offset + "Passing nullptr is not supported with '" + argsList + "' types.\n" + ...
                            offset + "To allow nullptr as an input, set MLTYPE to clib.array.\n");
        end
    end

    methods(Static, Access={?clibgen.ClassDefinition, ?clibgen.ConstructorDefinition})
        function note = formOpaqueTypeConstructionNote(offset, className, argsOpaqueWithinScope)
            argsUnique = unique(argsOpaqueWithinScope,'stable');
            argsList = strjoin(argsUnique, '/');
            msg = offset + "<strong>Note:</strong> " + "This constructor cannot create object '" + className + ...
                            "', if object '" + argsList + "' \n" + ...
                            offset + "is not available without constructing object of '"...
                            + className + "'. Consider using a MATLABType which is outside the scope of '" + className + "'.\n";
            link = offset + 'Click <a href="matlab:helpview(''matlab'', ''void_arguments'')">here</a> for more information.\n';
            note = sprintf( msg + link);

        end
    end

    methods(Access=private)
        function valid = verifyClass(obj,className)
            validateattributes(className,{'char', 'string'},{'scalartext'});
            % Class must not be added twice
            if(~isempty(obj.Classes.findobj('CPPName', className)))
                error(message('MATLAB:CPP:ClassExists', className));
            end
            valid = true;
        end

        function valid = verifyOpaqueType(obj,className)
            validateattributes(className,{'char', 'string'},{'scalartext'});
            % Class must not be added twice
            if(~isempty(obj.OpaqueTypes.findobj('CPPSignature', className)))
                error(message('MATLAB:CPP:OpaqueTypeExists', className));
            end
            valid = true;
        end

        function valid = verifyMATLABName(obj,mlname, isclass, isopaque, cppsig)
            arguments
                obj (1,1) clibgen.LibraryDefinition
                mlname
                isclass (1,1) = false
                isopaque (1,1) = false
                cppsig (1,1) string = ""
            end
            if(ischar(mlname) && ~isempty(mlname) || isStringScalar(mlname) && ~ismissing(mlname) && mlname ~= "")
                % Pull out the simple name and check for validity
                splitname = split(string(mlname),'.');
                valid = all(matlab.lang.makeValidName(splitname(1:end)) == splitname);
            else
                valid = false;
            end
            if(~valid)
                error(message('MATLAB:CPP:InvalidName'));
            end

            % Name in MATLAB should not be conflicting with other Types
            % that have been already added. This check is applicable for
            % all constructs including Functions.
            if(obj.nameExists(mlname) || obj.opaqueTypeNameExists(mlname) || obj.isFunctionType(mlname))
                error(message('MATLAB:CPP:NameConflict',mlname,obj.PackageName));
            end
            % For a class,opaqueType, functionType or enum MATLABName must not
            % be same as any function's MATLABName that is been added.
            if (isclass || isopaque) && (~isempty(obj.Functions) && ismember(mlname, [obj.Functions.MATLABName]))
                 error(message('MATLAB:CPP:NameConflict',mlname,obj.PackageName));
            end
        end

        function valid = verifyNewMATLABName(~, originalQualifiedName, mlname)
            try
                splitname = split(string(mlname),'.');
                valid = all(matlab.lang.makeValidName(splitname(1:end)) == splitname);
                if(~valid)
                    error(message('MATLAB:CPP:InvalidName'));
                end
                originalSplitName = split(originalQualifiedName,'.');
                if(numel(splitname)==numel(originalSplitName))
                    for i = 1:numel(splitname)-1
                        if not(splitname(i)==originalSplitName(i))
                            error(message("MATLAB:CPP:InvalidNewMATLABName", mlname, ...
                                originalSplitName{end}, originalQualifiedName));
                        end
                    end
                else
                    error(message("MATLAB:CPP:InvalidNewMATLABName", mlname, ...
                        originalSplitName{end}, originalQualifiedName));
                end
            catch ME
                throwAsCaller(ME);
            end

        end

        function valid = verifyFunction(obj,cppsignature)
            validateattributes(cppsignature,{'char','string'},{'scalartext'});
            % Function must not be added twice
            if(~isempty(obj.Functions) && ismember(cppsignature, [obj.Functions.CPPSignature]))
                error(message('MATLAB:CPP:FunctionExists', cppsignature));
            end
            valid = true;
        end

        function valid = verifyEnum(obj, cppname)
            validateattributes(cppname,{'char','string'},{'scalartext', 'nonempty'});
            %Enum must not be added twice
            if(~isempty(obj.Enumerations.findobj('CPPName', cppname)))
                error(message('MATLAB:CPP:EnumExists', cppname));
            end
            valid = true;
        end

        function val = validateEnumerant(~, enumerant)
            val = isstring(enumerant) && ~ismissing(enumerant) ...
                && ~(enumerant == "");
        end

        function verifyEnumerants(obj, enumerants)
            if(isempty(enumerants))
                return;
            end
            validateattributes(enumerants, {'string'}, {'row'});
            val = all(arrayfun(@(x) obj.validateEnumerant(x), enumerants, 'UniformOutput', true));
            if(~val)
                error(message('MATLAB:CPP:InvalidEnumEntryType'));
            end
        end

        function verifyEnumerantDescriptions(~, enumerantDescriptions, entries)
            if(isempty(enumerantDescriptions))
                return;
            end
            if not(numel(enumerantDescriptions) == numel(entries))
                error(message('MATLAB:CPP:InvalidEnumEntryType'));
            end
            for i = 1:numel(enumerantDescriptions)-1
                validateattributes(enumerantDescriptions(i),{'char','string'},{'scalartext'});
            end
        end

        function found = nameExists(obj, className)
            if (~isempty(obj.Classes) && any(className == [obj.Classes.MATLABName]))
                found = true;
                return;
            end
            if(~isempty(obj.Enumerations) && any(className == [obj.Enumerations.MATLABName]))
                found = true; return;
            end
            if(~isempty(obj.FundamentalArrays) && any(className == [obj.FundamentalArrays]))
                found = true;
                return;
            end
            if(~isempty(obj.ClassArrays) && any(className == [obj.ClassArrays]))
                found = true;
                return;
            end
            found = false;
        end

        function found = isEnum(obj,className)
            % Function to verify if the enum is specified for void* input
            if(~isempty(obj.Enumerations) && any(className == [obj.Enumerations.MATLABName]))
                found = true; return;
            end
            found = false;
        end

        function found = opaqueTypeNameExists(obj,className)
            % Function to verify if the opaqueType for void* exists
            if(~isempty(obj.OpaqueTypes) && any(className == [obj.OpaqueTypes.MATLABName]))
                found = true;
                return;
            end
            found = false;
        end

        function retVal = isClibArrFundamentalElemType(obj, mwType)
            retVal = ismember(mwType, obj.clibArrFundamentalMlTypeCppTypeMap.keys);
        end

        function cppType = getCppTypeForClibArrFundamentalType(obj, mwType)
            %Function to map specified MLType to corresponding CPPType for void*
            delimitedList = strsplit(mwType, '.');
            mwType = delimitedList(end);
            cppType =  obj.clibArrFundamentalMlTypeCppTypeMap(string(mwType));
        end

        function cppWrapperName = getUniqueCppWrapperName(obj, cppWrapperNames, cppName)
            cppWrapperName = strrep(cppName,"::","_");
            cppWrapperName = matlab.lang.makeUniqueStrings(cppWrapperName,cppWrapperNames);
        end

        function validateRootPathKeys(obj, propName, paths)
            if ~isempty(paths)
                rootpathIndices = find(startsWith(paths, "<"));
                if ~isempty(rootpathIndices)
                    % atleast one path seems to refer to a 'RootPaths' key
                    for idx = rootpathIndices
                        if count(paths(idx),">") ~= 1
                            error(message('MATLAB:CPP:InvalidRootPathKeySyntax',paths(idx),propName));
                        end
                        key = extractBetween(paths(idx),"<",">");
                        if ~isvarname(key)
                            error(message("MATLAB:CPP:InvalidRootPathKey",key,propName));
                        elseif ~isConfigured(obj.RootPaths) ||  ~isKey(obj.RootPaths,key)
                            error(message("MATLAB:CPP:SpecifyRootPathProperty",key,propName));
                        end
                        status = fileattrib(obj.RootPaths(key));
                        if ~status
                            error(message("MATLAB:CPP:InvalidRootPathValue",obj.RootPaths(key),key,propName));
                        end
                        if ~strcmp(propName,'OutputFolder')
                            % validate for valid file path for all
                            % properties except for OutputFolder
                            path = replace(paths(idx),strcat("<",key,">"),obj.RootPaths(key));
                            [status, ~]= fileattrib(path);
                            if ~status
                                error(message('MATLAB:CPP:FileNotFound',path));
                            end
                        end
                    end
                end
            end
        end

        function paths = getAbsolutePaths(obj, paths)
            if ~isempty(paths)
                rootpathIndices = find(startsWith(paths, "<"));
                if ~isempty(rootpathIndices)
                    % atleast one path seems to refer to a 'RootPaths' key
                    for idx = rootpathIndices
                        key = extractBetween(paths(idx),"<",">");
                        paths(idx) = replace(paths(idx),strcat("<",key,">"),obj.RootPaths(key));
                        [status, value]= fileattrib(paths(idx));
                        if status
                            paths(idx) = value.Name;
                        end
                    end
                end
            end
        end

        function validateFunctionOrMethod(obj, fcn)
            % Helper function to validate a function or method in the library
            % First check if the function has been previously validated
            if not(fcn.Valid)
                validate(fcn);
            end
            % Run global validation if needed
            if fcn.needsGlobalValidation()
                namesForValidation = fcn.NamesForValidation;
                for i = 1:numel(namesForValidation)
                    className = namesForValidation(i).className;
                    argPos = namesForValidation(i).argPos;
                    hasMultipleMlTypes = namesForValidation(i).hasMultipleMlTypes;
                    if (argPos == 0)
                        annotations = fcn.OutputAnnotation;
                        isVoidPtr = clibgen.MethodDefinition.isVoidPtrType(annotations.cppType);
                        isTypedef = false;
                        isDoubleVoidPtr = false;
                        if ~(isempty(annotations.opaqueTypeInfo))
                            opaqueTypeInfo = annotations.opaqueTypeInfo;
                            isTypedef = opaqueTypeInfo.isTypedef;
                        end
                    else
                        isVoidPtr = clibgen.MethodDefinition.isVoidPtrType(fcn.ArgAnnotations(argPos).cppType);
                        isDoubleVoidPtr = clibgen.MethodDefinition.isDoubleVoidPtrType(fcn.ArgAnnotations(argPos).cppType);
                        isTypedef = false;
                        opaqueTypeInfo = fcn.ArgAnnotations(argPos).opaqueTypeInfo;
                        if ~(isempty(opaqueTypeInfo))
                            isTypedef = opaqueTypeInfo.isTypedef;
                        end
                    end
                    if (isVoidPtr && argPos ~=0)
                        if iscell(className) == 1
                            className = className{1};
                            delimitedList = strsplit(className, '.');
                        else
                            delimitedList = strsplit(className, '.');
                        end
                        if startsWith(className,"clib.array.")
                            % check if it is a valid fundamental clib array
                            isClibArrFundamentalElemType = obj.isClibArrFundamentalElemType(delimitedList(end));
                            if (isClibArrFundamentalElemType)
                                if (length(delimitedList) ~= 4)
                                    error(message('MATLAB:CPP:MissingClass', fcn.getMATLABName(), className));
                                end
                                fcn.ArgAnnotations(argPos).cppType = obj.getCppTypeForClibArrFundamentalType(className);
                                % Add className to AddFundamental array if
                                % annotation for Fundamental array does
                                % not already exist
                                if ~(ismember(className,obj.FundamentalArrays) || ismember(className,obj.AddFundamentalArray))
                                    obj.AddFundamentalArray(end+1) = className;
                                end
                            else
                                % check if it is a valid clib array for user-defined types
                                if ~(ismember(className,obj.ClassArrays))
                                    actualClassName = regexprep(className,'clib.array','clib','once');
                                    if isEnum(obj,actualClassName)
                                        error(message('MATLAB:CPP:InvalidArgumentTypeEnumForVoid', fcn.getMATLABName(), className));
                                    end
                                    if not(nameExists(obj, actualClassName))
                                        error(message('MATLAB:CPP:MissingClass', fcn.getMATLABName(), className));
                                    end
                                    obj.ClassArrays(end+1) = className;
                                    obj.ClassesThatNeedArray(end+1) = actualClassName;
                                end
                                cppType = regexprep(className,strcat('clib.array.',obj.PackageName,'.'),'', 'once');
                                cppType = strrep(cppType,".","::");
                                fcn.ArgAnnotations(argPos).cppType = cppType;
                            end
                        else
                            % for plain void* in case of multiple MLTypes,
                            % only opaqueType are allowed as MLType
                            if nameExists(obj, className) && hasMultipleMlTypes
                                error(message('MATLAB:CPP:InvalidArgumentTypeMultipleForVoidPtr', fcn.getMATLABName(), fcn.ArgAnnotations(argPos).name, ...
                                    message('MATLAB:CPP:ErrorMessageVoidPtrInputWithoutTypedef').getString));
                            end

                            % check if it is a valid user-defined type
                            if isEnum(obj,className)
                                error(message('MATLAB:CPP:InvalidArgumentTypeEnumForVoid', fcn.getMATLABName(), className));
                            end
                            if isTypedef
                                %verify if it is typedef, then opaqueType name
                                %exists in annotation already
                                isOpaqueName = opaqueTypeNameExists(obj, className);
                                validTypes = fcn.ArgAnnotations(argPos).validTypes.toArray;
                                %if different existing opaqueType is specified and
                                %no opaqueType exists for the typedef name of void* input
                                if (isOpaqueName && isempty(validTypes))
                                    error(message('MATLAB:CPP:InvalidArgumentTypeMultipleForVoidPtr', ...
                                        fcn.getMATLABName(), fcn.ArgAnnotations(argPos).name, ...
                                        message('MATLAB:CPP:ErrorMessageVoidPtrInputTypedef').getString));
                                %if different existing opaqueType is specified for typedef name of void*
                                elseif (isOpaqueName && ~isempty(validTypes) && ~ismember(fcn.ArgAnnotations(argPos).validTypes.toArray, className))
                                    error(message('MATLAB:CPP:InvalidArgumentTypeMultipleForVoidPtr', ...
                                        fcn.getMATLABName(), fcn.ArgAnnotations(argPos).name, ...
                                        message('MATLAB:CPP:ErrorMessageVoidPtrInputTypedefIncludeTypedef', ...
                                        string(fcn.ArgAnnotations(argPos).validTypes.toArray)).getString));
                                %if new opaqueType is specified for typedef name of void*
                                elseif ( ~isOpaqueName && ismember(className, obj.OpaqueTypeNames))
                                    error(message('MATLAB:CPP:InvalidArgumentTypeMultipleForVoidPtr',fcn.getMATLABName(), ...
                                        fcn.ArgAnnotations(argPos).name, ...
                                        message('MATLAB:CPP:ErrorMessageVoidPtrInputTypedefIncludeTypedef', ...
                                        string(fcn.ArgAnnotations(argPos).validTypes.toArray)).getString));
                                %needs extra validation if the function
                                %returning typedef output is declared later
                                %in the header
                                elseif (isOpaqueName && ~ismember(className, obj.OpaqueTypeNames))
                                    fcn.OpaqueTypesForValidation(end+1).className = className;
                                    fcn.OpaqueTypesForValidation(end).argPos = argPos;
                                    fcn.OpaqueTypesForValidation(end).hasMultipleMlTypes = hasMultipleMlTypes;
                                %if it neither an opaqueType nor any
                                %existing class
                                elseif (~isOpaqueName && not(nameExists(obj, className)))
                                    if isempty(validTypes)
                                        error(message('MATLAB:CPP:InvalidArgumentTypeMultipleForVoidPtr', ...
                                            fcn.getMATLABName(), fcn.ArgAnnotations(argPos).name, ...
                                            message('MATLAB:CPP:ErrorMessageVoidPtrInputTypedef').getString));
                                    else
                                        error(message('MATLAB:CPP:InvalidArgumentTypeMultipleForVoidPtr',fcn.getMATLABName(), ...
                                            fcn.ArgAnnotations(argPos).name, ...
                                            message('MATLAB:CPP:ErrorMessageVoidPtrInputTypedefIncludeTypedef', ...
                                            string(fcn.ArgAnnotations(argPos).validTypes.toArray)).getString));
                                    end
                                end

                            else
                                % for plain void*, verify if the className
                                % is same as any of the OpaqueType outputs
                                isOpaqueName = ismember(className, obj.OpaqueTypeNames);
                                if  not(nameExists(obj, className))
                                    if ~isOpaqueName
                                        fcn.OpaqueTypesForValidation(end+1).className = className;
                                        fcn.OpaqueTypesForValidation(end).argPos = argPos;
                                        fcn.OpaqueTypesForValidation(end).hasMultipleMlTypes = hasMultipleMlTypes;
                                    else
                                        obj.updateArgAnnotationCppWrapperName(fcn, className, hasMultipleMlTypes, argPos);
                                    end
                                end
                            end
                            if nameExists(obj, className) && not(isOpaqueName)
                                cppType = regexprep(className,strcat('clib.',obj.PackageName,'.'),'', 'once');
                                cppType = strrep(cppType,".","::");
                                fcn.ArgAnnotations(argPos).cppType = cppType;
                            end
                        end
                    %validation for void* output
                    elseif ((isVoidPtr && argPos == 0) || isDoubleVoidPtr)
                        % check if the OpaqueType exists for void* typedef
                        if (not(opaqueTypeNameExists(obj, className)) && isTypedef)
                                error(message('MATLAB:CPP:MissingOpaqueType', fcn.getMATLABName(), className));
                        elseif not(isTypedef)
                            %check if the user-defined OpaqueType name for
                            %plain void* is not same as any existing clib type
                            if (nameExists(obj, className)) ...
                                    || not(isempty(obj.Functions.findobj('MATLABName', className)))
                                if (isVoidPtr)
                                    error(message('MATLAB:CPP:NameConflictsForOpaqueTypeReturn', fcn.getMATLABName()));
                                elseif(isDoubleVoidPtr)
                                    error(message('MATLAB:CPP:NameConflictsForOpaqueTypeArgument', fcn.getMATLABName(), fcn.ArgAnnotations(argPos).name));
                                end
                            end
                            %check if the user-defined OpaqueType name for
                            %plain void* is not same as any existing class
                            %methods or property
                            if numel((obj.Classes)) >0
                                for i = 1:numel(obj.Classes)
                                    if className.startsWith(obj.Classes(i).MATLABName)
                                        classNameNew = extractAfter(className,strcat(obj.Classes(i).MATLABName,"."));
                                        if not(isempty(obj.Classes(i).Methods.findobj('MATLABName', classNameNew))) ...
                                                || not(isempty(obj.Classes(i).Properties.findobj('CPPName', classNameNew)))
                                            if (isVoidPtr)
                                                error(message('MATLAB:CPP:NameConflictsForOpaqueTypeReturn', fcn.getMATLABName()));
                                            elseif(isDoubleVoidPtr)
                                                error(message('MATLAB:CPP:NameConflictsForOpaqueTypeArgument', fcn.getMATLABName(), fcn.ArgAnnotations(argPos).name));
                                            end
                                        end
                                    end
                                end
                            end
                            %check if the user-defined OpaqueType name for
                            %plain void* is not same as any existing enum
                            %entries
                            if numel((obj.Enumerations)) >0
                                for i = 1:numel(obj.Enumerations)
                                    if className.startsWith(obj.Enumerations(i).MATLABName)
                                        if (isVoidPtr)
                                            error(message('MATLAB:CPP:NameConflictsForOpaqueTypeReturn', fcn.getMATLABName()));
                                        elseif(isDoubleVoidPtr)
                                            error(message('MATLAB:CPP:NameConflictsForOpaqueTypeArgument', fcn.getMATLABName(), fcn.ArgAnnotations(argPos).name));
                                        end
                                    end
                                end
                            end
                            if (ismember(className, obj.OpaqueTypeNames))
                                if (isVoidPtr)
                                    obj.updateOutputAnnotationCppWrapperName(fcn, className);
                                elseif (isDoubleVoidPtr)
                                    obj.updateArgAnnotationCppWrapperName(fcn, className, false, argPos);
                                end
                            end
                        end
                        %list of all OpaqueTypes outputs available in
                        %library
                        if ~(ismember(className, obj.OpaqueTypeNames))
                            obj.OpaqueTypeNames(end+1) = className;
                            % create OpaqueTypeDefinition for
                            % user-defined opaque types
                            if not(opaqueTypeNameExists(obj, className))
                                opaqueType = obj.addUserDefinedOpaqueType(className);
                                obj.UserDefinedOpaqueTypes(end+1) = opaqueType;
                                if (isVoidPtr)
                                    fcn.OutputAnnotation.cppWrapperName = opaqueType.OpaqueTypeInterface.cppWrapperName;
                                elseif (isDoubleVoidPtr)
                                    fcn.ArgAnnotations(argPos).cppWrapperName = opaqueType.OpaqueTypeInterface.cppWrapperName;
                                end
                            elseif (isVoidPtr) && (isempty(fcn.OutputAnnotation.cppWrapperName))
                                obj.updateOutputAnnotationCppWrapperName(fcn, className);
                            elseif (isDoubleVoidPtr) && (isempty(fcn.ArgAnnotations(argPos).cppWrapperName))
                                obj.updateArgAnnotationCppWrapperName(fcn, className, false, argPos);
                            end
                        end
                    % MlType struct will be validated in
                    % validateMltypeAsStruct function
                    elseif className ~= "struct" && not(nameExists(obj, className)) && not(isFunctionType(obj, className))
                        error(message('MATLAB:CPP:MissingClass', fcn.getMATLABName(), className));
                    end
                end
            end
            % validate DeleteFcns
            obj.validateDeleteFcnForOutput(fcn);

            % validate DeleteFcns for void** and obj** arguments
            obj.validateDeleteFcnForDoublePtrArgs(fcn);
        end

        function validateDataMember(obj, prop)
            if not(prop.isFundamental())
                className = prop.MATLABType;
                if not(className=="string") && not(nameExists(obj, className))
                    error(message('MATLAB:CPP:PropertyTypeAbsent', className, prop.CPPName));
                end
            end
        end

        function value = isFromSystemHeader(~, type)
            value = false;
            if ~isempty(type.DefPos)
                value = type.DefPos.File.IsIncludedFromSystemIncludeDir;
            elseif ~isempty(type.DeclPos)
                for ii=1:numel(type.DeclPos)
                    if type.DeclPos(ii).File.IsIncludedFromSystemIncludeDir
                        value = true;
                        return;
                    end
                end
            end
        end

        function classType = findClassType(obj, scope, cppname)
            classTypes = scope.findSymbolByMetaClassAndName(...
                internal.cxxfe.ast.types.StructType.StaticMetaClass(), cppname);
            classTypes = classTypes(arrayfun(@(x) ~obj.isFromSystemHeader(x), classTypes));
            if not(isempty(classTypes))
                classType = classTypes(arrayfun(@(x) eq(x.Annotations(1).integrationStatus.definitionStatus, ...
                    internal.mwAnnotation.DefinitionStatus.FullySpecified), classTypes));
                if  (isempty(classType))
                    classType = double.empty(0,0);
                end
            else
                classType = double.empty(0,0);
            end
        end

        function enumType = findEnumType(obj, scope, cppname)
            % Search at the current scope
            enumTypes = scope.findSymbolByMetaClassAndName(...
                internal.cxxfe.ast.types.EnumType.StaticMetaClass(), cppname);
            enumTypes = enumTypes(arrayfun(@(x) ~obj.isFromSystemHeader(x), enumTypes));
            if not(isempty(enumTypes))
                enumType = enumTypes(arrayfun(@(x) eq(x.Annotations(1).integrationStatus.definitionStatus, ...
                    internal.mwAnnotation.DefinitionStatus.FullySpecified), enumTypes));
                if (isempty(enumType))
                    enumType = double.empty(0,0);
                end
            else
                enumType = double.empty(0,0);
            end
        end

        function retFunc = findFunction(obj, cppSig)
            retFunc = [];
            % Get AST of a function based on C++ signature from cppSig2AnnotationsMap
            if(obj.FunctionCppSigToASTMap.isKey(cppSig))
                retFunc = obj.FunctionCppSigToASTMap(cppSig);
            end
        end

        function retOpaqueType = findOpaqueType(obj, scope, cppSig)
            % Search at the current scope
            opaqueTypes = scope.opaqueTypes.toArray;
            for opaqueType = opaqueTypes
                if not(isempty(opaqueType.cppSignature))
                    if(cppSig == opaqueType.cppSignature)
                        retOpaqueType = opaqueType;
                        return;
                    end
                end
            end
            retOpaqueType = double.empty(0,0);
        end

        function clsType = getClass(obj, cppname)
            clsType = obj.findClassType(obj.LibraryInterface.Project.Compilations.at(1), cppname);
        end

        function funcType = getFunction(obj, cppSig)
            funcType = obj.findFunction(cppSig);
        end

        function enumType = getEnum(obj, cppname)
            enumType = obj.findEnumType(obj.LibraryInterface.Project.Compilations.at(1), cppname);
        end

        function opaqueType = getOpaqueType(obj, cppSignature)
            metaDataInfo = obj.LibraryInterface.Project.Compilations.at(1).Annotations.toArray;
            opaqueType = [];
            if(isprop(metaDataInfo, 'opaqueTypes') && metaDataInfo.opaqueTypes.Size() > 0)
               opaqueType = obj.findOpaqueType(metaDataInfo, cppSignature);
            end
        end

        function updateDeleterAnnotationForOpaqueType(obj, deleterAnnotation, mwTypePos)
            deleterAnnotation.isDeleteFcn = true;
            deleterAnnotation.opaqueTypeInfo.isDeleteFcnForMwTypes(mwTypePos) = true;
        end

        % Validate Source File changed in definition file
        function validateSourceFile(obj, sourceFiles)
            if ~iscellstr(sourceFiles)
                if isempty(sourceFiles)
                    error(message('MATLAB:CPP:Filename'));
                end
                try
                    validateattributes(sourceFiles,{'char','string'},{'vector','row'});
                catch ME
                    error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
                end
                % This will set if user want to assign SupportingSourceFiles
                % to empty
                if sourceFiles == ""
                    return;
                end
                if ismissing(sourceFiles)
                    error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
                end
            else
                if ~isrow(sourceFiles)
                    error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
                end
            end
            sourceFiles = cellstr(convertStringsToChars(sourceFiles));
            for index = 1:length(sourceFiles)
                % Error if the source file is a wildcard character
                if strfind(sourceFiles{index}, '*') > 0
                    error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
                end
                if startsWith(sourceFiles{index}, "<")
                    key = extractBetween(sourceFiles{index},"<",">");
                    if ~isKey(obj.RootPaths,key)
                        error(message("MATLAB:CPP:SpecifyRootPathProperty",strcat("<",key,">"),"SupportingSourceFiles"));
                    else
                        sourceFiles{index} = replace(sourceFiles{index},strcat("<",key,">"),obj.RootPaths(key));
                    end
                end

                [~,filename,ext] = fileparts(sourceFiles{index});
                if isempty(filename)
                    error(message('MATLAB:CPP:Filename'));
                end
                if isempty(dir(sourceFiles{index}))
                    error(message('MATLAB:CPP:FileNotFound',sourceFiles{index}));
                end
                % Validate extension of source.
                if ~isempty(ext)
                    if (~strcmp(ext,'.c')  && ~strcmp(ext,'.cpp') && ~strcmp(ext,'.cxx'))
                        error(message('MATLAB:CPP:IncorrectSourceExtension'));
                    end
                end
            end
        end

        %function to get the ML Element Type for FundamentalArray
        %Annotations
        function mlElemType = getMlElemType(obj, mwType)
            delimitedList = strsplit(mwType, '.');
            mwType = delimitedList(end);
            mlElemType =  obj.clibArrFundamentalMlTypeMlElemTypeMap(mwType);
        end

        function validateOpaqueTypeForFunctionOrMethod(obj, fcn)
            % Run additional validation if needed, for void* typedef used as inputs that
            % may or may not have been used as outputs in the library
            % and update the required annotation if these typedefs exist in library
            if fcn.needsAdditionalOpaqueValidation()
                namesForValidation = fcn.OpaqueTypesForValidation;
                for i = 1:numel(namesForValidation)
                    className = namesForValidation(i).className;
                    argPos = namesForValidation(i).argPos;
                    hasMultipleMlTypes = namesForValidation(i).hasMultipleMlTypes;
                    if (~ismember(className, obj.OpaqueTypeNames))
                        error(message('MATLAB:CPP:MissingOpaqueType', fcn.getMATLABName(), className));
                    end
                    obj.updateArgAnnotationCppWrapperName(fcn, className, hasMultipleMlTypes, argPos);
                end
            end
        end

        function valid = verifyFunctionType(obj,cppsignature)
            validateattributes(cppsignature,{'char','string'},{'scalartext'});
            % Function type must not be added twice
            if(~isempty(obj.FunctionTypes.findobj('CPPSignature', cppsignature)))
                error(message('MATLAB:CPP:FunctionTypeExists', cppsignature));
            end
            valid = true;
        end

        function fcnType = getFunctionType(obj, cppSig)
            functionTypeAnnotations = obj.LibraryInterface(1).Project(1).Compilations(1).Annotations(1).functionTypes.toArray;
            fcnType = functionTypeAnnotations.findobj('cppSignature', cppSig);
        end

        function found = isFunctionType(obj,className)
            if ~isempty(obj.FunctionTypes) && any(className == [obj.FunctionTypes.MATLABName])
                found = true;
            else
               found = false;
            end
        end

         function validateMltypeAsStruct(obj,fcn,validMatlabTypes)
            if fcn.needsMltypeStructValidation
                mlTypes = fcn.MlTypesForValidation;
                for i = 1:numel(mlTypes)
                    isStructPod = validMatlabTypes(mlTypes(i).mlType);
                    if ~isStructPod
                        if mlTypes(i).argPos == 0
                            % Argument position for return type = 0
                            error(message('MATLAB:CPP:InvalidMltypeStructForReturnType',fcn.getMATLABName()));
                        else
                            error(message('MATLAB:CPP:InvalidMltypeStructForInputArg',fcn.getMATLABName(),mlTypes(i).argPos));
                        end
                    end
                end
            end
         end

        function computeAvailableFunctions(obj)
            for fcn = obj.Functions
                fcnAnnotation = fcn.FunctionInterface.Annotations.toArray;
                if fcnAnnotation.isDeleteFcn
                    % skip functions that are marked 'DeleteFcn' as these
                    % are not available as MCOS methods
                    continue;
                end
                fcnMlNames = string(fcnAnnotation.name);
                if ~isempty(fcnAnnotation.templateInstantiation)
                    if fcnAnnotation.templateInstantiation.isOverloadPossible
                        % if overload possible for function template
                        % instantiation, add templateUniqueName to AvailableFunctionsMap
                        fcnMlNames(end+1) = string(fcnAnnotation.templateInstantiation.templateUniqueName);
                    end
                end
                for fcnMlName = fcnMlNames
                    if not(obj.AvailableFunctionsMap.isKey(fcnMlName))
                        % Add a mapping between function MATLAB name and its cppSignatureFcnType
                        obj.AvailableFunctionsMap(fcnMlName) = string(fcnAnnotation.cppSignatureFcnType);
                    else
                        % Function is already in the map, this is a overload
                        % add this function signature to the existing list
                        existingFcnSignatures = obj.AvailableFunctionsMap(fcnMlName);
                        existingFcnSignatures(end+1) = string(fcnAnnotation.cppSignatureFcnType);
                        obj.AvailableFunctionsMap(fcnMlName) = existingFcnSignatures;
                    end
                end
            end
            for cls = obj.Classes
                for meth = cls.Methods
                    if meth.MethodInterface.StorageClass ~= internal.cxxfe.ast.StorageClassKind.Static
                        % Do not add non-static method to availableFunctionsMap
                        continue;
                    end
                    methAnnotation = meth.MethodInterface.Annotations.toArray;
                    if methAnnotation.isDeleteFcn
                        % skip methods that are marked 'DeleteFcn' as these
                        % are not available as MCOS methods
                        continue;
                    end
                    fullMethodNames = strcat(cls.MATLABName,".",methAnnotation.name);
                    if ~isempty(methAnnotation.templateInstantiation)
                        if methAnnotation.templateInstantiation.isOverloadPossible
                            % if overload possible for method template
                            % instantiation, add templateUniqueName to AvailableFunctionsMap
                            fullMethodNames(end+1) = strcat(cls.MATLABName,".",methAnnotation.templateInstantiation.templateUniqueName);
                        end
                    end
                    for fullMethodName = fullMethodNames
                        if not(obj.AvailableFunctionsMap.isKey(fullMethodName))
                            % Add a mapping between static method MATLAB name and its cppSignatureFcnType
                            obj.AvailableFunctionsMap(fullMethodName) = string(methAnnotation.cppSignatureFcnType);
                        else
                            % Static method is already in the map, this is a overload
                            % add this method signature to the existing list
                            existingFcnSignatures = obj.AvailableFunctionsMap(fullMethodName);
                            existingFcnSignatures(end+1) = string(methAnnotation.cppSignatureFcnType);
                            obj.AvailableFunctionsMap(fullMethodName) = existingFcnSignatures;
                        end
                    end
                end
            end
        end

        function opaqueType = addUserDefinedOpaqueType(obj, mlName)
            %create annotation for new user-defined OpaqueTypes
            opaqueTypeAnnotation = internal.mwAnnotation.OpaqueTypeAnnotation(obj.LibraryInterface.Model);
            opaqueTypeDataAnnotation = internal.mwAnnotation.ClassAnnotation(obj.LibraryInterface.Model);
            opaqueTypeDataAnnotation.description = strcat(mlName,"    C++ opaque type.");
            opaqueTypeDataAnnotation.detailedDescription = "";
            opaqueTypeDataAnnotation.name = string(mlName);
            opaqueCPPName = extractAfter(string(mlName),strcat("clib.", obj.PackageName, "."));
            opaqueCPPName = strrep(opaqueCPPName,'.','::');
            opaqueTypeAnnotation.cppSignature = strcat("typedef void* ",opaqueCPPName);
            opaqueTypeDataAnnotation.deallocatorPTKey = strcat("O//delete");
            opaqueTypeDataAnnotation.isDestructible = true;
            opaqueTypeAnnotation.opaqueTypeData = opaqueTypeDataAnnotation;
            opaqueTypeAnnotation.cppWrapperName = obj.getUniqueCppWrapperName(obj.cppWrapperNames, opaqueCPPName);
            obj.cppWrapperNames(end+1) = opaqueTypeAnnotation.cppWrapperName;
            opaqueType = clibgen.OpaqueTypeDefinition(obj, string(opaqueTypeAnnotation.cppSignature), ...
                opaqueTypeAnnotation, mlName, opaqueTypeDataAnnotation.description, "");
        end

        function idx = getIndexOpaqueType(obj, OpaqueTypeList, mlName)
            idx = 0;
            for i = 1:numel(OpaqueTypeList)
                if (OpaqueTypeList(i).MATLABName == mlName)
                    idx = i;
                    return;
                end
            end
        end

        function updateOutputAnnotationCppWrapperName(obj, fcn, className)
            idx = obj.getIndexOpaqueType(obj.OpaqueTypes, className);
            if (idx)
                fcn.OutputAnnotation.cppWrapperName = obj.OpaqueTypes(idx).OpaqueTypeInterface.cppWrapperName;
            else
                % check if OpaqueType name is a user-defined typedef name
                % for void*
                idxUserDefined = obj.getIndexOpaqueType(obj.UserDefinedOpaqueTypes, className);
                if (idxUserDefined)
                    fcn.OutputAnnotation.cppWrapperName = obj.UserDefinedOpaqueTypes(idxUserDefined).OpaqueTypeInterface.cppWrapperName;
                end
            end
        end

        function updateArgAnnotationCppWrapperName(obj, fcn, className, hasMultipleMlTypes, argPos)
            % update the annotation with
            % cppWrapperName if the OpaqueType exists
            % check if OpaqueType name is present in library
            idx = obj.getIndexOpaqueType(obj.OpaqueTypes, className);
            if (idx)
                % for multiple typedefs to plain void*, update argument
                % cppWrapperNames for each typedef in
                % OpaqueTypeArgumentInfo else update the argument
                % annotation directly
                if (hasMultipleMlTypes)
                    fcn.ArgAnnotations(argPos).opaqueTypeInfo.cppWrapperNames(end+1) = obj.OpaqueTypes(idx).OpaqueTypeInterface.cppWrapperName;
                else
                    fcn.ArgAnnotations(argPos).cppWrapperName = obj.OpaqueTypes(idx).OpaqueTypeInterface.cppWrapperName;
                end
            else
                % check if OpaqueType name is a
                % user-defined typedef name for void*
                idxUserDefined = obj.getIndexOpaqueType(obj.UserDefinedOpaqueTypes, className);
                if (idxUserDefined)
                    if (hasMultipleMlTypes)
                        fcn.ArgAnnotations(argPos).opaqueTypeInfo.cppWrapperNames(end+1) = obj.UserDefinedOpaqueTypes(idxUserDefined).OpaqueTypeInterface.cppWrapperName;
                    else
                        fcn.ArgAnnotations(argPos).cppWrapperName = obj.UserDefinedOpaqueTypes(idxUserDefined).OpaqueTypeInterface.cppWrapperName;
                    end
                end
            end
        end

        function validateDeleteFcnForOutput(obj, fcn)
            if (~isa(fcn, "clibgen.ConstructorDefinition") && ~isempty(fcn.Output))
                deleteFcnInfo = fcn.Output.DeleteFcnPair;
                %deleteFcnInfo is a string array with two elements
                %first element contains name of Delete Function
                %second element contains the MATLABType for which
                %DeleteFcn is invoked
                if not(isempty(deleteFcnInfo))
                    isNullTermString = clibgen.MethodDefinition.isCharacterPointerNullTerminatedString(fcn.OutputAnnotation.cppType, ...
                        fcn.OutputAnnotation.storage, fcn.Output.MATLABType, fcn.Output.Shape);
                    % Update DeleteFcnInfo if delete is used or fundamental types are
                    % specified as MATLABType
                    if ((deleteFcnInfo(1)=="delete") || (deleteFcnInfo(1)=="free" && isNullTermString) || (deleteFcnInfo(1)=="free" && clibgen.MethodDefinition.isFundamentalMlType(fcn.Output.MATLABType)))
                        fcn.updateDeletePTKey(deleteFcnInfo(1));
                    else
                        deleterAnnotation = obj.findDeleteFcnAnnotation(deleteFcnInfo, fcn, false);
                        [mwTypePos,isValid] = obj.isValidMwTypeForDeleteFcn(deleterAnnotation, deleteFcnInfo);
                        if (~isValid && isNullTermString)
                            annotationsArr = deleterAnnotation.inputs.toArray;
                            % If it is NULLTerminated string and CPPType
                            % doesn't match between deleter function and
                            % the function output then throw error
                            if ~strcmp(annotationsArr.cppType,fcn.OutputAnnotation.cppType)
                                error(message("MATLAB:CPP:InvalidDeleteFcn", deleterAnnotation.cppSignature, deleteFcnInfo(2)));
                            end
                        end
                        % If not valid and MLTYPE is other than
                        % fundamental type or NullTerminated String then InvalidDeleteFcn
                        if not(isValid) && ~isNullTermString && ~clibgen.MethodDefinition.isFundamentalMlType(deleteFcnInfo(2))
                            error(message("MATLAB:CPP:InvalidDeleteFcn", deleterAnnotation.cppSignature, deleteFcnInfo(2)));
                        end
                        % If output is a const type and deleteFcn input is a non const type
                        if(clibgen.MethodDefinition.isFundamentalMlType(deleteFcnInfo(2)) && ~isNullTermString && fcn.OutputAnnotation.isConstData && ~deleterAnnotation.inputs.toArray.isConstData )
                            error(message("MATLAB:CPP:InvalidCppTypeForDeleteFcn", deleterAnnotation.cppSignature, fcn.CPPSignature, ...
                                extractBefore(extractAfter(deleterAnnotation.cppSignature,deleteFcnInfo(1)+"("), deleterAnnotation.inputs.toArray.name), ...
                                deleterAnnotation.inputs.toArray.name, deleteFcnInfo(1), ...
                                extractBefore(fcn.CPPSignature, fcn.FunctionInterface.Name), fcn.FunctionInterface.Name));
                        end
                        % custom deleter input type and C++ function output
                        % type does not match in case of fundamental type
                        % as DeleteFcn type
                        if(clibgen.MethodDefinition.isFundamentalMlType(deleteFcnInfo(2)) && ~strcmp(fcn.OutputAnnotation.mwType, deleterAnnotation.inputs.toArray.mwType) && ~isNullTermString)
                            error(message("MATLAB:CPP:InvalidMLTypeForDeleteFcn", deleterAnnotation.cppSignature, fcn.CPPSignature, deleterAnnotation.inputs.toArray.name, ...
                                deleteFcnInfo(1), fcn.FunctionInterface.Name, fcn.OutputAnnotation.mwType));
                        end
                        if (mwTypePos ~= -1)
                            fcn.updateDeletePTKey(strcat(deleterAnnotation.ptKey, '_', int2str(mwTypePos)));
                            if (~(isempty(deleterAnnotation.opaqueTypeInfo)))
                                obj.updateDeleterAnnotationForOpaqueType(deleterAnnotation, mwTypePos);
                            else
                                deleterAnnotation.opaqueTypeInfo = internal.mwAnnotation.OpaqueTypeFunctionInfo(obj.LibraryInterface.Model);
                                obj.updateDeleterAnnotationForOpaqueType(deleterAnnotation, mwTypePos);
                            end
                        else
                            fcn.updateDeletePTKey(deleterAnnotation.ptKey);
                            deleterAnnotation.isDeleteFcn = true;
                        end
                    end
                end
            end
        end

        function validateDeleteFcnForDoublePtrArgs(obj, fcn)
            if (~isa(fcn, "clibgen.ConstructorDefinition") && ~isempty(fcn.Arguments))
                for i = 1:numel(fcn.Arguments)
                    if (isa(fcn, "clibgen.FunctionDefinition"))
                        args = fcn.FunctionInterface.Params.toArray;
                    elseif isa(fcn, "clibgen.MethodDefinition")
                        args = fcn.MethodInterface.Params.toArray;
                    end
                    argType = args(i).Type;
                    if (clibgen.MethodDefinition.isDoublePointer(argType))
                        deleteFcnInfo = fcn.Arguments(i).DeleteFcnPair;
                        if not(isempty(deleteFcnInfo))
                            if(deleteFcnInfo(1)~="delete")
                                deleterAnnotation = obj.findDeleteFcnAnnotation(deleteFcnInfo, fcn, true);
                                [mwTypePos,isValid] = obj.isValidMwTypeForDeleteFcn(deleterAnnotation, deleteFcnInfo);
                                if not(isValid)
                                    error(message("MATLAB:CPP:InvalidDeleteFcn", deleterAnnotation.cppSignature, deleteFcnInfo(2)));
                                end
                                if (mwTypePos ~= -1)
                                    fcn.updateArgumentDeletePTKey(strcat(deleterAnnotation.ptKey, '_', int2str(mwTypePos)), i);
                                    if (~(isempty(deleterAnnotation.opaqueTypeInfo)))
                                        obj.updateDeleterAnnotationForOpaqueType(deleterAnnotation, mwTypePos);
                                    else
                                        deleterAnnotation.opaqueTypeInfo = internal.mwAnnotation.OpaqueTypeFunctionInfo(obj.LibraryInterface.Model);
                                        obj.updateDeleterAnnotationForOpaqueType(deleterAnnotation, mwTypePos);
                                    end
                                else
                                    fcn.updateArgumentDeletePTKey(deleterAnnotation.ptKey, i);
                                    deleterAnnotation.isDeleteFcn = true;
                                end

                            else
                                fcn.updateArgumentDeletePTKey(deleteFcnInfo(1), i);
                            end
                        end
                    end
                end
            end
        end

        % validates shape of deleter function and the function for which 
        % DeleteFcn is specified
        function isValid = validateShapeForDeleter(obj,deleterShape,fcn, isDoublePtr)
            isValid = false;
            % validates shape for function whose output is of type pointer
            if ~isDoublePtr && ~isempty(fcn.Output) && find(contains(fcn.Output.DeleteFcnPair,"struct"))
                % For scalar return type, match the shape
                if isnumeric(fcn.Output.Shape) && any(fcn.Output.Shape == 1)
                    if fcn.Output.Shape == deleterShape
                        isValid = true;
                    end
                else
                    % for array return type no need to match the shape
                    isValid = true;
                end
            else
                % validates shape of the function whose input
                % is of type double pointer
                for arg = fcn.Arguments
                    if ~isempty(arg.DeleteFcnPair) && find(contains(arg.DeleteFcnPair,"struct"))
                        if arg.Shape == deleterShape
                            isValid = true;
                        end
                    end
                end
            end
        end

        function deleterAnnotation = findDeleteFcnAnnotation(obj, deleteFcnInfo, fcn, isDoublePtr)
            deleteFcnDefinition = [];
            for func = obj.Functions
                if(func.CPPSignature == deleteFcnInfo(1))
                    deleteFcnDefinition = func;
                    break;
                else
                    if(func.CPPSignature.contains(deleteFcnInfo(1)))
                        % Do more work only if there is a
                        % possibility of a match
                        cppSig = func.CPPSignature;
                        funcName = cppSig.split("(");
                        funcName = funcName(1).split;
                        % Functions with mltype as "struct" should match
                        % the shape of the deleter function
                        if and(funcName(end) == deleteFcnInfo(1),find(contains(deleteFcnInfo,"struct")))
                            isValid = obj.validateShapeForDeleter(func.Arguments.Shape,fcn, isDoublePtr);
                            if isValid
                                deleteFcnDefinition = func;
                                break;
                            end
                        elseif(funcName(end) == deleteFcnInfo(1))
                            deleteFcnDefinition = func;
                            break;
                        end
                    end
                end
            end
            if(isempty(deleteFcnDefinition))
                error(message('MATLAB:CPP:DeleteFcnNotFound', deleteFcnInfo(1), fcn.CPPSignature));
            end
            deleterAnnotation = deleteFcnDefinition.FunctionInterface.Annotations(1);
        end
        function [mwTypePos,isValid] = isValidMwTypeForDeleteFcn(obj, deleterAnnotation, deleteFcnInfo)
            %Check for validity
            isValid = false;
            % to hold the position of mltype for void* as
            % Multiple MATLAB types
            mwTypePos = int32(-1);
            if(isempty(deleterAnnotation.outputs.toArray))
                annotationsArr = deleterAnnotation.inputs.toArray;
                if(length(annotationsArr)==1)
                    if((annotationsArr.storage == internal.mwAnnotation.StorageKind.Pointer ...
                            || annotationsArr.storage == internal.mwAnnotation.StorageKind.Reference))
                        if (~(isempty(annotationsArr.opaqueTypeInfo)) ...
                            && ~(isempty(annotationsArr.opaqueTypeInfo.mwTypeNames.toArray)))
                            mwTypesList = annotationsArr.opaqueTypeInfo.mwTypeNames.toArray;
                            %iterate over the list of MATLAB Types
                            %for OpaqueType and confirm if that
                            %is same as MATLAB Type for which
                            %DeleteFcn is specified
                            for i= 1:numel(mwTypesList)
                                if (mwTypesList(i) == deleteFcnInfo(2))
                                    isValid = true;
                                    mwTypePos = i;
                                    break;
                                end
                            end
                        elseif (annotationsArr.mwType == deleteFcnInfo(2))
                            isValid = true;
                        % If mwType is configuread as "struct" for function
                        % output argument then no need to validate mwType
                        elseif find(contains(deleteFcnInfo,"struct"))
                            deleterMwType = annotationsArr.mwType;
                            % For nonconst return type, user can mltype as
                            % struct and shape as array. As shape already
                            % validated, mwType will be validated below
                            if strncmp(annotationsArr.mwType,"clib.array.",strlength("clib.array."))
                                deleterMwType = "clib." + extractAfter(annotationsArr.mwType,"clib.array.");
                            end
                            if find(contains(deleteFcnInfo,deleterMwType))
                                isValid = true;
                            end
                        end
                    end
                end
            end
        end
        function createFunctionCppSigToASTMap(obj, scope)
            %Create a map that creates a mapping between C++ signatures and
            %the function annotation.
            arguments
                obj clibgen.LibraryDefinition
                scope (1,1) =missing
            end
            if(ismissing(scope))
                scope = obj.LibraryInterface.Project.Compilations.at(1);
            else
                assert(isa(scope, 'internal.cxxfe.ast.Namespace'))
            end
            funcs = scope.Funs.toArray;
            for func = funcs
                definitionStatus = func.Annotations(1).integrationStatus.definitionStatus;
                % Add only the FullySpecified and PartiallySpecified
                % functions, and skip all functions that are tagged
                % OutOfScope, Inaccessible and Unsupported
                if(definitionStatus==internal.mwAnnotation.DefinitionStatus.FullySpecified || ...
                        definitionStatus==internal.mwAnnotation.DefinitionStatus.PartiallySpecified)
                    cppSig = func.Annotations(1).cppSignature;
                    obj.FunctionCppSigToASTMap(cppSig) = func;
                end
            end
            % Recurse through all the namespaces in the current scope
            namespaces = scope.Namespaces.toArray;
            for ns = namespaces
                if (ns.Name ~= "std")
                    obj.createFunctionCppSigToASTMap(ns);
                end
            end
        end
    end

    methods(Access=public)
        function obj = LibraryDefinition(dataFile)
            %LibraryDefinition constructor
            %   LIBDEF = LIBRARYDEFINITION(DATAFILE) returns a LIBRARYDEFINITION
            %   object corresponding to the library represented by the metadata
            %   file DATAFILE
            import clibgen.internal.*;

            try
                % Verify that the metadata file exists
                validateattributes(dataFile,{'char','string'},{'scalartext'});
                % File must exist
                if(exist(dataFile,'file') == 0)
                    error(message('MATLAB:CPP:FileNotFound',dataFile));
                end
                obj.RenamingMap = containers.Map.empty();
                obj.MatchingFunctionsForCFunctionPtr = containers.Map.empty();
                obj.MatchingFunctionsForStdFunction  = containers.Map.empty();
                obj.AvailableFunctionsMap            = containers.Map.empty();
                % Handle wrong file extensions
                [~,~,ext] = fileparts(dataFile);
                if(~strcmp(ext, '.xml'))
                    error(message('MATLAB:CPP:IncorrectExtension'));
                end
                try
                    % Get the absolute path location of the .xml file
                    dataFile = which(dataFile);
                    obj.LibraryInterface = internal.cxxfe.ast.Ast.deserializeFromFile(dataFile, internal.cxxfe.ast.io.IoFormat.xml);
                catch e
                    if(e.identifier=="mf0:messages:NoSuchType")
                        error(message("MATLAB:CPP:IncompatibleDefinition"));
                    end
                    throwAsCaller(e);
                end
                metaDataInfo = obj.LibraryInterface.Project.Compilations.at(1).Annotations.toArray;

                rootpathKeys = string([]); rootpathValues = string([]);
                if(~isempty(metaDataInfo.rootpathKeys.toArray))
                    rootpathKeys = string(metaDataInfo.rootpathKeys.toArray);
                end
                if(~isempty(metaDataInfo.rootpathValues.toArray))
                    rootpathValues = string(metaDataInfo.rootpathValues.toArray);
                end
                obj.RootPaths = dictionary(rootpathKeys, rootpathValues);

                if(~isempty(metaDataInfo.librariesRelative.toArray))
                    obj.Libraries = metaDataInfo.librariesRelative.toArray;
                elseif(~isempty(metaDataInfo.libraries.toArray)) % for backward compatibility - to run definition files from previoius release
                    obj.Libraries = metaDataInfo.libraries.toArray;
                end

                if(~isempty(metaDataInfo.headersRelative.toArray))
                    obj.HeaderFiles = metaDataInfo.headersRelative.toArray;
                elseif(~isempty(metaDataInfo.headers.toArray)) % for backward compatibility
                    obj.HeaderFiles = metaDataInfo.headers.toArray;
                end

                if(~isempty(metaDataInfo.sourceFilesRelative.toArray))
                    obj.SupportingSourceFiles = metaDataInfo.sourceFilesRelative.toArray;
                elseif(~isempty(metaDataInfo.sourceFiles.toArray)) % for backward compatibility
                    obj.SupportingSourceFiles = metaDataInfo.sourceFiles.toArray;
                end

                if(~isempty(metaDataInfo.locationRelative))
                    obj.OutputFolder = metaDataInfo.locationRelative;
                elseif(~isempty(metaDataInfo.location)) % for backward compatibility
                    obj.OutputFolder = metaDataInfo.location;
                end

                obj.PackageName = metaDataInfo.libData.packageName;
                obj.SeparateProcess = metaDataInfo.libData.separateProcess;

                if(~isempty(metaDataInfo.includePathsRelative.toArray))
                    obj.IncludePath = metaDataInfo.includePathsRelative.toArray;
                elseif(~isempty(metaDataInfo.includePaths.toArray)) % for backward compatibility
                    obj.IncludePath = metaDataInfo.includePaths.toArray;
                end

                if(~isempty(metaDataInfo.definedMacros.toArray))
                    obj.DefinedMacros = metaDataInfo.definedMacros.toArray;
                end
                if(~isempty(metaDataInfo.undefinedMacros.toArray))
                    obj.UndefinedMacros = metaDataInfo.undefinedMacros.toArray;
                end
                if metaDataInfo.CLinkage
                    obj.CLinkage = logical(metaDataInfo.CLinkage);
                end
                if(~isempty(metaDataInfo.additionalCompilerFlags.toArray))
                    obj.additionalCompilerFlagsPassedtoParser = metaDataInfo.additionalCompilerFlags.toArray;
                end
                if(~isempty(metaDataInfo.additionalLinkerFlags.toArray))
                    obj.AdditionalLinkerFlags = metaDataInfo.additionalLinkerFlags.toArray;
                end
                obj.Verbose = metaDataInfo.verbose;
                if(isprop(metaDataInfo, 'fundamentalArrays') && metaDataInfo.fundamentalArrays.Size() > 0)
                    for fundamentalArray = metaDataInfo.fundamentalArrays.toArray
                        obj.FundamentalArrays(end+1) = fundamentalArray.name;
                    end
                end
                obj.FunctionCppSigToASTMap = containers.Map.empty();
                createFunctionCppSigToASTMap(obj);
            catch ME
                throw(ME);
            end
        end

        function cls = addClass(obj, cppname, varargin)

            %ADDCLASS Adds a class to the library definition
            %   CLSDEF = ADDCLASS(LIBRARYDEFINITION,CPPNAME,MATLABNAME,VALUE,VARARGIN) adds a class with
            %   C++ name CPPNAME to the library definition and returns it.
            try
                p = inputParser;
                addRequired(p,'CPPName',@(x)verifyClass(obj,x));
                addParameter(p,"MATLABName","",@(x)verifyMATLABName(obj,x,true,false));
                addParameter(p,"Description","",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"DetailedDescription","",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                p.KeepUnmatched = false;
                parse(p,cppname,varargin{:});
                parsedResults = p.Results;
                cppname = string(cppname);
                clsType = obj.getClass(cppname);
                if((strlength(cppname)==0) || isempty(clsType))
                    error(message("MATLAB:CPP:ClassNotFound", cppname, obj.PackageName));
                end
                if(isempty(varargin))
                    error(message('MATLAB:CPP:EmptyMlName', 'class'));
                end
                classAnnotation = clsType.Annotations.toArray;
                inputMATLABName = string(parsedResults.MATLABName);
                if not(classAnnotation(1).name == inputMATLABName)
                    % Class has been renamed, add to the map
                    for types = clsType.Scope.Types.toArray
                        nestedAnnotation = types.Annotations.toArray;
                        integrationStatus = nestedAnnotation.integrationStatus;
                        if(integrationStatus.definitionStatus == ...
                                internal.mwAnnotation.DefinitionStatus.FullySpecified)
                            % Renaming classes with nested classes or enums is
                            % not supported
                            error(message('MATLAB:CPP:RenamingNotSupported', ...
                                classAnnotation(1).name));
                        end
                    end
                    verifyNewMATLABName(obj, classAnnotation(1).name, inputMATLABName);
                    obj.RenamingMap(classAnnotation(1).name) = inputMATLABName;
                    classAnnotation(1).name = inputMATLABName;
                end
                cls = clibgen.ClassDefinition(obj, parsedResults.CPPName, clsType,...
                    classAnnotation(1).name, parsedResults.Description, parsedResults.DetailedDescription, classAnnotation(1).cppStructType);
                obj.Classes(end+1) = cls;
                obj.Valid = false;

                if(classAnnotation(1).needArray)
                    obj.ClassArrays(end+1) = insertAfter(cls.MATLABName, "clib.", "array.");
                end
            catch ME
                throw(ME);
            end
        end

        function fcn = addFunction(obj, CPPSignature, varargin)
            %ADDFUNCTION Adds a function to the library definition
            %   FCNDEF = ADDFUNCTION(LIBRARYDEFINITION,CPPSIGNATURE,MATLABNAME,VALUE,VARARGIN)
            %   adds a function with C++ signature CPPSIGNATURE to the library
            %   definition and returns it.
            try
                p = inputParser;
                addRequired(p,'CPPSignature',@(x)verifyFunction(obj,x));
                addParameter(p,"MATLABName","",@(x)verifyMATLABName(obj,x,false,false,CPPSignature));
                addParameter(p,"Description","",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"DetailedDescription","",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"TemplateUniqueName","",@(x)verifyMATLABName(obj,x,false,false));
                p.KeepUnmatched = false;
                parse(p,CPPSignature,varargin{:});
                parsedResults = p.Results;
                if(isempty(varargin))
                    error(message('MATLAB:CPP:EmptyMlName', 'function'));
                end
                functionInterface = obj.getFunction(string(CPPSignature));
                if (string(CPPSignature) == "") || (isempty(functionInterface))
                    error(message("MATLAB:CPP:FunctionNotFound", CPPSignature, obj.PackageName));
                end
                %Check to make sure not Inaccessible, OutOfScope or Unsupported
                functionAnnotation = functionInterface.Annotations.toArray;
                if not(clibgen.ClassDefinition.isSupported(functionAnnotation(1)))
                    error(message('MATLAB:CPP:FunctionNotSupported', functionAnnotation.cppSignature));
                end
                inputMATLABName = string(parsedResults.MATLABName);
                if not(functionAnnotation(1).name == inputMATLABName)
                    % Function has been renamed, add to the map
                    verifyNewMATLABName(obj, functionAnnotation(1).name, inputMATLABName);
                    % Ensure MATLABName does not match the TemplateUniqueName
                    % when overload is possible
                    if ~isempty(functionAnnotation(1).templateInstantiation)
                        inputTemplateUniqueName = string(parsedResults.TemplateUniqueName);
                        uniqueName = functionAnnotation(1).templateInstantiation.templateUniqueName;
                        if ((inputTemplateUniqueName~="") && ~strcmp(inputTemplateUniqueName,uniqueName))
                            uniqueName = inputTemplateUniqueName;
                        end
                        if (functionAnnotation(1).templateInstantiation.isOverloadPossible && ...
                                strcmp(inputMATLABName,uniqueName))
                            error(message("MATLAB:CPP:NewNameAlreadyExists", 'MATLABName', inputMATLABName, ...
                                'TemplateUniqueName'));
                        end
                    end
                    obj.RenamingMap(functionAnnotation(1).name) = inputMATLABName;
                    functionAnnotation(1).name = inputMATLABName;
                end
                % Check if template instantiation of a function
                if ((parsedResults.TemplateUniqueName~="") && ~isempty(functionAnnotation(1).templateInstantiation))
                    inputTemplateUniqueName = string(parsedResults.TemplateUniqueName);
                    verifyNewMATLABName(obj, functionAnnotation(1).templateInstantiation.templateUniqueName, inputTemplateUniqueName);
                    uniqueName = functionAnnotation(1).name;
                    if ((inputMATLABName~="") && ~strcmp(inputMATLABName,uniqueName))
                        uniqueName = inputMATLABName;
                    end
                    if (functionAnnotation(1).templateInstantiation.isOverloadPossible && ...
                            strcmp(inputTemplateUniqueName,uniqueName))
                        error(message("MATLAB:CPP:NewNameAlreadyExists", 'TemplateUniqueName', ...
                            inputTemplateUniqueName, 'MATLABName'));
                    end
                end
                fcn = clibgen.FunctionDefinition(obj, parsedResults.CPPSignature,....
                    functionInterface, parsedResults.MATLABName, parsedResults.Description, ...
                    parsedResults.DetailedDescription, parsedResults.TemplateUniqueName);
                obj.Functions(end+1) = fcn;
                obj.Valid = false;
            catch ME
                throw(ME);
            end
        end

        function addEnumeration(obj, cppName, mlType, entries, varargin)
            %ADDENUMERATION Adds an enumeration to the library definition
            %   ADDENUMERATION(LIBRARYDEFINITION,CPPNAME,MATLABTYPE,ENUMERANTS,MATLABNAME,VALUE,VARARGIN)
            %   adds an enumeration with C++ name CPPNAME to the library
            %   definition.
            try
                if(numel(varargin) > 8)
                    error(message("MATLAB:maxrhs"));
                elseif(numel(varargin) >=0 && numel(varargin) < 2)
                    error(message("MATLAB:minrhs"));
                end
                parser = inputParser;
                parser.CaseSensitive = true;
                parser.KeepUnmatched = false;
                parser.PartialMatching = false;
                addRequired(parser,  "LibraryDefinition", @(x) isa(x, "clibgen.LibraryDefinition"));
                addRequired(parser,  "CPPName",           @(x) verifyEnum(obj, x));
                addRequired(parser,  "MATLABType",        @(x) validateattributes(x, {'char','string'},{'scalartext', 'nonempty'}));
                addRequired(parser,  "Enumerants",        @(x) verifyEnumerants(obj, x));
                addParameter(parser, "MATLABName", "",    @(x) verifyMATLABName(obj,x, true, false));
                addParameter(parser, "Description","",    @(x) validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(parser, "DetailedDescription","", @(x) validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(parser, "EnumerantDescriptions",string.empty, @(x) verifyEnumerantDescriptions(obj, x, entries));
                parse(parser, obj, cppName, mlType, entries, varargin{:});
                mlName = string(parser.Results.MATLABName);
                enumInterface = obj.getEnum(string(cppName));
                if(isempty(enumInterface))
                     error(message("MATLAB:CPP:EnumNotFound", cppName));
                else
                    enumAnnotation = enumInterface.Annotations.toArray;
                    if not(enumAnnotation(1).name == string(mlName))
                       % enum has been renamed, add to the map
                       obj.RenamingMap(enumAnnotation(1).name) = string(mlName);
                    end
                end
                enumObj = clibgen.EnumDefinition(obj, string(cppName), string(mlType), string(mlName), entries, enumInterface, parser.Results.Description, parser.Results.DetailedDescription, parser.Results.EnumerantDescriptions);
                obj.Enumerations(end+1) = enumObj;
            catch ME
                throw(ME);
            end
        end

        function addOpaqueType(obj, cppsignature, varargin)

            %ADDOPAQUETYPE Adds an opaque type to the library definition
            %   ADDOPAQUETYPE(LIBRARYDEFINITION,CPPSIGNATURE,MATLABNAME,VALUE,VARARGIN) adds an opaque type with
            %   C++ signature CPPSIGNATURE to the library definition.
            try
                p = inputParser;
                addRequired(p,"CPPSignature",@(x)verifyOpaqueType(obj,x));
                addParameter(p,"MATLABName","",@(x)verifyMATLABName(obj,x,false,true));
                addParameter(p,"Description","",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                addParameter(p,"DetailedDescription","",@(x)validateattributes(x,{'char','string'},{'scalartext'}));
                p.KeepUnmatched = false;
                parse(p,cppsignature,varargin{:});
                parsedResults = p.Results;
                cppsignature = string(cppsignature);
                opaqueType = obj.getOpaqueType(cppsignature);
                if((strlength(cppsignature)==0) || isempty(opaqueType))
                    error(message("MATLAB:CPP:OpaqueTypeNotFound", cppsignature, obj.PackageName));
                end
                if(isempty(varargin))
                    error(message('MATLAB:CPP:EmptyMlName', 'OpaqueType'));
                end
                inputMATLABName = string(parsedResults.MATLABName);
                opaqueTypeDataAnnotation = opaqueType.opaqueTypeData;
                if not(opaqueTypeDataAnnotation.name == inputMATLABName)
                    verifyNewMATLABName(obj, opaqueTypeDataAnnotation.name, inputMATLABName);
                    obj.RenamingMap(opaqueTypeDataAnnotation.name) = inputMATLABName;
                    opaqueTypeDataAnnotation.name = inputMATLABName;
                end
                opaqueType = clibgen.OpaqueTypeDefinition(obj, parsedResults.CPPSignature, opaqueType, ...
                    parsedResults.MATLABName, parsedResults.Description, parsedResults.DetailedDescription);
                obj.OpaqueTypes(end+1) = opaqueType;
                obj.Valid = false;
                obj.cppWrapperNames(end+1) = obj.OpaqueTypes(end).OpaqueTypeInterface.cppWrapperName;
            catch ME
                throw(ME);
            end

        end

        function addFunctionType(obj, cppSignature, varargin)
            %ADDFUNCTIONTYPE adds a function type to the library definition
            %   ADDFUNCTIONTYPE(LIBRARYDEFINITION,CPPSIGNATURE,MATLABNAME,VALUE,VARARGIN) adds a function type with
            %   C++ CPPSIGNATURE to the library definition.
            try
                parser = inputParser;
                parser.KeepUnmatched = false;
                addRequired(parser,  "LibraryDefinition", @(x) isa(x, "clibgen.LibraryDefinition"));
                addRequired(parser,  "CPPSignature",      @(x) verifyFunctionType(obj, x));
                addParameter(parser, "MATLABName", "",    @(x) verifyMATLABName(obj, x, true));
                addParameter(parser, "Description","",    @(x) validateattributes(x,{'char','string'},{'scalartext'}));
                parse(parser, obj, cppSignature, varargin{:});
                mlName = string(parser.Results.MATLABName);
                functionTypeAnnotation = obj.getFunctionType(string(cppSignature));
                if(isempty(functionTypeAnnotation))
                    error(message("MATLAB:CPP:FunctionTypeNotFound", cppSignature));
                else
                    if not(functionTypeAnnotation.name == string(mlName))
                       % function type has been renamed, add to the map
                       obj.verifyNewMATLABName(functionTypeAnnotation.name, mlName);
                       obj.RenamingMap(functionTypeAnnotation.name) = string(mlName);
                    end
                end
                functionTypeObj = clibgen.FunctionTypeDefinition(obj, string(cppSignature), ...
                    string(mlName), functionTypeAnnotation, parser.Results.Description);
                obj.FunctionTypes(end+1) = functionTypeObj;
                obj.cppWrapperNames(end+1) = functionTypeAnnotation.cppWrapperName;
            catch ME
                throw(ME);
            end
        end

        function validate(obj)
            try
                FnMLSignatures = [];
                for fcn = obj.Functions
                    obj.validateFunctionOrMethod(fcn);
                    mlSignature = fcn.MATLABSignature;
                    % with void* input configured as multiple MLTypes,
                    % multiple signatures would be generated else
                    % for other cases single signature is generated
                    for i =1:numel(mlSignature)
                        fnNameIdx = strfind(mlSignature(i), ' clib');
                        if isempty(fnNameIdx)
                            mlInputSignature = mlSignature(i);
                        else
                            mlInputSignature = extractAfter(mlSignature(i), fnNameIdx(1));
                        end
                        idx = find(strcmp(FnMLSignatures, mlInputSignature), 1);
                        if ~isempty(idx)
                            error(message('MATLAB:CPP:MLSignatureOverload', ...
                                'function', fcn.CPPSignature, obj.Functions(idx).CPPSignature));
                        end
                        FnMLSignatures = [FnMLSignatures mlInputSignature]; %#ok<AGROW>
                    end
                end
                % dictionary that stores mltype of all visited classes and their pod status
                % to avoid revalidation
                visitedClassesWithPodStatus = dictionary;
                for cls = obj.Classes
                    for prop = cls.Properties
                        obj.validateDataMember(prop);
                    end
                    visitedClassesWithPodStatus = cls.updatePODStatus(visitedClassesWithPodStatus);
                    for meth = cls.Methods
                        obj.validateFunctionOrMethod(meth);
                    end
                    for ctor = cls.Constructors
                        obj.validateFunctionOrMethod(ctor);
                    end
                    cls.validateMLSignatures();
                end

                % validate void* inputs having opaque type that were not
                % available earlier
                % Validate inputs and output of functions or methods whose
                % mltype is updated as struct
                for fcn = obj.Functions
                    obj.validateOpaqueTypeForFunctionOrMethod(fcn);
                    obj.validateMltypeAsStruct(fcn, visitedClassesWithPodStatus);
                end
                for cls = obj.Classes
                    for meth = cls.Methods
                        obj.validateOpaqueTypeForFunctionOrMethod(meth);
                        obj.validateMltypeAsStruct(meth, visitedClassesWithPodStatus);
                    end
                    for ctor = cls.Constructors
                        obj.validateOpaqueTypeForFunctionOrMethod(ctor);
                    end
                end
                for opaqueType = obj.UserDefinedOpaqueTypes
                    obj.OpaqueTypes(end+1) = opaqueType;
                end
            catch ME
                validationME = MException('MATLAB:CPP:InvalidLibrary',...
                    char(message('MATLAB:CPP:InvalidLibrary', obj.PackageName).string));
                validationME = addCause(validationME,ME);
                throwAsCaller(validationME);
            end
            obj.Valid = true;
        end

        function build(obj)
            if(obj.Valid == false)
                validate(obj);
            end

            % validate <rootpath> keys in fileOrPath inputs
            obj.validateRootPathKeys('HeaderFiles', obj.HeaderFiles);
            obj.validateRootPathKeys('Libraries', obj.Libraries);
            obj.validateRootPathKeys('IncludePath', obj.IncludePath);
            obj.validateRootPathKeys('SupportingSourceFiles', obj.SupportingSourceFiles);
            obj.validateRootPathKeys('OutputFolder', obj.OutputFolder);

            % Check if no C++ symbols to call because need definition
            if isempty(obj.Classes) && isempty(obj.Functions) && isempty(obj.Enumerations)
                error(message('MATLAB:CPP:NoConstructsCheckDefinition'));
            end

            for cls = obj.Classes
                cls.addToLibrary(obj.ClassesThatNeedArray);
            end
            for fcn = obj.Functions
                if(isvalid(fcn))
                    fcn.addToLibrary;
                end
            end
            for enum = obj.Enumerations
                enum.addToLibrary;
            end
            classArrayAnnotations = obj.LibraryInterface(1).Project(1).Compilations(1).Annotations(1).classArrays;
            classArrayAnnotations.clear;
            for clsArr = obj.ClassArrays
                classArrayAnnotations.add(clsArr);
            end
            fundamentalArrayAnnotations = obj.LibraryInterface(1).Project(1).Compilations(1).Annotations(1).fundamentalArrays;
            for fundamentalArr = obj.AddFundamentalArray
                fundamentalArrAnnotation = internal.mwAnnotation.FundamentalArray(obj.LibraryInterface.Model);
                fundamentalArrAnnotation.cppElemType = obj.getCppTypeForClibArrFundamentalType(fundamentalArr);
                fundamentalArrAnnotation.mlElemType = obj.getMlElemType(fundamentalArr);
                fundamentalArrAnnotation.name = fundamentalArr;
                fundamentalArrayAnnotations.add(fundamentalArrAnnotation);
            end

            opaqueTypeAnnotations = obj.LibraryInterface(1).Project(1).Compilations(1).Annotations.toArray.opaqueTypes;
            opaqueTypeAnnotations.clear;
            opaqueMATLABName= "";
            for opaqueType = obj.OpaqueTypes
                if (isempty(opaqueMATLABName))
                    opaqueMATLABName(1) = opaqueType.MATLABName;
                else
                    opaqueMATLABName(end+1) = opaqueType.MATLABName;
                end
            end

            %add only those opaque types that are used as output
            for opaqueTypeName = obj.OpaqueTypeNames
                if ~isempty(obj.OpaqueTypes) && ismember(opaqueTypeName , opaqueMATLABName)
                    idx = find(opaqueMATLABName == opaqueTypeName);
                    opaqueTypeAnnotations.add(obj.OpaqueTypes(idx-1).OpaqueTypeInterface);
                end
            end

            % compute all available functions to compute matching functions
            % for function types
            obj.computeAvailableFunctions;
            for fcnType = obj.FunctionTypes
                fcnType.addToLibrary;
            end

            % update fileOrPath info in the build info annotation
            buildInfoAnnotations = obj.LibraryInterface(1).Project(1).Compilations(1).Annotations(1);
            buildInfoAnnotations.headers.clear;
            for header = obj.HeaderFilesAbsolute
                buildInfoAnnotations.headers.add(header);
            end

            buildInfoAnnotations.includePaths.clear;
            for path = obj.IncludePathAbsolute
                buildInfoAnnotations.includePaths.add(path);
            end

            buildInfoAnnotations.libraries.clear;
            for lib = obj.LibrariesAbsolute
                buildInfoAnnotations.libraries.add(lib);
            end

            buildInfoAnnotations.sourceFiles.clear;
            for srcFile = obj.SupportingSourceFilesAbsolute
                buildInfoAnnotations.sourceFiles.add(srcFile);
            end
            buildInfoAnnotations.location = obj.OutputFolderAbsolute;

            % clear relative path info
            buildInfoAnnotations.headersRelative.clear;
            buildInfoAnnotations.includePathsRelative.clear;
            buildInfoAnnotations.librariesRelative.clear;
            buildInfoAnnotations.sourceFilesRelative.clear;
            buildInfoAnnotations.locationRelative = "";
            buildInfoAnnotations.rootpathKeys.clear;
            buildInfoAnnotations.rootpathValues.clear;
            defineBuildHelper = clibgen.internal.DefineBuildHelper(obj, obj.LibraryInterface);
            defineBuildHelper.build;
        end

        function summary(obj, option)
            % SUMMARY Display summary of C++ classes, functions, enums and function types that are
            %   included in the interface
            %   SUMMARY(OBJ,OPTION)
            %   Specify option "mapping" to display mappings of C++
            %   functionality to MATLAB.
            arguments
                obj clibgen.LibraryDefinition
                option string {mustBeTextScalar}=""
            end
            if(option=="")
                    % Show the MATLAB summary of all functions and classes
                    summaryStr = sprintf("\nMATLAB Interface to " + obj.PackageName + ....
                        " Library\n");

                    for cls = obj.Classes
                        summaryStr = sprintf(summaryStr + "\n" + cls.summary);
                    end
                    first = true;
                    if not (isempty(obj.Functions))
                        for fcn = obj.Functions
                            try
                                validate(fcn);
                                if(first)
                                    summaryStr = sprintf(summaryStr + "\nFunctions\n");
                                    first = false;
                                end
                                mlSignature = fcn.MATLABSignature;
                                for i= 1:numel(mlSignature)
                                    summaryStr = summaryStr + mlSignature{i} + newline ;
                                end
                                argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(fcn, obj.getFunction(fcn.CPPSignature));
                                if numel(argsFundamental) > 0
                                    summaryStr = summaryStr + clibgen.LibraryDefinition.formNotNullableNote("    ", argsFundamental);
                                end
                            catch
                                % Do nothing if an exception is thrown, move to the next function
                            end
                        end
                    end
                    first = true;
                    if not (isempty(obj.FunctionTypes))
                        for fcnType = obj.FunctionTypes
                            if(first)
                                summaryStr = sprintf(summaryStr + "\nFunction Types\n");
                                first = false;
                            end
                            summaryStr = sprintf(summaryStr + "  " + fcnType.MATLABName + "\n");
                        end
                    end
                    for en = obj.Enumerations
                        summaryStr = sprintf(summaryStr + "\n" + en.summary);
                    end
                    first = true;
                    if not (isempty(obj.OpaqueTypes))
                        for opaqueType = obj.OpaqueTypes
                            if(first)
                                summaryStr = sprintf(summaryStr + "\nOpaque Types\n");
                                first = false;
                            end
                            summaryStr = sprintf(summaryStr + "  " + opaqueType.MATLABName + "\n");
                        end
                    end
            elseif(option == "mapping")
                    validateattributes(option, {'char','string'},{'scalartext', 'nonempty'});
                    summaryStr = sprintf("\nMapping between C++ Library " + obj.PackageName + ....
                        " and MATLAB Interface\n");
                    for cls = obj.Classes
                        summaryStr = summaryStr + cls.summary('mapping');
                    end
                    first = true;
                    for fcn = obj.Functions
                        try
                            validate(fcn);
                            if(first)
                                summaryStr = sprintf(summaryStr + "\nFunctions\n");
                                first = false;
                            end
                            summaryStr = sprintf(summaryStr + "  C++:    " + fcn.CPPSignature + "\n");
                            summaryStr = sprintf(summaryStr + "  MATLAB: " + fcn.MATLABSignature + "\n");
                            argsFundamental = clibgen.MethodDefinition.getFundamentalInputPointers(fcn, obj.getFunction(fcn.CPPSignature));
                            if numel(argsFundamental) > 0
                                summaryStr = summaryStr + clibgen.LibraryDefinition.formNotNullableNote("    ", argsFundamental);
                            end
                        catch
                            % Do nothing if an exception is thrown, move on to the
                            % next function
                        end
                    end
                    first = true;
                    for fcnType = obj.FunctionTypes
                        if(first)
                            summaryStr = sprintf(summaryStr + "\nFunction Types\n");
                            first = false;
                        end
                        summaryStr = sprintf(summaryStr + "  C++:    " + fcnType.CPPSignature + "\n");
                    end
                    for en = obj.Enumerations
                        summaryStr = summaryStr + en.summary('mapping');
                    end
                    first = true;
                    for opaqueType = obj.OpaqueTypes
                        if(first)
                            summaryStr = sprintf(summaryStr + "\nOpaque Types\n");
                            first = false;
                        end
                        summaryStr = sprintf(summaryStr + "  C++:    " + opaqueType.CPPSignature + "\n");
                        summaryStr = sprintf(summaryStr + "  MATLAB: " + opaqueType.MATLABName + "\n");
                    end
            else
                error(message('MATLAB:CPP:InvalidOptionForSummary'));
            end
            disp(summaryStr);
        end
        function copyRuntimeDependencies(obj, options)
        %copyRuntimeDependencies Copy each run-time library specified in
        %obj.Libraries to the interface library folder.
        %
        %Run-time library dependencies include .dll files on Windows, .so
        %files on Linux, and .dylib files on MacOS.
        %
        %On Windows, for each import library(.lib) in obj.Libraries, a
        %dynamic link library(.dll) with the same name is copied if it exists.
        %
        %Call copyRuntimeDependencies after building the C++ interface library.
        %
        %   copyRuntimeDependencies(libdef, options)
        %
        %     Input Arguments
        %       libdef  A clibgen.LibraryDefinition for the library.
        %
        %     Options
        %       AdditionalRuntimeFolders
        %       A string vector of absolute paths to folders with additional
        %       run-time dependencies. All run-time dependencies from each
        %       run-time path is copied to the interface library folder.
        %
        %       AdditionalRuntimeDependencies
        %       A string vector of absolute pathnames to additional run-time
        %       dependencies to be copied to the interface library folder.
        %
        %       Verbose
        %       Specify true to display copy details.
        %       The default value is libdef.Verbose. If logical value is
        %       true, details of each library copied is displayed. If value
        %       is false, a brief success message is displayed.
        %
        %    Examples:
        %       % Copy libdef.Libraries to interface library folder
        %       libdef.copyRuntimeDependencies
        %        Run-time dependencies copied to interface library folder.
        %
        %       % Copy libdef.Libraries and AdditionalRuntimeFolders
        %       % to interface library folder with copy details in the
        %       % output
        %       libdef.copyRuntimeDependencies(AdditionalRuntimeFolders="C:\mylib\util\win64",Verbose=true)
        %        Copied 5 run-time library file(s) to 'C:\matlab\win64\mylib'
        %           C:\mylib\lib\win64\mylib.dll
        %           C:\mylib\util\win64\bar.dll
        %           C:\mylib\util\win64\foo.dll
        %           C:\mylib\util\win64\foo32.dll
        %           C:\mylib\util\win64\fubar.dll
        %        Run-time dependencies copied to interface library folder.
        %

            arguments
                obj clibgen.LibraryDefinition
                options.AdditionalRuntimeFolders (1,:) string = ""
                options.AdditionalRuntimeDependencies (1,:) string = ""
                options.Verbose (1,1) logical = obj.Verbose
            end
            platformExt = ".dll";
            if ismac
                platformExt = ".dylib";
            elseif isunix
                platformExt = ".so";
            end
            destPath = fullfile(obj.OutputFolderAbsolute,obj.PackageName);
            % Ensure that the interface library folder and file exist
            if ~isfolder(destPath)
                error(message('MATLAB:CPP:NoInterfaceLibraryFolder', destPath));
            else
                destFile = fullfile(destPath,obj.PackageName + "Interface" + platformExt);
                if ~isfile(destFile)
                    error(message('MATLAB:CPP:NoInterfaceLibraryFile', destFile));
                end
            end
            libraryDependencies = obj.LibrariesAbsolute;
            if options.AdditionalRuntimeDependencies ~= ""
                libraryDependencies = [libraryDependencies options.AdditionalRuntimeDependencies];
            end
            if options.AdditionalRuntimeFolders ~= ""
                % g3025151 - perform dir on each additional runtime path
                libraryFiles = [];
                for folderIdx = 1:numel(options.AdditionalRuntimeFolders)
                    dirPath = options.AdditionalRuntimeFolders(folderIdx);
                    files = dir(fullfile(dirPath,strcat('*',platformExt)));
                    fileNames = convertCharsToStrings({files.name});
                    libraryFiles = [libraryFiles fullfile(dirPath, fileNames)];
                end
                libraryFiles = string(libraryFiles);
                libraryDependencies = [libraryDependencies libraryFiles];
            end
            if ispc
                % On Windows, use .dll for .lib
                libraryDependencies = strrep(libraryDependencies, '.lib', '.dll');
            end
            libraryDependencies = unique(libraryDependencies,'stable');
            % Remove invalid dependent libraries
            idxRemove = ~isfile(libraryDependencies);
            libraryDependencies(idxRemove) = [];
            % Copy dependent libraries into the interface library folder
            arrayfun(@(lib) copyfile(lib,destPath,"f"), libraryDependencies);
            if options.Verbose
                numLibrariesCopied = length(libraryDependencies);
                fileNames = libraryDependencies;
                fileNames = strjoin(fileNames,'\n    ');
                disp(getString(message('MATLAB:CPP:CopyRuntimeDependencies', ...
                    numLibrariesCopied,destPath,fileNames)));
            end
            disp(getString(message('MATLAB:CPP:CopyRuntimeDependenciesBrief')));
        end
    end
    methods
        function compilerFlags = get.AdditionalCompilerFlags(obj)
            compilerFlags = horzcat(obj.additionalCompilerFlagsPassedtoParser, obj.AdditionalCompilerFlags);

        end
        function set.InterfaceName(obj, v)
            obj.PackageName = v;
        end
        function v = get.InterfaceName(obj)
            v = obj.PackageName;
        end
    end
end
