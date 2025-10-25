classdef InstanceIndRuntime < handle 
%

%   Copyright 2018-2019 The MathWorks, Inc.

    methods(Static)

        function verifyArguments(~, matchingRuntimeVersion, ~, chartName, ~, ~ )
            assert(~matchingRuntimeVersion, 'to grandfather sfx versions 19b or earlier, if this function is called, it must be old release and we should error out');
            errId = 'MATLAB:sfx:VersionMismatch';
            msg = getString(message(errId,Stateflow.App.Utils.getChartHyperlink(chartName)));
            error(errId, msg);
        end
    end
end

% LocalWords:  coverageexception Whitebox
