classdef PressureSensor < handle
     %   Base class for pressure outputs
     
     %   Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected, Constant)
        PressureDataRegister; % output data register
    end
    
    properties(Access = protected)
        PressureDataName = {'Pressure'};
    end
    
    methods(Abstract, Access = protected)
        data = readPressureImpl(obj);
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.PressureSensor';
        end
    end
    
    methods(Sealed, Access = public)
        function  [data,timeStamp] = readPressure(obj)
            %   Read one sample of Pressure from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [pressureReadings, timestamp]= readPressure(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   pressureReadings - Pressure readings
            %   read from sensor in units of hPa.
            %
            %   timestamp - the time at which MATLAB® receives pressure data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = lps22hb(a);
            %   [pressureReadings,timestamp] = readPressure(imu)
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.Pressure(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming  
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming);
                else
                    [data,~,targetTime] = readPressureImpl(obj);
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
