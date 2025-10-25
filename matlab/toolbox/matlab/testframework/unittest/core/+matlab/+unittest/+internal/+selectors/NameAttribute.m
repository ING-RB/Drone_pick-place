classdef NameAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    % NameAttribute - Attribute for TestSuite element name.
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    methods
        function attribute = NameAttribute(data)
            arguments
                data (1, :) {mustBeText}
            end
            attribute@matlab.unittest.internal.selectors.SelectionAttribute(cellstr(data));
        end

        function result = acceptsName(attribute, selector)
            nameData = attribute.Data;
            result = true(size(nameData));
            
            % Only evaluate the constraint on unique name data
            [uniqueNames, ~, nameIdxInData] = unique(nameData);
            for nameIdx = 1:numel(uniqueNames)
                nameResult = selector.Constraint.satisfiedBy(uniqueNames{nameIdx});
                result(nameIdx==nameIdxInData) = nameResult;
            end
        end
    end
end
