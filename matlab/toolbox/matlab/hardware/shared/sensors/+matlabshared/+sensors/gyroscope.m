classdef gyroscope < handle
  %Base class for gyroscope  modules
  
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected, Constant)
        GyroscopeDataRegister; % output data register
    end
    
    properties(Access = protected)
        % not making this property as abstract because not every sensor
        % have this parameter
        GyroscopeDataName = {'AngularVelocity'};
    end
    
    methods(Abstract, Access = protected)
        data = readAngularVelocityImpl(obj);
        initGyroscopeImpl(obj);
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.gyroscope';
        end
    end
    
    methods(Access = public)
        function  [data,timeStamp] = readAngularVelocity(obj)
            %   Read one sample of angular velocity from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [gyroReadings, timestamp]= readAngularVelocity(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   gyroReadings - Angular Velocity values on x,y and z axis
            %   read from sensor in units of rad/s.
            %
            %   timestamp - the time at which MATLAB® receives angular velocity data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = mpu6050(a);
            %   [gyroReadings,timestamp] = readAngularVelocity(imu)
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.AngularVelocity(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming); 
                else
                    [data,~,targetTime] = readAngularVelocityImpl(obj);
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
