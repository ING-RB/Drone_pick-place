classdef factorIMUParameters
%FACTORIMUPARAMETERS Factor IMU parameters
%
%
%   PARAMS = factorIMUParameters returns a factor IMU parameters object,
%   PARAMS.
%
%   PARAMS = factorIMUParameters(Name=Value) specifies properties using
%    one or more name-value arguments.
%
%   FACTORIMUPARAMETERS properties:
%       SampleRate                - IMU Sampling Rate (Hz)
%       GyroscopeBiasNoise        - Process noise for gyroscope bias
%       AccelerometerBiasNoise    - Process noise for accelerometer bias
%       GyroscopeNoise            - Gyroscope measurement noise
%       AccelerometerNoise        - Accelerometer measurement noise
%       ReferenceFrame            - IMU reference frame
%
%   Example:
%       % Specify IMU parameters.
%       sampleRate = 400; % Hz
%       gyroBiasNoise = 1.5e-9 * eye(3);
%       accelBiasNoise = diag([9.62e-9,9.62e-9,2.17e-8]);
%       gyroNoise = 6.93e-5 * eye(3);
%       accelNoise = 2.9e-6 * eye(3);
%
%       % Create factorIMUParameters object.
%       params = factorIMUParameters( ...
%                   SampleRate = sampleRate, ...
%                   GyroscopeBiasNoise = gyroBiasNoise, ...
%                   AccelerometerBiasNoise = accelBiasNoise, ...
%                   GyroscopeNoise = gyroNoise, ...
%                   AccelerometerNoise = accelNoise, ...
%                   ReferenceFrame = "NED" ...
%                   );
%
%   See also factorGraph, factorIMU, estimateGravityRotation, 
%   estimateGravityRotationAndPoseScale

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    properties
        %SampleRate IMU sampling rate
        %   IMU sampling rate, specified a positive scalar in Hz. The value
        %   must be greater than or equal to 100.
        %
        %   Default: 100
        SampleRate = 100

        %GyroscopeBiasNoise Gyroscope bias process noise covariance
        %   Gyroscope bias process noise covariance, specified as a 3-by-3
        %   matrix, 3-element row vector, or scalar in (rad/s)^2.
        %
        %   Default:  eye(3)
        GyroscopeBiasNoise = eye(3) 

        %AccelerometerBiasNoise Accelerometer bias process noise covariance
        %   Accelerometer bias process noise covariance, specified as a
        %   3-by-3 matrix, 3-element row vector, or scalar in (m/s^2)^2.
        %
        %   Default: eye(3)
        AccelerometerBiasNoise = eye(3)

        %GyroscopeNoise Gyroscope measurement noise covariance
        %   Gyroscope measurement noise covariance, specified as a
        %   3-by-3 matrix, 3-element row vector, or scalar in (m/s^2)^2.
        %
        %   Default: eye(3)
        GyroscopeNoise = eye(3)

        %AccelerometerNoise Accelerometer measurement noise covariance
        %   Accelerometer measurement noise covariance, specified as a
        %   3-by-3 matrix, 3-element row vector, or scalar in (m/s^2)^2.
        %
        %   Default: eye(3)
        AccelerometerNoise = eye(3)

        %ReferenceFrame IMU reference frame
        %   IMU reference frame for the local coordinate system, specified
        %   as "ENU" (East-North-Up) or "NED" (North-East-Down).
        %
        %   Default: "ENU"
        ReferenceFrame = "ENU"
    end
    
    methods
        function obj = factorIMUParameters(varargin)
            %FACTORIMUPARAMETERS Constructor
            obj = matlabshared.fusionutils.internal.setProperties(obj, nargin, varargin{:});
        end
        
        function obj = set.SampleRate(obj, sampleRate)
            %set.SampleRate
            validateattributes(sampleRate, 'numeric', ...
                {'real', 'nonempty','nonnan','finite','nonsparse','scalar', ...
                '>=', 100}, 'factorIMUParameters', 'SampleRate');
            obj.SampleRate = double(sampleRate);
        end

        function obj = set.GyroscopeBiasNoise(obj, gyroBiasNoise)
            %set.GyroscopeBiasNoise
            
            obj.GyroscopeBiasNoise = obj.validateNoise(gyroBiasNoise, 'GyroscopeBiasNoise');
        end

        function obj = set.AccelerometerBiasNoise(obj, accelBiasNoise)
            %set.AccelerometerBiasNoise

            obj.AccelerometerBiasNoise = obj.validateNoise(accelBiasNoise, 'AccelerometerBiasNoise');
        end

        function obj = set.GyroscopeNoise(obj, gyroNoise)
            %set.GyroscopeNoise
            
            obj.GyroscopeNoise = obj.validateNoise(gyroNoise, 'GyroscopeNoise');
        end

        function obj = set.AccelerometerNoise(obj, accelNoise)
            %set.AccelerometerNoise
            
            obj.AccelerometerNoise = obj.validateNoise(accelNoise, 'AccelerometerNoise');
        end

        function obj = set.ReferenceFrame(obj, referenceFrame)
            %set.TrustRegionStrategyType
            ref = validatestring(referenceFrame, {'ENU', 'NED'}, 'factorIMUParameters', 'ReferenceFrame');
            obj.ReferenceFrame = convertCharsToStrings(ref);
        end

    end

    methods (Static, Access = private)
        function nd = validateNoise(n, propName)
            %validateNoise
            validateattributes(n, 'numeric', ...
                {'real', 'nonempty', 'nonnan', 'finite', 'nonsparse'}, 'factorIMUParameters', propName);

            nd = eye(3);
            if isscalar(n)
                nd = double(n(1))*nd;
            elseif isvector(n) && (numel(n)==3)
                nd = diag(double(n(1:3)));
            elseif (size(n,1) == 3) && (size(n,2) == 3)
                nd = double(n(1:3,1:3));
            else
                coder.internal.error('nav:navalgs:factorgraph:InvalidNoiseDim', propName);
            end
        end
    end
end