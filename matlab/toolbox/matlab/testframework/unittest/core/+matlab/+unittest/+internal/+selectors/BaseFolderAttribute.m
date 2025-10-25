classdef BaseFolderAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    % BaseFolderAttribute - Attribute for TestSuite element defining folder.
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    methods
        function attribute = BaseFolderAttribute(data)
            arguments
                data (1, :) {mustBeText}
            end
            attribute@matlab.unittest.internal.selectors.SelectionAttribute(cellstr(data));
        end

        function result = acceptsBaseFolder(attribute, selector)
            folderData = attribute.Data;
            result = true(1, numel(folderData));
            
            % Only evaluate the constraint once for each unique folder
            [uniqueFolders, ~, folderIdxInData] = unique(folderData);
            for folderIdx = 1:numel(uniqueFolders)
                folderResult = selector.Constraint.satisfiedBy(uniqueFolders{folderIdx});
                result(folderIdx==folderIdxInData) = folderResult;
            end
        end
    end
end
