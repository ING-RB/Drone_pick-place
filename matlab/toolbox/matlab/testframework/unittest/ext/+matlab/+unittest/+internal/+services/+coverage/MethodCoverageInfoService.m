classdef MethodCoverageInfoService < matlab.unittest.internal.services.Service
    % MethodCoverageInfoService - Interface for method coverage info services

    % Copyright 2024 The MathWorks, Inc.
    methods (Abstract)
        methodCoverageInfoList = publish(fileCoverageInfo)
    end
    methods (Abstract, Static)
        supports(fileCoverageInfo)
    end

    methods (Sealed)
        function methodCoverageInfoList = fulfill(services,fileCoverageInfo)
            for serviceIndex = 1:length(services)
                if services(serviceIndex).supports(fileCoverageInfo)
                    methodCoverageInfoList = services(serviceIndex).publish(fileCoverageInfo);
                end
            end
        end
    end
end
