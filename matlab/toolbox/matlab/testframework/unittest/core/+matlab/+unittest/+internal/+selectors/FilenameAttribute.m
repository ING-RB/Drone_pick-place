classdef FilenameAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    % FilenameAttribute - Attribute for TestSuite element defining filename.
    
    % Copyright 2021-2022 The MathWorks, Inc.
    
    methods
        function attribute = FilenameAttribute(data)
            arguments
                data (1, :) string
            end
            attribute@matlab.unittest.internal.selectors.SelectionAttribute(data);
        end

        function result = acceptsFilename(attribute, selector)
            filenameData = attribute.Data;
            result = true(1, numel(filenameData));
            
            % Only evaluate the constraint on unique name data
            [uniqueNames, ~, nameIdxInData] = unique(filenameData);
            for nameIdx = 1:numel(uniqueNames)
                nameResult = selector.Constraint.satisfiedBy(uniqueNames(nameIdx));
                result(nameIdx==nameIdxInData) = nameResult;
            end
        end
    end
end
