classdef (Hidden) GPSUtilities < matlabshared.sensors.internal.Accessor
    
    % This class provides internal API to be used by GPS sensor
    % infrastructure. It should be inherited by the hardware class to
    % support GPS
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods(Abstract, Access = protected)
        % Implement the following methods in the hardware class
        getBoardSpecificPropertiesGPSImpl(obj,callingObj,serialPort);
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % Codegen redirector class. During codegen the current class
            % will willbe replaced by the following class
            name = 'matlabshared.sensors.coder.matlab.GPSUtilities';
        end
    end
    
    methods(Hidden)
        function gpsObj = gpsdev(obj,varargin)
            %GPSDEV creates a connection to GPS Receiver
            %
            %  Syntax:
            %      gpsObj = gpsdev(hardwareObj)              Creates a connection to GPS Reciever connected to SerialPort of the hardware board specified by hardwareObj.
            %      gpsObj = gpsdev(hardwareObjt,Name,Value)  Creates a connection to GPS Reciever connected to SerialPort of the hardware board specified by hardwareObj with additional Name-Value options.
            %
            %  Example
            %    % Creates a connection to GPS Reciever connected to SerialPort of the hardware board specified by hardwareObj
            %    a = arduino("com4","Mega2560","Libraries","Serial")
            %    g = gpsdev(a)
            %
            %    % Creates a connection to GPS Reciever connected to a specified serialPort of the hardware board specified by hardwareObj
            %    g = gpsdev(a,"Serialport",2);
            %
            %    Creates a connection to the GPS Receiver on the hardware board with additional Name-Value options.
            %    g = gpsdev(a,"SamplesPerRead",2,"OutputFormat","matrix","TimeFormat","timetable","ReadMode","oldest");
            %
            %  GPSDEV properties:
            %
            %   SerialPort : The ID of the serial port available on the Arduino
            %   hardware specified as a number.Default value is 1.
            %
            %   Note: The properties ReadMode, SamplesPerRead, OutputFormat,TimeFormat, SamplesRead and SamplesAvailable are only available with Sensor Fusion and Tracking toolbox or
            %   Navigation toolbox
            %
            %   Non tunable properties:
            %
            %   ReadMode        -  Choose whether to read the latest available readings or the values accumulated from the beginning.
            %                      The property can have value 'latest'(default) or 'oldest'.
            %
            %   SamplesPerRead   - A positive integer in the range [1 10]. Default value is 1.
            %
            %   Tunable properties:
            %
            %   OutputFormat     - Format of output data can be 'timetable' (default) or 'matrix'.
            %   TimeFormat       - Format of time stamps can be 'datetime' (default) or 'duration'.
            %
            %   Read only properties:
            %
            %   SamplesAvailable - Number of samples remaining in the buffer waiting to be read.
            %   SamplesRead      - Number of samples read from the sensor.
            %   BaudRate         - The baudrate at which hardware object is expecting data from GPS module
            %
            %  GPSDEV methods:
            %
            %   read                - Returns one frame each of lla (latitude,longitude, altitude), ground speed, course, DOPs (PDOP, HDOP, VDOP) and GPS Receiver time
            %                         along with time stamps and overrun.
            %   flush               - Flushes all the data accumulated in the buffers and resets 'SamplesAvailable' and 'SamplesRead'.
            %   writeBytes          - Writes raw commands to GPS module.
            %   info                - Returns GPS Update Rate, Number of Satellites in view the module can use and GPS lock information
            %   stop/release        - Tells hardware to stop sending data and release the system object.
            try
               gpsObj= sensors.internal.gpsdev(obj,varargin{:});
            catch ME
                throwAsCaller(ME);
            end
        end
    end
    
    methods (Access = {?matlabshared.sensors.internal.Accessor})
        % These functions are to be used only by GPS
        
        function getStreamingRateGPS(obj,gpsObject)
            % The rate at which GPS data is read from hardware is being set
            % here. This implementation is specific to Arduino Boards. The
            % rate at which GPS data is read is found from the BaudRate of
            % the GPS. An additional +15 is given, so as to avoid data loss
            getStreamingRateGPSHook(obj, gpsObject);
        end
        
        function getBoardSpecificPropertiesGPS(obj,callingObj,serialPort)
            getBoardSpecificPropertiesGPSImpl(obj,callingObj,serialPort);
        end
    end
    
    methods(Access = protected)
        function getStreamingRateGPSHook(obj,gpsObject)
            % The rate at which GPS data is read from arduino is being set
            % here. This implementation is specific to Arduino Boards. The
            % rate at which GPS data is read is found from the BaudRate of
            % the GPS. An additional +15 is given, so as to avoid data loss
            gpsObject.RateReadfromTarget = round((gpsObject.Device.BaudRate)/(10*gpsObject.BytesToRead))+ 15;
            % If multiple sensors are streaming at a higher rate than GPS, keep the rate of gps and imu same to
            % avoid performance degradation of high rate streaming
            % sensor.
            for index = 1:obj.NumOfStreamingObject
                if(isa(obj.StreamingObjects{index},'matlabshared.sensors.sensorBase'))
                    if(gpsObject.RateReadfromTarget <= obj.StreamingObjects{index}.SampleRate)
                        gpsObject.RateReadfromTarget = obj.StreamingObjects{index}.SampleRate;
                    else
                        error(message('matlab_sensors:general:sensorSampleRateLimitation',num2str(gpsObject.RateReadfromTarget)));
                    end
                end
            end
        end
    end
end