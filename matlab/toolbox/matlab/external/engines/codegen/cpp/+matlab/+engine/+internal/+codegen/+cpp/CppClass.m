classdef CppClass
    %CPPCLASS Represents a C++ class
    %   Represents and generates the C++ class, given
    %   language-agnostic MATLAB metadata
    
    %   Copyright 2023 The MathWorks, Inc.
    
    properties
        Class matlab.engine.internal.codegen.ClassTpl;
    end
    
    methods
        function obj = CppClass(Class)
            obj.Class = Class;
        end
        

         function sectionContent = string(obj)

            sectionContent = "[namespaceSection]" + ...
                "[oneIndent]class [className] : public [objectType]<MATLABControllerType> { " + newline +  ...
                "[rootIndent][oneIndent]public:" + newline + newline + ...
                "[comparisonFriendSection]" + ...
                "[constructorSection]" + ...
                "[propertySection]" + ...
                "[methodSection]" + ...
                "[rootIndent][oneIndent]};" + newline + ...
                "[templateSpecSection]"+ newline + ...
                "[comparisonOperatorSection]" + ...
                "[namespaceClose]";

            if(obj.Class.IsEnumeration)
            sectionContent = "[namespaceSection]" + ...
                "[oneIndent]enum class [className] { " + newline +  ...
                "[enumSection]" + ...
                "[rootIndent][oneIndent]};" + ...
                "[namespaceClose]" + newline + ...
                "[enumHelpers]" + newline;
            end

            % Get the namespace opening and closure
            namespaceSection = "";
            namespaceClose = "" + newline;
            [namespaceSection, namespaceClose] = matlab.engine.internal.codegen.cpp.utilcpp.generateNamespace(obj.Class.FullClass);

            % Get the namespace in full "::" notation
            nsParts = split(obj.Class.FullClass, '.');
            fullNameSpace = "";
            if(~isempty(nsParts(1:end-1)))
                fullNameSpace = nsParts(1:end-1) + "::";
                fullNameSpace = string(horzcat(fullNameSpace{:}));
            end

            % Start writing the class
            constructorSection = "[rootIndent][oneIndent][oneIndent]// constructors" + newline;
            for constructorIterator = obj.Class.Constructor
                constructorSection = constructorSection + matlab.engine.internal.codegen.cpp.CppConstructor(constructorIterator).string();
            end

            propertySection = "[rootIndent][oneIndent][oneIndent]// properties" + newline;
            for propertyIterator = obj.Class.Properties
                propertySection = propertySection + matlab.engine.internal.codegen.cpp.CppProperty(propertyIterator).string();
            end

            propertySection = propertySection + newline;

            templateSpecSection = "";
            methodSection = "[rootIndent][oneIndent][oneIndent]// methods" + newline;
            for methodIterator =  obj.Class.Methods
                skipMethod = methodIterator.DefiningClass == "handle" && methodIterator.ShortName == "isvalid"; % skip generating handle.isvalid() method because it is hardcoded in the MATLABHandleObject superclass
                if(~skipMethod)
                    methodSection = methodSection + matlab.engine.internal.codegen.cpp.CppMethod(methodIterator).string();
                    templateSpecSection = templateSpecSection + methodIterator.TemplateSpecSection + newline; % method member specializations must be defined outside the class
                end
            end

            % Generate comparison operator sections, if applicable
            [comparisonOperatorSection, comparisonFriendSection] = generateComparisonOperators(obj);

            enumHelpers = "";
            enumSection = "";
            if(~isempty(obj.Class.Enumerations))
                enumSection = "[rootIndent][oneIndent][oneIndent]// enumerations" + newline;
                for i =  1: length(obj.Class.Enumerations)
                    enumSection = enumSection + "[rootIndent][oneIndent][oneIndent]" + string(obj.Class.Enumerations(i).Name);
                    if(i ~= length(obj.Class.Enumerations))
                        enumSection = enumSection + ",";
                    end
                    enumSection = enumSection + newline;
                end
                enumMemberNames = string({obj.Class.Enumerations.Name});
                mapToStr = "{" + fullNameSpace + obj.Class.SectionName +  "::" + enumMemberNames + ", " + ("""" + enumMemberNames + """") + "}";
                mapFromStr = "{"  + ("""" + enumMemberNames + """") + ", " + fullNameSpace + obj.Class.SectionName + "::" + enumMemberNames + "}";
                mapToStr(1:end-1) = mapToStr(1:end-1) + ",";
                mapFromStr(1:end-1) = mapFromStr(1:end-1) + ",";
                enumHelpers = "namespace {" + newline + ...
                    "[oneIndent]std::string get" + fullNameSpace.replace("::", "_") + obj.Class.SectionName + "String(const " + fullNameSpace + obj.Class.SectionName + "& _enum) {" + newline + ...
                    "[oneIndent][oneIndent]static const std::map<" + fullNameSpace + obj.Class.SectionName +", std::string> " + "map = { " + strjoin(mapToStr) + " };" + newline + ...
                    "[oneIndent][oneIndent]return (map.find(_enum))->second;" + newline + ...
                    "[oneIndent]}" + newline + ...
                    "[oneIndent]" + fullNameSpace + obj.Class.SectionName + " get" + fullNameSpace.replace("::", "_") + obj.Class.SectionName + "Enum(const " + "std::string& _str) {" + newline + ...
                    "[oneIndent][oneIndent]static const std::map<std::string, " + fullNameSpace + obj.Class.SectionName + "> " + "map = { " + strjoin(mapFromStr) + " };" + newline + ...
                    "[oneIndent][oneIndent]return (map.find(_str))->second;" + newline + ...
                    "[oneIndent]}" + newline + ...
                    "}" + newline;
            end

            % Fill in content
            sectionContent = replace(sectionContent, "[namespaceSection]", namespaceSection);
            sectionContent = replace(sectionContent, "[namespaceClose]", namespaceClose);
            sectionContent = replace(sectionContent, "[className]", obj.Class.SectionName);
            sectionContent = replace(sectionContent, "[constructorSection]", constructorSection);
            sectionContent = replace(sectionContent, "[propertySection]", propertySection);
            sectionContent = replace(sectionContent, "[methodSection]", methodSection);
            sectionContent = replace(sectionContent, "[enumSection]", enumSection);
            sectionContent = replace(sectionContent, "[enumHelpers]", enumHelpers);
            sectionContent = replace(sectionContent, "[templateSpecSection]", templateSpecSection); % Fill-in method member specializations outside of the class
            sectionContent = replace(sectionContent, "[comparisonOperatorSection]", comparisonOperatorSection);
            sectionContent = replace(sectionContent, "[comparisonFriendSection]", comparisonFriendSection);

            % Inherit value class or handle class
            if obj.Class.IsHandleClass
                objectType = "MATLABHandleObject";
            else
                objectType = "MATLABObject";
            end
            sectionContent = replace(sectionContent, "[objectType]", objectType);

            % "Expand" root indents
            sectionContent = replace(sectionContent, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Class.IndentLevel));

            % Don't generate the class if it is hidden or abstract
            if(obj.Class.IsHidden || obj.Class.IsAbstract)
                sectionContent = "";
            end

            obj.Class.SectionContent = sectionContent;

        end

        function obj = handleNameConflicts(obj)
            % Identify and handle name or keyword conflicts that
            % will occur in the generated C++ code if unaddressed

            % check property set/gets against constructor/methods
            % check own name, props, methods, constructor, and enums
            % against CPP keywords

            import matlab.engine.internal.codegen.*

            % Handle enum conflicts with C++ keyword
            if(obj.Class.IsEnumeration && ~isempty(obj.Class.Enumerations))
                enums = string({obj.Class.Enumerations.Name});
                k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
                conflicts = k.getKeywordConflicts(enums);
                if(~isempty(conflicts))
                    deleteIndex = [];

                    for c = conflicts
                        deleteIndex = [deleteIndex find(c == enums)];
                    end

                    droppedEnums = obj.Class.Enumerations(deleteIndex);
                    messageObj = message("MATLAB:engine_codegen:CPPKeywordConflictEnumMember");
                    obj.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.EnumMember, droppedEnums, messageObj);

                    obj.Class.Enumerations(deleteIndex) = []; % Delete the offending enumerations
                end

            end

            if(~isempty(obj.Class.Properties) && ~isempty(obj.Class.Methods))
                properties = [obj.Class.Properties.SectionName];
                methods = [obj.Class.Methods.SectionName];

                propertyAccessors = horzcat("set" + properties, "get" + properties);

                % Delete methods that conflict with property setters / getters, and warn
                conflicts = intersect(propertyAccessors, methods);
                deleteIndex = [];
                if(~isempty(conflicts))

                    for c = conflicts
                        deleteIndex = [deleteIndex find(c == methods)];
                    end
                    
                    droppedMethods = obj.Class.Methods(deleteIndex);
                    messageObj = message("MATLAB:engine_codegen:MethodConflictsWithPropertyAccessor");
                    obj.Class.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassMethod, droppedMethods, messageObj);

                    obj.Class.Methods(deleteIndex) = []; % Delete the offending methods
                end
            end

            % Check if any prop names or method names conflict with C++ keywords
            % Drop the associated code and warn

            % Check the property accessors for C++ keyword conflicts
            if(~isempty(obj.Class.Properties))

                properties = [obj.Class.Properties.SectionName];
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
                    droppedProps = obj.Class.Properties(deleteIndex);

                    messageObj =  message("MATLAB:engine_codegen:CPPKeywordConflictProperty");
                    obj.Class.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassProperty, droppedProps, messageObj);

                    obj.Class.Properties(deleteIndex) = []; % Delete the offending properties
                end

                % Also check for property accessors that conflict with class name
                properties = [obj.Class.Properties.SectionName]; % refetch
                propertyAccessors = horzcat("set" + properties, "get" + properties);

                conflicts = intersect(propertyAccessors, obj.Class.SectionName);
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

                    droppedProps = obj.Class.Properties(deleteIndex);

                    messageObj = message("MATLAB:engine_codegen:PropertyAccessorConflictsWithClassName");
                    obj.Class.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassProperty, droppedProps, messageObj);

                    obj.Class.Properties(deleteIndex) = []; % Delete the offending properties
                end

            end

            % Check the method names for C++ keyword conflicts
            if(~isempty(obj.Class.Methods))
                methods = [obj.Class.Methods.SectionName]; % refetch methods
                k = matlab.engine.internal.codegen.cpp.utilcpp.KeywordsCPP();
                conflicts = k.getKeywordConflicts(methods);
                if(~isempty(conflicts))

                    deleteIndex = [];
                    for c = conflicts
                        deleteIndex = [deleteIndex, find(c == methods)];
                    end

                    droppedMethods = obj.Class.Methods(deleteIndex);

                    messageObj = message("MATLAB:engine_codegen:CPPKeywordConflictMethod");
                    obj.ReportObj.recordDropped(matlab.engine.internal.codegen.reporting.UnitType.ClassMethod, droppedMethods, messageObj);

                    obj.Methods(deleteIndex) = []; % Delete the offending methods

                end
            end
        end

        function [comparisonOperatorSection, comparisonFriendSection] = generateComparisonOperators(obj)
            %generateComparisonOperators Generates C++ operator free functions for the given class

            arguments(Output)
                comparisonOperatorSection (1,1) string
                comparisonFriendSection (1,1) string
            end

            % Skeleton for the comparison operator C++ free-function
            comparisonBlueprint = "" + ...
                "bool operator[OperatorSymbol](const [Class]& [Arg1Name], const [Class]& [Arg2Name]) {" + newline +...
                "[oneIndent]std::vector<matlab::data::Array> _args = { [Arg1Name].m_object, [Arg2Name].m_object };" + newline +...
                "[oneIndent]matlab::data::TypedArray<bool> _result_mda = [Arg1Name].m_matlabPtr->feval(u""[ComparisonMethodName]"", _args);" + newline + ...
                "[oneIndent]bool _result = _result_mda[0];" + newline + ...
                "[oneIndent]return _result;" + newline +...
                "}" + newline + newline;
                 
            % Skeleton for listing the comparison operator as a friend
            friendBlueprint = "[rootIndent][oneIndent]friend bool operator[OperatorSymbol](const [Class]& [Arg1Name], const [Class]& [Arg2Name]);" + newline;

            % Detect which comparison operators to implement
            comparisonMethods = ["eq", "ne", "lt", "gt", "le", "ge"];
            cppOperators =      ["==", "!=", "<",  ">",  "<=", ">="]; % corresponding operators in C++
            operatorDictionary = dictionary(comparisonMethods, cppOperators); % links comparison methods to corresponding C++ operator
            classMethods = string.empty(1,0);
            if ~isempty(obj.Class.Methods)
                classMethods = [obj.Class.Methods.ShortName];
            end

            index = ismember(comparisonMethods, classMethods); % logical array for which comparison operators to implement
            comparisonsToImplement = comparisonMethods(index);
 
            % Initialize these operators
            comparisonOperatorSection = "";
            comparisonFriendSection = "";

            % Fill out the comparison section
            for i = 1:length(comparisonsToImplement)
                mName = comparisonsToImplement(i); % MATLAB name of the comparison method
                operatorSymbol = operatorDictionary(mName); % Operator symbol in C++
                fullClass = replace(obj.Class.FullName, ".", "::"); % Fully qualified class name

                % Get argument names for the C++
                arg1Name = "obj1"; % default arg names
                arg2Name = "obj2";
                mMethods = obj.Class.Methods([obj.Class.Methods.ShortName] == mName);
                if ~isempty(mMethods)
                    mMethod = mMethods(1); % ensure we only inspect 1 method
                    % overwrite default arg names if the args exist
                    if mMethod.NumArgIn >= 1
                        arg1Name = mMethod.InputArgs(1).Name;
                        if mMethod.NumArgIn >= 2
                            arg2Name = mMethod.InputArgs(2).Name;
                        end
                    end
                end

                % Replace tokens for comparison free-function
                comparisonFunction = comparisonBlueprint;
                comparisonFunction = replace(comparisonFunction,"[OperatorSymbol]", operatorSymbol);
                comparisonFunction = replace(comparisonFunction,"[Class]", fullClass);
                comparisonFunction = replace(comparisonFunction,"[Arg1Name]", arg1Name);
                comparisonFunction = replace(comparisonFunction,"[Arg2Name]", arg2Name);
                comparisonFunction = replace(comparisonFunction,"[ComparisonMethodName]", mName);

                % add filled out comparison to the comparison section
                comparisonOperatorSection = comparisonOperatorSection + comparisonFunction + newline;

                % Replace the tokens for the friend definition
                friendDefinition = friendBlueprint;
                friendDefinition = replace(friendDefinition,"[OperatorSymbol]", operatorSymbol);
                friendDefinition = replace(friendDefinition,"[Class]", fullClass);
                friendDefinition = replace(friendDefinition,"[Arg1Name]", arg1Name);
                friendDefinition = replace(friendDefinition,"[Arg2Name]", arg2Name);

                % add filled out friend definition
                comparisonFriendSection = comparisonFriendSection + friendDefinition;
            end

        end

    end
end

