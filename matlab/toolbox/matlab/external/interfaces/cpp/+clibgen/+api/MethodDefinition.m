classdef (Sealed) MethodDefinition < clibgen.api.CallableDefinition
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        CPPName         string
        OwningClassName string
        CPPReturn       clibgen.api.OutputArgumentDefinition
    end

    properties(Access=public, Dependent)
        MATLABName      (1,1)   string
    end

    properties(Access=private)
        MLName          string
    end

    properties(Access={?clibgen.api.CallableDefinition}, WeakHandle)
        OwningDef       clibgen.api.ClassDefinition
    end

    methods(Access={?clibgen.api.CallableDefinition})
        function displayall(obj)
            oneGroupHeading = "";
            oneGroupList = ["CPPName", "MATLABName", "OwningClassName", ...
                "CPPSignature", "MATLABSignature", "CPPParameters", ...
                "IncompleteCPPParameters", "CPPReturn", ...
                "Status", "Included", "Description", "DetailedDescription"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, oneGroup);
        end

        function t = makeCallablesTable(methods)
            variableNames = {'CPPName', 'MATLABName', 'Status', 'Included'};
            t = table(arrayfun(@(c)c.CPPName,methods)',...
                arrayfun(@(c)string(c.MATLABName),methods)',...
                arrayfun(@(c)c.Status,methods)',...
                arrayfun(@(c)c.Included,methods)');
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
            oneGroupList = ["CPPName", "MATLABName", "OwningClassName", ...
                "CPPSignature", "MATLABSignature", "Status", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end
    end

    methods(Access={?clibgen.api.ClassDefinition})
        function obj = MethodDefinition(meth, clsDef)
            arguments
                meth    (1,1) internal.cxxfe.ast.types.Method
                clsDef  (1,1) clibgen.api.ClassDefinition
            end
            methAnnot = meth.Annotations(1);
            obj@clibgen.api.CallableDefinition(methAnnot);
            obj.OwningDef = clsDef;
            obj.CPPName = meth.Name;
            obj.OwningClassName = meth.OwningAggregate.getFullyQualifiedName;
            obj.MLName = methAnnot.name;
            if ~isempty(methAnnot.outputs.toArray)
                obj.CPPReturn = clibgen.api.OutputArgumentDefinition(methAnnot.outputs(1));
                if ~isempty(obj.CPPReturn.ValidClibTypes)
                    % usage is clib type which could be class/struct or
                    % typedef for void* or fcn ptr
                    % Todo: add a better check to determine if type is
                    % class/struct or typedef to void* or fcn ptr
                    typeInUse = obj.CPPReturn.SimpleCppType;
                    obj.addTypeUsage(obj.CPPReturn, typeInUse);
                end
            else
                retType = meth.Type.RetType;
                if retType.Name == 'void'
                    % Todo: add a constructor to OutputArgumentDefinition
                    % to handle void type
                end
            end
            allCppTypesInUse = string(obj.TypeUsages.keys);
            if ~isempty(allCppTypesInUse)
                for cppTypeInUse = allCppTypesInUse
                    obj.OwningDef.OwningDef.addTypeUsage(obj, cppTypeInUse);
                end
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
            if numel(newNameElems) ~= 1
                % split the name and check it should only be 1 as only
                % simple names allowed for method renaming
                % Todo: add error msg id
                error("Not in right format");
            end
            if ~isvarname(newName)
                % check it is MATLAB name
                % Todo: add error msg id
                error("Not in right format");
            end
            if obj.OwningDef.isNameInUse(newName)
                % check if name collides with other members in the class
                % Todo: add error msg id
                error("Name collision with other names in class");
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