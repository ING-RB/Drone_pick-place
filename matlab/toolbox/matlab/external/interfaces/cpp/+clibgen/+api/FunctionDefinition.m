classdef (Sealed) FunctionDefinition < clibgen.api.CallableDefinition
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        CPPName      string
        CPPReturn    clibgen.api.OutputArgumentDefinition
    end

    properties(Access=public, Dependent)
        MATLABName   (1,1)   string
    end

    properties(Access=private)
        MLName       string
    end

    properties(Access={?clibgen.api.CallableDefinition}, WeakHandle)
        OwningDef    clibgen.api.InterfaceDefinition
    end

    methods(Access={?clibgen.api.CallableDefinition})
        function displayall(obj)
            oneGroupHeading = "";
            oneGroupList = ["CPPName", "MATLABName", "CPPSignature", ...
                "MATLABSignature", "CPPParameters", "IncompleteCPPParameters", ...
                "CPPReturn", "Status", "Included", ...
                "Description", "DetailedDescription"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, oneGroup);
        end

        function t = makeCallablesTable(functions)
            variableNames = {'CPPName', 'MATLABName', 'Status', 'Included'};
            t = table(arrayfun(@(c)c.CPPName,functions)',...
                arrayfun(@(c)string(c.MATLABName),functions)',...
                arrayfun(@(c)c.Status,functions)',...
                arrayfun(@(c)c.Included,functions)');
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
            oneGroupList = ["CPPName", "MATLABName", ...
                "CPPSignature", "MATLABSignature", "Status", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end
    end

    methods(Access={?clibgen.api.InterfaceDefinition})
        function obj = FunctionDefinition(fcn, idef)
            arguments
                fcn     (1,1) internal.cxxfe.ast.Function
                idef    (1,1) clibgen.api.InterfaceDefinition
            end
            fcnAnnot = fcn.Annotations(1);
            obj@clibgen.api.CallableDefinition(fcnAnnot);
            obj.OwningDef = idef;
            obj.CPPName = fcn.getFullyQualifiedName;
            obj.MLName = fcnAnnot.name;
            if ~isempty(fcnAnnot.outputs.toArray)
                obj.CPPReturn = clibgen.api.OutputArgumentDefinition(fcnAnnot.outputs(1));
                if ~isempty(obj.CPPReturn.ValidClibTypes)
                    % usage is clib type which could be class/struct or
                    % typedef for void* or fcn ptr
                    % Todo: add a better check to determine if type is
                    % class/struct or typedef to void* or fcn ptr
                    typeInUse = obj.CPPReturn.SimpleCppType;
                    obj.addTypeUsage(obj.CPPReturn, typeInUse);
                end
            else
                retType = fcn.Type.RetType;
                if retType.Name == 'void'
                    % Todo: add a constructor to OutputArgumentDefinition
                    % to handle void type
                end
            end
            allCppTypesInUse = string(obj.TypeUsages.keys);
            if ~isempty(allCppTypesInUse)
                for cppTypeInUse = allCppTypesInUse
                    obj.OwningDef.addTypeUsage(obj, cppTypeInUse);
                end
            end
            if obj.Status == "Complete"
                % Todo: add MATLABSignature
                % obj.MATLABSignature = clibgen.internal.computeMATLABSignature(obj.MLName, ...
                %     obj.CPPParameters, obj.CPPReturn, 1);
            else
                obj.MATLABSignature = "<need more info>";
            end
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
            obj.FcnAnnot.name = newName;
        end

        function val = get.MATLABName(obj)
            val = obj.MLName;
        end
    end

    methods(Access={?clibgen.api.InterfaceDefinition, ...
            ?clibgen.api.ClassDefinition, ?clibgen.api.FunctionDefinition, ...
            ?clibgen.api.MethodDefinition, ?clibgen.api.ConstructorDefinition})
        function delete(obj)
            delete(obj.CPPReturn);
            delete@clibgen.api.CallableDefinition(obj);
        end
    end
end