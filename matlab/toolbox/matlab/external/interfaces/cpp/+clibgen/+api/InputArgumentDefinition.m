classdef (Sealed) InputArgumentDefinition < handle & matlab.mixin.CustomDisplay
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        Name            string
        Position        uint32
        CPPType         string
        MATLABType      string
        Direction       string
        Size
        Status          clibgen.internal.DefinitionStatus
    end

    properties(Access=public)
        Description     string
    end

    properties(Access=private)
        ArgAnnot        internal.mwAnnotation.Argument
    end

    properties(Access={?clibgen.api.CallableDefinition})
        SimpleCppType   string
        ValidClibTypes  string
    end

    methods(Access=private)
        function props = makePropertiesString(~, props, name)
            if isfield(props.PropertyList, name)
                val = props.PropertyList.(name);
                props.PropertyList.(name) = categorical(val);
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
            g = makePropertiesString(obj, g, "Direction");
            g = makePropertiesString(obj, g, "Size");
        end

        function t = makeArgumentsTable(args)
            variableNames = {'Name', 'Position', 'CPPType', 'MATLABType', 'Status'};
            t = table(arrayfun(@(c)c.Name,args)',...
                arrayfun(@(c)string(c.Position),args)',...
                arrayfun(@(c)string(c.CPPType),args)',...
                arrayfun(@(c)string(c.MATLABType),args)',...
                arrayfun(@(c)c.Status,args)');
            t.Properties.VariableNames = variableNames;
        end
    end

    methods(Access=protected)
        function oneGroup = getPropertyGroups(obj)
            if ~(obj.isvalid)
                oneGroup = '';
                return;
            end
            oneGroupHeading = "";
            oneGroupList = ["Name", "Position", "CPPType", "MATLABType", ...
                "Direction", "Size", "Status"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end

        function displayNonScalarObject(objArr)
            if all(objArr.isvalid)
                disp(makeArgumentsTable(objArr));
            else
                % Todo: display object array when all are not valid handles
            end
        end
    end

    methods(Static, Access={?clibgen.api.OutputArgumentDefinition, ...
            ?clibgen.api.PropertyDefinition})
        function result = getSimpleCppType(cppType)
            % Eg., cppType is of format [ns::Myclass]Ref for Myclass&
            % extract between "[", "]" gives the simple type name
            result = extractBetween(cppType, "[","]");
        end
    end

    methods(Access={?clibgen.api.CallableDefinition})
        function obj = InputArgumentDefinition(argAnnot)
            arguments
                argAnnot internal.mwAnnotation.Argument
            end
            % Read info from argAnnot and populate props
            obj.ArgAnnot = argAnnot;
            obj.Name = argAnnot.name;
            obj.CPPType = argAnnot.cppType;
            obj.SimpleCppType = clibgen.api.InputArgumentDefinition.getSimpleCppType(obj.CPPType);
            obj.Position = argAnnot.cppPosition;
            obj.MATLABType = argAnnot.mwType;
            % Todo - write helper to convert into category or enum
            if argAnnot.direction == "In"
                direction = "input";
            elseif argAnnot.direction == "Out"
                direction = "output";
            elseif argAnnot.direction == "InOut"
                direction = "inputoutput";
            else
                direction = "undefined";
            end
            obj.Direction = direction;
            % Todo - write helper to convert shapeKind and dimensions info
            % to Size
            if argAnnot.shape == "Scalar"
                size = "1";
            elseif argAnnot.shape == "Array"
                % Todo - concatenate dimensions to string
                size = "Array";
            elseif argAnnot.shape == "nullTerminated"
                size = "nullTerminated";
            else % undefined
                size = "undefined";
            end
            obj.Size = size;
            if obj.MATLABType == "" || obj.Direction == "undefined" ...
                    || obj.Size == "undefined"
                obj.Status = clibgen.internal.DefinitionStatus.Incomplete;
            else
                obj.Status = clibgen.internal.DefinitionStatus.Complete;
            end
            for mlType = argAnnot.validTypes.toArray
                if string(mlType).startsWith("clib.")
                    obj.ValidClibTypes(end+1) = mlType;
                end
            end
            obj.Description = argAnnot.description;
        end

        function updateMATLABName(obj, MATLABName)
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
            obj.ArgAnnot.mwType = MATLABName;
        end
    end

    methods(Access=public)
        function define(varargin)
        end
    end

    methods(Access={?clibgen.api.CallableDefinition})
        function delete(~)
            % Override the delete method to prevent deletion from user
        end
    end
end