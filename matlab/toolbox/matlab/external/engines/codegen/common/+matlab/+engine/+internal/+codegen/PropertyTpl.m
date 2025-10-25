classdef PropertyTpl < matlab.engine.internal.codegen.CodeGenSection
    % PropertyTpl Holds property level data

    %   Copyright 2020-2023 The MathWorks, Inc.

    properties
        SectionName = "";
        FullName = "";
        SectionContent = "";
        SectionMetaData;
        IndentLevel = 0;
        DefiningClass (1,1) string = "";
        EncapsulatingClass (1,1) string = ""; % Class which has this property as a member. May be different than defining class e.g. through inheritance.
        IsImplicit = true; % Properties are always implictly specified as part of classes

        % Holds how the property can be accessed
        GetAccess;
        SetAccess;
        IsHidden;
        IsAbstract;
        IsDependent;
        CustomGetter = []; % fh to the custom getter
        CustomSetter = []; % fh to the custom setter

        % Holds if the property can be generated or not
        IsGetAccessible;
        IsSetAccessible;

        % Holds reason property setter/getter is dropped
        ReasonGetInaccessible;
        ReasonSetInaccessible;

        MatlabPropertyClass = "";
        CppPropertyClass = "";

        ArrayDimensions;
        ArrayType;
        IsEnumeration = false; % Holds if type is MATLAB enumeration class

        Dependency = "";
        VacantMeta; % Holds if the property has vacant size or type meta-data
    end

    properties (Access = private)
        ReportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
    end

    methods
        function obj = PropertyTpl(propertyMetaData, className, indentLevel, reportObj)
            arguments
                propertyMetaData (1,1) meta.property
                className (1,1) string
                indentLevel (1,1) int64
                reportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
            end

            obj.SectionMetaData = propertyMetaData;
            obj.EncapsulatingClass = className;
            obj.IndentLevel = indentLevel;
            obj.ReportObj = reportObj;
            obj = read(obj);

        end

        function obj = read(obj)
            import matlab.engine.internal.codegen.*

            isReal = 0;

            % Inspect meta-data carefully since it might be empty in places

            if(~isempty(obj.SectionMetaData))
                if(~isempty(obj.SectionMetaData.Name))
                    obj.SectionName = obj.SectionMetaData.Name; % Read name
                else
                    obj.SectionName = "";
                    % The property has an empty name. This should never happen.
                    messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                    error(messageObj);
                end

                % Read defining class
                if(~isempty(obj.SectionMetaData.DefiningClass.Name))
                    obj.DefiningClass = string(obj.SectionMetaData.DefiningClass.Name);
                else
                    obj.DefiningClass = "";
                    % The property has an empty name for defining class. This should never happen.
                    messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                    error(messageObj);
                end
                obj.FullName = string(obj.DefiningClass + "." + obj.SectionName);

                % Read in how the property can be accessed
                obj.GetAccess = obj.SectionMetaData.GetAccess;
                obj.SetAccess = obj.SectionMetaData.SetAccess;
                obj.IsHidden = obj.SectionMetaData.Hidden;
                obj.IsAbstract = obj.SectionMetaData.Abstract;
                obj.IsDependent = obj.SectionMetaData.Dependent;
                obj.CustomGetter = obj.SectionMetaData.GetMethod;
                obj.CustomSetter = obj.SectionMetaData.SetMethod;
            else
                % The property metadata object supplied is empty. This
                % should never happen
                messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                error(messageObj);
            end

            % Inspect the validation metadata, carefully
            obj.VacantMeta = [];
            if(isempty(obj.SectionMetaData.Validation))
                % if there is no validation data, assume multi-dim
                obj.ArrayType = DimType.MultiDim;
                obj.MatlabPropertyClass = "unknown";
                obj.VacantMeta = matlab.engine.internal.codegen.reporting.MetaUnit("Property", obj.SectionName, obj.SectionName, false, false);

            else % there is some validation data

                % Check size
                if(isempty(obj.SectionMetaData.Validation.Size))
                    % Just no size validation data, assume multi-dim
                    obj.ArrayType = DimType.MultiDim;
                    hasSize = false;
                else
                    % The size validation data should be populated here
                    lengthdims = length(obj.SectionMetaData.Validation.Size);
                    dims = zeros(1, lengthdims);
                    for i = 1 : lengthdims
                        sizeObj = obj.SectionMetaData.Validation.Size(i);
                        % Replace meta.UnrestrictedDimension with inf
                        if isa(sizeObj,'meta.UnrestrictedDimension')
                            dims(i) = inf;
                        else
                            dims(i) = sizeObj.Length;
                        end
                        hasSize = true;
                    end

                    % aflewell - This block is redundant, and should be handled by classifyArraySize()
                    % Use MATLAB Data Array in C++ to represent properties with
                    % unrestricted dimensions
                    %if sum(dims==inf) > 1
                    %    obj.ArrayType = DimType.MultiDim;
                    %    obj.MatlabPropertyClass = "unknown";
                    %else
                    %end

                    obj.ArrayDimensions = dims;
                    % Classify the array based on its dimensions. E.g. Scalar
                    obj.ArrayType = classifyArraySize(dims);

                end

                % Check if class validation is populated. If it is, read.
                if (isempty(obj.SectionMetaData.Validation.Class))
                    obj.MatlabPropertyClass = "unknown";
                    hasType = false;
                else
                    % Class metadata should be there, so read the class name
                    obj.MatlabPropertyClass = string(obj.SectionMetaData.Validation.Class.Name);
                    obj.IsEnumeration = obj.SectionMetaData.Validation.Class.Enumeration;
                    hasType = true;
                end

                if(~hasSize || ~hasType)
                    obj.VacantMeta = matlab.engine.internal.codegen.reporting.MetaUnit("Property", ...
                        obj.SectionName, obj.SectionName, hasSize, hasType);
                end

                % Search for extra relevant validator functions
                validators = obj.SectionMetaData.Validation.ValidatorFunctions;
                for j = 1 : numel(validators)
                    val = string(char(validators{j}));
                    if val.matches("mustBeReal")
                        isReal = 1;
                    else
                        isReal = 0;
                    end
                end

            end

            % aflewell - remove convertPropertyTypes() alltogether, due to growing redundancies
            %obj.CppPropertyClass = convertPropertyTypes(obj.SectionMetaData);

            % Find corresponding type of the property in CPP
            tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();
            obj.CppPropertyClass = tc.convertType2CPP(obj.MatlabPropertyClass, obj.ArrayType, isReal);

            % Only generate the getter and setter if they are public and
            % not hidden and not restricted and not abstract
            % If dependent, only generate getter and setter if they are
            % custom-provided

            obj.IsGetAccessible = true;
            obj.IsSetAccessible = true;

            if(obj.IsHidden)
                obj.IsGetAccessible = false;
                obj.IsSetAccessible = false;
                obj.ReasonGetInaccessible = "Property is hidden";
                obj.ReasonSetInaccessible = "Property is hidden";
            elseif(obj.IsAbstract)
                obj.IsGetAccessible = false;
                obj.IsSetAccessible = false;
            else
                if(~isa(obj.GetAccess, 'char') && ~isa(obj.GetAccess, 'string'))
                    obj.IsGetAccessible = false; % Restricted getter case
                    obj.ReasonGetInaccessible = "Property is not public";
                elseif(string(obj.GetAccess) ~= "public")
                    obj.IsGetAccessible = false; % Non-public getter case
                    obj.ReasonGetInaccessible = "Property is not public";
                end
                if(~isa(obj.SetAccess, 'char') && ~isa(obj.SetAccess, 'string'))
                    obj.IsSetAccessible = false; % Restricted setter case
                    obj.ReasonSetInaccessible = "Property is not public";
                elseif(string(obj.SetAccess) ~= "public")
                    obj.IsSetAccessible = false; % Non-public setter case
                    obj.ReasonSetInaccessible = "Property is not public";
                end
                if(obj.IsDependent) % Check for custom set/get
                    if(isempty(obj.CustomGetter))
                        obj.IsGetAccessible = false;
                        obj.ReasonGetInaccessible = "Custom property getter not found";
                    end
                    if(isempty(obj.CustomSetter))
                        obj.IsSetAccessible = false;
                        obj.ReasonSetInaccessible = "Custom property setter not found";
                    end
                end
            end

        end
    end
end
