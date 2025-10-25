classdef TemperatureSensor < handle
    %Base class for temperature modules
    
    %   Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected, Constant)
        TemperatureDataRegister; % output data register
    end
    
    properties(Access = protected)
        TemperatureDataName = {'Temperature'};
    end
    
    methods(Abstract, Access = protected)
        data = readTemperatureImpl(obj);
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.TemperatureSensor';
        end
    end
    
    methods(Access = public)
        function  [data,timeStamp] = readTemperature(obj)
            %   Read one sample of temperature from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [temp, timestamp]= readTemperature(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   temp - Temperature reading in degree Celsius
            %
            %   timestamp - the time at which MATLAB® receives temperature data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = lsm6ds3(a);
            %   [temp,timestamp] = readTemperature(imu)
            try
                 timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.Temperature(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming); 
                else
                    [data,~,targetTime] = readTemperatureImpl(obj);
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
