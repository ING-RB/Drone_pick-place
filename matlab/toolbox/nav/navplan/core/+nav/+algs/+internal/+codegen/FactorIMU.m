classdef FactorIMU < coder.ExternalDependency & nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%FactorIMU Codegen redirect class for nav.algs.internal.builtin.FactorIMU 

% Copyright 2022 The MathWorks, Inc.

%#codegen
    methods (Static)
        function name = getDescriptiveName(~)
            %getDescriptiveName
            name = 'FactorIMU';
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

        function obj = FactorIMU(nodeID, ...
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
            obj.FactorInternal = coder.ceval('cerescodegen_constructIMUFactor', int32(nodeID), ...
                sampleRate, gravitationalAcceleration, gyroBiasN, accelBiasN, gyroN, accelN, gyroRaw, accelRaw, numel(gyroRaw), sensorTransform);
        end
        
        function delete(obj)
            %delete
            coder.cinclude('cerescodegen_api.hpp');
            
            if ~isempty(obj.FactorInternal)
                coder.ceval('cerescodegen_destructIMUFactor', obj.FactorInternal);
            end
        end

        function res = predict(obj, prevPose, prevVel, prevBias)
            %predict 
            coder.cinclude('cerescodegen_api.hpp');

            predictedPose = coder.nullcopy(zeros(1,7));
            predictedVel = coder.nullcopy(zeros(1,3));
            coder.ceval('cerescodegen_predictIMU', obj.FactorInternal, prevBias, prevPose,...
                prevVel, coder.ref(predictedPose), coder.ref(predictedVel));
            res = struct('PredictedPose',predictedPose, 'PredictedVel', predictedVel);
        end
        
    end

end

