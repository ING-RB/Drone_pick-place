classdef CPPCodeGenerator < handle
    %CPPCODEGENERATOR A CPP code generator class
    %   The codegenerator class can read metadata on
    %   MATLAB classes or functions, and generate CPP code wrappers
    %   so you can easily create and interact with
    %   them in C++

    %   Copyright 2020-2023 The MathWorks, Inc.

    properties
        IndentChar = char(" ");  % char used to form indents
        IndentSize = 4;  % Number of IndentChar in one indent
        HeaderName = [];
        Inputs = [];

        Header = [];
        SourceMeta = [];

        ClassList (1,:) matlab.engine.internal.codegen.ClassTpl = matlab.engine.internal.codegen.ClassTpl.empty();
        FunctionList (1,:) matlab.engine.internal.codegen.FunctionTpl = matlab.engine.internal.codegen.FunctionTpl.empty();

        UnresolvedDependencies = [];

        ReportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData

    end

    properties (Access = private)
        ClassNames = string.empty(1,0);    % Holds names of unique classes
        FunctionNames = string.empty(1,0); % Holds names of unique functions
    end

    methods

        function obj = read(obj, nameValuePairs)

            arguments
                obj
                nameValuePairs.Namespaces (1,:) string = []
                nameValuePairs.Packages  (1,:) string = []
                nameValuePairs.Classes   (1,:) string = []
                nameValuePairs.Functions (1,:) string = []
                nameValuePairs.DisplayReport   (1,1) logical = 0
                nameValuePairs.SaveReport      {mustBeTextScalar} = ""
            end

            if ~isfield(nameValuePairs, "Namespaces") && ~isfield(nameValuePairs, "Packages") && ~isfield(nameValuePairs, "Classes") && ~isfield(nameValuePairs, "Functions")
                messageObj = message("MATLAB:engine_codegen:NoInputList");
                error(messageObj);
            end

            import matlab.engine.internal.codegen.*

            obj.ClassList = matlab.engine.internal.codegen.ClassTpl.empty();
            obj.FunctionList = matlab.engine.internal.codegen.FunctionTpl.empty();
            obj.ClassNames = string.empty(1,0);
            obj.FunctionNames = string.empty(1,0);
            obj.ReportObj = matlab.engine.internal.codegen.reporting.ReportData();

            obj.SourceMeta = [];

            % Initialize
            obj.Inputs = nameValuePairs;
            obj.Inputs.SaveReport = string(obj.Inputs.SaveReport); % make sure filename is a string as it is the most predictable format
            obj.Header = cpp.CppHeader();
            obj.ClassList = matlab.engine.internal.codegen.ClassTpl.empty();
            obj.FunctionList = matlab.engine.internal.codegen.FunctionTpl.empty();
            obj.SourceMeta = struct();
            obj.SourceMeta.NamespaceObjs = [];
            obj.SourceMeta.ClassObjs = [];
            obj.SourceMeta.FunctionObjs = [];

            % Read data and populate total, flat, classlist and/or
            % function list

            % Handle Namespace names
            metaPackageList = [];
            invalidPackages = [];
            for i = 1:numel(nameValuePairs.Packages)
                pname = nameValuePairs.Packages(i);
                metaPackage = meta.package.fromName(pname);
                metaPackageList = [metaPackageList metaPackage];
                if(isempty(metaPackage))
                    % If the meta.package object is empty, the name is invalid
                    invalidPackages = [invalidPackages pname];
                end

            end
            for i = 1:numel(nameValuePairs.Namespaces)
                pname = nameValuePairs.Namespaces(i);
                metaPackage = meta.package.fromName(pname);
                metaPackageList = [metaPackageList metaPackage];
                if(isempty(metaPackage))
                    % If the meta.package object is empty, the name is invalid
                    invalidPackages = [invalidPackages pname];
                end

            end
            if(~isempty(invalidPackages))
                % Error citing invalid package names
                messageObj = message("MATLAB:engine_codegen:NamespaceNamesNotFound", strjoin(invalidPackages, " "));
                error(messageObj);

            end
            for i = 1:numel(metaPackageList)
                namespaceObj = NameSpaceTpl(metaPackageList(i), 0, obj.ReportObj);
                obj.SourceMeta.NamespaceObjs = [obj.SourceMeta.NamespaceObjs, namespaceObj];

                % Only add new class or function if it is unique
                obj.addUniqueToList(namespaceObj.ClassList);
                obj.addUniqueToList(namespaceObj.FunctionList);
            end

            % Handle Class names
            metaClassList = [];
            invalidClasses = [];
            for i = 1:numel(nameValuePairs.Classes)
                cname = nameValuePairs.Classes(i);
                metaClass = meta.class.fromName(cname);
                metaClassList = [metaClassList metaClass];
                if(isempty(metaClass))
                    % If the meta.class object is empty, the name is invalid
                    invalidClasses = [invalidClasses cname];
                end
            end
            if(~isempty(invalidClasses))
                % Error citing invalid class names that could not be found
                messageObj = message("MATLAB:engine_codegen:ClassNamesNotFound", strjoin(invalidClasses, " "));
                error(messageObj);
            end

            for i = 1:numel(metaClassList)
                classObj = ClassTpl(metaClassList(i), 0, 0, obj.ReportObj);
                obj.addUniqueToList(classObj); % Add only unique to list
            end

            % Handle Function names
            functionList = [];
            invalidFunctions = [];
            for i = 1:numel(nameValuePairs.Functions)
                funcNameFull = nameValuePairs.Functions(i);
                functionList = [functionList funcNameFull];
                try
                    % Must work with nargin
                    nargin(funcNameFull);

                    % g2684488 -Verify function name has correct case as
                    % "nargin" and "which" don't have case sensitive inputs
                    fullFileName = which(funcNameFull);
                    if(~isfile(fullFileName))
                        error("The function is not a file. This error should be caught and should never be visible.")
                    end
                    [~, actualName, ~] = fileparts(fullFileName);
                    fname = string(split(funcNameFull, '.'));
                    fname = fname(end); % compare case only for function name, not package prefix
                    if(~strcmp(actualName, fname))
                        error("The function likely has incorrect casing provided by user. This error should be caught and should never be visible.")
                    end
                catch
                    invalidFunctions = [invalidFunctions funcNameFull];
                end
            end
            if(~isempty(invalidFunctions))
                % Error citing invalid function which could not be found
                messageObj = message("MATLAB:engine_codegen:FunctionNamesNotFound", strjoin(invalidFunctions, " "));
                error(messageObj);
            end
            for i = 1:numel(functionList)
                functionObj = FunctionTpl(functionList(i), 0, false, obj.ReportObj);
                obj.addUniqueToList(functionObj); % Add unique functions
            end

            % Code below assumes that the classes and functions we have queued so
            % far are unique, in order to avoid duplicates and graphing problems

            % Drop classes that are hidden or abstract
            obj = obj.handleHiddenAndAbstractClasses();

            % Check class names and function names for conflicts with C++ keywords
            obj = obj.handleNameConflicts();

            % Resolve class dependencies
            if(~isempty(obj.ClassList) || ~isempty(obj.FunctionList))

                % Sort the class list and store the result
                % UnresolvedDependencies and dependants are related
                % by indicies. Consider using a map container instead of this
                [obj.ClassList, obj.UnresolvedDependencies, dependants] = resolveClassDependencies(obj.ClassList, obj.FunctionList, obj.ReportObj);
            end

            % For classes/functions that were not dropped, record optional
            % metadata that was not provided, and could be populated
            for i = 1:length(obj.ClassList)
                c = obj.ClassList(i);
                if(~isempty(c.VacantMeta))
                    obj.ReportObj.recordVacant("Class", c.FullName, c.VacantMeta)
                end
            end

            for i = 1:length(obj.FunctionList)
                f = obj.FunctionList(i);
                if(~isempty(f.VacantMeta))
                    obj.ReportObj.recordVacant("Function", f.FullName, f.VacantMeta)
                end
            end

            % Check for any error or warning conditions in recorded data
            obj.ReportObj.checkErrorsWarnings();

        end

        function write(obj, targetFileName)
            % Generate the CPP code
            arguments
                obj
                targetFileName (1,1) string {mustBeNonzeroLengthText}
            end

            import matlab.engine.internal.codegen.*

            contents = "";

            %TODO - If there is nothing to write, skip code below, and warn

            % Put header info if the file does not exist already,
            % or, if file exists, but is empty
            if ~isfile(targetFileName)
                contents = obj.Header.string(targetFileName);
            elseif numel(dir(targetFileName)) == 1
                targetfile = dir(targetFileName);
                if(targetfile.bytes == 0)
                    contents = obj.Header.string(targetFileName);
                end
            else % The file already has stuff in it.
                % TODO probably find a way to append a newline here
            end

            % Start the recursive writing routine on the sorted flat classlist
            for c = obj.ClassList
                contents = contents + matlab.engine.internal.codegen.cpp.CppClass(c).string();
            end

            % Write functions after classes, due to possible dependency
            for f = obj.FunctionList
                contents = contents + matlab.engine.internal.codegen.cpp.CppFunction(f).string();
            end

            % Replace indent token with the chosen characters
            contents = replace(contents, "[oneIndent]", repmat(obj.IndentChar, 1, obj.IndentSize));

            % Trim trailing spaces and newlines
            contents = strip(contents, 'right');

            % Write the CPP code to the file
            wh = fopen(targetFileName, 'a+');
            if wh >= 3
                fprintf(wh, '%s', contents); % %s to prevent possible \ escape char
            else
                messageObj = message("MATLAB:engine_codegen:FileWriteError", targetFileName);
                error(messageObj);
            end
            fclose(wh);

            % Note the written file name
            obj.HeaderName = targetFileName;

            % Add to report: Classes and Functions written to the interface
            if(~isempty(obj.ClassList))
                obj.ReportObj.recordGenerated(reporting.UnitType.Class, obj.ClassList);
            end
            if(~isempty(obj.FunctionList))
                obj.ReportObj.recordGenerated(reporting.UnitType.Function, obj.FunctionList);
            end

            % Display brief 1-line summary after writing to file in MATLAB
            % cmd window
            obj.ReportObj.displayBriefGenerationReport(targetFileName);

            % Display full report if specified to MATLAB cmd window
            if(obj.Inputs.DisplayReport)
                obj.ReportObj.displayReport(targetFileName, obj.Inputs);
            end

            % Save full report to file if specified and if the filename is
            % not empty or missing
            if(obj.Inputs.SaveReport ~= "" && ~isempty(obj.Inputs.SaveReport) && (sum(ismissing(obj.Inputs.SaveReport)) == 0))
                obj.ReportObj.saveReport(obj.Inputs.SaveReport, targetFileName, obj.Inputs);
            end

        end

    end

    methods (Access = private)

        function obj = handleNameConflicts(obj)
            % Drops classes that conflict with C++ keywords

            import matlab.engine.internal.codegen.*
            import matlab.engine.internal.codegen.reporting.*

            % Check class names for conflicts with C++ keywords
            if(~isempty(obj.ClassList))
                classnames = [obj.ClassList.SectionName];
                k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
                conflicts = k.getKeywordConflicts(classnames);
                deleteIndex = [];
                if(~isempty(conflicts))

                    for c = conflicts
                        deleteIndex = [deleteIndex, find(classnames == c)];
                    end

                    offendingClasses = obj.ClassList(deleteIndex);

                    % Record the classes that will be dropped
                    messageObj = message("MATLAB:engine_codegen:CPPKeywordConflictClass");
                    obj.ReportObj.recordDropped(UnitType.Class, offendingClasses, messageObj)

                    obj.ClassList(deleteIndex) = []; % Delete the offending classes
                end
            end

            % Check function names for conflicts with C++ keywords
            if(~isempty(obj.FunctionList))
                functionNames = string([obj.FunctionList.SectionName]);
                % Erase any dot-notation in function names
                functionNames = eraseBetween(functionNames, wildcardPattern, ".");
                functionNames = erase(functionNames, ".");
                k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
                conflicts = k.getKeywordConflicts(functionNames);
                deleteIndex = [];
                if(~isempty(conflicts))

                    for c = conflicts
                        deleteIndex = [deleteIndex, find(functionNames == c)];
                    end

                    offendingFunctions = obj.FunctionList(deleteIndex);
                    %TODO centralize this warning by handling in the report
                    %object instead

                    messageObj = message("MATLAB:engine_codegen:CPPKeywordConflictFunction");

                    obj.ReportObj.recordDropped(UnitType.Function, offendingFunctions, messageObj)

                    obj.FunctionList(deleteIndex) = []; % Delete the offending functions

                end
            end

        end

        function obj = handleHiddenAndAbstractClasses(obj)
            % Drop hidden and abstract classes in the flat classlist, as
            % they should not be generated
            if(~isempty(obj.ClassList))
                obj.ClassList = obj.ClassList(~[obj.ClassList.IsHidden]);
                obj.ClassList = obj.ClassList(~[obj.ClassList.IsAbstract]);
            end
        end

        function obj = addUniqueToList(obj, elements)
            % addUniqueToList adds a clas(es) or function(s) objs to the list
            % making sure each is unique

            if(string(class(elements)) == "matlab.engine.internal.codegen.ClassTpl")

            for e = elements
                % Only add class if it is unique
                if(~ismember(e.FullName, obj.ClassNames))
                    obj.ClassNames = [obj.ClassNames e.FullName];
                    obj.SourceMeta.ClassObjs = [obj.SourceMeta.ClassObjs, e];
                    obj.ClassList = [obj.ClassList e];
                elseif(~e.IsImplicit)
                    % Case class not unique. Don't add duplicate class, but
                    % make sure if class is specified explicitly for generation
                    % that it is marked as such in other instance
                    index = ([obj.SourceMeta.ClassObjs.FullName] == e.FullName);
                    obj.SourceMeta.ClassObjs(index) = e;
                    index = ([obj.ClassList.FullName] == e.FullName);
                    obj.ClassList(index) = e;

                end
            end

            elseif(string(class(elements)) == "matlab.engine.internal.codegen.FunctionTpl")
                for e = elements
                    % Only add function if it is unique
                    if(~ismember(e.FullName, obj.FunctionNames))
                        obj.FunctionNames = [obj.FunctionNames e.FullName];
                        obj.SourceMeta.FunctionObjs = [obj.SourceMeta.FunctionObjs, e];
                        obj.FunctionList = [obj.FunctionList e];
                    elseif(~e.IsImplicit)
                        % Case function not unique. Don't add duplicate class, but
                        % make sure if function is specified explicitly for generation
                        % that it is marked as such in other instance
                        index = ([obj.SourceMeta.FunctionObjs.FullName] == e.FullName);
                        obj.SourceMeta.FunctionObjs(index) = e;
                        index = ([obj.FunctionList.FullName] == e.FullName);
                        obj.FunctionList(index) = e;

                    end
                end

            end

        end

    end
end