classdef (Hidden, Abstract) GPSUtilities < handle
    
    % This class is the codegen class for
    % matlabshared.sensors.GPSUtilities. It does not add any feature.
    % Rather this empty class ensures that when a hardware class inherits
    % matlabshared.sensors.GPSUtilities, no unneccessary error is thrown
    % while generating code from sensor object. Also, it errors out when
    % gpsdev function is called.
    
    % Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    methods(Hidden)
        function gpsObj = gpsdev(varargin)
            gpsObj = [];
            coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionCodegen', 'gpsdev');
        end
    end
end