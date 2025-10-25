function states = processINSFilterAsync(params, sensorData)
%PROCESSINSFILTERASYNC Run the insfilterAsync on sensorData

%   Copyright 2020 The MathWorks, Inc.    

%#codegen 


    filt = insfilterAsync;
    fusion.internal.tuner.insfilterAsync.configure(filt, params, false);

    % Fuse sensorData using filt and noise values in params.
    accel = sensorData.Accelerometer;
    gyro = sensorData.Gyroscope;
    mag = sensorData.Magnetometer;
    gpspos = sensorData.GPSPosition;
    gpsvel = sensorData.GPSVelocity;

    doAccel = all(~isnan(accel),2);
    doGyro = all(~isnan(gyro),2);
    doMag = all(~isnan(mag),2);
    doGPSPos = all(~isnan(gpspos),2);
    doGPSVel = all(~isnan(gpsvel),2);
    numdata = size(accel,1);
    ns = numel(filt.State);
    states = zeros(numdata,ns);
    dt = seconds(diff(sensorData.Properties.RowTimes));
    idx = stateinfo(filt);

    for ii=1:numdata
        if ii ~= 1
            predict(filt, dt(ii-1));
        end
        if doAccel(ii)
            fuseaccel(filt, accel(ii,:), params.AccelerometerNoise);
        end
        if doGyro(ii)
            fusegyro(filt, gyro(ii,:), params.GyroscopeNoise);
        end
        if doMag(ii)
            fusemag(filt, mag(ii,:), params.MagnetometerNoise);
        end
        if doGPSPos(ii)
            fusegps(filt, gpspos(ii,:), params.GPSPositionNoise);
        end
        if doGPSVel(ii)
            correct(filt, idx.Velocity, gpsvel(ii,:), params.GPSVelocityNoise);
        end
        states(ii,:) = filt.State;
    end

end
