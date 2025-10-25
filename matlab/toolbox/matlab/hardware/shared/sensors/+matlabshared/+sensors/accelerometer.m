classdef accelerometer < handle
  %Base class for accelerometer modules
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected, Constant)
        AccelerometerDataRegister; % output data register
    end
        
    properties(Access = protected)
        AccelerometerDataName = {'Acceleration'};
    end
    
    methods(Abstract,Access = protected)
        readAccelerationImpl(obj);
        initAccelerometerImpl(obj);
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.accelerometer';
        end
    end
    
    methods(Access = public)
        function [data,timeStamp] = readAcceleration(obj)
            %   Read one sample of acceleration from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [accelReadings,timestamp] = readAcceleration(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   accelReadings - Acceleration values on x,y and z axis
            %   read from sensor in units of m/s^2.
            %
            %   timestamp - the time at which MATLAB® receives accelerometer data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = mpu6050(a);
            %   [accelReadings,timestamp] = readAcceleration(imu)
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.Acceleration(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand / Streaming
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming); 
                else
                    [data,~,targetTime] = readAccelerationImpl(obj);
                    % Target time will only be returned for streaming case,
                    % Use target time in such instances
                    if ~isempty(targetTime)
                        timeStamp = targetTime;
                    else
                    	%Collect DDUX data for sensors (MATLAB). 
                    	%The second argument determines the mode OnDemand /
                        %Streaming / OnDemandWhileStreaming
                        dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemand);  
                    end
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end
end