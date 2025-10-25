classdef FixtureQualificationAdapter
    %

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (SetAccess=private)
        Fixture;
    end

    methods
        function adapter = FixtureQualificationAdapter(fixture)
            adapter.Fixture = fixture;
        end

        function verifyThat(varargin)
            error(message("MATLAB:unittest:QualifyingPlugin:VerifyUsingWithFixture"));
        end

        function assumeThat(adapter, varargin)
            adapter.Fixture.assumeThatQualificationAdapter_(varargin{:});
        end

        function assertThat(adapter, varargin)
            adapter.Fixture.assertThatQualificationAdapter_(varargin{:});
        end

        function fatalAssertThat(adapter, varargin)
            adapter.Fixture.fatalAssertThatQualificationAdapter_(varargin{:});
        end
    end
end
