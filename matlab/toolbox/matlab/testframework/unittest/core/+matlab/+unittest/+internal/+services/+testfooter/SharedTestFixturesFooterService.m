classdef SharedTestFixturesFooterService < matlab.unittest.internal.services.testfooter.TestFooterService
    %

    % Copyright 2022 The MathWorks, Inc.

    methods (Access=protected)
        function footer = getFooter(~, suite, ~)
            import matlab.unittest.fixtures.Fixture;
            import matlab.unittest.internal.diagnostics.PlainString;
            import matlab.unittest.internal.diagnostics.CommandHyperlinkableString;

            fixtures = [Fixture.empty, suite.SharedTestFixtures];
            fixtures = fixtures.getUniqueFixtureInstances;
            fixtureNames = arrayfun(@class, fixtures, UniformOutput=false).';
            fixtureNames = unique(fixtureNames);
            numFixtures = numel(fixtureNames);

            if numFixtures == 0
                label = getString(message("MATLAB:unittest:TestSuite:ZeroSharedTestFixturesFooter"));
            elseif numFixtures == 1
                label = getString(message("MATLAB:unittest:TestSuite:SingleSharedTestFixtureFooter"));
            else
                label = getString(message("MATLAB:unittest:TestSuite:MultipleSharedTestFixturesFooter", numFixtures));
            end

            % Early return if hyperlinking is not necessary
            if isempty(fixtureNames)
                footer = PlainString(label);
                return;
            end

            commandToDisplayFixtures = sprintf("matlab.unittest.internal.diagnostics.displayCellArrayAsTable({%s}, {'%s'})", ...
                sprintf("'%s';", fixtureNames{:}), "FixtureName");
            footer = CommandHyperlinkableString(label, commandToDisplayFixtures);
        end
    end
end

% LocalWords:  Hyperlinkable
