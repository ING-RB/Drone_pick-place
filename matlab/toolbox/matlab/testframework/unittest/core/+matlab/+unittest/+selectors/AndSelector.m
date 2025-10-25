classdef (Sealed) AndSelector < matlab.unittest.selectors.Selector
    % AndSelector - Boolean conjunction of two selectors.
    %   An AndSelector is produced when the "&" operator is used to denote the
    %   conjunction of two selectors.
    
    %  Copyright 2013-2024 The MathWorks, Inc.
    
    properties (SetAccess=private)
        % FirstSelector - The left selector that is being AND'ed.
        FirstSelector (1,1) matlab.unittest.selectors.Selector = ...
            matlab.unittest.internal.selectors.NeverFilterSelector;
        
        % SecondSelector - The right selector that is being AND'ed.
        SecondSelector (1,1) matlab.unittest.selectors.Selector = ...
            matlab.unittest.internal.selectors.NeverFilterSelector;
    end
    
    methods (Access=?matlab.unittest.selectors.Selector)
        function andSelector = AndSelector(firstSelector, secondSelector)
            andSelector.FirstSelector = firstSelector;
            andSelector.SecondSelector = secondSelector;
        end
    end
    
    methods (Sealed)
        function notSelector = not(andSelector)
            notSelector = ~andSelector.FirstSelector | ~andSelector.SecondSelector;
        end
    end
    
    methods (Hidden)
        function bool = uses(selector, attributeClass)
            bool = selector.FirstSelector.uses(attributeClass) || ...
                selector.SecondSelector.uses(attributeClass);
        end
        
        function results = select(selector, attributeSet)
            results = selector.FirstSelector.select(attributeSet);

            % Implement logicial short-circuit behavior. We only need to
            % evaluate the second selector where first selector returned
            % true
            if all(~results)
                return
            else
                subsetIndices = results;
                secondSelectorSet = attributeSet.dataSubset(subsetIndices);
                secondSelection = selector.SecondSelector.select(secondSelectorSet);
                results(subsetIndices) = results(subsetIndices) & secondSelection;
            end
        end
        
        function results = reject(selector, attributeSet)
            results = selector.FirstSelector.reject(attributeSet);

            % Implement logicial short-circuit behavior. We only need to
            % evaluate the second selector where first selector returned
            % false
            if all(results)
                return
            else
                subsetIndices = ~results;
                secondSelectorSet = attributeSet.dataSubset(subsetIndices);
                secondRejection = selector.SecondSelector.reject(secondSelectorSet);
                results(subsetIndices) = results(subsetIndices) | secondRejection;
            end
        end
    end
end

% LocalWords:  AND'ed
