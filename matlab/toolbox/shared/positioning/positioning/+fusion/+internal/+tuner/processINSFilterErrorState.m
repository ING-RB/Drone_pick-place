function states = processINSFilterErrorState(params, sensorData)
%PROCESSINSFILTERERRORSTATE Run the insfilterErrorState on sensorData

%   Copyright 2020 The MathWorks, Inc.    

%#codegen 

    filt = insfilterErrorState;
    fusion.internal.tuner.insfilterErrorState.configure(filt, params, false);
    accel = sensorData.Accelerometer;
    gyro = sensorData.Gyroscope;
    gpspos = sensorData.GPSPosition;
    gpsvel = sensorData.GPSVelocity;
    mvopos = sensorData.MVOPosition;
    mvoorient = sensorData.MVOOrientation;

    doGPSPos = all(~isnan(gpspos),2);
    doGPSVel = all(~isnan(gpsvel),2);
    % In processSensorData we have ensured that nans are present in the
    % same locations in mvopos and movorient so we can just check mvopos
    % here.
    doMVO = all( ~isnan(mvopos), 2);
    numdata = size(accel,1);
    ns = numel(filt.State);
    states = zeros(numdata,ns);
    idx = stateinfo(filt);

    for ii=1:numdata
        predict(filt, accel(ii,:), gyro(ii,:));
        if doGPSPos(ii)
            fusegps(filt, gpspos(ii,:), params.GPSPositionNoise);
        end
        if doGPSVel(ii)
            correct(filt, idx.Velocity, gpsvel(ii,:), params.GPSVelocityNoise);
        end

        % Validation has previously happened (in processSensorData) that
        % mvopos and mvoorient occur together. There cannot be nans in one and not the other.
        if doMVO(ii)
            fusemvo(filt, mvopos(ii,:), params.MVOPositionNoise, mvoorient{ii}, params.MVOOrientationNoise);
        end
        states(ii,:) = filt.State;
    end
    
    
