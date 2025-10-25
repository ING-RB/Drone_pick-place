classdef LibraryConfiguration < handle & matlab.mixin.SetGet & matlab.mixin.CustomDisplay
% LibraryConfiguration Configurations required to build a C++ interface
% library
%

%   Copyright 2024 The MathWorks, Inc.
    properties(Access=public)
        HeaderFiles
        IncludePath
        IncludedFunctions
        IncludedClasses
        IncludedEnumerations
        AdditionalCompilerFlags
        UndefinedMacros
        DefinedMacros                  dictionary=configureDictionary("string","string")
        FunctionNames                  dictionary = configureDictionary("string","string")
        FunctionTypeNames              dictionary = configureDictionary("string","string")
        ClassNames                     dictionary = configureDictionary("string","string")
        ClassMethodNames               dictionary = configureDictionary("string","string")
        EnumerationNames               dictionary = configureDictionary("string","string")
        OpaqueTypeNames                dictionary = configureDictionary("string","string")
        InvalidNamePerfix              string = "x"
        InvalidNameReplacementStyle    string {mustBeMember(InvalidNameReplacementStyle,["underscore","delete","hex"])} = "underscore"
        UseMATLABDataTypes             logical = false
        TreatObjectPointerAsScalar     logical = false
        TreatConstCharPointerAsCString logical = false
        GenerateDocumentationFromHeaderFiles (1,1) logical = true

    end

    properties(Dependent)
        InterfaceName string
        OutputFolder string
    end
    properties(Access = private)
        CppInterfaceName (1,1) string = ""
        CppOutputFolder  (1,1) string = pwd
    end

    methods
        function obj = LibraryConfiguration(varargin)
            if matlab.internal.feature('ScriptingWorkflows')~=1
                % TODO Add error IDs and messages to message catalogue
                error("Scripting Workflows is not supported");
            end
            narginchk(0,1);
            if(nargin == 0)
                interfaceName = "";
            else
                interfaceName = string(varargin{1});
                clibgen.internal.validateInterfaceName(interfaceName);
            end
            % Check for installed supported C++ compiler
            compilerConfig = mex.getCompilerConfigurations('C++', 'Selected');
            if isempty(compilerConfig)
                if matlab.internal.display.isHot
                    error(message("MATLAB:mex:NoCompilerFound_link"));
                else
                    error(message("MATLAB:mex:NoCompilerFound"));
                end
            elseif(ispc && contains(compilerConfig.ShortName, 'MinGW64SDK'))
                error(message('MATLAB:CPP:UnsupportedCompiler', obj.compilerConfig.Name));
            end
            obj.CppInterfaceName = interfaceName;
        end
        function interfaceName = get.InterfaceName(obj)
            interfaceName = obj.CppInterfaceName;
        end
        function outputfolder = get.OutputFolder(obj)
            outputfolder = obj.CppOutputFolder;
        end
        function headerfiles = get.HeaderFiles(obj)
            if(isempty(obj.HeaderFiles))
                headerfiles = strings(1,0);
            else
                headerfiles = obj.HeaderFiles;
            end
        end
        function includePaths = get.IncludePath(obj)
            if(isempty(obj.IncludePath))
                includePaths = strings(1,0);
            else
                includePaths = obj.IncludePath;
            end
        end
        function functions = get.IncludedFunctions(obj)
            if(isempty(obj.IncludedFunctions))
                functions = pattern.empty();
            else
                functions = obj.IncludedFunctions;
            end
        end
        function classes = get.IncludedClasses(obj)
            if(isempty(obj.IncludedClasses))
                classes = pattern.empty();
            else
                classes = obj.IncludedClasses;
            end
        end
        function enums = get.IncludedEnumerations(obj)
            if(isempty(obj.IncludedEnumerations))
                enums = pattern.empty();
            else
                enums = obj.IncludedEnumerations;
            end
        end
        function compilerFlags = get.AdditionalCompilerFlags(obj)
            if(isempty(obj.AdditionalCompilerFlags))
                compilerFlags = strings(1,0);
            else
                compilerFlags = obj.AdditionalCompilerFlags;
            end
        end
        function macros = get.UndefinedMacros(obj)
            if(isempty(obj.UndefinedMacros))
                macros = strings(1,0);
            else
                macros = obj.UndefinedMacros;
            end
        end
        function set.InterfaceName(obj, interfaceName)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                interfaceName (1,1) string  {mustBeNonzeroLengthText, mustBeTextScalar}
            end
            %validate interface name before setting
            clibgen.internal.validateInterfaceName(interfaceName);
            obj.CppInterfaceName = interfaceName;
        end
        function set.HeaderFiles(obj, headerFiles)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                headerFiles (1,:) string {clibgen.internal.mustBeStringOrCharOrCell}
            end
            % Validate header files
            headerFiles = string(headerFiles);
            clibgen.internal.validateHeaders([], headerFiles);
            for headerFile = headerFiles
                [~,~,ext] = fileparts(headerFile);
                if isempty(ext)
                    error(message('MATLAB:CPP:IncorrectFileExtension',headerFile));
                end
            end
            obj.HeaderFiles = clibgen.internal.makePathAbsolute(headerFiles);
        end
        function set.AdditionalCompilerFlags(obj, compilerFlags)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                compilerFlags (1,:) {mustBeNonempty, clibgen.internal.mustBeStringOrCharOrCell}
            end
            if ~isstring(compilerFlags)
                compilerFlags = string(compilerFlags);
            end
            obj.AdditionalCompilerFlags = compilerFlags;
        end
        function set.IncludePath(obj, includePath)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                includePath (1,:) {mustBeNonempty, clibgen.internal.mustBeStringOrCharOrCell}
            end
            includePath = string(inputPath);
            clibgen.internal.validateUserIncludePath(includePath);
            obj.IncludePath = clibgen.internal.makePathAbsolute(includePath);
        end
        function set.DefinedMacros(obj, macros)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                macros (1,1) dictionary=configureDictionary("string","string")
            end
            macrosString = strings(macros.numEntries,1);
            keys = macros.keys;
            for ind = 1:macros.numEntries
                if(macros(key) == "")
                    macrosString(ind) = keys(ind);
                else
                    macrosString(ind) = keys(ind) + "=" + macros(keys(ind));
                end
            end
            clibgen.internal.validateMacro(macrosString, true);
            obj.DefinedMacros = macros;
        end
        function set.UndefinedMacros(obj, macros)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                macros (1,:) {mustBeNonempty, mustBeNonzeroLengthText ,clibgen.internal.mustBeStringOrCharOrCell}=""
            end
            macros = string(macros);
            clibgen.internal.validateMacro(macros, false);
            obj.UndefinedMacros = macros;
        end
        function set.IncludedFunctions(obj, functions)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                functions (1,:) pattern
            end
            % TODO Add validation like Removing empty and duplicate names in the input list
            obj.IncludedFunctions = functions;
        end
        function set.IncludedClasses(obj, classes)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                classes (1,:) pattern
            end
            % TODO Add validation like Removing empty and duplicate names in the input list
            obj.IncludedClasses = classes;
        end
        function set.IncludedEnumerations(obj, enums)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                enums (1,:) pattern
            end
            % TODO Add validation like Removing empty and duplicate names in the input list
            obj.IncludedEnumerations = enums;
        end
        function set.FunctionNames(obj, names)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                names dictionary
            end
            obj.validateDictionaryForRenaming(names, "FunctionNames")
            obj.FunctionNames = names;
        end
        function set.FunctionTypeNames(obj, names)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                names dictionary
            end
            obj.validateDictionaryForRenaming(names, "FunctionTypeNames")
            obj.FunctionTypeNames =names;
        end
        function set.ClassNames(obj, names)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                names dictionary
            end
            obj.validateDictionaryForRenaming(names, "ClassNames")
            obj.ClassNames = names;
        end
        function set.ClassMethodNames(obj, names)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                names dictionary
            end
            obj.validateDictionaryForRenaming(names, "ClassMethodNames")
            obj.ClassMethodNames = names;
        end
        function set.EnumerationNames(obj, names)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                names dictionary
            end
            obj.validateDictionaryForRenaming(names, "EnumerationNames")
            obj.EnumNames = names;
        end
        function set.OpaqueTypeNames(obj, names)
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                names dictionary
            end
            obj.validateDictionaryForRenaming(names, "OpaqueTypeNames")
            obj.OpaqueTypeNames = names;
        end
        function set.OutputFolder(obj, folderName)
            arguments
                obj
                folderName (1,1) string {mustBeNonzeroLengthText}
            end
            if fileparts(folderName)==""
                folderName = fullfile(pwd, folderName);
            end
            folderName = clibgen.internal.makePathAbsolute(folderName);
            [status,x] = fileattrib(folderName);
            % if the OutputFolder is readonly
            if status~=0 && ~x.UserWrite
                % TODO Add error IDs and messages to message catalogue
                error("OutputFolder '%s' is read-only", pwd);
            end
            if(isfile(fullfile(folderName, obj.CppInterfaceName)))
                % TODO Add error IDs and messages to message catalogue
                error("OutputFolder '%s' exists as a file", folderName);
            end
            obj.CppOutputFolder = folderName;
        end

        function validate(obj)
        % Validate method validates the libraryConfiguration object is
        % ready to be used. The object is ready to be used only when
        % InterfaceName and HeaderFiles are set.
        %
            if (isempty(obj.HeaderFiles))
                % TODO Add error IDs and messages to message catalogue
                error("HeaderFiles needs to be set")
            end
            if(obj.CppInterfaceName == "")
                % TODO Add error IDs and messages to message catalogue
                error("InterfaceFileName needs to be set")
            end
            if(isfile(fullfile(obj.CppOutputFolder, obj.CppInterfaceName)))
                % TODO Add error IDs and messages to message catalogue
                error("File exists in OutputFolder  %s.", obj.CppOutputFolder)
            end
        end
    end

    methods(Access=public,Hidden)

        function validateRenamesWithPattern(obj)
        %Validate the new names given by the users, the new names are
        %used in renaming workflows.
            obj.validateSymBolRenamesWithPattern(obj.IncludedFunctions, obj.FunctionNames.keys, "IncludedFunctions", "FunctionNames");
            obj.validateSymBolRenamesWithPattern(obj.IncludedClasses, obj.ClassNames.keys, "IncludedClasses", "ClassNames");
            obj.validateSymBolRenamesWithPattern(obj.IncludedEnums, obj.EnumerationNames.keys, "IncludedEnums", "EnumerationNames");
            newNames = horzcat(obj.FunctionNames.keys, obj.ClassNames.keys, obj.EnumrationNames.keys);
            % TODO check if extensive validation is required
            if(length(newNames) ~= length(unique(newNames)))
                % TODO Add error IDs and messages to message catalogue
                error("Names supplied for renames must be unique");
            end
        end
    end
    methods(Access=protected)
        function propGrp = getPropertyGroups(~)
            requiredInfoHeading = "<strong>Required Information</strong>";
            requiredInfoList = ["InterfaceName", "HeaderFiles", "IncludePath", "OutputFolder"];
            requiredGroup = matlab.mixin.util.PropertyGroup(requiredInfoList, requiredInfoHeading);

            interfaceContentsControlHeading = "<strong>Control Interface Contents and Global Settings</strong>";
            interfaceContentsControlList = ["IncludedFunctions", "IncludedClasses", "IncludedEnumerations","TreatConstCharPointerAsCString", "TreatObjectPointerAsScalar"];
            interfaceContentsControlGroup = matlab.mixin.util.PropertyGroup(interfaceContentsControlList, interfaceContentsControlHeading);

            matlabNamesGroupHeading = "<strong>Control MATLAB Names</strong>";
            matlabNamesGroupList = ["ClassNames", "ClassMethodNames", "EnumerationNames", "FunctionNames","FunctionTypeNames","OpaqueTypeNames"];
            matlabNamesGroup = matlab.mixin.util.PropertyGroup(matlabNamesGroupList, matlabNamesGroupHeading);

            compilationOptionsHeading = "<strong>Control Compilation</strong>";
            compilationOptionsGroupList = ["AdditionalCompilerFlags", "DefinedMacros", "UndefinedMacros"];
            compilationOptionsGroup = matlab.mixin.util.PropertyGroup(compilationOptionsGroupList, compilationOptionsHeading);

            propGrp = [requiredGroup, interfaceContentsControlGroup, matlabNamesGroup, compilationOptionsGroup];
        end

    end
    methods(Access=private)
        function validateSymBolRenamesWithPattern(obj, patt, namesInDict, typeName, pattName)
        % Validate the symbol-names given for renaming matches the pattern
        % given by the user
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                patt (1,:) string
                namesInDict (1, :) string
                typeName (1,1) string
                pattName (1,1) string
            end
            if(patt ~= "")
                symbolNames = sort(namesInDict);
                ret = all(matches(symbolNames, pattern(patt)));
                if(~ret)
                    % TODO Add error IDs and messages to message catalogue
                    warning("Names in '%s' must match the pattern provided in '%s'.", pattName, typeName);
                end
            end
        end
        function validateDictionaryForRenaming(obj, names, symbolKind)
        % Validate the symbol names provided in the renaming
        % dictionary
            arguments
                obj (1,1) clibgen.api.LibraryConfiguration
                names dictionary
                symbolKind (1,1) string
            end
            %values must be nonempty and scalartext
            validateattributes(names.values,{'string'}, {'nonempty', 'scalartext',});
            %values  must be valid matlab identifiers
            if ~all(arrayfun(@isvarname, names.values))
                % TODO Add error IDs and messages to message catalogue
                error("Values in %s must be valid MATLAB identifiers", symbolKind);
            end
            %values must be unique
            if(length(names.values)~= length(unique(names.values)))
                % TODO Add error IDs and messages to message catalogue
                error("Values in '%s' must be unique", symbolKind)
            end
        end
    end
end
