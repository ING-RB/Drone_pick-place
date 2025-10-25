%TUNERPLOTPOSE Plot filter pose estimates during tuning
%   The TUNERPLOTPOSE function plots the current pose estimate (orientation
%   and possibly position, depending on the filter) along with the ground
%   truth values. The FPARAMS input is a struct which contains the best
%   estimates of the filter parameters during the current iteration of
%   tuning using the TUNE function. The FPARAMS struct contains one field
%   for every public property of the filter and additional fields for any
%   measurement noises needed. The exact field names vary depending on
%   which filter is being tuned. The TUNERVALUES struct has
%   fields
%       Iteration - the iteration count of the tuner 
%       SensorData - the sensor data input to the TUNE function 
%       GroundTruth - the ground truth input to the TUNE function 
%       Configuration - the TUNERCONFIG object used for tuning 
%       Cost - the tuning cost at the end of the current iteration
%
%   This function always returns FALSE indicating that tuning
%   should continue on to the next iteration.
%
%   Example: 
%
%       figure; % new window for plotting
%       tc = tunerconfig('imufilter', 'OutputFcn', @tunerPlotPose)
%       ld = load('imufilterTuneData.mat');
%       tune(imufilter, ld.sensorData, ld.groundTruth, tc);
%
%   See also TUNERCONFIG

 
%   Copyright 2020-2023 The MathWorks, Inc.

