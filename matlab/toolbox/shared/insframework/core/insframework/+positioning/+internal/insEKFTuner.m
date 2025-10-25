classdef (Hidden, HandleCompatible) insEKFTuner < fusion.internal.tuner.FilterTuner & ...
        fusion.internal.tuner.InstanceHelperBase
%

%   Copyright 2021 The MathWorks, Inc.
    
%#codegen 

    methods (Static, Hidden)
        function [tunerparams, staticparams] = getParamsForAutotune %#ok<STOUT> 
            coder.internal.error('insframework:insEKF:InstanceRequired'); 
        end
        function tf = hasMeasNoise
            tf = true;
        end
        function measNoise = getMeasNoiseExemplar %#ok<STOUT> 
            coder.internal.error('insframework:insEKF:InstanceRequired'); 
        end
        function [cost, stateEst] = tunerfuse(~, ~, ~, ~) %#ok<STOUT> 
            coder.internal.error('insframework:insEKF:InstanceRequired'); 
        end
    end

    methods
        function tn = tune(filt, mnoise, sensorData, groundTruth, cfg)
            %TN = tune(FILT, MNOISE, SENSORDATA, GROUNDTRUTH) adjusts the
            %     value of the measurement noises in MNOISE and the
            %     AdditiveProcessNoise property of FILT 
            %      to reduce the root-mean-squared (RMS) state
            %     estimation error between the fused sensor data and ground
            %     truth.  The function fuses the sensor readings in
            %     SENSORDATA to form a state estimate which is compared to
            %     variables in GROUNDTRUTH. The function uses the property
            %     values in FILT and the values in the MEASNOISE struct as
            %     the starting guess for the optimization algorithm. The
            %     returned TN is a struct, with the same fields as
            %     MEASNOISE, containing optimized measurement noise values.
            %     
            %     The variables names in the timetable SENSORDATA must
            %     match those set in the filter's SensorNames property to
            %     indicate which sensor should fuse each column. Use NaNs
            %     or MISSING to indicate that data is not present for a
            %     sensor at a given time. 
            %
            %     The variable names in the timetable SENSORDATA must be a
            %     subset of the filter's State names. The filter's state
            %     names are the field names output by the STATEINFO
            %     function. 
            % 
            %     TN = tune(..., CFG) tunes the filter based on
            %     the tuner configuration parameters CFG which is created
            %     by the TUNERCONFIG function. If the Cost property of CFG
            %     is set to 'custom' then any types are allowed for
            %     SENSORDATA and GROUNDTRUTH.
            %
            %     Example : Tune filter to optimize orientation estimate
            %     
            %     % Load sensor data and ground truth
            %     ld = load("accelGyroINSEKFData.mat");
            %     
            %     % Make a filter for orientation estimation and initialize
            %     filt = insEKF;
            %     stateparts(filt, "Orientation", compact(ld.initOrient));
            %     statecovparts(filt, "Orientation", 1e-2);
            %
            %     % Estimate states with an untuned filter     
            %     mnoise = tunernoise(filt);
            %     untunedEst = estimateStates(filt, ld.sensorData, mnoise);
            %     
            %     % Reinitialize filter and tune 
            %     stateparts(filt, "Orientation", compact(ld.initOrient));
            %     statecovparts(filt, "Orientation", 1e-2);
            %     cfg = tunerconfig(filt, MaxIterations=10, ...
            %        ObjectiveLimit=1e-4);
            %     tunedmn = tune(filt, mnoise, ld.sensorData, ...
            %         ld.groundTruth, cfg);
            %
            %     % Re-estimate states with the tuned filter
            %     tunedEst = estimateStates(filt, ld.sensorData, tunedmn);
            %     
            %     % Compare orientation estimates
            %     times = ld.groundTruth.Properties.RowTimes;
            %     duntuned = rad2deg(dist(untunedEst.Orientation, ...
            %         ld.groundTruth.Orientation));
            %     dtuned = rad2deg(dist(tunedEst.Orientation, ...
            %         ld.groundTruth.Orientation));
            %     plot(times, duntuned, times, dtuned);
            %     legend("Untuned", "Tuned");
            %     title("Filter Orientation Error");
            %     
            %     % Print RMS error of untuned and tuned filter
            %     untunedRMSError = sqrt(mean(duntuned.^2));
            %     tunedRMSError = sqrt(mean(dtuned.^2));
            %     fprintf("Untuned RMS error : %.2f degrees\n", ...
            %         untunedRMSError);
            %     fprintf("Tuned RMS error : %.2f degrees\n", ...
            %         tunedRMSError);
            %
            %   See also: insEKF/estimateStates

            narginchk(4,5);
            if nargin < 5
                tn = tune@fusion.internal.tuner.FilterTuner(filt, ...
                    mnoise, sensorData, groundTruth);
            else
                tn = tune@fusion.internal.tuner.FilterTuner(filt, ...
                    mnoise, sensorData, groundTruth, cfg);
            end
        end
    end

    methods (Access = protected)    
        function sensorData = processSensorData(filt, sensorData)
            % Validate sensorData

            % Validate column names
            expvn = filt.SensorNames; 
            % Validate table columns
            fusion.internal.tuner.FilterTuner.validateTimetableVars(...
                sensorData, 'sensorData', ...
                2, expvn);
            % Validate table column data attributes but don't assume
            % anything about the data size (rows or columns) 
            attrs1 = { {'double', 'single'}, ...
                { 'nonempty', 'nonsparse', 'real' }};
            attrs = repmat(attrs1, numel(expvn), 1);
            fusion.internal.tuner.FilterTuner.validateTableVarAttrs(...
                sensorData, expvn, attrs, "sensorData");
            
            % Force RowTimes to be explicit, durations
            sensorData = filt.coerceRowTimes(sensorData);
        end

        function groundTruth = processGroundTruth(filt, groundTruth)
            %  Use validateAndFixGroundTruthTimeTable to 
            %    1. input is timetable
            %    2. Variables present are all states. No variables allowed
            %    that are not states, but not all states need to be present.
            %    3. If Orientation is present, validate and convert it to a
            %    quaternion.
            %  Then
            %    4. Validate all other Variables.
            
            % Input is timetable

            sinfo = stateinfo(filt);
            groundTruth = filt.validateAndFixGroundTruthTimeTable(groundTruth, sinfo);

            % Validate the rest of the table
            tbl = timetable2table(groundTruth, 'ConvertRowTimes', false);
            vn = groundTruth.Properties.VariableNames;
            % Remove orientation if present
            if any(matches(vn, 'Orientation'))
                tbl.Orientation = [];
            end
            
            expvn = string(tbl.Properties.VariableNames); % May be empty after removing orientation
            attrs1 = { {'double', 'single'}, ...
                {'nonempty', 'finite', ...
                'nonsparse', 'real' }};
            attrs = repmat(attrs1, numel(expvn), 1);
            fusion.internal.tuner.FilterTuner.validateTableVarAttrs(...
                tbl, expvn, attrs, "groundTruth");
            
        end

        function varargout = makeTunerOutput(filt, info, measNoise)
            params = info(end);
            filt.State = params.State;
            filt.StateCovariance = params.StateCovariance;
            filt.AdditiveProcessNoise = params.AdditiveProcessNoise;
            fn = fieldnames(measNoise);
            for ff=1:numel(fn)
                fld = fn{ff};
                measNoise.(fld)(:) = params.(fld);
            end
            varargout = {measNoise};
        end

        function crossValidateInputs(filt, sensorData, groundTruth) 
            filt.validateSameTimetableTimes(sensorData, groundTruth);
        end

        function configure(filt, params)
            filt.State(:) = params.State;
            filt.StateCovariance(:) = params.StateCovariance;
            filt.AdditiveProcessNoise(:) = params.AdditiveProcessNoise;
        end
    end
    
    methods (Hidden)
        function p = getDefaultTunableParameters(filt)
            % Default Tunable Parameters uses AdditiveProcessNoise indices
            measnoise = fieldnames(getMeasNoiseExemplarFromInst(filt));
            procnoise = 'AdditiveProcessNoise';
            z = zeros(size(filt.AdditiveProcessNoise));
            z(:) = 1:numel(z);
            pnidx = diag(z);
            p = [ {{procnoise pnidx.'}} measnoise(:).'];
        end
    end


    methods (Hidden)
        % Protected versions of some of the above static methods. Overload for filters
        % which need the instance to complete the method tasks.
        % All methods named the same as above, with the suffix FromInst(ance)
        function [tunerparams, staticparams] = getParamsForAutotuneFromInst(filt)
            measnoise = fieldnames(getMeasNoiseExemplarFromInst(filt));
            procnoise = 'AdditiveProcessNoise';
            tunerparams = [...
                procnoise;    
                measnoise(:)].';
            p = properties(filt);
            staticparams = setdiff(p, procnoise).'; 
        end
        function measNoise = getMeasNoiseExemplarFromInst(filt)
            % Default implementation : call static method
            snames = filt.SensorNames;
            if ~isempty(snames)
                measNoiseNames = snames + "Noise"; 
            else
                measNoiseNames = string.empty;
            end
            [c{1:numel(snames)}] = deal(1);
            measNoise = cell2struct(c, measNoiseNames, 2);
        end
        function cost = tunerfuseFromInst(filt, params, sensorData, groundTruth, ~)
            configure(filt, params);
            state = positioning.internal.fuseTimetable(filt, params, sensorData);
            cost = filt.rmsStateErr(state, groundTruth, stateinfo(filt)); 
        end
    end

end
