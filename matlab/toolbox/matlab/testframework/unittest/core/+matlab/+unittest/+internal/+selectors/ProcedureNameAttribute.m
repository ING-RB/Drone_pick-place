classdef ProcedureNameAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    % ProcedureNameAttribute - Attribute for TestSuite element's procedure name.
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    methods
        function attribute = ProcedureNameAttribute(data)
            arguments
                data (1, :) {mustBeText}
            end
            attribute@matlab.unittest.internal.selectors.SelectionAttribute(cellstr(data));
        end
        
        function result = acceptsProcedureName(attribute, selector)
            procNameData = attribute.Data;
            result = true(1, numel(procNameData));
            
            % Only evaluate the constraint on unique name data
            [uniqueNames, ~, nameIdxInData] = unique(procNameData);
            for nameIdx = 1:numel(uniqueNames)
                nameResult = selector.Constraint.satisfiedBy(uniqueNames{nameIdx});
                result(nameIdx==nameIdxInData) = nameResult;
            end
        end
    end
end
