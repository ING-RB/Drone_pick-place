classdef (Sealed) ConstructorDefinition < clibgen.api.CallableDefinition
%

%   Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        OwningClassName string
    end

    properties(Access={?clibgen.api.CallableDefinition}, WeakHandle)
        OwningDef       clibgen.api.ClassDefinition
    end

    methods(Access={?clibgen.api.CallableDefinition})
        function displayall(obj)
            oneGroupHeading = "";
            oneGroupList = ["OwningClassName", "CPPSignature", ...
                "MATLABSignature", "CPPParameters", "IncompleteCPPParameters", ...
                "Status", "Included", "Description", "DetailedDescription"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
            matlab.mixin.CustomDisplay.displayPropertyGroups(obj, oneGroup);
        end

        function t = makeCallablesTable(ctors)
            variableNames = {'CPPSignature', 'Status', 'Included'};
            t = table(arrayfun(@(c)c.CPPSignature,ctors)',...
                arrayfun(@(c)c.Status,ctors)', ...
                arrayfun(@(c)c.Included,ctors)');
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
            oneGroupList = ["OwningClassName", "CPPSignature", ...
                "MATLABSignature", "Status", "Included"];
            oneGroup = obj.makeGroup(oneGroupHeading, oneGroupList);
        end
    end

    methods(Access={?clibgen.api.ClassDefinition})
        function obj = ConstructorDefinition(meth, clsDef)
            arguments
                meth (1,1) internal.cxxfe.ast.types.Method
                clsDef  (1,1) clibgen.api.ClassDefinition
            end
            methAnnot = meth.Annotations(1);
            obj@clibgen.api.CallableDefinition(methAnnot);
            obj.OwningDef = clsDef;
            obj.OwningClassName = meth.OwningAggregate.getFullyQualifiedName;
            allCppTypesInUse = string(obj.TypeUsages.keys);
            if ~isempty(allCppTypesInUse)
                for cppTypeInUse = allCppTypesInUse
                    obj.OwningDef.OwningDef.addTypeUsage(obj, cppTypeInUse);
                end
            end
        end
    end

    methods(Access={?clibgen.api.InterfaceDefinition, ...
            ?clibgen.api.ClassDefinition, ?clibgen.api.FunctionDefinition, ...
            ?clibgen.api.MethodDefinition, ?clibgen.api.ConstructorDefinition})
        function delete(obj)
            delete@clibgen.api.CallableDefinition(obj);
        end
    end
end