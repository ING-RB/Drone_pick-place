classdef(Hidden) SingleAttributeSelector < matlab.unittest.selectors.Selector
    % This class is undocumented and may change in a future release.
    
    % SingleAttributeSelector - Selector that uses only one attribute.
    %
    %   The SingleAttributeSelector implements the Selector interface for a
    %   selector that uses only one attribute and can therefore definitively
    %   reject a suite element based on a subset of attributes by returning
    %   false from the select method. Selectors that use multiple attributes
    %   (e.g., AndSelector, OrSelector, NotSelector) cannot use this interface
    %   because they cannot definitely reject a suite element by returning
    %   false from the select method. For selectors that use multiple
    %   attributes, the presence of additional attributes can change the result
    %   of select from false to true.
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties (Abstract, Constant, Hidden, Access=protected)
        % AttributeClassName - Name of the attribute class the selector uses
        AttributeClassName (1,1) string;
        
        % AttributeAcceptMethodName - Name of the attribute method the selector
        %   uses to make a selection determination.
        AttributeAcceptMethodName (1,1) string;
    end
    
    methods (Sealed)
        function notSelector = not(selector)
            import matlab.unittest.selectors.NotSelector;
            notSelector = NotSelector(selector);
        end
    end
    
    methods (Hidden, Sealed)
        function bool = uses(selector, attributeClass)
            bool = attributeClass <= meta.class.fromName(selector.AttributeClassName);
        end
        
        function bool = select(selector, attributeSet)
            attributes = attributeSet.Attributes;
            bool = true(1, attributeSet.AttributeDataLength);

            for currentAttribute = attributes
                attributeSelection = currentAttribute.(selector.AttributeAcceptMethodName)(selector);

                % The selection of SingleAttributeSelectors should only be
                % influenced by one attribute. If evaluating an attribute
                % filters any elements from the suite we can return early
                % because no other attributes should contribute to the
                % selection.
                attributeFiltersSuite = any(~attributeSelection);
                if attributeFiltersSuite
                    bool = attributeSelection;
                    return;
                end
            end
        end
        
        function bool = reject(selector, attributeSet)
            bool = ~selector.select(attributeSet);
        end
        
        function bool = negatedReject(selector, attributeSet)
            if selector.usesAnyOf(attributeSet.Attributes)
                bool = selector.select(attributeSet);
            else
                bool = false(1, attributeSet.AttributeDataLength);
            end
        end
    end
    
    methods (Access=private)
        function bool = usesAnyOf(selector, attributes)
            bool = any(arrayfun(@(attr)selector.uses(metaclass(attr)), attributes));
        end
    end
end

