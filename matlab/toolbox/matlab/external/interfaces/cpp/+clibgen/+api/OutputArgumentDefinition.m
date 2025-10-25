classdef (Sealed) OutputArgumentDefinition < handle & matlab.mixin.CustomDisplay
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        Name            string
        CPPType         string
        MATLABType      string
        Size
        Status          clibgen.internal.DefinitionStatus
    end

    properties(Access=public)
        Description     string
    end

    properties(Access=private)
        ArgAnnot        internal.mwAnnotation.Argument
    end

    properties(Access={?clibgen.api.FunctionDefinition, ...
            ?clibgen.api.MethodDefinition})
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
            g = makePropertiesString(obj, g, "Size");
        end
    end

    methods(Access=protected)
        function oneGroup = getPropertyGroups(obj)
            if ~(obj.isvalid)
                oneGroup = '';
                return;
            end
            oneGroupHeading = "";
            oneGroupList = ["Name", "CPPType", "MATLABType", "Size", "Status"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end
    end

    methods(Access={?clibgen.api.FunctionDefinition, ?clibgen.api.MethodDefinition})
        function obj = OutputArgumentDefinition(argAnnot)
            arguments
                argAnnot internal.mwAnnotation.Argument
            end
            % Read info from argAnnot and populate props
            obj.ArgAnnot = argAnnot;
            obj.Name = "RetVal";
            obj.CPPType = argAnnot.cppType;
            obj.SimpleCppType = clibgen.api.InputArgumentDefinition.getSimpleCppType(obj.CPPType);
            obj.MATLABType = argAnnot.mwType;
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
            if obj.MATLABType == "" || obj.Size == "undefined"
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

    methods(Access={?clibgen.api.MethodDefinition, ?clibgen.api.FunctionDefinition})
        function delete(~)
            % Override the delete method to prevent deletion from user
        end
    end
end