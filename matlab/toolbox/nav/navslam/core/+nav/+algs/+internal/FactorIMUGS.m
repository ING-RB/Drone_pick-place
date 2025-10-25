classdef FactorIMUGS < factorIMU
%FactorIMUGS creates a factor IMU with additional gravity and bias nodes.
%   Functionally this factor is very similar to factorIMU.
%
%   F = FACTORIMUGS(ID,GYROREADINGS,ACCELREADINGS, IMUPARAMS) creates a
%   factorIMU object, F, with the node identification number set to ID, 
%   and gyroscope readings, and accelerometer readings all set to the
%   corresponding values, respectively.

%   Copyright 2022 The MathWorks, Inc.

%#codegen
    methods (Static, Access = protected)
        function validateIds(ids)
            %validateIds
            nav.algs.internal.validation.validateNodeID_FactorConstruction(ids, 8, 'factorIMUGS', 'ids');
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
                    nav.algs.internal.builtin.FactorIMUGS(int32(obj.NodeID), ...
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
                    nav.algs.internal.codegen.FactorIMUGS(obj.NodeID, ...
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

end