classdef (Sealed) EnumDefinition < handle & matlab.mixin.CustomDisplay
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        CPPName                 string
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
        CPPIncluded             logical
        MLName                  string
        EnumAnnot               internal.mwAnnotation.EnumAnnotation
    end

    properties(Access=private, WeakHandle)
        OwningDef               clibgen.api.InterfaceDefinition
    end

    methods(Access=private)
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
            g = makePropertiesBoolean(obj, g, "Included");
        end

        function displayall(obj)
            oneGroupHeading = "";
            oneGroupList = ["CPPName", "MATLABName", ...
                "Description", "DetailedDescription", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, oneGroup);
        end

        function t = makeEnumsTable(enums)
            variableNames = {'CPPName','MATLABName','Included'};
            t = table(arrayfun(@(c)c.CPPName,enums)',...
                arrayfun(@(c)string(c.MATLABName),enums)',...
                arrayfun(@(c)c.Included,enums)');
            t.Properties.VariableNames = variableNames;
        end

        function updateInInterface(obj, val)
            integStatus = obj.EnumAnnot.integrationStatus;
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
            oneGroupList = ["CPPName", "MATLABName", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end

        function displayNonScalarObject(objArr)
            if all(objArr.isvalid)
                disp(makeEnumsTable(objArr));
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

    methods(Access=?clibgen.api.InterfaceDefinition)
        function obj = EnumDefinition(enumType, idef)
            arguments
                enumType (1,1) internal.cxxfe.ast.types.Type
                idef    (1,1) clibgen.api.InterfaceDefinition
            end
            obj.OwningDef = idef;
            enumAnnot = enumType.Annotations(1);
            obj.EnumAnnot = enumAnnot;
            obj.CPPName = enumType.getFullyQualifiedName;
            obj.MLName = enumAnnot.name;
            obj.Description = enumAnnot.description;
            obj.DetailedDescription = enumAnnot.detailedDescription;
            obj.CPPIncluded = true;
        end
    end

    methods
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
            obj.EnumAnnot.name = newName;
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
                % if true, include the enum
                obj.CPPIncluded = true;
            else
                % if false, exclude the usages of the type
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
        function delete(~)
            % Override the delete method to prevent deletion from user
        end
    end
end