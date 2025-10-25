classdef (Hidden) ahrsfilter
%   This class is for internal use only. It may be removed in the future. 

%AHRSFILTER Tuner specific functions for the ahrsfilter

%   Copyright 2020 The MathWorks, Inc.    

% Add codegen pragma for configure method
%#codegen 

    methods (Static)
        function [tunerparams, staticparams]  = getParamsForAutotune
            tunerparams = ["AccelerometerNoise", ...
                "GyroscopeNoise", ...
                "MagnetometerNoise", ...
                "GyroscopeDriftNoise", ...
                "LinearAccelerationNoise", ...
                "MagneticDisturbanceNoise", ...
                "LinearAccelerationDecayFactor", ...
                "MagneticDisturbanceDecayFactor"];
            staticparams = ["SampleRate", ...
                "DecimationFactor", ...
                "InitialProcessNoise", ...
                "ExpectedMagneticFieldStrength", ...
                "OrientationFormat"];
        end
        function [cost, q] = tunerfuse(params, sensorData, groundTruth, cfg)
            if ~isempty(coder.target) || ~cfg.UseMex
                q = fusion.internal.tuner.processAHRSFilter(params, sensorData);
            else
                q = fusion.internal.tuner.mex.processAHRSFilter_mex(params, sensorData);
            end
            qexp = groundTruth.Orientation;
            d = dist(q, qexp);
            cost = sqrt(mean(d.^2));
        end
        function measNoise = getMeasNoiseExemplar
            % Not used. Required by mixin
            measNoise = [];
        end
        function tf = hasMeasNoise
            tf = false;
        end

        function sensorData = processSensorData(sensorData)
            % Validate sensorData
            expvn = ["Accelerometer", "Gyroscope", "Magnetometer"];
            % Validate table columns
            fusion.internal.tuner.FilterTuner.validateTableVars(...
                sensorData, 'sensorData', ...
                2, expvn);
            % Validate table column data attributes 
            attrs1 = { {'double', 'single'}, ...
                {'ncols', 3, 'finite', 'nonempty', ...
                'nonsparse', 'real' }};
            attrs = repmat(attrs1, numel(expvn), 1);
            fusion.internal.tuner.FilterTuner.validateTableVarAttrs(...
                sensorData, expvn, attrs, "sensorData");
        end

        function groundTruth = processGroundTruth(groundTruth)
            expvn = "Orientation";
            fusion.internal.tuner.FilterTuner.validateTableVars(...
                groundTruth, 'groundTruth', ...
                3, expvn);
            o = fusion.internal.tuner.FilterTuner.validateAndConvertOrientation(...
                groundTruth, 'groundTruth', 'Orientation');
            groundTruth.Orientation = o;
        end

        function varargout = makeTunerOutput(obj, info)
            params = info(end);
            release(obj);
            reset(obj);
            % Configure, but leave OrientationFormat however it was set
            % originally.
            fusion.internal.tuner.ahrsfilter.configure(obj, params, true);
            
            varargout = {}; % no outputs for ahrsfilter/tune
        end

        function x = configure(x, y, preserveDstType)
            % Configure object or struct x with the ahrsfilter parameters
            % in object or struct y. Skip OrientationFormat. If
            % preserveDstType is true, the type of x's fields/properties
            % are preserved. If preserveDstType is false, the type of y's
            % fields/properties are used. That is: 
            % preserveDstType=true implies a(:) = b 
            % preserveDstType=false implies a = b

            if preserveDstType
                ex = x;
            else
                ex = y;
            end

            x.SampleRate                     = cast(y.SampleRate, 'like', ex.SampleRate);
            x.DecimationFactor               = cast(y.DecimationFactor, 'like', ex.DecimationFactor);
            x.AccelerometerNoise             = cast(y.AccelerometerNoise, 'like', ex.AccelerometerNoise);
            x.GyroscopeNoise                 = cast(y.GyroscopeNoise, 'like', ex.GyroscopeNoise);
            x.MagnetometerNoise              = cast(y.MagnetometerNoise, 'like', ex.MagnetometerNoise);
            x.GyroscopeDriftNoise            = cast(y.GyroscopeDriftNoise, 'like', ex.GyroscopeDriftNoise);
            x.LinearAccelerationNoise        = cast(y.LinearAccelerationNoise, 'like', ex.LinearAccelerationNoise);
            x.MagneticDisturbanceNoise       = cast(y.MagneticDisturbanceNoise, 'like', ex.MagneticDisturbanceNoise);
            x.LinearAccelerationDecayFactor  = cast(y.LinearAccelerationDecayFactor, 'like', ex.LinearAccelerationDecayFactor);
            x.MagneticDisturbanceDecayFactor = cast(y.MagneticDisturbanceDecayFactor, 'like', ex.MagneticDisturbanceDecayFactor);
            x.ExpectedMagneticFieldStrength  = cast(y.ExpectedMagneticFieldStrength, 'like', ex.ExpectedMagneticFieldStrength);
            x.InitialProcessNoise            = cast(y.InitialProcessNoise, 'like', ex.InitialProcessNoise);
            % Don't set OrientationFormat. Do that in calling functions.
        end
    end
end

