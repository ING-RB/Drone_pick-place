classdef NeverFilterSelector < matlab.unittest.selectors.Selector
    % NeverFilterSelector - Selector that performs no filtering.
    
    %  Copyright 2013-2024 The MathWorks, Inc.
    
    methods
        function bool = uses(~,~)
            bool = false;
        end
        
        function result = select(~, attributeSet)
            result = true(1, attributeSet.AttributeDataLength);
        end
        
        function bool = reject(~, attributeSet)
            bool = false(1, attributeSet.AttributeDataLength);
        end
        
        % Not used
        notSelector = not(selector);
    end
end

