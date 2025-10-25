function [poseEst, smEst] = estimateStates(filt, sensorData, mnoise)
% ESTIMATESTATES Estimate states based on sensor data and motion model 
%   POSEEST = ESTIMATESTATES(FILT, SENSORDATA, MNOISE) forms state
%   estimates based on the motion model used by FILT, the sensor data in
%   SENSORDATA, and the measurement noise in MNOISE. FILT is a handle to an
%   insEKF instance.
%   
%   The SENSORDATA input is a timetable where each variable name matches a
%   SensorName of FILT. The ESTIMATESTATES function will predict the filter
%   state estimates forward in time based on the timestamps in SENSORDATA
%   and then fuse data from table columns one-by-one along each row. The
%   elements of the timetable SENSORDATA are sensor measurements taken at
%   each row time. When data is not present from a sensor at a given time
%   step the timetable element should contain NaNs.
%   
%   The measurement noise MNOISE is a struct of measurement noises with
%   field names of STRCAT(FILT.SensorNames, "Noise"). 
%   
%   The POSEEST output is a timetable with the same number of rows and same
%   RowTimes as SENSORDATA. Each state is one column of the table and a the
%   state covariance is the final column StateCovariance.
%
%   [POSEEST, SMEST] = ESTIMATESTATES(...) returns a timetable SMEST of
%   the same size as POSEEST containing smoothed versions of the state
%   variables. The smoothed estimate is the result of a Rauch-Tung-Striebel
%   nonlinear Kalman smoother. 
%
%   Example : Fuse sensor data
%
%   ld = load("accelGyroINSEKFData.mat");
%   filt = insEKF;
%   stateparts(filt, "Orientation", compact(ld.initOrient));
%   statecovparts(filt, "Orientation", 1e-2);
%
%   % Use optimal noise parameters obtained using the tune function. See
%   % help insEKF/tune for more information.
%   mnoise = struct("AccelerometerNoise", 0.1739, ...
%       "GyroscopeNoise", 1.1129);
%   apn = diag([...
%     2.8586 1.3718 0.8956 3.2148 4.3574 2.5411 3.2148 0.5465 0.2811 ...
%     1.7149 0.1739 0.7752 0.1739]);
%   filt.AdditiveProcessNoise = apn;
%   
%   % Estimate states with a tuned filter
%   [est, sm] = estimateStates(filt, ld.sensorData, mnoise);
%
%   % Plot estimated vs smoothed results
%   subplot(3,1,1)
%   t = est.Properties.RowTimes;
%   gto = ld.groundTruth.Orientation;
%   plot(t, eulerd(est.Orientation, 'ZYX', 'frame'));
%   title('Estimated Orientation');
%   ylabel('Degrees')
%   subplot(3,1,2)
%   plot(t, eulerd(sm.Orientation, 'ZYX', 'frame'));
%   title('Smoothed Orientation');
%   ylabel('Degrees')
%   subplot(3,1,3);
%   plot(t, rad2deg(dist(est.Orientation, gto)), ...
%     t, rad2deg(dist(sm.Orientation, gto)));
%   title('Estimated and Smoother Error');
%   legend('Estimation Error', 'Smoother Error')
%   xlabel('Time');
%   ylabel('Degrees')
%
%
%   See also: insEKF, insEKF/tune

%   Copyright 2021-2022 The MathWorks, Inc.      

%#codegen 

    %%%%%%%%%%%%%%%%%%%%%%%%%
    % Validation
    
    % Ensure sensorData is a timetable and the columns match Filt.SensorNames
    coder.internal.assert(isa(sensorData, 'timetable'), ...
        'insframework:insEKF:EstimateTimeTable');

    % Ensure mnoise is a struct
    coder.internal.assert(isstruct(mnoise) && isscalar(mnoise), ...
        'insframework:insEKF:EstimateMnoiseStruct');

    sensorNames = filt.SensorNames;
    sdVars = sensorData.Properties.VariableNames; 
    mnfields = fieldnames(mnoise);

    for ii=1:numel(sdVars)
        % Ensure sensorData variables match a filt.SensorNames element
        coder.internal.assert(local_ismember(sdVars{ii}, sensorNames), ...
            'insframework:insEKF:EstimateVarNames', sdVars{ii}, ...
            strjoin(sensorNames, ', ' ));

        % Ensure mnoise has the needed measurement noises
        thisnoise = [sdVars{ii} 'Noise']; 
        coder.internal.assert(local_ismember(thisnoise, mnfields), ...
            'insframework:insEKF:EstimateMnoiseNames', thisnoise, ...
            strjoin(mnfields, ', ' ));
    end

    % End validation
    %%%%%%%%%%%%%%%%%%%%%%%%%


    % Estimate and optionally smooth

    rtimes = sensorData.Properties.RowTimes;
    
    if (nargout == 1)
        [state, statecov] = positioning.internal.fuseTimetable(...
            filt, mnoise, sensorData);
        poseEst = buildOutputTable(state, statecov, rtimes, filt);
        
    else
        [state, statecov, imd] = positioning.internal.fuseTimetable(...
            filt, mnoise, sensorData);
        poseEst = buildOutputTable(state, statecov, rtimes, filt);
        % Smooth if requested.
        % Save state
        stateFinal = filt.State;
        scFinal = filt.StateCovariance;
        % Smooth - walk backwards over data
        [smstate, smstatecov] = rtsSmooth(filt, imd.state, imd.statecov, rtimes);
        % Restore state
        filt.State = stateFinal;
        filt.StateCovariance = scFinal;
        smEst = buildOutputTable(smstate, smstatecov, rtimes, filt);
    end
end

function tbl = buildOutputTable(state, statecov, timestamps, filt)
    % Build output timetable
    idx = stateinfo(filt);
    fn = fieldnames(idx);
    Nfields = numel(fn);
    vars = cell(1,Nfields);
    names = cell(1,Nfields);
    coder.unroll;
    for ii=1:Nfields
        thisfield = fn{ii};
        v = state(:,idx.(thisfield));
        % Try to make likely quaternions into quaternions
        if strcmpi(thisfield, 'Orientation') && size(v,2) == 4
            vars{ii} = quaternion(v);
        else
            vars{ii} = v;
        end
        names{ii} = thisfield;
    end

    % Convert statecov to a column vector cell array. Each row is a page of
    % the statecov array.
    % MATLAB equivalent is : statecovCol = squeeze(num2cell(statecov,[1 2]));
    % but that doesn't code generate, so....
    [~,~,sz3] = size(statecov);
    statecovCol = cell(sz3,1);
    for ii=1:sz3
        statecovCol{ii} = statecov(:,:,ii);
    end

    % Create a timetable with the same RowTimes as the input sensorData
    tbl = timetable(vars{:}, statecovCol, ...
        'VariableNames', {names{:}, 'StateCovariance'}, ...
        'RowTimes', timestamps);

    
end
