classdef (Sealed) PropertyDefinition < handle & matlab.mixin.CustomDisplay
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        CPPName             string
        OwningClassName     string
        CPPType             string
        MATLABType          string
        Size
        Status              clibgen.internal.DefinitionStatus
    end

    properties(Access=public, Dependent)
        Included            (1,1)   logical
    end

    properties(Access=public)
        Description         (1,1)   string
        DetailedDescription (1,1)   string
    end

    properties(Access=private)
        CPPIncluded         logical
        PropAnnot           internal.mwAnnotation.VariableAnnotation
    end

    properties(Access={?clibgen.api.ClassDefinition})
        SimpleCppType       string
        ValidClibTypes      string
    end

    properties(Access=private, WeakHandle)
        OwningDef           clibgen.api.ClassDefinition
    end

    methods(Access=private)
        function props = makePropertiesString(~, props, name)
            if isfield(props.PropertyList, name)
                val = props.PropertyList.(name);
                props.PropertyList.(name) = categorical(val);
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
            g = makePropertiesString(obj, g, "Size");
            g = makePropertiesBoolean(obj, g, "Included");
        end

        function displayall(obj)
            oneGroupHeading = "";
            oneGroupList = ["CPPName", "OwningClassName", ...
                "CPPType", "MATLABType", "Size", ...
                "Status", "Included", "Description", "DetailedDescription"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, oneGroup);
        end

        function t = makePropertiesTable(props)
            variableNames = {'CPPName', 'CPPType', 'MATLABType', 'Status', 'Included'};
            t = table(arrayfun(@(c)c.CPPName,props)',...
                arrayfun(@(c)string(c.CPPType),props)',...
                arrayfun(@(c)string(c.MATLABType),props)',...
                arrayfun(@(c)c.Included,props)',...
                arrayfun(@(c)c.Status,props)');
            t.Properties.VariableNames = variableNames;
        end

        function updateInInterface(obj, val)
            integStatus = obj.PropAnnot.integrationStatus;
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
            oneGroupList = ["CPPName", "CPPType", "MATLABType", "Size", ...
                "Status", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end

        function displayNonScalarObject(objArr)
            if all(objArr.isvalid)
                disp(makePropertiesTable(objArr));
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

    methods(Access={?clibgen.api.InterfaceDefinition, ...
            ?clibgen.api.ClassDefinition})
        function obj = PropertyDefinition(propAst, clsDef)
            arguments
                propAst (1,1) internal.cxxfe.ast.types.Member
                clsDef  (1,1) clibgen.api.ClassDefinition
            end
            propAnnot = propAst.Annotations(1);
            obj.PropAnnot = propAnnot;
            obj.OwningDef = clsDef;
            obj.CPPName = propAst.Name;
            obj.OwningClassName = propAst.Aggregate.getFullyQualifiedName;
            obj.Description = propAnnot.description;
            obj.DetailedDescription = propAnnot.detailedDescription;
            integStatus = propAnnot.integrationStatus;
            if integStatus.definitionStatus == "FullySpecified"
                obj.Status = clibgen.internal.DefinitionStatus.Complete;
                obj.CPPIncluded = true;
            else % PartiallySpecfied
                obj.Status = clibgen.internal.DefinitionStatus.Incomplete;
                obj.CPPIncluded = false;
            end
            obj.CPPType = propAnnot.cppType;
            obj.SimpleCppType = clibgen.api.InputArgumentDefinition.getSimpleCppType(obj.CPPType);
            obj.MATLABType = propAnnot.mwType;
            % Todo - write helper to convert shapeKind and dimensions info
            % to Size
            if propAnnot.shape == "Scalar"
                size = "1";
            elseif propAnnot.shape == "Array"
                % Todo - concatenate dimensions to string
                size = "Array";
            elseif propAnnot.shape == "nullTerminated"
                size = "nullTerminated";
            else % undefined
                size = "undefined";
            end
            obj.Size = size;
            for mlType = propAnnot.validTypes.toArray
                if string(mlType).startsWith("clib.")
                    obj.ValidClibTypes(end+1) = mlType;
                end
            end
            if ~isempty(obj.ValidClibTypes)
                % usage is clib type which could be class/struct or
                % typedef for void* or fcn ptr
                % Todo: add a better check to determine if type is
                % class/struct or typedef to void* or fcn ptr
                obj.OwningDef.OwningDef.addTypeUsage(obj, obj.SimpleCppType);
            end
        end

        function exclude(obj)
            obj.CPPIncluded = false;
            obj.updateInInterface(false);
        end

        function updateMATLABNameInTypeUsage(obj, ~, MATLABName)
            % update ValidClibTypes
            for idx=1:numel(obj.ValidClibTypes)
                clibType = obj.ValidClibTypes(idx);
                if clibType.startsWith("clib.array")
                     mlNameWithoutClib = extractAfter(MATLABName, "clib.");
                     obj.ValidClibTypes(idx) = "clib.array." + mlNameWithoutClib;
                else
                     obj.ValidClibTypes(idx) = MATLABName;
                end
            end
            % update MATLABType
            if obj.MATLABType == "struct"
                % nothing to update
                return;
            elseif obj.MATLABType.startsWith("clib.array")
                mlNameWithoutClib = extractAfter(MATLABName, "clib.");
                obj.MATLABType = "clib.array." + mlNameWithoutClib;
            else
                obj.MATLABType = MATLABName;
            end
            % update MATLAB type in the annotation
            obj.PropAnnot.mwType = MATLABName;
        end
    end

    methods(Access=public)
        function define(varargin)
        end
    end

    methods
        function set.Included(obj, val)
            arguments
                obj
                val (1,1) logical
            end
            if val == obj.CPPIncluded
                % same as existing; nothing to update
                return;
            end

            if val && obj.Status == "Incomplete"
                % error if status is incomplete
                % Todo: add error msg id
                error("Cannot be included as its incompletely defined");
            end
            obj.CPPIncluded = val;
            obj.updateInInterface(val);
        end

        function val = get.Included(obj)
            val = obj.CPPIncluded;
        end
    end

    methods(Access=?clibgen.api.ClassDefinition)
        function delete(~)
            % Override the delete method to prevent deletion from user
        end
    end
end