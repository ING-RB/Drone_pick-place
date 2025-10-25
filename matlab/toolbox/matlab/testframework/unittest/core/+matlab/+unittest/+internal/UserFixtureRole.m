classdef UserFixtureRole < matlab.unittest.internal.FixtureRole
    %

    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties (Constant, Access=protected)
        IsSetUpByRunner logical = true;
        IsUserVisible logical = true;
    end
    
    methods (Sealed)
        function roles = UserFixtureRole(fixtures)
            roles = roles@matlab.unittest.internal.FixtureRole(fixtures);
        end
        
        function role = constructFixture(role, callback, locationProvider)
            role.DetailsLocationProvider = locationProvider;
            role.Instance = callback(role);
        end
        
        function setupFixture(role, callback)
            callback(role);
        end
        
        function teardownFixture(role, callback)
            callback(role);
        end
        
        function deleteFixture(role)
            delete(role.Instance);
        end
    end
end

