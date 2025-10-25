classdef FactorIMUGST < factorIMU
%FactorIMUGST creates a factor IMU with additional gravity and bias nodes.
%   Functionally this factor is very similar to factorIMU.
%
%   F = FACTORIMUGST(ID,GYROREADINGS,ACCELREADINGS, IMUPARAMS) creates a
%   factorIMUGST object, F, with the node identification number set to ID, 
%   and gyroscope readings, and accelerometer readings all set to the
%   corresponding values, respectively.

%   Copyright 2023 The MathWorks, Inc.

%#codegen
    methods (Static, Access = protected)
        function validateIds(ids)
            %validateIds
            nav.algs.internal.validation.validateNodeID_FactorConstruction(ids, 9, 'factorIMUGST', 'ids');
        end
    end

    methods (Access={?factorGraph,?factorIMU})
        function internalObj = createBuiltinObject(obj)
            %createBuiltinObject
            gyroBiasN = obj.GyroscopeBiasNoise';
            accelBiasN = obj.AccelerometerBiasNoise';
            gyroN = obj.GyroscopeNoise';
            accelN = obj.AccelerometerNoise';
            gyroRaw = obj.GyroscopeReadings';
            accelRaw = obj.AccelerometerReadings';
            
            sensorTransform = tform(obj.SensorTransform)';

            % Define gravitational vector to be added to rotated
            % accelerometer readings to obtain linear accelerations without
            % gravity.
            if strcmp(obj.ReferenceFrame, "ENU")
                gravitationalAcceleration = [0,0,fusion.internal.ConstantValue.Gravity];
            else % strcmp(obj.ReferenceFrame, "NED")
                gravitationalAcceleration = [0,0, -fusion.internal.ConstantValue.Gravity];
            end
            
            if coder.target('MATLAB')
                % Call MCOS method in MATLAB
                internalObj = ...
                    nav.algs.internal.builtin.FactorIMUGST(int32(obj.NodeID), ...
                    obj.SampleRate, gravitationalAcceleration, ...
                    gyroBiasN(:), ...
                    accelBiasN(:), ...
                    gyroN(:), ...
                    accelN(:), ...
                    gyroRaw(:), ...
                    accelRaw(:), ...
                    sensorTransform(:));
            else
                % Generate code through external dependency
                internalObj = ...
                    nav.algs.internal.codegen.FactorIMUGST(obj.NodeID, ...
                    obj.SampleRate, gravitationalAcceleration, ...
                    gyroBiasN(:), ...
                    accelBiasN(:), ...
                    gyroN(:), ...
                    accelN(:), ...
                    gyroRaw(:), ...
                    accelRaw(:), ...
                    sensorTransform(:));
            end
        end

    end

    methods
        function [predictedPose, predictedVel] = predict(obj, prevPose, prevVel, prevBias, gRot, scale, sensorTform)
            %predict Predict pose and velocity based on the previously
            %   estimated pose, velocity, IMU biases, gravity rotation,
            %   sensor transform and the collected raw IMU readings as
            %   saved in GyroscopeReadings and AccelerometerReadings
            %   properties.

            internalObj = obj.createBuiltinObject();
            prevPose = [prevPose(1:3), prevPose(5:7), prevPose(4)];
            sensorTform = [sensorTform(1:3), sensorTform(5:7), sensorTform(4)];
            result = internalObj.predict(prevPose, prevVel, prevBias, gRot, scale, sensorTform);
            poseTmp = result.PredictedPose;
            predictedPose = [poseTmp(1:3), poseTmp(7), poseTmp(4:6)] ;
            predictedVel = result.PredictedVel;
        end
    end

end