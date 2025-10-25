classdef FunctionTestCaseModifierProvider
    %

    % Copyright 2021 The MathWorks, Inc.

    properties (Constant, Access=private)
        % Note: all instances share the same ModifierMap.
        ModifierMap = containers.Map;
    end

    methods
        function provider = FunctionTestCaseModifierProvider
            mlock;
        end

        function cleaner = set(provider, testName, modifier)
            map = provider.ModifierMap;
            assert(~map.isKey(testName));
            cleaner = onCleanup(@()map.remove(testName));
            map(testName) = modifier; %#ok<NASGU> 
        end

        function modifier = get(provider, testName)
            import matlab.unittest.internal.selectors.getSuiteModifier;

            map = provider.ModifierMap;
            if map.isKey(testName)
                modifier = map(testName);
            else
                modifier = getSuiteModifier;
            end
        end
    end
end

