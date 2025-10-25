classdef TagAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    % TagAttribute - Attribute for TestSuite element tag.
    
    % Copyright 2014-2022 The MathWorks, Inc.
    
    methods
        function attribute = TagAttribute(data)
            arguments
                data (1, :) cell
            end
            attribute = attribute@matlab.unittest.internal.selectors.SelectionAttribute(data);
        end
        
        function result = acceptsTag(attribute, selector)
            import matlab.unittest.constraints.AnyCellOf;
            tagSets = attribute.Data;
            result = true(1, numel(tagSets));
            for setIdx = 1:numel(tagSets)
                proxy = AnyCellOf(tagSets{setIdx});
                result(setIdx) = proxy.satisfiedBy(selector.Constraint);
            end
        end
    end
end
