classdef TestElementModifier
    % This class is undocumented and subject to change in a future release

    % Copyright 2023 The Mathworks, Inc.

    methods (Static)
        function modifiedResults = assignTestElement(results,suite)
            for idx = 1:numel(suite)
                results(idx).TestElement = suite(idx);
            end
            modifiedResults = results;
        end

        function results = clearTestRunner(results)
            [results.TestRunner] = deal(matlab.unittest.TestRunner.empty);
        end
    end
end