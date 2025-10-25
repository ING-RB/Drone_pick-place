classdef CallableDefinition < handle & matlab.mixin.CustomDisplay
    %
    % Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=protected)
        CPPSignature                  string
        MATLABSignature               string
        Status                        clibgen.internal.DefinitionStatus
    end

    properties(Access=public, Dependent)
        Included                      (1,1) logical
    end

    properties(SetAccess=private, Dependent)
        CPPParameters                 clibgen.api.InputArgumentDefinition
        IncompleteCPPParameters       clibgen.api.InputArgumentDefinition
    end

    properties(Access=public)
        Description                   (1,1) string
        DetailedDescription           (1,1) string
    end

    properties(Access=protected)
        CPPIncluded                   logical
        TypeUsages                    containers.Map
    end

    properties(Access=private)
        AllCPPParameters              clibgen.api.InputArgumentDefinition
    end

    properties(Access=protected)
        FcnAnnot                      internal.mwAnnotation.FunctionAnnotation
    end

    methods(Access=private)
        function updateInInterface(obj, val)
            integStatus = obj.FcnAnnot.integrationStatus;
            integStatus.inInterface = val;
        end
    end

    methods(Access=protected)
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
            g = makePropertiesString(obj, g, "MATLABSignature");
            g = makePropertiesBoolean(obj, g, "Included");
        end

        function displayNonScalarObject(objArr)
            if all(objArr.isvalid)
                disp(makeCallablesTable(objArr));
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

        function addTypeUsage(obj, defObj, typeInUse)
            if obj.TypeUsages.isKey(typeInUse)
                val = obj.TypeUsages(typeInUse);
                val{end+1} = defObj;
                obj.TypeUsages(typeInUse) = val;
            else
                obj.TypeUsages(typeInUse) = {defObj};
            end
        end

        function obj = CallableDefinition(fcnAnnot)
            arguments
                fcnAnnot (1,1) internal.mwAnnotation.FunctionAnnotation
            end
            obj.FcnAnnot = fcnAnnot;
            obj.Description = obj.FcnAnnot.description;
            obj.DetailedDescription = obj.FcnAnnot.detailedDescription;
            obj.TypeUsages = containers.Map('KeyType', 'char', 'ValueType', 'any');
            integStatus = obj.FcnAnnot.integrationStatus;
            if integStatus.definitionStatus == "FullySpecified"
                obj.Status = clibgen.internal.DefinitionStatus.Complete;
                obj.CPPIncluded = true;
            else % PartiallySpecified
                obj.Status = clibgen.internal.DefinitionStatus.Incomplete;
                obj.CPPIncluded = false;
                obj.MATLABSignature = "<Need more info>";
            end
            obj.CPPSignature = obj.FcnAnnot.cppSignature;
            for argAnnot = obj.FcnAnnot.inputs.toArray
                paramDef = clibgen.api.InputArgumentDefinition(argAnnot);
                obj.AllCPPParameters(end+1) = paramDef;
                if ~isempty(paramDef.ValidClibTypes)
                    % usage is clib type which could be class/struct or
                    % typedef for void* or fcn ptr
                    % Todo: add a better check to determine if type is
                    % class/struct or typedef to void* or fcn ptr
                    typeInUse = paramDef.SimpleCppType;
                    obj.addTypeUsage(paramDef, typeInUse);
                end
            end
        end
    end

    methods(Access=public)
        function res = findArg(obj, position)
            arguments
                obj
                position (1,1) {mustBeInteger}
            end
            if isempty(obj.AllCPPParameters)
                idx = [];
            else
                idx = find([obj.AllCPPParameters.Position] == position);
            end
            if isempty(idx)
                res = clibgen.api.InputArgumentDefinition.empty(1, 0);
            else
                res = obj.AllCPPParameters(idx);
            end
        end
    end

    methods(Access={?clibgen.api.InterfaceDefinition, ...
                       ?clibgen.api.ClassDefinition})
        function exclude(obj)
            obj.CPPIncluded = false;
            obj.updateInInterface(false);
        end

        function updateMATLABNameInTypeUsage(obj, typeInUse, MATLABName)
            if obj.TypeUsages.isKey(typeInUse)
                cellfun(@(def) def.updateMATLABName(MATLABName), obj.TypeUsages(typeInUse));
            end
        end
    end

    methods
        function res = get.CPPParameters(obj)
            if isempty(obj.AllCPPParameters)
                res = obj.AllCPPParameters;
                return;
            end
            idx = find([obj.AllCPPParameters.Status] == "Complete");
            res = obj.AllCPPParameters(idx);
        end

        function res = get.IncompleteCPPParameters(obj)
            if isempty(obj.AllCPPParameters)
                res = obj.AllCPPParameters;
                return;
            end
            idx = find([obj.AllCPPParameters.Status] == "Incomplete");
            res = obj.AllCPPParameters(idx);
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
                if obj.Status == "Incomplete"
                    % error if status is incomplete
                    % Todo: add error msg id
                    error("Cannot be included as its incompletely defined");
                else
                    % check if all type usages are included
                    typesInUse = obj.TypeUsages.keys;
                    for typeInUse = typesInUse
                        if ~obj.OwningDef.isTypeIncluded(string(typeInUse{1}))
                            % Todo: add error msg id
                            error("Cannot be included as the type used is not included");
                        end
                    end
                end
            end
            obj.CPPIncluded = val;
            obj.updateInInterface(val);
        end

        function val = get.Included(obj)
            val = obj.CPPIncluded;
        end
    end

    methods(Access={?clibgen.api.InterfaceDefinition, ...
            ?clibgen.api.ClassDefinition, ?clibgen.api.FunctionDefinition, ...
            ?clibgen.api.MethodDefinition, ?clibgen.api.ConstructorDefinition})
        function delete(obj)
            arrayfun(@(x) delete(x), obj.AllCPPParameters);
        end
    end
end