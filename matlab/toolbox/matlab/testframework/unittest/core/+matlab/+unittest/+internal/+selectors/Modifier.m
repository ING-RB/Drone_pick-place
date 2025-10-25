classdef (Hidden) Modifier
    %

    % Copyright 2021-2022 The MathWorks, Inc.

    methods (Abstract)
        combined = and(firstModifier, secondModifier);
        combined = or(firstModifier, secondModifier);
    end

    methods (Hidden, Abstract)
        % apply - Apply all modifiers
        %
        %   The apply method returns a modified suite that results from applying
        %   the full modifier specification.
        suite = apply(modifier, suite);

        % getRejector - Return selector for suite creation time optimizations.
        %
        %   The getRejector method returns a selector for use at suite creation time
        %   to short-circuit activities that are known to be rejected.
        selector = getRejector(modifier);
    end

    % Methods to support arbitrary combination of modifiers using & and | in any order.
    methods (Hidden, Abstract, Access=protected)
        % andWithModifier - AND where firstModifier is an arbitrary modifier.
        combined = andWithModifier(secondModifier, firstModifier);

        % andWithSelector - AND where firstSelector is a selector.
        combined = andWithSelector(secondModifier, firstSelector);

        % orWithSelector - OR where firstSelector is a selector.
        combined = orWithSelector(secondModifier, firstSelector);
    end

    methods (Hidden, Sealed, Static)
        function combined = combine(modifiers, operator)
            % combine - Merge a cell array of modifiers into a single modifier.

            import matlab.unittest.internal.selectors.NeverFilterSelector;

            if isempty(modifiers)
                combined = NeverFilterSelector;
                return;
            end

            combined = modifiers{1};
            for idx = 2:numel(modifiers)
                combined = operator(combined, modifiers{idx});
            end
        end
    end
end

% LocalWords:  Rejector
