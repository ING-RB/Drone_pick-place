classdef RejectorDecorator < matlab.unittest.selectors.Selector
    % RejectorDecorator - Selector that decorates a selector to only reject.

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Selector (1,1) matlab.unittest.selectors.Selector= ...
            matlab.unittest.internal.selectors.NeverFilterSelector;
    end

    methods (Sealed)
        function decorator = RejectorDecorator(selector)
            decorator.Selector = selector;
        end

        function bool = uses(decorator, attributeClass)
            bool = decorator.Selector.uses(attributeClass);
        end

        function result = select(~, attributeSet)
            result = true(1, attributeSet.AttributeDataLength); % Never filters, only rejects
        end

        function bool = reject(decorator, attributes)
            bool = decorator.Selector.reject(attributes);
        end

        % Not used
        notSelector = not(selector);
    end
end
