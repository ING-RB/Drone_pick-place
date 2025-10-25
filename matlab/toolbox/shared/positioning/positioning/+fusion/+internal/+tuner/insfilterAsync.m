classdef (Hidden) insfilterAsync < fusion.internal.tuner.InstanceHelperBase
%   This class is for internal use only. It may be removed in the future. 

%INSFILTERASYNC Tuner specific functions for the insfilterAsync

%   Copyright 2020-2021 The MathWorks, Inc.

% Codegen pragma for configure method
%#codegen 


    methods (Static)
        function [tunerparams, staticparams]  = getParamsForAutotune
            tunerparams = ["AccelerometerNoise", ...
                "GyroscopeNoise", ...
                "MagnetometerNoise", ...
                "GPSPositionNoise", ...
                "GPSVelocityNoise", ...
                "QuaternionNoise", ...
                "AngularVelocityNoise", ...
                "PositionNoise", ...
                "VelocityNoise", ...
                "AccelerationNoise", ...
                "GyroscopeBiasNoise", ...
                "AccelerometerBiasNoise", ...
                "GeomagneticVectorNoise", ...
                "MagnetometerBiasNoise"];
            staticparams = ["ReferenceLocation", ...
                "State", ...
                "StateCovariance"];
        end

        function [cost, stateEst] = tunerfuse(params, sensorData, groundTruth, cfg)
            if ~isempty(coder.target) || ~cfg.UseMex
                stateEst = fusion.internal.tuner.processINSFilterAsync(params, sensorData);
            else
                stateEst = fusion.internal.tuner.mex.processINSFilterAsync_mex(params, sensorData);
            end
            cost = fusion.internal.tuner.insfilterAsync.rmsStateErr(stateEst, groundTruth, stateinfo(insfilterAsync)); 
        end

        function measNoise = getMeasNoiseExemplar
            measNoise.AccelerometerNoise = 1;
            measNoise.GyroscopeNoise = 1;
            measNoise.MagnetometerNoise = 1;
            measNoise.GPSPositionNoise = 1;
            measNoise.GPSVelocityNoise = 1;
        end

        function tf = hasMeasNoise
            tf = true;
        end

        function sensorData = processSensorData(sensorData)
            % Validate sensorData
            expvn = ["Accelerometer", "Gyroscope", "Magnetometer", ...
                "GPSPosition", "GPSVelocity"];
            % Validate table columns
            fusion.internal.tuner.FilterTuner.validateTimetableVars(...
                sensorData, 'sensorData', ...
                2, expvn);
            % Validate table column data attributes 
            attrs1 = { {'double', 'single'}, ...
                {'ncols', 3, 'nonempty', ...
                'nonsparse', 'real' }};
            attrs = repmat(attrs1, numel(expvn), 1);
            fusion.internal.tuner.FilterTuner.validateTableVarAttrs(...
                sensorData, expvn, attrs, "sensorData");
            
            % Force RowTimes to be explicit, durations
            sensorData = fusion.internal.tuner.insfilterAsync.coerceRowTimes(sensorData);
           
        end

        function groundTruth = processGroundTruth(groundTruth)
            %  Use validateAndFixGroundTruthTimeTable to 
            %    1. input is timetable
            %    2. Variables present are all states. No variables allowed
            %    that are not states, but not all states need to be present.
            %    3. If Orientation is present, validate and convert it to a
            %    quaternion.
            %  Then
            %    4. Validate all other Variables.
            
            % Input is timetable


            groundTruth = fusion.internal.tuner.insfilterAsync.validateAndFixGroundTruthTimeTable(...
                groundTruth, stateinfo(insfilterAsync));

            % Validate the rest of the table
            tbl = timetable2table(groundTruth, 'ConvertRowTimes', false);
            vn = groundTruth.Properties.VariableNames;
            % Remove orientation if present
            if any(matches(vn, 'Orientation'))
                tbl.Orientation = [];
            end
            
            expvn = string(tbl.Properties.VariableNames); % May be empty after removing orientation
            attrs1 = { {'double', 'single'}, ...
                {'ncols', 3, 'nonempty', 'finite', ...
                'nonsparse', 'real' }};
            attrs = repmat(attrs1, numel(expvn), 1);
            fusion.internal.tuner.FilterTuner.validateTableVarAttrs(...
                tbl, expvn, attrs, "groundTruth");
        
        end

        function crossValidateInputs(sensorData, groundTruth) 
            fusion.internal.tuner.insfilterAsync.validateSameTimetableTimes(sensorData, groundTruth);
        end

        function varargout = makeTunerOutput(obj, info, measNoise)
            params = info(end);
            reset(obj);
            fusion.internal.tuner.insfilterAsync.configure(obj, params, ...
                true);
            % Overwrite input (copy) of measNoise to preserve datatypes
            measNoise.AccelerometerNoise(:) = params.AccelerometerNoise; 
            measNoise.GyroscopeNoise(:) = params.GyroscopeNoise; 
            measNoise.MagnetometerNoise(:) = params.MagnetometerNoise; 
            measNoise.GPSPositionNoise(:) = params.GPSPositionNoise; 
            measNoise.GPSVelocityNoise(:) = params.GPSVelocityNoise; 
            varargout = {measNoise}; 
        end
        function configure(x, y, preserveDstType)
            % Configure object or struct x with the insfilterAsync parameters
            % in object or struct y.If preserveDstType is true, the type of
            % x's fields/properties are preserved. If preserveDstType is
            % false, the type of y's fields/properties are used. That is:
            % preserveDstType=true implies a(:) = b 
            % preserveDstType=false implies a = b

            if preserveDstType
                ex = x;
            else
                ex = y;
            end

            x.QuaternionNoise         = cast(y.QuaternionNoise, 'like', ex.QuaternionNoise);
            x.AngularVelocityNoise    = cast(y.AngularVelocityNoise, 'like', ex.AngularVelocityNoise);
            x.PositionNoise           = cast(y.PositionNoise, 'like', ex.PositionNoise);
            x.VelocityNoise           = cast(y.VelocityNoise, 'like', ex.VelocityNoise);
            x.AccelerationNoise       = cast(y.AccelerationNoise, 'like', ex.AccelerationNoise);
            x.GyroscopeBiasNoise      = cast(y.GyroscopeBiasNoise, 'like', ex.GyroscopeBiasNoise);
            x.AccelerometerBiasNoise  = cast(y.AccelerometerBiasNoise, 'like', ex.AccelerometerBiasNoise);
            x.GeomagneticVectorNoise  = cast(y.GeomagneticVectorNoise, 'like', ex.GeomagneticVectorNoise);
            x.MagnetometerBiasNoise   = cast(y.MagnetometerBiasNoise, 'like', ex.MagnetometerBiasNoise);
            x.State                   = cast(y.State, 'like', ex.State);
            x.StateCovariance         = cast(y.StateCovariance, 'like', ex.StateCovariance);
            x.ReferenceLocation       = cast(y.ReferenceLocation, 'like', ex.ReferenceLocation);
        end
    end
end



