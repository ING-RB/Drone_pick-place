classdef SuperclassAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    
    % This class is undocumented and may change in a future release.
    
    % Copyright 2017-2022 The MathWorks, Inc.
    
    methods
        function attribute = SuperclassAttribute(data)
            arguments
                data (1, :) cell
            end
            attribute@matlab.unittest.internal.selectors.SelectionAttribute(data);
        end

        function result = acceptsSuperclass(attribute, selector)
            classSet = attribute.Data;
            result = true(1, numel(classSet));
            for setIdx = 1:numel(classSet)
                result(setIdx) = selector.Constraint.satisfiedBy(classSet{setIdx});
            end
        end
    end
end
