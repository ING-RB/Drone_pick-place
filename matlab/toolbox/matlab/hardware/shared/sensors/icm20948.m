classdef (Sealed) icm20948 < matlabshared.sensors.sensorBoard
    %ICM20948 connects to the ICM-20948 sensor connected to the I2C bus of the hardware board.
    %
    %   IMU = icm20948(hardwareObj) returns a ICM-20948 System object with 
    %   default property values. The argument 'hardwareObj' represents the 
    %   connection to the hardware board. The icm20948 object can be used to 
    %   read sensor data from the ICM-20948 sensor connected to the I2C bus   
    %   of the hardware board. 
    %
    %   IMU = icm20948(hardwareObj, 'Name', Value, ...) returns a ICM-20948 
    %   System object with each specified property name set to the specified 
    %   value. You can specify additional name-value pair arguments in any 
    %   order as (Name1, Value1, ...,NameN, ValueN).
    %
    %   icm20948 Properties:
    %
    %   I2CAddress      : Specify the I2C Address of the ICM-20948 sensor.
    %   Bus             : Specify the I2C Bus where sensor is connected.
    %   ReadMode        : Specify whether to return the latest available
    %                     sensor values or the values accumulated from the
    %                     beginning when the 'read' API is executed.
    %                     ReadMode can be either 'latest' or 'oldest'.
    %                     Default value is 'latest'.
    %   SampleRate      : Rate at which samples are read from hardware.
    %                     Default value is 100 (samples/s).
    %   SamplesPerRead  : Number of samples returned per execution of read
    %                     function. Default value is 10
    %   OutputFormat    : Format of output of read function. OutputFormat
    %                     can be either 'timetable' or 'matrix'. Default
    %                     value is 'timetable'.
    %   TimeFormat      : Format of time stamps returned by read function.
    %                     TimeFormat can be either 'datetime' or 'duration'
    %                     Default value is 'datetime'.
    %   SamplesAvailable: Number of samples remaining in the buffer waiting
    %                     to be read.
    %   SamplesRead     : Number of samples read from the sensor.
    %
    %   icm20948 methods:
    %
    %   readAcceleration      : Returns one sample of acceleration data on  
    %                           x, y, and z axes read from the sensor along
    %                           with the timestamp.
    %   readAngularVelocity   : Returns one sample of angular velocity data on  
    %                           x, y, and z axes read from the sensor along
    %                           with the timestamp.
    %   readMagneticField     : Returns one sample of magnetic field data on  
    %                           x, y, and z axes read from the sensor along
    %                           with the timestamp.
    %   readTemperature       : Returns one sample of temperature data read 
    %                           read from the sensor along  with the 
    %                           timestamp.                          
    %   read                  : Returns one frame of acceleration, angular
    %                           velocity, magnetic field  and temperature
    %                           values read from the sensor at the specified
    %                           rate along with timestamps and overruns.
    %                           The number of samples depends on the
    %                           'SamplesPerRead' value specified while
    %                           creating the sensor object.
    %  stop/release           : Stops sending data from the hardware and 
    %                           allow changes to non-tunable properties 
    %                           values.
    %  flush                  : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %  info                   : Read sensor information such as output
    %                           data rate, bandwidth and so on.
    %
    %  Note: For Arduino, real-time data rate acquisition from ICM-20948 
    %  sensor can be achieved by using the 'Samplerate' property and read 
    %  function. For hardware boards other than Arduino, icm20948 object is 
    %  supported with limited functionality. For those hardware boards, you 
    %  can use the readAcceleration, readAngularVelocity, readMagneticField,  
    %  and readTemperature functions, and the 'Bus' and 'I2CAddress' 
    %  properties to acquire data from the ICM-20948 sensor.
    %
    %  Example 1: Read one sample of acceleration value from ICM-20948 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = icm20948(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %  Example 2: Read and plot acceleration values from an ICM-20948 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = icm20948(a,'SampleRate',120,'SamplesPerRead',15);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from ICM20948 sensor');
    %   x_val = animatedline('Color','r');
    %   y_val = animatedline('Color','g');
    %   z_val = animatedline('Color','b');
    %   axis tight;
    %   legend('Acceleration in X-axis','Acceleration in Y-axis',...
    %      'Acceleration in Z-axis');
    %   stop_time = 10; %  time in seconds
    %   count = 1;
    %   tic;
    %   while(toc <= stop_time)
    %     [accel,gyro,temp,mag] = read(sensorObj);
    %     addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %     addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %     addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %     count = count + sensorObj.SamplesPerRead;
    %     drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also mpu6050, lsm9ds1, bno055, read, readAcceleration,
    %   readTemperature, readAngularVelocity, readMagneticField

    %   Copyright 2021 The MathWorks, Inc.

    %#codegen
    properties(Access = public, Hidden)
        SensorObjects = {};
    end

    properties(Constant, Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Hidden)
        NumSensorUnits = 2;
    end

    properties (Access=private,Nontunable)
        AccelGyroTempArguments = {};
        MagArguments = {};
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    methods
        function obj = icm20948(varargin)
            % Code generation does not support try-catch block. So init
            % function call is made separately in both codegen and IO
            % context.
            obj@matlabshared.sensors.sensorBoard(varargin{:})
            if ~obj.isSimulink
                % For MATLAB workflow, ensure only below name value pairs
                % are used.
                names = {'Bus','OutputFormat','TimeFormat','SamplesPerRead', 'SampleRate','ReadMode','I2CAddress'};
                defaults = {[],'timetable','datetime', 10, 100, 'latest',[]};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:})
                    catch ME
                        throwAsCaller(ME);
                    end
                end
            else
                names = {'Bus','I2CAddress','IsOutDoubleType','IsActiveAccel', 'IsActiveGyro', 'IsActiveTemp', 'IsActiveMag', ...
                    'AccelerometerRange', 'AccelerometerODR', 'AccelerometerBW',...
                    'GyroscopeRange', 'GyroscopeODR', 'GyroscopeBW', 'TemperatureBW' ,'MagnetometerODR',...
                    'EnableDRDY','IsActiveLow'};
                defaults = {0,[],true,true,true,true,true,2,100,23.9,250,100,23.9,34.1,100,false,false};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                obj.AccelGyroTempArguments = {'IsActiveAccel',p.parameterValue('IsActiveAccel'),'AccelerometerRange',p.parameterValue('AccelerometerRange'),...
                    'AccelerometerODR',p.parameterValue('AccelerometerODR'),'AccelerometerBW',p.parameterValue('AccelerometerBW'),...
                    'IsActiveMag',p.parameterValue('IsActiveMag'), 'IsActiveGyro',p.parameterValue('IsActiveGyro'), 'GyroscopeRange',p.parameterValue('GyroscopeRange'),...
                    'GyroscopeODR',p.parameterValue('GyroscopeODR'),'GyroscopeBW',p.parameterValue('GyroscopeBW'),...
                    'IsActiveTemp',p.parameterValue('IsActiveTemp'),'TemperatureBW',p.parameterValue('TemperatureBW')...
                    'EnableDRDY',p.parameterValue('EnableDRDY'),'IsActiveLow',p.parameterValue('IsActiveLow'),'IsOutDoubleType',p.parameterValue('IsOutDoubleType')};
                obj.MagArguments = {'MagnetometerODR',p.parameterValue('MagnetometerODR'),'IsOutDoubleType',p.parameterValue('IsOutDoubleType')};
                obj.init(varargin{1},'Bus',p.parameterValue('Bus'),'I2CAddress',p.parameterValue('I2CAddress'));
            end
        end

        function [data,varargout] = readAcceleration(obj)
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
            %   timestamp - the time at which MATLAB® receives accelerometer
            %   data, specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = icm20948(a);
            %   [accelReadings,timestamp] = readAcceleration(imu)

            nargoutchk(0,2);
            if coder.target('MATLAB')
                [data,timeStamp] = readAcceleration(obj.SensorObjects{1});
                varargout{1} = timeStamp;
            else
                % To avoid unneccessary function call on hardware, get
                % timestamp from target only if it is requested.
                data = readAcceleration(obj.SensorObjects{1});
                if nargout == 2
                    varargout{1} = getCurrentTime(obj.Parent);
                end
            end
        end

        function [data,varargout] = readAngularVelocity(obj)
            %   Read one sample of angular velocity from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [gyroReadings,timestamp] = readAngularVelocity(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   gyroReadings - Angular Velocity values on x,y and z axis
            %   read from sensor in units of rad/s.
            %
            %   timestamp - the time at which MATLAB® receives angular
            %   velocity data, specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = icm20948(a);
            %   [gyroReadings,timestamp] = readAngularVelocity(imu)
            nargoutchk(0,2);
            if coder.target('MATLAB')
                [data,timeStamp] = readAngularVelocity(obj.SensorObjects{1});
                varargout{1} = timeStamp;
            else
                % To avoid unneccessary function call on hardware, get
                % timestamp from target only if it is requested.
                data = readAngularVelocity(obj.SensorObjects{1});
                if nargout == 2
                    varargout{1} = getCurrentTime(obj.Parent);
                end
            end
        end

        function [data,varargout] = readTemperature(obj)
            %   Read one sample of temperature from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [tempReadings,timestamp] = readTemperature(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   tempReadings - Temperature values in units of degree Celsius.
            %
            %   timestamp - the time at which MATLAB® receives temperature
            %   data, specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = icm20948(a);
            %   [tempReadings,timestamp] = readTemperature(imu)

            nargoutchk(0,2);
            if coder.target('MATLAB')
                [data,timeStamp] = readTemperature(obj.SensorObjects{1});
                varargout{1} = timeStamp;
            else
                % To avoid unneccessary function call on hardware, get
                % timestamp from target only if it is requested.
                data = readTemperature(obj.SensorObjects{1});
                if nargout == 2
                    varargout{1} = getCurrentTime(obj.Parent);
                end
            end
        end

        function [data,varargout] = readMagneticField(obj)
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
            %   timestamp - the time at which MATLAB® receives magnetic
            %   feild data, specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = icm20948(a);
            %   [magReadings,timestamp] = readMagneticField(imu)
            %
            nargoutchk(0,2);
            if coder.target('MATLAB')
                [data,timeStamp] = readMagneticField(obj.SensorObjects{2});
                varargout{1} = timeStamp;
            else
                % To avoid unneccessary function call on hardware, get
                % timestamp from target only if it is requested.
                data = readMagneticField(obj.SensorObjects{2});
                if nargout == 2
                    varargout{1} = getCurrentTime(obj.Parent);
                end
            end
        end
    end

    methods(Hidden)
        function [status, timeStamp] = readStatus(obj)
            status = uint8([1,1]);
            [status(1),timeStamp] = readStatus(obj.SensorObjects{1});
            [status(2),~] = readStatus(obj.SensorObjects{2});
        end
    end

    methods(Access = protected)
        function createSensorUnitsImpl(obj,varargin)
            accelGyro = sensors.internal.icm20948_accel_gyro_temp(varargin{:},obj.AccelGyroTempArguments{:});
            magneto = sensors.internal.ak09916(varargin{:},obj.MagArguments{:});
            obj.SensorObjects = {accelGyro, magneto};
        end
    end

    methods(Access={?matlabshared.sensors.simulink.internal.SensorBlockBase})
        function interface = getSensorInterface(obj)
            interface = obj.Interface;
        end
    end
end