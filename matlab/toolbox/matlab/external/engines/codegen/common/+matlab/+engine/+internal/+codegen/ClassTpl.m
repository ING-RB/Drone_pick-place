classdef ClassTpl < matlab.engine.internal.codegen.CodeGenSection
    %ClassTpl holds class metadata

    %   Copyright 2020-2023 The MathWorks, Inc.

    properties
        SectionName = "";     % Class name
        FullName = "";        % Full name including package prefixes
        SectionContent = "";
        SectionMetaData;      % Raw metadata
        IndentLevel = 0;
        IsImplicit = 0;       % Holds whether implicty generated (e.g. as part of package) or explicitly specified by user
        IsHandleClass (1,1) logical; % true if type is a handle class, false if value class

        FullClass = "";       % Class name including package prefixes
        Constructor = [];
        Properties = [];
        Methods = [];
        Enumerations = [];

        IsHidden;   % If hidden, should not be generated
        IsAbstract; % If abstract, should not be generated
        IsEnumeration; % if enum, C++ scoped enum is generated, not a C++ class

        Dependencies = []; % Dependencies to consider in CPP generation
        VacantMeta = [];
        ReportObj     (1,1) matlab.engine.internal.codegen.reporting.ReportData

        IsCSharp (1,1) logical
    end

    methods
        %TODO remove isCSharp upon flag being no longer needed
        function obj = ClassTpl(classMetaData, indentLevel, isImplicit, reportObj, isCSharp)
            arguments
                classMetaData (1,1) meta.class
                indentLevel   (1,1) int64
                isImplicit    (1,1) logical  % Set to true if creating implicitly as part of a MATLAB package
                reportObj     (1,1) matlab.engine.internal.codegen.reporting.ReportData
                isCSharp      (1,1) logical = false  % temporary flag to prevent C# from having C++ keyword conflicts.
            end
            obj.SectionMetaData = classMetaData;
            obj.IndentLevel = indentLevel;
            obj.IsImplicit = isImplicit;
            obj.ReportObj = reportObj;
            obj.IsCSharp = isCSharp;
            obj = read(obj);
            obj = handleNameConflicts(obj);

        end

        function obj = read(obj)
            % Populates properties this class
            import matlab.engine.internal.codegen.*

            obj.FullClass = string(obj.SectionMetaData.Name);
            obj.FullName = string(obj.SectionMetaData.Name);
            pathParts = split(obj.FullClass, '.');
            obj.SectionName = pathParts(end);
            obj.IsHidden = obj.SectionMetaData.Hidden;
            obj.IsAbstract = obj.SectionMetaData.Abstract;
            obj.VacantMeta = [];
            obj.IsHandleClass = matlab.engine.internal.codegen.util.isHandleClass(obj.SectionMetaData);

            obj.IsEnumeration = obj.SectionMetaData.Enumeration;
            if(obj.IsEnumeration && ~isempty(obj.SectionMetaData.EnumerationMemberList))
                % Read in enumeration data
                obj.Enumerations = obj.SectionMetaData.EnumerationMemberList;

                % Ignore hidden enumerations. If all enums are hidden,
                % don't consider the class to be an enum class for strongly
                % typed interface purposes
                obj.Enumerations = obj.Enumerations(~[obj.Enumerations.Hidden]);
                if(isempty(obj.Enumerations))
                    obj.IsEnumeration = false;
                end
               
            end

            if(~obj.IsAbstract && ~obj.IsEnumeration) % Guard reading property and method data on abstract classes or enum classes.
                % Reading methods of an abstract class is not smooth.
                % If enumeration class, we only care about enumeration block.

                % Read in properties
                propertyCount = length(obj.SectionMetaData.PropertyList);
                for i =1: propertyCount
                    propertyMeta = obj.SectionMetaData.PropertyList(i);
                    newProperty = PropertyTpl(propertyMeta, obj.FullName, obj.IndentLevel+2, obj.ReportObj);
                    if(newProperty.IsGetAccessible || newProperty.IsSetAccessible) % If not public, etc., don't generate
                        obj.Properties = [obj.Properties newProperty];

                        % Inherit dependencies of the property
                        obj.Dependencies = [obj.Dependencies newProperty.MatlabPropertyClass];

                        % Inherit vacant meta-data (properties without size and or type data)
                        obj.VacantMeta = [obj.VacantMeta newProperty.VacantMeta];
                    end

                end

                % Read in methods
                methodCount = length(obj.SectionMetaData.MethodList);
                constructorObj = [];
                for i = 1: methodCount
                    methodMeta = obj.SectionMetaData.MethodList(i);

                    if(methodMeta.Name == "empty")
                        continue; % Skip the special "empty" method
                    end

                    if ~isempty(obj.Methods)
                        if ismember(methodMeta.Name, [obj.Methods.ShortName])
                            continue; % Skip adding MATLAB overloads more than once
                        elseif ismember(methodMeta.Name, [obj.ReportObj.Dropped.Name])
                            continue; % Skip processing MATLAB overloads that are already dropped
                        end
                    end

                    % Read in method metadata and obtain any MATLAB overloads
                    newMethods = matlab.engine.internal.codegen.util.GetMethodOverloads(methodMeta, obj.FullName, obj.IndentLevel+2, obj.ReportObj, obj.IsCSharp);

                    % Disallow built-ins if applicable
                    firstMethod = newMethods(1); % Out of the overloads, we only need 1 for built-in info
                    location = string(which(firstMethod.DefiningClass));
                    
                    if(location.contains("built-in"))
                        if string(firstMethod.DefiningClass) == "handle"
                            if ~ismember(firstMethod.ShortName, ["eq" "ne" "lt" "le" "gt" "ge" "isvalid"])
                                if ~(obj.IsCSharp && firstMethod.ShortName == "delete")
                                    continue; % skip listing the method unless it's a comparison. isvalid() is hardcoded in MATLABHandleObject and not generated
                                end
                            end

                        else % Error on non-handle built-in TODO, maybe make this a drop the whole class instead
                            messageObj = message("MATLAB:engine_codegen:BuiltinMethodNotSupported", firstMethod.MethodPath);
                            error(messageObj);
                        end
                    end



                    for newMethod = newMethods

                        % remove check on constructor as every empty
                        % constructor is varargin by default
                        if (obj.IsCSharp && newMethod.IsVarargin && ~newMethod.IsConstructor)
                            messageObj = message("MATLAB:engine_codegen:MethodVararginNotSupported", newMethod.SectionName);
                            obj.ReportObj.recordDropped("ClassMethod", newMethod, messageObj);
                        elseif (obj.IsCSharp && newMethod.IsVarargout)
                            messageObj = message("MATLAB:engine_codegen:MethodVarargoutNotSupported", newMethod.SectionName);
                            obj.ReportObj.recordDropped("ClassMethod", newMethod, messageObj);
                        elseif(newMethod.IsAccessible)
                            % check for synthetic constructor C#
                            if (obj.IsCSharp && newMethod.IsConstructor)
                                if(newMethod.IsVarargin && length(newMethod.InputArgs)~=1)
                                    messageObj = message("MATLAB:engine_codegen:MethodVararginNotSupported", newMethod.SectionName);
                                    obj.ReportObj.recordDropped("ClassMethod", newMethod, messageObj);
                                end
                            end
                            % Inherit dependencies of method to class level
                            % For input arguments
                            % Don't inherit "self obj" class
                            if(newMethod.IsStatic || newMethod.IsConstructor)
                                start = 1;
                            else
                                start = 2;
                            end
    
                            dependTypes = [];
                            for j = start : newMethod.NumArgIn
                                dependTypes = [dependTypes,  newMethod.InputArgs(j).MATLABArrayInfo.ClassName];
                            end
    
                             % For output type support
                             if (newMethod.IsAccessible)
                                 for j = 1: newMethod.NumArgOut
                                    dependTypes = [dependTypes,  newMethod.OutputArgs(j).MATLABArrayInfo.ClassName];
                                 end
                             end
                            obj.Dependencies = [obj.Dependencies dependTypes];  % Populate class dependencies
    
                            % Inherit vacant metadata from methods (arguments that have missing size and or type
                            % data). Don't report if it's a handle class method because this data is not actionable by user
                            if(newMethod.DefiningClass ~= "handle")
                                obj.VacantMeta = [obj.VacantMeta newMethod.VacantMeta];
                            end
    
                            % Put method in method list, or the constructor section
                            if(newMethod.SectionName == obj.SectionName)
                                constructorObj = newMethod;
                            else
                                obj.Methods = [obj.Methods newMethod];
                            end
    
                        end
    
                    end
                end
    
                % We should have gotten one constructor method
                if(isempty(constructorObj))
                    messageObj = message("MATLAB:engine_codegen:ClassConstructorNotFound", obj.FullClass);
                    error(messageObj);
                end

                obj.Constructor = ConstructorTpl(constructorObj, obj.IndentLevel+2);

                % Remove repeated dependencies and self-dependency
                if ~isempty(obj.Dependencies)
                    obj.Dependencies = setdiff(obj.Dependencies, obj.FullClass);
                end
            end
        end
        
        function obj = handleNameConflicts(obj)
            % Identify and handle name or keyword conflicts that
            % will occur in the generated C++ code if unaddressed

            % check property set/gets against constructor/methods
            % check own name, props, methods, constructor, and enums
            % against CPP keywords
            %TODO remove isCSharp upon flag being no longer needed
            if obj.IsCSharp
                return
            end

            import matlab.engine.internal.codegen.*

            % Handle enum conflicts with C++ keyword
            if(obj.IsEnumeration && ~isempty(obj.Enumerations))
                enums = string({obj.Enumerations.Name});
                k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
                conflicts = k.getKeywordConflicts(enums);
                if(~isempty(conflicts))
                    deleteIndex = [];

                    for c = conflicts
                        deleteIndex = [deleteIndex find(c == enums)];
                    end

                    droppedEnums = obj.Enumerations(deleteIndex);
                    messageObj = message("MATLAB:engine_codegen:CPPKeywordConflictEnumMember");
                    obj.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.EnumMember, droppedEnums, messageObj);

                    obj.Enumerations(deleteIndex) = []; % Delete the offending enumerations
                end

            end

            if(~isempty(obj.Properties) && ~isempty(obj.Methods))
                properties = [obj.Properties.SectionName];
                methods = [obj.Methods.SectionName];

                propertyAccessors = horzcat("set" + properties, "get" + properties);

                % Delete methods that conflict with property setters / getters, and warn
                conflicts = intersect(propertyAccessors, methods);
                deleteIndex = [];
                if(~isempty(conflicts))

                    for c = conflicts
                        deleteIndex = [deleteIndex find(c == methods)];
                    end
                    
                    droppedMethods = obj.Methods(deleteIndex);
                    messageObj = message("MATLAB:engine_codegen:MethodConflictsWithPropertyAccessor");
                    obj.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassMethod, droppedMethods, messageObj);

                    obj.Methods(deleteIndex) = []; % Delete the offending methods
                end
            end

            % Check if any prop names or method names conflict with C++ keywords
            % Drop the associated code and warn

            % Check the property accessors for C++ keyword conflicts
            if(~isempty(obj.Properties))

                properties = [obj.Properties.SectionName];
                propertyAccessors = horzcat("set" + properties, "get" + properties);

                k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
                conflicts = k.getKeywordConflicts(propertyAccessors);
                if(~isempty(conflicts))

                    deleteIndex = [];
                    for c = conflicts % locate accessors
                        deleteIndex = [deleteIndex, find(c == propertyAccessors)];
                    end

                    % Find offending props without "set" "get" formatting
                    props = [properties, properties]; % mirrored indexing to propertyAccessors
                    conflicts = unique(props(deleteIndex));

                    deleteIndex = [];
                    for c = conflicts % locate related property
                        deleteIndex = [deleteIndex, find(c == properties)];
                    end

                    % TODO consider only dropping the setter or getter that
                    % conflicts instead of the whole thing
                    droppedProps = obj.Properties(deleteIndex);

                    messageObj =  message("MATLAB:engine_codegen:CPPKeywordConflictProperty");
                    obj.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassProperty, droppedProps, messageObj);

                    obj.Properties(deleteIndex) = []; % Delete the offending properties
                end

                % Also check for property accessors that conflict with class name
                properties = [obj.Properties.SectionName]; % refetch
                propertyAccessors = horzcat("set" + properties, "get" + properties);

                conflicts = intersect(propertyAccessors, obj.SectionName);
                if(~isempty(conflicts))

                    deleteIndex = [];

                    for c = conflicts % locate accessors
                        deleteIndex = [deleteIndex, find(c == propertyAccessors)];
                    end

                    % Find offending props without "set" "get" formatting
                    props = [properties, properties]; % mirrored indexing to propertyAccessors
                    conflicts = unique(props(deleteIndex));

                    deleteIndex = [];
                    for c = conflicts % locate related property
                        deleteIndex = [deleteIndex, find(c == properties)];
                    end

                    droppedProps = obj.Properties(deleteIndex);

                    messageObj = message("MATLAB:engine_codegen:PropertyAccessorConflictsWithClassName");
                    obj.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassProperty, droppedProps, messageObj);

                    obj.Properties(deleteIndex) = []; % Delete the offending properties
                end

            end

            % Check the method names for C++ keyword conflicts
            if(~isempty(obj.Methods))
                methods = [obj.Methods.SectionName]; % refetch methods
                tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();
                k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
                conflicts = k.getKeywordConflicts(methods);
                if(~isempty(conflicts))

                    deleteIndex = [];
                    for c = conflicts
                        deleteIndex = [deleteIndex, find(c == methods)];
                    end

                    droppedMethods = obj.Methods(deleteIndex);

                    messageObj = message("MATLAB:engine_codegen:CPPKeywordConflictMethod");
                    obj.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassMethod, droppedMethods, messageObj);

                    obj.Methods(deleteIndex) = []; % Delete the offending methods

                end
            end
        end
    end
end
