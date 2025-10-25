classdef (Hidden,HandleCompatible)TestResultDetailsAccessorMixin
    % This class is undocumented and may change in a future release.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(Hidden,GetAccess = protected, SetAccess=immutable)
        TestRunData;
        ForLeafResult;
    end
    
    properties(Hidden, SetAccess=immutable)
        DetailsLocationProvider;
    end
    
    properties (Dependent, SetAccess=private)
        % ResultDetails - Modifier to add data to Details on TestResult
        %
        %   The ResultDetails property provides a modifier that allows a
        %   TestRunnerPlugin instance to add information to the Details property of
        %   TestResult objects.
        ResultDetails
    end
    
    methods(Hidden,Access = protected)
        function mixin = TestResultDetailsAccessorMixin(testRunData,detailsLocationProvider, forLeafResult)
            mixin.TestRunData = testRunData;
            mixin.DetailsLocationProvider = detailsLocationProvider;
            mixin.ForLeafResult = forLeafResult;
        end
    end
    
    methods
        function resultDetails = get.ResultDetails(mixin)
            resultDetails = matlab.unittest.plugins.plugindata.ResultDetails(mixin.TestRunData,...
                mixin.DetailsLocationProvider, mixin.ForLeafResult);
        end
    end
end
