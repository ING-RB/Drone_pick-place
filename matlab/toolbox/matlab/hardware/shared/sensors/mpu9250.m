classdef (Sealed) mpu9250 < matlabshared.sensors.sensorBoard
    %MPU9250 connects to the MPU9250 sensor connected to a hardware object
    %
    %   IMU = mpu9250(a) returns a System object, IMU that reads sensor
    %   data from the MPU9250 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   IMU = mpu9250(a, 'Name', Value, ...) returns a MPU9250 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   mpu9250 Properties
    %   I2CAddress      : Specify the I2C Address of the MPU9250.
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
    %                     value is ‘timetable’.
    %   TimeFormat      : Format of time stamps returned by read function.
    %                     TimeFormat can be either 'datetime' or 'duration'
    %                     Default value is 'datetime'.
    %   SamplesAvailable: Number of samples remaining in the buffer waiting
    %                     to be read.
    %   SamplesRead     : Number of samples read from the sensor.
    %
    %   mpu9250 methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.
    %   readAngularVelocity   : Read one sample of angular velocity values from
    %                           sensor. 
    %   readMagneticFeild     : Read one sample of magnetic field values from
    %                           sensor.
    %   read                  : Read one frame of acceleration, angular
    %                           velocity and magnetic field values from 
    %                           the sensor along with time stamps and 
    %                           overruns.
    %  stop/release           : Stop sending data from hardware and
    %                           allow changes to non-tunable properties
    %                           values and input characteristics.
    %  flush                  : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %  info                   : Read sensor information such as output
    %                           data rate, bandwidth and so on.
    %
    %  Note: For targets other than Arduino, mpu9250 object is supported 
    %  with limited functionality. For those targets, you can use the
    %  'readAcceleration', 'readAngularVelocity', and 'readMagneticField' 
    %  functions, and the 'Bus' and 'I2CAddress' properties.
    %  
    %   Example 1: Read one sample of acceleration value from MPU9250 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = mpu9250(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an MPU9250 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = mpu9250(a,'SampleRate',100,'SamplesPerRead',15);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from MPU9250 sensor');
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
    %     [accel,gyro,mag] = read(sensorObj);
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
    %   readAngularVelocity, readMagneticField
    
    %   Copyright 2018-2021 The MathWorks, Inc.
    %#codegen
    
    properties(Access = public, Hidden)
        SensorObjects = {};
    end
    
    properties(Constant, Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Hidden)
        NumSensorUnits = 2;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    methods
        function obj = mpu9250(varargin)
            % Code generation does not support try-catch block. So init
            % function call is made separately in both codegen and IO
            % context.
            obj@matlabshared.sensors.sensorBoard(varargin{:})
            if ~coder.target('MATLAB')
                obj.init(varargin{:});
            else
                try
                    obj.init(varargin{:})
                catch ME
                    throwAsCaller(ME);
                end
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
            %   timestamp - the time at which MATLAB® receives accelerometer data,
            %   specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = mpu9250(a);
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
            %   timestamp - the time at which MATLAB® receives angular velocity data,
            %   specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = mpu9250(a);
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
            %   timestamp - the time at which MATLAB® receives magnetic feild data,
            %   specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = mpu9250(a);
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
    
    methods(Access = protected)
        function createSensorUnitsImpl(obj,varargin)
            accelGyro = sensors.internal.mpu9250_accel_gyro(varargin{:});
            magneto = sensors.internal.ak8963(varargin{:});
            obj.SensorObjects = {accelGyro, magneto};
        end
    end

    methods(Access={?matlabshared.sensors.simulink.internal.SensorBlockBase})
        function interface = getSensorInterface(obj)
            interface = obj.Interface;
        end
    end
end

