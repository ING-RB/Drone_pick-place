function states = processAHRS10Filter(params, sensorData)
%PROCESSAHRS10FILTER Run the ahrs10filter on sensorData

%   Copyright 2020 The MathWorks, Inc.    

%#codegen 


    filt = ahrs10filter;
    fusion.internal.tuner.ahrs10filter.configure(filt, params, false);
    accel = sensorData.Accelerometer;
    gyro = sensorData.Gyroscope;
    mag = sensorData.Magnetometer;
    alt = sensorData.Altimeter;

    doMag = all(~isnan(mag),2);
    doAlt = all(~isnan(alt),2);
    numdata = size(accel,1);
    ns = numel(filt.State);
    states = zeros(numdata,ns);

    for ii=1:numdata
        predict(filt, accel(ii,:), gyro(ii,:));
        if doMag(ii)
            fusemag(filt, mag(ii,:), params.MagnetometerNoise);
        end
        if doAlt(ii)
            fusealtimeter(filt, alt(ii), params.AltimeterNoise);
        end
        states(ii,:) = filt.State;
    end
    
    
