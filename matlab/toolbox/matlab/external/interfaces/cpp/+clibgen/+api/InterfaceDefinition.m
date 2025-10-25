 classdef (Sealed) InterfaceDefinition < handle & matlab.mixin.CustomDisplay
    %

    %  Copyright 2024 The MathWorks, Inc.
    properties(SetAccess=private)
        InterfaceName                           string
        Enums                                   clibgen.api.EnumDefinition
        UnsupportedClasses                      clibgen.api.UnsupportedClass
        UnsupportedFunctions                    clibgen.api.UnsupportedFunction
        UnsupportedEnums                        clibgen.api.UnsupportedEnum
        ParserErrors                            table
        ParserWarnings                          table
        OutputFolder                            string
    end
    properties(GetAccess=public, SetAccess=?clibgen.api.ClassDefinition)
        UnsupportedMethods                      clibgen.api.UnsupportedMethod
        UnsupportedProperties                   clibgen.api.UnsupportedProperty
    end

    properties(SetAccess=private, Dependent)
        Classes                                 clibgen.api.ClassDefinition
        Functions                               clibgen.api.FunctionDefinition
        IncompleteClasses                       clibgen.api.ClassDefinition
        IncompleteFunctions                     clibgen.api.FunctionDefinition
    end

    properties(Dependent)
        Libraries                               string
        SourceFiles                             string
        CLinkage                                (1,1)   logical
    end

    properties(Access=public)
        DisplayOutput                           (1,1)   logical
        AdditionalLinkerFlags                   string
    end

    properties(Access=private)
        HeaderFiles                             string
        TreatObjectPointerAsScalar              logical
        TreatConstCharPointerAsCString          logical
        GenerateDocumentationFromHeaderFiles    logical
        ReturnCArrays                           logical
        CppLibraries                            string
        CppSourceFiles                          string
        CLinkageFlag                            (1,1) logical
    end

    properties(Access=private)
        AllClasses                              clibgen.api.ClassDefinition
        AllFunctions                            clibgen.api.FunctionDefinition
        TypeUsages                              containers.Map
        ClassesMap                              containers.Map
        FunctionsMap                            containers.Map
        FunctionNames                           string
        ClassNames                              string
        EnunNames                               string
    end

    properties(Access={?clibgen.internal.ApiBuildHelper})
        IncludePath                             string
        DefinedMacros                           string
        UndefinedMacros                         string
        AdditionalCompilerFlags                 string
        Ast                                     internal.cxxfe.ast.Ast
    end

    methods(Access={?clibgen.api.ConstructorDefinition, ...
            ?clibgen.api.FunctionDefinition, ?clibgen.api.MethodDefinition, ...
            ?clibgen.api.CallableDefinition, ?clibgen.api.PropertyDefinition})
        % typeInUse is fully qualified C++ name of the simple type
        function addTypeUsage(obj, defObj, typeInUse)
            if obj.TypeUsages.isKey(typeInUse)
                val = obj.TypeUsages(typeInUse);
                val{end+1} = defObj;
                obj.TypeUsages(typeInUse) = val;
            else
                obj.TypeUsages(typeInUse) = {defObj};
            end
        end 

        function val = isTypeIncluded(obj, typeInUse)
            % Todo: update this to add opaque, function types
            if isempty(obj.AllClasses)
                clses_idx = [];
            else
                clses_idx = find([obj.AllClasses.CPPName] == typeInUse);
            end
            if isempty(obj.Enums)
                enums_idx = [];
            else
                enums_idx = find([obj.Enums.CPPName] == typeInUse);
            end
            if ~isempty(clses_idx)
                val = obj.AllClasses(clses_idx).Included;
            elseif ~isempty(enums_idx)
                val = obj.Enums(enums_idx).Included;
            else
                val = false;
            end
        end
    end

    methods(Access={?clibgen.api.ClassDefinition, ?clibgen.api.EnumDefinition})
        function excludeTypeUsage(obj, typeInUse)
            if obj.TypeUsages.isKey(typeInUse)
                cellfun(@(def) def.exclude, obj.TypeUsages(typeInUse));
            end
        end

        function updateMATLABNameInTypeUsage(obj, typeInUse, MATLABName)
            if obj.TypeUsages.isKey(typeInUse)
                cellfun(@(def) def.updateMATLABNameInTypeUsage(typeInUse, MATLABName), ...
                    obj.TypeUsages(typeInUse));
            end
        end
    end

    methods(Access={?clibgen.api.ClassDefinition, ?clibgen.api.FunctionDefinition, ...
            ?clibgen.api.EnumDefinition, ?clibgen.api.FunctionTypeDefinition, ...
            ?clibgen.api.OpaqueTypeDefinition})
        function res = isMATLABNameInUse(obj, MATLABName)
            arguments
                obj
                MATLABName (1,1) string
            end
            symsUseMATLABName = @(syms, mlName) (~isempty(obj.(syms)) && ...
                any([obj.(syms).MATLABName] == mlName));
            % Todo: update this to add opaque, function types
            res = symsUseMATLABName('AllClasses', MATLABName) || ...
                symsUseMATLABName('AllFunctions', MATLABName) || ...
                symsUseMATLABName('Enums', MATLABName);
        end
    end

    methods(Access=private)
        function strArray = constructStringArrayFromDefinedMacros(~, definedMacros)
            keys = definedMacros.keys();
            strArray = strings(1, numel(keys));

            % Iterate over each key to create "<key>=<value>" strings
            for i = 1:numel(keys)
                key = keys{i};
                value = char(definedMacros(key));
                strArray(i) = sprintf('%s=%s', key, value);
            end
        end

        function parseEnv = parseHeaders(obj)
            compilerConfig = mex.getCompilerConfigurations('C++', 'Selected');
            if isempty(compilerConfig)
                if matlab.internal.display.isHot
                    error(message("MATLAB:mex:NoCompilerFound_link"));
                else
                    error(message("MATLAB:mex:NoCompilerFound"));
                end
            end
            % Todo: fix passing macros
            feOpts = clibgen.internal.getFrontEndOptions(obj.HeaderFiles, ...
                        obj.IncludePath,'', ...
                        '',compilerConfig.Details.CompilerFlags, ...
                        obj.AdditionalCompilerFlags);
            parseEnv = internal.cxxfe.il2ast.Env(feOpts);
            cvtOpts = internal.cxxfe.il2ast.Options();
            cvtOpts.BindComments = obj.GenerateDocumentationFromHeaderFiles;
            cvtOpts.SkipTypeAttributes = true;
            cvtOpts.RemoveDupStaticFuns = true;
            cvtOpts.ConvertInitialization = true;
            parseEnv.parseFile(obj.HeaderFiles(1), cvtOpts);
        end

        function res = constructParserMessagesTable(~, messages)
            filePaths = arrayfun(@(x) string(x.file), messages);
            [~, fileNames, exts] = arrayfun(@(filePath) fileparts(filePath), filePaths, 'UniformOutput', false);
            fileNames = strcat(string(fileNames), string(exts));
            lineNums = arrayfun(@(x) string(x.line), messages);
            errorMsgs = arrayfun(@(x) string(x.desc), messages);

            if matlab.internal.display.isHot()
                matlab_fcn = "matlab.desktop.editor.openAndGoToLine";
                hyperlinkedPaths = arrayfun(@(filePath, lineNum, fileName) ...
                    sprintf('<a href="matlab: %s(''%s'',str2num(''%s''));">%s:%s</a>', ...
                    matlab_fcn, filePath, lineNum, fileName, lineNum), filePaths, ...
                    lineNums, fileNames, 'UniformOutput', false);
                paths = string(hyperlinkedPaths);
            else
                nonHyperLinkedPaths = arrayfun(@(filePath, lineNum) sprintf('%s:%s', filePath, lineNum), ...
                    filePaths, lineNums, 'UniformOutput', false);
                paths = string(nonHyperLinkedPaths);
            end
            res = table(paths, errorMsgs, 'VariableNames', {'FilePath', 'Message'});
        end

        function addEntryToFunctionsMap(obj, fcnDef)
            cppName = fcnDef.CPPName;
            % Todo: replace parameterTypes with data from fcnDef
            % parameterTypes = strings(1,0);
            % pair = {parameterTypes, fcnDef};
            if obj.FunctionsMap.isKey(cppName)
                val = obj.FunctionsMap(cppName);
                val{end+1} = fcnDef; % Todo: replace fcnDef with pair
                obj.FunctionsMap(cppName) = val;
            else
                 % Todo: replace fcnDef with pair
                obj.FunctionsMap(cppName) = {fcnDef};
            end
        end
        function collectSymbolsNames(obj, scope)
            arguments
                obj,
                scope {mustBeA(scope, ["internal.cxxfe.ast.source.CompilationUnit", "internal.cxxfe.ast.Scope"])}
            end
            for t = scope.Types.toArray
                if isFromSystemHeader(t)
                    continue
                end
                if t.isStructType
                    if isempty(t.DefPos)
                        continue;
                    end
                    obj.ClassNames(end+1) = t.getFullyQualifiedName;
                    if numel(t.Scope)~=0
                        obj.collectSymbolsNames(t.Scope);
                    end
                elseif t.isEnumType
                    obj.EnunNames(end+1) = t.getFullyQualifiedName;
                end
            end
            for func = scope.Funs.toArray
                if func.IsDeleted || func.IsVariadic || isempty(func.DefPos)
                    continue
                end
                obj.FunctionNames(end+1) = func.getFullyQualifiedName;
            end
            for namespace = scope.Namespaces.toArray
                if namespace.Name == "std" || isempty(namespace.Name)
                    continue;
                end
                obj.collectSymbolsNames(namespace);
            end
        end
        function constructSymbolDefinitions(obj, scope)
            arguments
                obj
                scope   {mustBeA(scope, ["internal.cxxfe.ast.source.CompilationUnit", "internal.cxxfe.ast.Scope"])}
            end

            % iterate thru types
            for t = scope.Types.toArray
                if isFromSystemHeader(t)
                    continue;
                end
                if isempty(t.Annotations)
                    continue;
                end
                if t.isStructType
                    clsAnnot = t.Annotations(1);
                    defStatus = clsAnnot.integrationStatus.definitionStatus;
                    if defStatus == "FullySpecified" || defStatus == "PartiallySpecified"
                        clsDef = clibgen.api.ClassDefinition(t, obj);
                        obj.AllClasses(end+1) = clsDef;
                        obj.ClassesMap(clsDef.CPPName) = clsDef;
                    elseif defStatus == "Unsupported"
                        uannot = t.Annotations(2);
                        if uannot.symbolKind ~= "SymbolNotReported"
                            obj.UnsupportedClasses(end+1) = clibgen.api.UnsupportedClass(...
                                uannot.fileName,...
                                uannot.filePath,...
                                uannot.line,...
                                uannot.reason, ...
                                uannot.cppName ...
                                );
                        end
                        t.Annotations.removeAt(2);
                    end
                    % visit class scope
                    if ~isempty(t.Scope) && ~isempty(t.Scope.Annotations)
                        clsScopeAnnot = t.Scope.Annotations(1);
                        defStatus = clsScopeAnnot.integrationStatus.definitionStatus;
                        if defStatus == "FullySpecified" || defStatus == "PartiallySpecified"
                            constructSymbolDefinitions(obj, t.Scope);
                        end
                    end
                elseif t.isEnumType
                    % create enum or unsupported enum
                    enumAnnot = t.Annotations(1);
                    defStatus = enumAnnot.integrationStatus.definitionStatus;
                    if defStatus == "FullySpecified" || defStatus == "PartiallySpecified"
                        obj.Enums(end+1) = clibgen.api.EnumDefinition(t, obj);
                    elseif defStatus == "Unsupported"
                        if uannot.symbolKind ~= "SymbolNotReported"
                            obj.UnsupportedEnums(end+1) = clibgen.api.UnsupportedEnum(...
                                                                      uannot.fileName,...
                                                                      uannot.filePath,...
                                                                      uannot.line,...
                                                                      uannot.reason,...
                                                                      uannot.cppSignature,...
                                                                      uannot.cppName);
                        end
                        t.Annotations.removeAt(2);
                    end
                end
            end

            % iterate thru funs to create functions
            for fcn = scope.Funs.toArray
                if isempty(fcn.Annotations)
                    continue;
                end
                fcnAnnot = fcn.Annotations(1);
                defStatus = fcnAnnot.integrationStatus.definitionStatus;
                if defStatus == "FullySpecified" || defStatus == "PartiallySpecified"
                    fcnDef = clibgen.api.FunctionDefinition(fcn, obj);
                    obj.AllFunctions(end+1) = fcnDef;
                    obj.addEntryToFunctionsMap(fcnDef);
                elseif defStatus == "Unsupported"
                    % Create clibgen.api.UnsupportedFunction
                    uannot = fcn.Annotations(2);
                    if uannot.symbolKind ~= "SymbolNotReported"
                    obj.UnsupportedFunctions(end+1) = clibgen.api.UnsupportedFunction(...
                        uannot.fileName,...
                        uannot.filePath,...
                        uannot.line,...
                        uannot.reason, ...
                        uannot.cppSignature,...
                        uannot.cppName ...
                        );
                    end
                    fcn.Annotations.removeAt(2);
                end
            end
            % iterate through namepsaces
            for ns = scope.Namespaces.toArray
                if ns.Name == "std"
                    continue;
                end
                if isempty(ns.Annotations)
                    continue;
                end
                nsAnnot = ns.Annotations(1);
                defStatus = nsAnnot.integrationStatus.definitionStatus;
                if defStatus == "FullySpecified" || defStatus == "PartiallySpecified"
                    constructSymbolDefinitions(obj, ns);
                end
            end
        end

        function props = makePropertiesBoolean(~, props, name)
            % Use a categorical to show booleans as "true"/"false" without quotes
            if isfield(props.PropertyList, name)
                val = props.PropertyList.(name);
                props.PropertyList.(name) = categorical(val, [false, true], {'false', 'true'});
            end
        end

        function g = makeGroup(obj, name, props)
            % Helper to create a property display group and adjust formatting as
            % required.

            g = matlab.mixin.util.PropertyGroup(props,name);
            % Convert the property name list into a struct.
            c = cellfun(@(x) obj.(x), g.PropertyList, "UniformOutput", false);
            s = cell2struct(c, g.PropertyList, 2);
            g.PropertyList = s;
            g = makePropertiesBoolean(obj, g, "CLinkage");
            g = makePropertiesBoolean(obj, g, "DisplayOutput");
        end

        function displayall(obj)
            grpName = "";
            grpList = ["InterfaceName", "Classes", "Functions", "Enums", ...
                 "IncompleteClasses", "IncompleteFunctions", "UnsupportedClasses", ...
                 "UnsupportedFunctions", "UnsupportedEnums", "UnsupportedMethods", ...
                 "UnsupportedProperties", "ParserErrors", "ParserWarnings", ...
                 "OutputFolder", "Libraries", "SourceFiles", "DisplayOutput", ...
                 "AdditionalLinkerFlags", "CLinkage"];
            grp = obj.makeGroup(grpName, grpList);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, grp);
        end

        function res = isBuildable(obj)
            if ~isempty(obj.ParserErrors)
                res = false; % not buildable if there are parser errors
            else
                symsInInterface = @(syms) (~isempty(obj.(syms)) && ...
                any([obj.(syms).Included]));

                isExistSymbolInInterface = symsInInterface('AllClasses') || ...
                    symsInInterface('AllFunctions') || symsInInterface('Enums');
                if isExistSymbolInInterface
                    res = true; % buildable if there are symbols in interface
                else
                    res = false;
                end
            end
        end

        function updateBuildInfoAnnotation(obj)
            buildInfoAnnotation = obj.Ast.Project.Compilations.at(1).Annotations.toArray;
            buildInfoAnnotation.headers.clear;
            for header = obj.HeaderFiles
                buildInfoAnnotation.headers.add(header);
            end
            buildInfoAnnotation.includePaths.clear;
            for includePath = obj.IncludePath
                buildInfoAnnotation.includePaths.add(includePath);
            end
            buildInfoAnnotation.libraries.clear;
            for library = obj.CppLibraries
                buildInfoAnnotation.libraries.add(library);
            end
            buildInfoAnnotation.sourceFiles.clear;
            for srcFile = obj.SourceFiles
                buildInfoAnnotation.sourceFiles.add(srcFile);
            end
            buildInfoAnnotation.location = obj.OutputFolder;
            buildInfoAnnotation.definedMacros.clear;
            for defMacro = obj.DefinedMacros
                buildInfoAnnotation.definedMacros.add(defMacro);
            end
            buildInfoAnnotation.undefinedMacros.clear;
            for undefMacro = obj.UndefinedMacros
                buildInfoAnnotation.undefinedMacros.add(undefMacro);
            end
            buildInfoAnnotation.additionalCompilerFlags.clear;
            for compFlag = obj.AdditionalCompilerFlags
                buildInfoAnnotation.additionalCompilerFlags.add(compFlag);
            end
            buildInfoAnnotation.additionalLinkerFlags.clear;
            for linkFlag = obj.AdditionalLinkerFlags
                buildInfoAnnotation.additionalLinkerFlags.add(linkFlag);
            end
        end
    end

    methods(Access=protected)
        function header = getHeader(obj)
            if obj.isBuildable
                state = 'Buildable';
            else
                state = 'Unbuildable';
            end
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            header = sprintf('  %s %s with properties:\n', state, className);
        end

        function propGroups = getPropertyGroups(obj)
            if ~isempty(obj.ParserErrors) || ~isempty(obj.ParserWarnings)
                errorGroupHeading = "";
                errorGroupList = ["ParserErrors", "ParserWarnings"];
                propGroups = matlab.mixin.util.PropertyGroup(errorGroupList, errorGroupHeading);
            else
                symbolGroupHeading = "";
                symbolGroupList = ["Classes", "Functions", "Enums"];
                symbolGroup = matlab.mixin.util.PropertyGroup(symbolGroupList, symbolGroupHeading);

                buildInfoGroupHeading = "";
                buildInfoGroupList = ["InterfaceName", "Libraries", "SourceFiles"];
                buildInfoGroup = matlab.mixin.util.PropertyGroup(buildInfoGroupList, buildInfoGroupHeading);

                incompleteGroupHeading = "";
                incompleteGroupList = ["IncompleteClasses" "IncompleteFunctions"];
                incompleteGroup = matlab.mixin.util.PropertyGroup(incompleteGroupList, incompleteGroupHeading);

                unsupportedGroupHeading = "";
                unsupportedGroupList = ["UnsupportedClasses" "UnsupportedFunctions"];
                unsupportedGroup = matlab.mixin.util.PropertyGroup(unsupportedGroupList, unsupportedGroupHeading);
                propGroups = [symbolGroup, buildInfoGroup, incompleteGroup, unsupportedGroup];
            end
        end

        function footer = getFooter(obj)
            % We only show a footer if a scalar object and the default display is
            % compact (hyperlinks are enabled).
            if ~isscalar(obj) || ~matlab.internal.display.isHot()
                footer = '';
                return;
            end

            % We encode to avoid special characters (newlines, quotes, etc.)
            % that would upset the href line.
            txt = urlencode(evalc("displayall(obj)"));

            % Bake the full display into a hyperlink in the footer.
            footer = ['  ' getString(message("MATLAB:CPP:ShowAllInterfaceDefProperties", txt)) newline];
        end
    end

    methods(Access=public)
        function obj = InterfaceDefinition(libcfg)
            arguments
                libcfg (1,1) clibgen.api.LibraryConfiguration
            end
            if matlab.internal.feature('ScriptingWorkflows')==0
                % Todo: Add error msg id from message catalog
                error("Scripting Workflows is not supported");
            end
            libcfg.validate;
            obj.HeaderFiles = libcfg.HeaderFiles;
            obj.IncludePath = libcfg.IncludePath;
            obj.DefinedMacros = obj.constructStringArrayFromDefinedMacros(libcfg.DefinedMacros);
            obj.UndefinedMacros = libcfg.UndefinedMacros;
            obj.AdditionalCompilerFlags = libcfg.AdditionalCompilerFlags;
            obj.InterfaceName = libcfg.InterfaceName;
            obj.TreatObjectPointerAsScalar = libcfg.TreatObjectPointerAsScalar;
            obj.TreatConstCharPointerAsCString = libcfg.TreatConstCharPointerAsCString;
            obj.GenerateDocumentationFromHeaderFiles = libcfg.GenerateDocumentationFromHeaderFiles;
            % Todo: update ReturnCArrays with the new name from the spec
            % obj.ReturnCArrays = libcfg.ReturnCArrays;
            obj.ReturnCArrays = false;
            obj.OutputFolder = libcfg.OutputFolder;
            % initialize properties to empty
            obj.AllClasses             = clibgen.api.ClassDefinition.empty(1,0);
            obj.AllFunctions           = clibgen.api.FunctionDefinition.empty(1,0);
            obj.Enums                  = clibgen.api.EnumDefinition.empty(1,0);

            obj.UnsupportedClasses  = clibgen.api.UnsupportedClass.empty(1,0);
            obj.UnsupportedFunctions= clibgen.api.UnsupportedFunction.empty(1,0);
            obj.UnsupportedEnums    = clibgen.api.UnsupportedEnum.empty(1,0);
            obj.UnsupportedMethods  = clibgen.api.UnsupportedMethod.empty(1,0);
            obj.UnsupportedProperties = clibgen.api.UnsupportedProperty.empty(1,0);

            obj.TypeUsages = containers.Map('KeyType','char','ValueType','any');
            obj.ClassesMap = containers.Map('KeyType','char','ValueType','any');
            obj.FunctionsMap = containers.Map('KeyType','char','ValueType','any');
            try
                parseEnv = obj.parseHeaders;
                if isempty(parseEnv.Ast.Project.Compilations.toArray)
                    messages = parseEnv.getMessages;
                    isError = strcmp({messages.kind}, 'error');
                    isWarning = strcmp({messages.kind}, 'warning');

                    % Separate struct arrays
                    errors = messages(isError);
                    warnings = messages(isWarning);
                    if ~isempty(errors)
                        obj.ParserErrors = obj.constructParserMessagesTable(errors);
                    end
                    if ~isempty(warnings)
                        obj.ParserWarnings = obj.constructParserMessagesTable(warnings);
                    end
                else
                    obj.Ast = parseEnv.Ast;
                    % Todo: add creating buildInfo after apiHandler code is added
                    % buildInfoAnnotation = internal.mwAnnotation.AbsolutePathBuildInfo(obj.Ast.Model);
                    % metadataInfo = obj.Ast.Project.Compilations.at(1).Annotations;
                    % metadataInfo.add(buildInfoAnnotation);
                    compUnit = obj.Ast.Project.Compilations(1);
                    obj.collectSymbolsNames(compUnit);
                    inputObj.InterfaceName = obj.InterfaceName;
                    inputObj.TreatObjectPointerAsScalar = obj.TreatObjectPointerAsScalar;
                    inputObj.TreatConstCharPointerAsCString = obj.TreatConstCharPointerAsCString;
                    inputObj.ReturnCArrays = obj.ReturnCArrays;
                    inputObj.OutputFolder = obj.OutputFolder;
                    if ~isempty(libcfg.IncludedClasses)
                        inputObj.IncludedClasses = obj.ClassNames(matches(obj.ClassNames, libcfg.IncludedClasses));
                    else
                        inputObj.IncludedClasses = "<IncludeAllClasses>";
                    end
                    if ~isempty(libcfg.IncludedFunctions)
                        inputObj.IncludedFunctions = obj.FunctionNames(matches(obj.FunctionNames, libcfg.IncludedFunctions));
                    else
                        inputObj.IncludedFunctions = "<IncludeAllFunctions>";
                    end
                    if ~isempty(libcfg.IncludedEnumerations)
                        inputObj.IncludedEnumerations = obj.EnunNames(matches(obj.EnunNames, libcfg.IncludedEnumerations));
                    else
                        inputObj.IncludedEnumerations = "<IncludeAllEnums>";
                    end
                    clibgen.internal.apigenerate(inputObj,obj.Ast);

                    % iterate thru AST to create class, enum, functions,
                    % etc.,
                    compUnit = obj.Ast.Project.Compilations(1);
                    constructSymbolDefinitions(obj, compUnit);
                end
            catch ME
                throwAsCaller(ME);
            end
        end

        function build(obj)
            if ~isempty(obj.ParserErrors)
                % Todo: add error message that library cannot build and
                % show Parser errors property
                parser_errors_cmd = '<a href="matlab: obj.ParserErrors">ParserErrors</a>';
                error(['Interface Definition for ''' char(obj.InterfaceName) ''' is not buildable. See ' parser_errors_cmd '.']);
            end
            if ~obj.isBuildable
                % Todo: add error message that library cannot build as
                % there are no symbols in interface
                error(['Interface Definition for ''' char(obj.InterfaceName) ''' is not buildable. No symbols are in interface.']);
            end

            headerFiles = cellstr(convertStringsToChars(obj.HeaderFiles));
            clibgen.internal.checkCLinkage(headerFiles,obj.SourceFiles,obj.CLinkageFlag);

            obj.updateBuildInfoAnnotation;
            apiBuildHelper = clibgen.internal.ApiBuildHelper(obj);
            apiBuildHelper.build;
        end

        function res = findFunction(obj, CPPName, varargin)
            % Todo:
            % validate CPPName, varargin is 2, CPPParameters and string arr
            % find def obj from obj.FunctionsMap
           if isKey(obj.FunctionsMap, CPPName)
                res = obj.FunctionsMap(CPPName);
                res = [res{:}];
            else
                res = clibgen.api.FunctionDefinition.empty(1, 0);
            end
        end

        function res = findClass(obj, CPPName)
            arguments
                obj
                CPPName (1,1) string
            end
            if isKey(obj.ClassesMap, CPPName)
                res = obj.ClassesMap(CPPName);
            else
                res = clibgen.api.ClassDefinition.empty(1, 0);
            end
        end

        function res = findEnum(obj, CPPName)
            arguments
                obj
                CPPName (1,1) string
            end
            if isempty(obj.Enums)
                idx = [];
            else
                idx = find([obj.Enums.CPPName] == CPPName);
            end
            if isempty(idx)
                res = clibgen.api.EnumDefinition.empty(1, 0);
            else
                res = obj.Enums(idx);
            end
        end

        function delete(obj)
            delete(obj.ClassesMap);
            delete(obj.FunctionsMap);
            delete(obj.TypeUsages);

            arrayfun(@(x) delete(x), obj.UnsupportedClasses);
            arrayfun(@(x) delete(x), obj.UnsupportedFunctions);
            arrayfun(@(x) delete(x), obj.UnsupportedEnums);
            arrayfun(@(x) delete(x), obj.UnsupportedMethods);
            arrayfun(@(x) delete(x), obj.UnsupportedProperties);

            arrayfun(@(x) delete(x), obj.AllClasses);
            arrayfun(@(x) delete(x), obj.AllFunctions);
            arrayfun(@(x) delete(x), obj.Enums);
        end
    end

    methods
        function res = get.Classes(obj)
            if isempty(obj.AllClasses)
                res = obj.AllClasses;
                return;
            end
            idx = find([obj.AllClasses.HasIncompleteMembers] == false);
            res = obj.AllClasses(idx);
        end

        function res = get.Functions(obj)
            if isempty(obj.AllFunctions)
                res = obj.AllFunctions;
                return;
            end
            idx = find([obj.AllFunctions.Status] == "Complete");
            res = obj.AllFunctions(idx);
        end

        function res = get.IncompleteClasses(obj)
            if isempty(obj.AllClasses)
                res = obj.AllClasses;
                return;
            end
            idx = find([obj.AllClasses.HasIncompleteMembers]);
            res = obj.AllClasses(idx);
        end

        function res = get.IncompleteFunctions(obj)
            if isempty(obj.AllFunctions)
                res = obj.AllFunctions;
                return;
            end
            idx = find([obj.AllFunctions.Status] == "Incomplete");
            res = obj.AllFunctions(idx);
        end

        function set.Libraries(obj, libraries)
            arguments
                obj
                libraries {clibgen.internal.mustBeStringOrCharOrCell}
            end
            libraries = string(libraries);
            clibgen.internal.validateLibName(libraries);
            for idx=1:numel(libraries)
                [status, value] = fileattrib(libraries(idx));
                if status
                   libraries(idx) = value.Name;
                end
            end
            if ispc
                % Setup lib / dll compiled libraries
                compilerConfig = mex.getCompilerConfigurations('C++', 'Selected');
                headerFiles = cellstr(convertStringsToChars(obj.HeaderFiles));
                libraries = cellstr(convertStringsToChars(libraries));
                libraries = clibgen.internal.setupLibDll(libraries, headerFiles, compilerConfig.Manufacturer);
                libraries = string(libraries);
            end
            obj.CppLibraries = libraries;
        end

        function libraries = get.Libraries(obj)
            if isempty(obj.CppLibraries)
                libraries = strings(1,0);
            else
                libraries = obj.CppLibraries;
            end
        end

        function set.SourceFiles(obj, srcFiles)
            arguments
                obj
                srcFiles {clibgen.internal.mustBeStringOrCharOrCell}
            end
            srcFiles = string(srcFiles);
            clibgen.internal.validateSourceFile(srcFiles);
            headerFiles = cellstr(convertStringsToChars(obj.HeaderFiles));
            clibgen.internal.checkSourceFiles(headerFiles,srcFiles);
            obj.CppSourceFiles = strings(1, numel(srcFiles));
            for idx=1:numel(srcFiles)
                [status, value] = fileattrib(srcFiles(idx));
                if status
                   obj.CppSourceFiles(idx) = value.Name;
                end
            end
        end

        function srcFiles = get.SourceFiles(obj)
            if isempty(obj.CppSourceFiles)
                srcFiles = strings(1,0);
            else
                srcFiles = obj.CppSourceFiles;
            end
        end

        function set.AdditionalLinkerFlags(obj, linkerFlags)
            arguments
                obj
                linkerFlags {clibgen.internal.mustBeStringOrCharOrCell}
            end
            linkerFlags = string(linkerFlags);
            obj.AdditionalLinkerFlags = linkerFlags;
        end

        function linkerFlags = get.AdditionalLinkerFlags(obj)
            if isempty(obj.AdditionalLinkerFlags)
                linkerFlags = strings(1,0);
            else
                linkerFlags = obj.AdditionalLinkerFlags;
            end
        end

        function set.CLinkage(obj, val)
            arguments
                obj
                val logical
            end
            headerFiles = cellstr(convertStringsToChars(obj.HeaderFiles));
            clibgen.internal.checkCLinkage(headerFiles,obj.SourceFiles,val);
            obj.CLinkageFlag = val;
        end

        function val = get.CLinkage(obj)
            val = obj.CLinkageFlag;
        end
    end

end

function value = isFromSystemHeader(type)
value = false;
if ~isempty(type.DefPos)
    value = type.DefPos.File.IsIncludedFromSystemIncludeDir;
elseif ~isempty(type.DeclPos.toArray)
    for ii=1:numel(type.DeclPos)
        if type.DeclPos(ii).File.IsIncludedFromSystemIncludeDir
            value = true;
            return;
        end
    end
end
end