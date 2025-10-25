classdef MATLABMethodCoverageInfoService < matlab.unittest.internal.services.coverage.MethodCoverageInfoService
    % MATLABMethodCoverageInfoService is used to get method coverage
    % information for a MATLAB file

    % Copyright 2024 The MathWorks, Inc.

    methods
        function methodCoverageInfoList = publish(~,fileCoveargeInfo)
            methodCoverageInfo = matlab.unittest.internal.coverage.MATLABMethodCoverageInfo(fileCoveargeInfo);
            methodCoverageInfoList = methodCoverageInfo.getMethodCoverageInfoList();
        end
    end

    methods(Static)
        function tf = supports(fileCoverageInfo)
            [~,~,ext] = fileparts(fileCoverageInfo.FullName);
            tf =  ismember(ext, {'.m', '.mlx', '.mlapp'});
        end
    end
end
