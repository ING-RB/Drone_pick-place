classdef magnetometer < handle
    %Base class for magnetometer modules
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = protected, Constant)
        MagnetometerDataRegister; % output data register
    end
    
    properties(Abstract, Access = protected)
        MagnetometerResolution; % resolution
    end
    
    properties(Access = protected)
        MagnetometerDataName = {'MagneticField'};
    end
    
    methods(Abstract, Access = protected)
        data = readMagneticFieldImpl(obj);
        initMagnetometerImpl(obj);
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.sensors.coder.matlab.magnetometer';
        end
    end
    
    methods(Access = public)
        function  [data,timeStamp] = readMagneticField(obj)
            %   Read one sample of magnetic field values from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [magReadings,timestamp] = readMagneticField(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   magReadings - Magnetic field values on x,y and z axis read
            %   from sensor in units of µT (microtesla).
            %
            %   timestamp - the time at which MATLAB® receives magnetic feild data,
            %   specified as a datetime.
            %
            %   Example:
            %   a=arduino();
            %   imu = lsm9ds1(a);
            %   [magReadings,timestamp] = readMagneticField(imu)
            %
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.MagneticField(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming  
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming);
                else
                    [data,~,targetTime] = readMagneticFieldImpl(obj);
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

