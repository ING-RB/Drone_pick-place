classdef MethodTpl < matlab.engine.internal.codegen.CodeGenSection
    %MethodTpl Holds method data

    %   Copyright 2020-2023 The MathWorks, Inc.

    properties
        SectionName = "";
        SectionContent = "";
        SectionMetaData;
        IndentLevel = 0;
        MethodPath = ""; % package / class prefix of method in dot notation
        FullName = "";   % name of method in format namespace1.namespace2.classname/methodname
        ShortName = "";  % name of the method without dot-notation / class prefix
        DefiningClass (1,1) string = "";
        EncapsulatingClass (1,1) string = ""; % Class which has this method as a member. Most derived class, may be different than defining class e.g. through inheritance.
        IsConstructor;
        IsVarargin;
        IsVarargout;
        IsImplicit = true; % Methods are always implictly specified as part of classes
        TemplateSpecSection = "";

        % Holds how the method can be accessed
        Access;
        IsHidden;
        IsAbstract;
        IsStatic;

        % Holds if method can be generated based on accessibility
        IsAccessible;
        ReasonInaccessible; % Holds reason inaccessible, if applicable

        % Holds info regarding input arguments (new API using metafunction)
        InputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl = matlab.engine.internal.codegen.ArgumentTpl.empty() % holds output args (ArgumentTpl)
        NumArgIn  (1,1) uint64 = 0;

        % Holds info regarding output arguments
        MetaFunc; % main metadata object
        NumArgOut  (1,1) uint64 = 0;
        OutputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl = matlab.engine.internal.codegen.ArgumentTpl.empty() % holds output args (ArgumentTpl)

        VacantMeta; % Holds vacant size/type metadata for method inputs/outputs

        IsCSharp (1,1) logical

    end

    properties (Access = private)
        ReportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
    end

    methods
        function obj = MethodTpl(methodMetaData, className, indentLevel, reportObj, isCSharp)
            arguments
                methodMetaData (1,1) meta.method
                className (1,1) string % The name of the encapsulating most derived class (may be different than the defining class through inheritance)
                indentLevel (1,1) int64
                reportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
                isCSharp (1,1) logical
            end

            obj.IndentLevel = indentLevel;
            obj.SectionMetaData = methodMetaData;
            obj.ReportObj = reportObj;
            obj.EncapsulatingClass = className;
            obj.IsCSharp = isCSharp;
            obj = obj.read();
        end
        
        % This function should never be called outside the class, the logic that was once
        % here is now in the GetMethodOverloads function
        function obj = read(obj)
            % Read in the metadata
            obj.SectionName = obj.SectionMetaData.Name;
            obj.ShortName = obj.SectionName;
            obj.DefiningClass = string(obj.SectionMetaData.DefiningClass.Name);
            obj.MethodPath = [obj.SectionMetaData.DefiningClass.Name '/' obj.SectionMetaData.Name];
            obj.FullName = string([obj.SectionMetaData.DefiningClass.Name '/' obj.SectionMetaData.Name]);
            obj.Access = obj.SectionMetaData.Access;
            obj.IsHidden = obj.SectionMetaData.Hidden;
            obj.IsStatic = obj.SectionMetaData.Static;
            obj.IsAbstract = obj.SectionMetaData.Abstract;
        end
    end
end
