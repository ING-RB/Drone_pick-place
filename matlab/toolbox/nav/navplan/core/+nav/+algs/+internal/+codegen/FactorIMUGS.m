classdef FactorIMUGS < coder.ExternalDependency & nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%FactorIMUGS Codegen redirect class for nav.algs.internal.builtin.FactorIMUGS 

% Copyright 2022 The MathWorks, Inc.

%#codegen
    methods (Static)
        function name = getDescriptiveName(~)
            %getDescriptiveName
            name = 'FactorIMUGS';
        end

        function isSupported = isSupportedContext(~)
            %isSupportedContext Determine if build context supports external dependency
            isSupported = true;
        end

        function updateBuildInfo(buildInfo, buildConfig)
            %updateBuildInfo

            nav.algs.internal.codegen.portableCeresEigenBuildInfo(buildInfo, buildConfig);
        end
    end
    
    properties
        %FactorInternal
        FactorInternal
    end
    
    methods

        function obj = FactorIMUGS(nodeID, ...
                sampleRate, gravitationalAcceleration, ...
                gyroBiasN, ...
                accelBiasN, ...
                gyroN, ...
                accelN, ...
                gyroRaw, ...
                accelRaw, ...
                sensorTransform)
            %FactorIMU Constructor (for codegen redirect class)
            coder.cinclude('cerescodegen_api.hpp');
            obj.FactorInternal = coder.opaquePtr('void', coder.internal.null);
            obj.FactorInternal = coder.ceval('cerescodegen_constructIMUGSFactor', int32(nodeID), ...
                sampleRate, gravitationalAcceleration, gyroBiasN, accelBiasN, gyroN, accelN, gyroRaw, accelRaw, numel(gyroRaw), sensorTransform);
        end
        
        function delete(obj)
            %delete
            coder.cinclude('cerescodegen_api.hpp');
            
            if ~isempty(obj.FactorInternal)
                coder.ceval('cerescodegen_destructIMUGSFactor', obj.FactorInternal);
            end
        end
        
    end

end

