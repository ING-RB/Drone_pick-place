classdef FixtureService < matlab.automation.internal.services.Service
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2023 The MathWorks, Inc.

    methods (Abstract)
        fixtures = provideFixtures(service, rootFolder)
    end

    methods (Sealed)
        function fulfill(services, liaison)
            arguments
                services matlab.buildtool.internal.services.fixtures.FixtureService
                liaison (1,1) matlab.buildtool.internal.services.fixtures.FixtureLiaison
            end

            import matlab.buildtool.internal.fixtures.Fixture;

            fixtures = arrayfun(@(s)s.provideFixtures(liaison.RootFolder), services, UniformOutput=false);
            liaison.Fixtures = [fixtures{:} Fixture.empty(1,0)];
        end
    end
end
