classdef (Sealed) ClassDefinition < handle & matlab.mixin.CustomDisplay
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        CPPName                 string
    end

    properties(SetAccess=private, Dependent)
        Constructors            clibgen.api.ConstructorDefinition
        Methods                 clibgen.api.MethodDefinition
        Properties              clibgen.api.PropertyDefinition
        IncompleteConstructors  clibgen.api.ConstructorDefinition
        IncompleteMethods       clibgen.api.MethodDefinition
        IncompleteProperties    clibgen.api.PropertyDefinition
        HasIncompleteMembers    logical
        IsConstructibleInMATLAB logical
    end

    properties(Access=public, Dependent)
        Included                (1,1)   logical
        MATLABName              (1,1)   string
    end

    properties(Access=public)
        Description             (1,1)   string
        DetailedDescription     (1,1)   string
    end

    properties(Access=private)
        AllConstructors         clibgen.api.ConstructorDefinition
        AllMethods              clibgen.api.MethodDefinition
        AllProperties           clibgen.api.PropertyDefinition
        CPPIncluded             logical
        MLName                  string
        ConstructorsMap         containers.Map
        MethodsMap              containers.Map
    end

    properties(Access=private)
        ClassAnnot              internal.mwAnnotation.ClassAnnotation        
    end
    properties(Access={?clibgen.api.MethodDefinition, ?clibgen.api.ConstructorDefinition, ...
            ?clibgen.api.PropertyDefinition}, WeakHandle)
        OwningDef    clibgen.api.InterfaceDefinition
    end

    methods(Access=private)
        function addEntryToConstructorsMap(obj, ctorDef)
            % cppName = ctorDef.CPPName;
            % % Todo: replace parameterTypes with data from ctorDef
            % % parameterTypes = strings(1,0);
            % % pair = {parameterTypes, fcnDef};
            % if obj.FunctionsMap.isKey(cppName)
            %     val = obj.FunctionsMap(cppName);
            %     val{end+1} = ctorDef; % Todo: replace fcnDef with pair
            %     obj.FunctionsMap(cppName) = val;
            % else
            %      % Todo: replace fcnDef with pair
            %     obj.FunctionsMap(cppName) = {ctorDef};
            % end
        end

        function addEntryToMethodsMap(obj, methDef)
            cppName = methDef.CPPName;
            % Todo: replace parameterTypes with data from methodDef
            % parameterTypes = strings(1,0);
            % pair = {parameterTypes, methodDef};
            if obj.MethodsMap.isKey(cppName)
                val = obj.MethodsMap(cppName);
                val{end+1} = methDef; % Todo: replace methDef with pair
                obj.MethodsMap(cppName) = val;
            else
                 % Todo: replace methDef with pair
                obj.MethodsMap(cppName) = {methDef};
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
            g = makePropertiesBoolean(obj, g, "IsConstructibleInMATLAB");
            g = makePropertiesBoolean(obj, g, "HasIncompleteMembers");
            g = makePropertiesBoolean(obj, g, "Included");
        end

        function displayall(obj)
            oneGroupHeading = "";
            oneGroupList = ["CPPName", "MATLABName", "Constructors", ...
                "Methods", "Properties", "IncompleteConstructors", ...
                "IncompleteMethods", "IncompleteProperties", ...
                "HasIncompleteMembers", "IsConstructibleInMATLAB", ...
                "Description", "DetailedDescription", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, oneGroup);
        end

        function t = makeClassesTable(classes)
            variableNames = {'CPPName','MATLABName','HasIncompleteMembers', ...
                'IsConstructibleInMATLAB','Included'};
            t = table(arrayfun(@(c)c.CPPName,classes)',...
                arrayfun(@(c)string(c.MATLABName),classes)',...
                arrayfun(@(c)c.Included,classes)',...
                arrayfun(@(c)c.IsConstructibleInMATLAB,classes)',...
                arrayfun(@(c)c.HasIncompleteMembers,classes)');
            t.Properties.VariableNames = variableNames;
        end

        function updateInInterface(obj, val)
            integStatus = obj.ClassAnnot.integrationStatus;
            integStatus.inInterface = val;
        end
    end

    methods(Access=protected)
        function oneGroup = getPropertyGroups(obj)
            if ~(obj.isvalid)
                oneGroup = '';
                return;
            end
            oneGroupHeading = "";
            oneGroupList = ["CPPName", "MATLABName", "HasIncompleteMembers", ...
                "IsConstructibleInMATLAB", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end

        function displayNonScalarObject(objArr)
            if all(objArr.isvalid)
                disp(makeClassesTable(objArr));
            else
                % Todo: display object array when all are not valid handles
            end
        end

        function footer = getFooter(obj)
            if ~(obj.isvalid)
                footer = '';
                return;
            end
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

    methods(Access=?clibgen.api.MethodDefinition)
        function res = isNameInUse(obj, name)
            arguments
                obj
                name (1,1) string
            end
            symsUseMATLABName = @(syms, mlName) (~isempty(obj.(syms)) && ...
                any([obj.(syms).MATLABName] == mlName));
            res = symsUseMATLABName('AllMethods', name) || ...
                symsUseMATLABName('AllProperties', name);
        end
    end

    methods(Access=?clibgen.api.InterfaceDefinition)
        function obj = ClassDefinition(clsType, idef)
            arguments
                clsType (1,1) internal.cxxfe.ast.types.Type
                idef    (1,1) clibgen.api.InterfaceDefinition
            end
            obj.OwningDef = idef;
            clsAnnot = clsType.Annotations(1);
            obj.ClassAnnot = clsAnnot;
            obj.MLName = clsAnnot.name;
            obj.CPPIncluded = true;
            obj.Description = clsAnnot.description;
            obj.DetailedDescription = clsAnnot.detailedDescription;
            obj.CPPName = clsType.getFullyQualifiedName;

            obj.AllConstructors    = clibgen.api.ConstructorDefinition.empty(1,0);
            obj.AllMethods         = clibgen.api.MethodDefinition.empty(1,0);
            obj.AllProperties      = clibgen.api.PropertyDefinition.empty(1,0);

            obj.ConstructorsMap = containers.Map('KeyType','char','ValueType','any');
            obj.MethodsMap      = containers.Map('KeyType','char','ValueType','any');

            % iterate thru ctors, meths
            for meth = clsType.Methods.toArray
                if isempty(meth.Annotations)
                    continue;
                end
                methAnnot = meth.Annotations(1);
                defStatus = methAnnot.integrationStatus.definitionStatus;
                if defStatus == "FullySpecified" || defStatus == "PartiallySpecified"
                    if meth.SpecialKind == internal.cxxfe.ast.SpecialFunctionKind.Constructor || ...
                        meth.SpecialKind == internal.cxxfe.ast.SpecialFunctionKind.CopyConstructor
                        ctorDef = clibgen.api.ConstructorDefinition(meth, obj);
                        obj.AllConstructors(end+1) = ctorDef;
                        obj.addEntryToConstructorsMap(ctorDef);
                    elseif meth.SpecialKind == internal.cxxfe.ast.SpecialFunctionKind.None 
                        methDef = clibgen.api.MethodDefinition(meth, obj);
                        obj.AllMethods(end+1) = methDef;
                        obj.addEntryToMethodsMap(methDef);
                    end
                elseif defStatus == "Unsupported"
                    uannot = meth.Annotations(2);
                    if(uannot.symbolKind == "SymbolNotReported")
                        continue;

                    else
                        obj.OwningDef.UnsupportedMethods(end+1) = clibgen.api.UnsupportedMethod(...
                            uannot.fileName,...
                            uannot.filePath,...
                            uannot.line,...
                            uannot.reason, ...
                            uannot.className, ...
                            uannot.cppSignature,...
                            uannot.cppName ...
                            );

                    end
                    meth.Annotations.removeAt(2);
                end
            end
            % iterate thru props
            for prop = clsType.Members.toArray
                if isempty(prop.Annotations)
                    continue;
                end
                propAnnot = prop.Annotations(1);
                defStatus = propAnnot.integrationStatus.definitionStatus;
                if defStatus == "FullySpecified" || defStatus == "PartiallySpecified"
                    obj.AllProperties(end+1) = clibgen.api.PropertyDefinition(prop, obj);
                elseif defStatus == "Unsupported"
                    % create unsupported prop and add to
                    % obj.Parent.UnsupportedProperties
                    uannot = prop.Annotations(2);
                    if uannot.symbolKind ~= "SymbolNotReported"
                    obj.OwningDef.UnsupportedProperties(end+1) = clibgen.api.UnsupportedProperty(...
                            uannot.fileName,...
                            uannot.filePath,...
                            uannot.line,...
                            uannot.reason,...
                            obj.CPPName,...
                            uannot.cppName, ...
                            uannot.cppType...
                            );
                    end
                    prop.Annotations.removeAt(2);
                end
            end
        end
    end

    methods(Access=public)
        function findConstructor(obj, varargin)
            % Todo:
            % validate varargin is 2, CPPParameters and string arr
            % find def obj from obj.ConstructorsMap
           % if isKey(obj.ConstructorsMap, varargin{2})
           %      res = obj.ConstructorsMap(varargin{2});
           %      res = res{:};
           %  else
           %      res = clibgen.api.ConstructorDefinition.empty(1, 0);
           %  end
        end

        function res = findMethod(obj, CPPName, varargin)
            % Todo:
            % validate CPPName, varargin is 2, CPPParameters and string arr
            % find def obj from obj.MethodsMap
           if isKey(obj.MethodsMap, CPPName)
                res = obj.MethodsMap(CPPName);
                res = [res{:}];
            else
                res = clibgen.api.MethodDefinition.empty(1, 0);
            end
        end

        function res = findProperty(obj, CPPName)
            arguments
                obj
                CPPName (1,1) string
            end
            if isempty(obj.AllProperties)
                idx = [];
            else
                idx = find([obj.AllProperties.CPPName] == CPPName);
            end
            if isempty(idx)
                res = clibgen.api.PropertyDefinition.empty(1, 0);
            else
                res = obj.AllProperties(idx);
            end
        end
    end

    methods
        function res = get.Constructors(obj)
            if isempty(obj.AllConstructors)
                res = obj.AllConstructors;
                return;
            end
            idx = find([obj.AllConstructors.Status] == "Complete");
            res = obj.AllConstructors(idx);
        end

        function res = get.Methods(obj)
            if isempty(obj.AllMethods)
                res = obj.AllMethods;
                return;
            end
            idx = find([obj.AllMethods.Status] == "Complete");
            res = obj.AllMethods(idx);
        end

        function res = get.Properties(obj)
            if isempty(obj.AllProperties)
                res = obj.AllProperties;
                return;
            end
            idx = find([obj.AllProperties.Status] == "Complete");
            res = obj.AllProperties(idx);
        end

        function res = get.IncompleteConstructors(obj)
            if isempty(obj.AllConstructors)
                res = obj.AllConstructors;
                return;
            end
            idx = find([obj.AllConstructors.Status] == "Incomplete");
            res = obj.AllConstructors(idx);
        end

        function res = get.IncompleteMethods(obj)
            if isempty(obj.AllMethods)
                res = obj.AllMethods;
                return;
            end
            idx = find([obj.AllMethods.Status] == "Incomplete");
            res = obj.AllMethods(idx);
        end

        function res = get.IncompleteProperties(obj)
            if isempty(obj.AllProperties)
                res = obj.AllProperties;
                return;
            end
            idx = find([obj.AllProperties.Status] == "Incomplete");
            res = obj.AllProperties(idx);
        end

        function res = get.HasIncompleteMembers(obj)
            % check if any ctor or meth or prop is incomplete
            res =  ~isempty(obj.IncompleteConstructors) || ...
                ~isempty(obj.IncompleteMethods) || ~isempty(obj.IncompleteProperties);
        end

        function res = get.IsConstructibleInMATLAB(obj)
            res = ~isempty(obj.AllConstructors) && any(obj.AllConstructors.Included);
        end

        function set.MATLABName(obj, newName)
            arguments
                obj
                newName (1,1) string
            end
            newName = string(newName);
            newNameElems = split(newName, '.');
            currNameElems = split(obj.MLName, '.');
            if numel(newNameElems) ~= numel(currNameElems)
                % split the name and compare the size with existing
                % Todo: add error msg id
                error("Not in right format");
            end
            if ~all(newNameElems(1:end-1) == currNameElems(1:end-1))
                % check all portions are same except for last one
                % Todo: add error msg id
                error("Not in right format");
            end
            simpleName = newNameElems(end);
            if ~isvarname(simpleName)
                % check last portion is MATLAB name
                % Todo: add error msg id
                error("Not in right format");
            end
            if obj.OwningDef.isMATLABNameInUse(newName)
                % check if name collides with other names in the library
                % Todo: add error msg id
                error("Name collision with other names in library");
            end
            % update MATLAB name in the definition
            obj.MLName = newName;
            % update MATLAB name in the annotation
            obj.ClassAnnot.name = newName;
            % Update MATLABName in all usages of the type
            obj.OwningDef.updateMATLABNameInTypeUsage(obj.CPPName, newName);
        end

        function val = get.MATLABName(obj)
            val = obj.MLName;
        end

        function set.Included(obj, val)
            arguments
                obj
                val (1,1) logical
            end
            if val == obj.CPPIncluded
                % same as existing; nothing to update
                return;
            end
            if val
                % if true, include the class
                obj.CPPIncluded = true;
            else
                % if false, exclude the usages of the class
                obj.OwningDef.excludeTypeUsage(obj.CPPName);
                obj.CPPIncluded = false;
            end
            % update annotation
            obj.updateInInterface(val);
        end

        function val = get.Included(obj)
            val = obj.CPPIncluded;
        end
    end

    methods(Access=?clibgen.api.InterfaceDefinition)
        function delete(obj)
            % Override the delete method to prevent deletion from user
            % delete all children recursively
            arrayfun(@(x) delete(x), obj.AllConstructors);
            arrayfun(@(x) delete(x), obj.AllMethods);
            arrayfun(@(x) delete(x), obj.AllProperties);
        end
    end
end