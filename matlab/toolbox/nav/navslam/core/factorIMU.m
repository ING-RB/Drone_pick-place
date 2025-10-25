classdef factorIMU
%FACTORIMU Convert IMU readings into factor
%
%   F = FACTORIMU(ID,GYROREADINGS,ACCELREADINGS) creates a factorIMU
%   object, F, with the specified node identification numbers property
%   NodeID set to nodeID, and with the gyroscope and accelerometer readings
%   set to their corresponding values.
%
%   F = FACTORIMU(ID,GYROREADINGS,ACCELREADINGS,IMUPARAMS) specifies IMU
%   parameters such as sampling rate, gyroscope bias noise, etc. as a
%   factorIMUParameters object.
%   
%   F = FACTORIMU(ID,SAMPLERATE,GYROBIASNOISE,ACCELBIASNOISE,
%   GYRONOISE,ACCELNOISE,GYROREADINGS,ACCELREADINGS) creates a factorIMU
%   object, F, with the node identification number set to ID, and with the
%   sample rate, gyroscope bias noise, accelerometer bias noise, gyroscope
%   noise, accelerometer noise, gyroscope readings, and accelerometer
%   readings all set to the corresponding values, respectively.
%
%   F = FACTORIMU(...,Name=Value) specifies properties using one or more
%   name-value arguments.
%
%   FACTORIMU methods:
%      nodeType          - Retrieve the node type for specified node ID
%      predict           - Estimate pose and velocity based on raw
%                          measurements
%       
%   FACTORIMU properties:
%      NodeID                    - IDs of nodes to connect to in factor 
%                                  graph
%      SampleRate                - IMU sampling rate
%      GyroscopeBiasNoise        - Process noise for gyroscope bias
%      AccelerometerBiasNoise    - Process noise for accelerometer bias
%      GyroscopeNoise            - Gyroscope measurement noise
%      AccelerometerNoise        - Accelerometer measurement noise
%      GyroscopeReadings         - Collected raw gyroscope readings
%      AccelerometerReadings     - Collected raw accelerometer readings
%      ReferenceFrame            - Reference frame
%      SensorTransform           - Transformation consisting of 3-D
%                                  translation and rotation to transform
%                                  connecting pose nodes to initial IMU
%                                  sensor reference frame
%
%   Example:
%      % Add an IMU factor to a factor graph
%      nodeID = [1,2,3,4,5,6];
%      sampleRate = 400; % Hz
%      gyroBiasNoise = 1.5e-9 * eye(3);
%      accelBiasNoise = diag([9.62e-9,9.62e-9,2.17e-8]);
%      gyroNoise = 6.93e-5 * eye(3);
%      accelNoise = 2.9e-6 * eye(3);
%         
%      gyroReadings = [ -0.0151    0.0299    0.0027
%                       -0.0079    0.0370   -0.0014
%                       -0.0320    0.0306    0.0035
%                       -0.0043    0.0340   -0.0066
%                       -0.0033    0.0331   -0.0011];
%      accelReadings = [   1.0666    0.0802    9.9586
%                          1.1002    0.0199    9.6650
%                          1.0287    0.3071   10.1864
%                          0.9077   -0.2239   10.2989
%                          1.2322    0.0174    9.8411];
%         
%      params = factorIMUParameters( ...
%              SampleRate = sampleRate, ...
%              GyroscopeBiasNoise = gyroBiasNoise, ...
%              AccelerometerBiasNoise = accelBiasNoise, ...
%              GyroscopeNoise = gyroNoise, ...
%              AccelerometerNoise = accelNoise, ...
%              ReferenceFrame = "NED" ...
%              );
%
%      f = factorIMU(nodeID, gyroReadings, accelReadings, params);
%         
%      G = factorGraph;
%      G.addFactor(f)
%      % After adding the factor, six new nodes are automatically added to 
%      % the factor graph. Check the node type of the first node.
%      nodeType(G, 1);
%
%   References:
%
%   [1] C. Foster, L. Carlone, F. Dellaert and D. Scaramuzza, "On-Manifold
%       Preintegration for Real-Time Visual-Inertial Odometry," IEEE 
%       Transactions on Robotics, Vol. 33, No. 1, pp. 1-21, Feb. 2017,
%       doi: 10.1109/TRO.2016.2597321
%
%   See also factorGraph, estimateGravityRotationAndPoseScale,
%   estimateGravityRotation, factorIMUParameters

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "IMU_F";
    end

    properties (SetAccess=protected)
        %NodeID Node ID numbers this factor connects in the factor graph
        %   Expects a 1-by-6 vector.
        %
        %   Must be specified at construction
        NodeID

        %SampleRate IMU sampling rate in Hz. Expects a positive scalar 
        %   larger than 100.
        %
        %   Must be specified at construction
        SampleRate

        %GyroscopeBiasNoise  Gyroscope bias process noise covariance
        %   Expects a 3-by-3 matrix.
        %
        %   Must be specified at construction   
        GyroscopeBiasNoise

        %AccelerometerBiasNoise Accelerometer bias process noise covariance
        %   Expects a 3-by-3 matrix.
        %
        %   Must be specified at construction
        AccelerometerBiasNoise 

        %GyroscopeNoise Gyroscope measurement noise covariance 
        %   Expects a 3-by-3 matrix.
        %
        %   Must be specified at construction
        GyroscopeNoise

        %AccelerometerNoise Accelerometer measurement noise covariance
        %   Expects a 3-by-3 matrix.
        %
        %   Must be specified at construction
        AccelerometerNoise

        %GyroscopeReadings A collection of raw gyroscope readings to be
        %   pre-integrated. Expects an N-by-3 matrix, where N is the number
        %   of readings. GyroscopeReadings and AccelerometerReadings must
        %   have the same size.
        %
        %   Must be specified at construction
        GyroscopeReadings

        %AccelerometerReadings A collection of raw accelerometer readings
        %   to be pre-integrated. Expects an N-by-3 matrix, where N is the 
        %   number of readings. GyroscopeReadings and AccelerometerReadings 
        %   must have the same size.
        %
        %   Must be specified at construction
        AccelerometerReadings
    end

    properties

        %ReferenceFrame Reference frame
        %   Reference frame for the local coordinate system, specified as
        %   "ENU" (East-North-Up) or "NED" (North-East-Down).
        %   
        %   Default: "ENU"
        ReferenceFrame = "ENU"

        %SensorTransform Sensor transform
        %   Transformation consisting of 3-D translation and rotation to
        %   transform connecting pose nodes to the initial IMU sensor
        %   reference frame, specified as an se3 object.
        %   
        %   For example, if the connected pose nodes store camera poses in
        %   the initial camera sensor reference frame, the sensor transform
        %   rotates and translates a pose in the initial camera sensor
        %   reference frame to the initial IMU sensor reference frame. The
        %   initial sensor reference frame has the very first sensor pose
        %   at its origin.
        %
        %   A sensor transform is unnecessary if the connecting pose nodes
        %   contain poses in the initial IMU sensor reference frame.
        %   Otherwise, you must specify the sensor transform.
        %
        %   Default: se3()
        SensorTransform

    end

    methods
        function obj = factorIMU(ids, varargin)
            %factorIMU Constructor

            narginchk(3,12);
            
            % input validation
            obj.validateIds(ids);
            obj.NodeID = double(ids);

            % default value
            obj.SensorTransform = se3();

            useNewConstructor = false;
            nvIdx = 8;
            if ((~isscalar(varargin{1})) && (nargin == 3)) || ...
                    ((~isscalar(varargin{1})) && (nargin > 3) && ...
                    (isStringScalar(varargin{3}) || ischar(varargin{3})))
                % if imu parameters are not provided use defaults
                imuParams = factorIMUParameters;
                useNewConstructor = true;
                nvIdx = 3;
            elseif (~isscalar(varargin{1})) && (nargin > 3) && ...
                    isa(varargin{3},'factorIMUParameters')
                % use imu parameters if provided
                imuParams = varargin{3};
                useNewConstructor = true;
                nvIdx = 4;
            end

            if useNewConstructor
                obj.SampleRate = imuParams.SampleRate;
                obj.GyroscopeBiasNoise = imuParams.GyroscopeBiasNoise;
                obj.AccelerometerBiasNoise = imuParams.AccelerometerBiasNoise;
                obj.GyroscopeNoise = imuParams.GyroscopeNoise;
                obj.AccelerometerNoise = imuParams.AccelerometerNoise;
                obj.ReferenceFrame = imuParams.ReferenceFrame;
                
                gyroReadings = varargin{1};
                accelReadings = varargin{2};
            else
                narginchk(8,inf);
                sampleRate = varargin{1};
                gyroBiasNoise = varargin{2};
                accelBiasNoise = varargin{3};
                gyroNoise = varargin{4};
                accelNoise = varargin{5};
                gyroReadings = varargin{6};
                accelReadings = varargin{7};

                validateattributes(sampleRate, 'numeric', ...
                    {'scalar', 'real', 'nonempty','finite','nonnan','nonsparse', '>=', 100}, 'factorIMU', 'sampleRate');
                obj.SampleRate = double(sampleRate);

                validateattributes(gyroBiasNoise, 'numeric', ...
                    {'size', [3, 3], 'real', 'finite','nonnan', 'nonsparse'}, 'factorIMU', 'gyroBiasNoise');
                obj.GyroscopeBiasNoise = double(gyroBiasNoise);

                validateattributes(accelBiasNoise, 'numeric', ...
                    {'size', [3, 3], 'real', 'finite', 'nonnan', 'nonsparse'}, 'factorIMU', 'accelBiasNoise');
                obj.AccelerometerBiasNoise = double(accelBiasNoise);

                validateattributes(gyroNoise, 'numeric', ...
                    {'size', [3, 3], 'real', 'finite', 'nonnan', 'nonsparse'}, 'factorIMU', 'gyroNoise');
                obj.GyroscopeNoise = double(gyroNoise);

                validateattributes(accelNoise, 'numeric', ...
                    {'size', [3, 3], 'real', 'finite', 'nonnan', 'nonsparse'}, 'factorIMU', 'accelNoise');
                obj.AccelerometerNoise = double(accelNoise);
            end

            validateattributes(gyroReadings, 'numeric', ...
                {'2d', 'ncols', 3, 'real', 'nonempty','nonnan','finite', 'nonsparse'}, 'factorIMU', 'gyroReadings');
            validateattributes(accelReadings, 'numeric', ...
                {'2d', 'ncols', 3, 'real', 'nonempty','nonnan','finite', 'nonsparse'}, 'factorIMU', 'accelReadings');

            coder.internal.errorIf(size(gyroReadings,1) ~= size(accelReadings, 1), ...
                'nav:navalgs:factors:MismatchedIMUReadings');
            obj.GyroscopeReadings = double(gyroReadings);
            obj.AccelerometerReadings = double(accelReadings);

            nar = nargin - nvIdx;
            var = cell(1,nar);
            for k = 1:nar
                var{k} = varargin{nvIdx+k-1};
            end
            obj = matlabshared.fusionutils.internal.setProperties(obj, nar, var{:});
        end

        function [predictedPose, predictedVel] = predict(obj, prevPose, prevVel, prevBias)
            %predict Predict pose and velocity based on the previously
            %   estimated pose, velocity, and IMU biases and the collected
            %   raw IMU readings as saved in GyroscopeReadings and 
            %   AccelerometerReadings properties.
            %
            %   [PREDICTEDPOSE,PREDICTEDVEL] = PREDICT(F,PREVPOSE,PREVVEL,
            %   PREVBIAS) updates the pose, PREDICTEDPOSE, and velocity, 
            %   PREDICTEDVEL, based on the IMU readings and the initial 
            %   values, PREVPOSE, PREVVEL, and PREVBIAS. PREVPOSE is a 
            %   7-element vector containing the 3D position and the
            %   orientation quaternion. PREVVEL is a 3-element vector
            %   containing the 3D velocity. PREVBIAS is a 6-element vector
            %   containing the gyroscope and accelerometer 3D biases.

            internalObj = obj.createBuiltinObject();
            prevPose = [prevPose(1:3), prevPose(5:7), prevPose(4)];
            result = internalObj.predict(prevPose, prevVel, prevBias);
            poseTmp = result.PredictedPose;
            predictedPose = [poseTmp(1:3), poseTmp(7), poseTmp(4:6)] ;
            predictedVel = result.PredictedVel;
        end

        function obj = set.ReferenceFrame(obj, refFrame)
            %set.ReferenceFrame
            obj.ReferenceFrame = validatestring(refFrame, {'ENU', 'NED'}, 'factorIMU','refFrame');
        end

        function type = nodeType(obj, id)
            %nodeType Retrieve the node type for a specified node ID.
            narginchk(2,2);
            nav.algs.internal.validation.validateNodeID_FactorQuery(id, obj.NodeID, 'factorIMU', 'id');
            nodeInd = find(obj.NodeID == id);
            % code-generation doesn't know that NodeId only contains
            % non-duplicate elements. Using the scalar first element in the
            % returned indices explicitly for all verifications.
            type = ""; % assign default value for codegen. 
            if nodeInd(1) == 1 || nodeInd(1) == 4
                type = nav.internal.factorgraph.NodeTypes.SE3; % for the first and fourth IDs
            elseif nodeInd(1) == 2 || nodeInd(1) == 5
                type = nav.internal.factorgraph.NodeTypes.Velocity3; % for the second and fifth IDs
            elseif nodeInd(1) == 3 || nodeInd(1) == 6 
                type = nav.internal.factorgraph.NodeTypes.IMUBias; % for the third and sixth IDs 
            end
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
                    nav.algs.internal.builtin.FactorIMU(int32(obj.NodeID), ...
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
                    nav.algs.internal.codegen.FactorIMU(obj.NodeID, ...
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

    methods (Static, Access = protected)
        function validateIds(ids)
            %validateIds
            nav.algs.internal.validation.validateNodeID_FactorConstruction(ids, 6, 'factorIMU', 'ids');
        end
    end

    methods
        function obj = set.SensorTransform(obj, tf)
            %set.SensorTransform
            validateattributes(tf, {'se3'}, {'nonempty', 'scalar'}, 'factorIMU', 'SensorTransform');
            obj.SensorTransform = tf;
        end
    end


end