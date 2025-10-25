classdef HumiditySensor < handle
    %   Humidity base class
    
    %   Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected, Constant)
        HumidityDataRegister; % output data register
    end
    
    properties(Access = protected)
        HumidityDataName = {'Humidity'};
    end
    
    methods(Abstract, Access = protected)
        data = readHumidityImpl(obj);
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.HumiditySensor';
        end
    end
    
    methods(Sealed, Access = public)
        function  [data,timeStamp] = readHumidity(obj)
            %   Read one sample of Humidity from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [humidityReadings, timestamp]= readHumidity(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   humidityReadings - Humidity readings
            %   read from sensor in units of %rH.
            %
            %   timestamp - the time at which MATLAB® receives humidity data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = hts221(a);
            %   [humidityReadings,timestamp] = readHumidity(imu)
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.Humidity(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming); 
                else
                    [data,~,targetTime] = readHumidityImpl(obj);
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
