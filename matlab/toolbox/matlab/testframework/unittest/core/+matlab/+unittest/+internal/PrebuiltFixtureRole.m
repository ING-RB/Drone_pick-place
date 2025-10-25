classdef PrebuiltFixtureRole < matlab.unittest.internal.FixtureRole
    %

    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties (Constant, Access=protected)
        IsSetUpByRunner logical = false;
        IsUserVisible logical = true;
    end
    
    methods (Sealed)
        function roles = PrebuiltFixtureRole(fixtures)
            roles = roles@matlab.unittest.internal.FixtureRole(fixtures);
        end
        
        function role = constructFixture(role, ~, detailsLocationProvider)
            role.DetailsLocationProvider = detailsLocationProvider;
        end
        
        function setupFixture(~, ~)
        end
        
        function teardownFixture(~, ~)
        end
        
        function deleteFixture(~)
        end
    end
end

