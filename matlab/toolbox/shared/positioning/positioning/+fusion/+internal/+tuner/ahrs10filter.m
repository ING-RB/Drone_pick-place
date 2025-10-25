classdef (Hidden) ahrs10filter
%   This class is for internal use only. It may be removed in the future. 

%AHRS10FILTER Tuner specific functions for the ahrs10filter

%   Copyright 2020 The MathWorks, Inc.    

% Codegen pragma for configure method
%#codegen 

    methods (Static)
        function [tunerparams, staticparams]  = getParamsForAutotune
            tunerparams = ["AccelerometerNoise", ...
                "GyroscopeNoise", ...
                "MagnetometerNoise", ...
                "AltimeterNoise", ...
                "AccelerometerBiasNoise", ...
                "GyroscopeBiasNoise", ...
                "GeomagneticVectorNoise", ...
                "MagnetometerBiasNoise"];

            staticparams = ["IMUSampleRate", ...
                "State", ...
                "StateCovariance"];
        end

        function [cost, states] = tunerfuse(params, sensorData, groundTruth, cfg)
            if ~isempty(coder.target) || ~cfg.UseMex
                states = fusion.internal.tuner.processAHRS10Filter(params, sensorData);
            else
                states = fusion.internal.tuner.mex.processAHRS10Filter_mex(params, sensorData);
            end
            cost  = rmsStateErr(states, groundTruth, stateinfo(ahrs10filter)); 
        end

        function measNoise = getMeasNoiseExemplar
            measNoise.MagnetometerNoise = 1;
            measNoise.AltimeterNoise = 1;
        end

        function tf = hasMeasNoise
            tf = true;
        end

        function sensorData = processSensorData(sensorData)
            % Validate sensorData
            expvn = ["Accelerometer", "Gyroscope", "Magnetometer", ...
                "Altimeter" ];
            % Validate table columns
            fusion.internal.tuner.FilterTuner.validateTableVars(...
                sensorData, 'sensorData', ...
                2, expvn);
            % Validate table column data attributes for accel,gyro,mag
            attrs = cell(numel(expvn),2);
            attrs3col = { {'double', 'single'}, ...
                {'ncols', 3, 'nonempty', ...
                'nonsparse', 'real' }};
            attrs(1:3,:) = repmat(attrs3col, 3, 1);

            attrs(end,:) = { {'double', 'single'}, ...
                {'ncols', 1, 'nonempty', ...
                'nonsparse', 'real' }};
            fusion.internal.tuner.FilterTuner.validateTableVarAttrs(...
                sensorData, expvn, attrs, "sensorData");

            % Ensure no nans in Accelerometer or Gyroscope
            validateattributes(sensorData.Accelerometer, ...
                {'double', 'single'}, {'nonnan'}, "tune", ...
                "sensorData.Accelerometer");
            validateattributes(sensorData.Gyroscope, ...
                {'double', 'single'}, {'nonnan'}, "tune", ...
                "sensorData.Gyroscope");

        end

        function groundTruth = processGroundTruth(groundTruth)
            % Ensure:
            % 1. input is table
            % 2. Variables present are all states. No variables allowed
            % that are not states, but not all states need to be present.
            % 3. If Orientation is present, validate and convert it to a
            % quaternion.
            % 4. Validate all other Variables.
            
            % Input is table
            assert(istable(groundTruth), ...
                message('shared_positioning:tuner:InputMustBeTable', ...
                'groundTruth', 4));
           assert(~isempty(groundTruth), message('shared_positioning:tuner:InputMustBeNonempty'));
 
            % Variables are states
            vn = groundTruth.Properties.VariableNames;
            sinfo = stateinfo(ahrs10filter);
            sfn = fieldnames(sinfo);  
            assert( all(matches(vn, sfn, 'IgnoreCase', false)), ...
                message('shared_positioning:tuner:ExpectedOnlyVars', ...
                strjoin(sfn,', ') ));

            % Fix orientation
            if any(matches(vn, 'Orientation'))
                o = fusion.internal.tuner.FilterTuner.validateAndConvertOrientation(...
                    groundTruth, 'groundTruth',  'Orientation');
                groundTruth.Orientation = o;
            end
            
            % Validate the rest of the table
            tbl = groundTruth; 
            % Remove orientation if present
            if any(matches(vn, 'Orientation'))
                tbl.Orientation = [];
            end
            
            expvn = string(tbl.Properties.VariableNames); % May be empty after removing orientation
            % Build attributes for whatever variables are left
            attrs = cell(numel(expvn),2);
            for ii=1:numel(expvn)
                switch expvn{ii}
                    case {"Altitude", "VerticalVelocity"}
                        attrs(ii,:) = { {'double', 'single'}, ...
                            {'ncols', 1, 'nonempty', 'finite', ...
                            'nonsparse', 'real' }};
                    otherwise
                        attrs(ii,:) = { {'double', 'single'}, ...
                            {'ncols', 3, 'nonempty', 'finite', ...
                            'nonsparse', 'real' }};
                end
            end
            fusion.internal.tuner.FilterTuner.validateTableVarAttrs(...
                tbl, expvn, attrs, "groundTruth");
        
        end

        function crossValidateInputs(sensorData, groundTruth) 
            % Ensure that number of rows are the same.
            Ns = size(sensorData,1);
            Ng = size(groundTruth,1);
            assert(Ns == Ng, ...
                message('shared_positioning:tuner:InputTableLength'));
        end
        function varargout = makeTunerOutput(obj, info, measNoise)
            params = info(end);
            reset(obj);
            fusion.internal.tuner.ahrs10filter.configure(obj, params, true);
            
            % Overwrite (copy) of input measNoise struct to preserve
            % datatypes.
            measNoise.MagnetometerNoise(:) = params.MagnetometerNoise; 
            measNoise.AltimeterNoise(:) = params.AltimeterNoise ; 
            varargout = {measNoise}; 
        end

        function configure(x, y, preserveDstType)
            % Configure object or struct x with the ahrs10filter parameters
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

            x.AccelerometerNoise     = cast(y.AccelerometerNoise, 'like', ex.AccelerometerNoise);     
            x.GyroscopeNoise         = cast(y.GyroscopeNoise, 'like', ex.GyroscopeNoise);
            x.GyroscopeBiasNoise     = cast(y.GyroscopeBiasNoise, 'like', ex.GyroscopeBiasNoise);
            x.AccelerometerBiasNoise = cast(y.AccelerometerBiasNoise, 'like', ex.AccelerometerBiasNoise);
            x.GeomagneticVectorNoise = cast(y.GeomagneticVectorNoise, 'like', ex.GeomagneticVectorNoise);
            x.MagnetometerBiasNoise  = cast(y.MagnetometerBiasNoise, 'like', ex.MagnetometerBiasNoise);
            x.State                  = cast(y.State, 'like', ex.State);
            x.StateCovariance        = cast(y.StateCovariance, 'like', ex.StateCovariance);
            x.IMUSampleRate          = cast(y.IMUSampleRate, 'like', ex.IMUSampleRate);
        end
    end
end


function cost = rmsStateErr(states, groundTruth, sinfo)
    % states is N-by-numstates where N is the number of samples.

    % It is guaranteed by processGroundTruth that the Orientation is stored
    % as a quaternion and that all table variables correspond to a state.
    % It is also guaranteed that the times in the groundTruth timetable are
    % aligned with the states times.
    
    vars = groundTruth.Properties.VariableNames;
    % Fix orientation. Compact the quaternions
    if any(contains(vars, "Orientation"))
        groundTruth.Orientation = compact(groundTruth.Orientation);
    end
    garr = table2array(groundTruth);

    % create a subset struct of just the needed fields
    for v=1:numel(vars)
        thisvar = vars{v};
        subsi.(thisvar) = sinfo.(thisvar);
    end
    % Extract the field values into an array
    subsicell = struct2cell(subsi);
    statesidx = [subsicell{:}];

    sarr = states(:, statesidx);

    % We are doing an RMS difference between two multivariable timeseries.
    % Using the approach defined in 
    % Abbeel, et al. "Discriminative Training of Kalman Filters." Section
    % IV, equation on page 6.
    d = (garr - sarr).';
    cost = sqrt(mean(vecnorm(d).^2));
    
end

