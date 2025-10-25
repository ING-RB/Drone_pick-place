classdef VoltageSensor < handle
     %   Base class for Voltage outputs
     %   Copyright 2022-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected, Constant)
        VoltageDataRegister; % output data register
    end
    
    properties(Access = protected)
        VoltageDataName = {'Voltage'};
    end
    
    methods(Abstract, Access = protected)
        data = readVoltageImpl(obj,pinNumber);
    end
     
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.VoltageSensor';
        end
    end
    
    methods(Access = public)
        function  [data,timeStamp] = readVoltage(obj,pinNumber)
            %   Read one sample of Voltage from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [VoltageReadings, timestamp]= readVoltage(sensorObj,"ADC1");
            %
            %   Input Argument:
            %   sensor - Sensor object.
            %
            %   Output Argument:
            %   VoltageReadings - digital reading
            %
            %   timestamp - the time at which MATLAB® receives Voltage data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = lis3dh(a);
            %   [VoltageReadings,timestamp] = readVoltage(imu,"ADC1")
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj,obj.VoltageDataName{1});
                    data = dataOut.Voltage(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming); 
                else
                    [data,~,targetTime] = readVoltageImpl(obj,pinNumber);
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
