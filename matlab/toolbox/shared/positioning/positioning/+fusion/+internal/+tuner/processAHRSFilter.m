function q = processAHRSFilter(params, sensorData)
%PROCESSAHRSFILTER Single run of the ahrsfilter on sensorData

%   Copyright 2020 The MathWorks, Inc.    

%#codegen 

filt = ahrsfilter;
fusion.internal.tuner.ahrsfilter.configure(filt, params, false);
filt.OrientationFormat = 'quaternion';
q = filt(sensorData.Accelerometer, sensorData.Gyroscope, ...
    sensorData.Magnetometer);
