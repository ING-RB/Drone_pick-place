function states = processINSFilterNonholonomic(params, sensorData)
%PROCESSINSFILTERNonholonomic Run the insfilterNonholonomic on sensorData

%   Copyright 2020 The MathWorks, Inc.    

%#codegen 

    filt = insfilterNonholonomic;
    fusion.internal.tuner.insfilterNonholonomic.configure(filt, params, false);
    accel = sensorData.Accelerometer;
    gyro = sensorData.Gyroscope;
    gpspos = sensorData.GPSPosition;
    gpsvel = sensorData.GPSVelocity;

    doGPSPos = all(~isnan(gpspos),2);
    doGPSVel = all(~isnan(gpsvel),2);
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
        states(ii,:) = filt.State;
    end
    
    
