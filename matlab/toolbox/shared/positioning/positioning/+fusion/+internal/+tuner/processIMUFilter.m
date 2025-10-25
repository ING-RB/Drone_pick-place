function q = processIMUFilter(params, sensorData)
%PROCESSIMUFILTER Single run of the imufilter on sensorData

%   Copyright 2020 The MathWorks, Inc.    

%#codegen 

filt = imufilter;
fusion.internal.tuner.imufilter.configure(filt, params, false);
filt.OrientationFormat = 'quaternion';
q = filt(sensorData.Accelerometer, sensorData.Gyroscope);
    
