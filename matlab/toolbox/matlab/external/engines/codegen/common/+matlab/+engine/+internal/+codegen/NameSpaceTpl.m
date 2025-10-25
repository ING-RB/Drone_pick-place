classdef NameSpaceTpl < matlab.engine.internal.codegen.CodeGenSection
    %NameSpaceTpl Holds Namespace/Package level data

%   Copyright 2020-2023 The MathWorks, Inc.

    properties
        SectionName = "";
        SectionContent = "";
        ClassList = []; % Holds flat list of all classes under the pkg
        LocalClassList = [];
        FunctionList = []; % Holds flat list of all functions under the pkg
        LocalFunctionList = [];
        ClassNames = [];
        Dependencies = [];
        SectionMetaData;
        IndentLevel = 0;
        %TODO remove isCSharp upon flag being no longer needed
        IsCSharp;
    end

    properties (Access = private)
        ReportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
    end
    
    methods
        %TODO remove isCSharp upon flag being no longer needed
        function obj = NameSpaceTpl(pkgMetaData, indentLevel, reportObj, isCSharp)
            % Returns the namespace obj, and a flat list of all classes in
            % the package tree
            arguments
               pkgMetaData (1,1) meta.package
               indentLevel (1,1) int64
               reportObj   (1,1) matlab.engine.internal.codegen.reporting.ReportData
               isCSharp    (1,1) logical = false
            end
            
            obj.SectionMetaData = pkgMetaData;
            obj.IndentLevel = indentLevel;
            obj.ReportObj = reportObj;
            %TODO remove isCSharp upon flag being no longer needed
            obj.IsCSharp = isCSharp;
            obj = obj.read(); % Recursion is here
            
        end
        
        function obj = read(obj)
            import matlab.engine.internal.codegen.*
            
            % Gather and read metadata from source
            obj.ClassList = [];
            obj.LocalClassList = [];
            obj.FunctionList = [];
            obj.LocalFunctionList = [];
            
            obj.SectionName = obj.SectionMetaData.Name;
            
            % Traverse the package tree to find all the classes
            % and package functions, and then populate data
            
            % find local classes under immediate package
            localClassCount = length(obj.SectionMetaData.ClassList);
            for i = 1 : localClassCount
                classMeta = obj.SectionMetaData.ClassList(i);
                %TODO remove isCSharp upon flag being no longer needed
                c = ClassTpl(classMeta, obj.IndentLevel, true, obj.ReportObj, obj.IsCSharp);
                obj.LocalClassList = [obj.LocalClassList c];
                obj.ClassNames = [obj.ClassNames c.FullClass];
            end
            
            % Add local classes to the list of all contained classes
            obj.ClassList = obj.LocalClassList;
            
            %find local function under immediate package
            localFunctionCount = length(obj.SectionMetaData.FunctionList);
            for i = 1 : localFunctionCount
                functionMeta = obj.SectionMetaData.FunctionList(i);
                functionPath = string(obj.SectionMetaData.Name) + "." + string(functionMeta.Name);
                %TODO remove isCSharp upon flag being no longer needed
                f = FunctionTpl(functionPath, 0, true, obj.ReportObj, obj.IsCSharp);
                obj.LocalFunctionList = [obj.LocalFunctionList f];
            end
            
            % Add local functions to the list of all contained functions
            obj.FunctionList = obj.LocalFunctionList;
            
            % Recursively search sub-packages
            subPkgCount = length(obj.SectionMetaData.PackageList);
            for i = 1 : subPkgCount
                nsMeta = obj.SectionMetaData.PackageList(i);
                n = NameSpaceTpl(nsMeta, obj.IndentLevel, obj.ReportObj); % Recurse here
                % Add sub-lists to parent lists
                obj.ClassList = [obj.ClassList n.ClassList];
                obj.FunctionList = [obj.FunctionList n.FunctionList];
            end     
            
        end
        
        function sectionContent = toString(obj)
            % Recursively build the content string
            
            % For namespace, just print the subclasses
            sectionContent = "[generatedClasses]";
            
            generatedClasses = "";
            for classIterator = obj.ClassList
                generatedClasses = generatedClasses + classIterator.toString();
            end
            
            % Expand relevant tokens
            sectionContent = replace(sectionContent, "[generatedClasses]", generatedClasses);
            obj.SectionContent = sectionContent;
        end

    end
end

