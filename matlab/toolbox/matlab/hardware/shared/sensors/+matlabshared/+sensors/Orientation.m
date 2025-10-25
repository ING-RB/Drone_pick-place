classdef Orientation < handle
  % Parent class for Orientation sensors
  
    %   Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected,Constant)        
       OrientationDataRegister; % output data register
    end

    properties(Access = protected)
        OrientationDataName = {'Orientation'};
    end
    
    methods(Abstract, Access = protected)
        readOrientationImpl(obj); 
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.sensors.coder.matlab.Orientation';
        end
    end
    
    methods(Access = public)
        function [data,timeStamp] = readOrientation(obj)
            %   Read one sample of orientation data from imu sensor along with timestamp.
            %   
            %   Syntax:
            %   [Orientation,timestamp] = readOrientation(imu);
            %
            %   Input Argument:
            %   imu - Sensor object. 
            %
            %   Output Argument:
            %   Orientation - Orientation Values.
            %
            %   timestamp - the time at which MATLABÂ® receives accelerometer data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = bno055(a);
            %   [accelReadings,timestamp] = readOrientation(imu)
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.Orientation(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming  
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming);
                else
                    [data,~,targetTime] = readOrientationImpl(obj);
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