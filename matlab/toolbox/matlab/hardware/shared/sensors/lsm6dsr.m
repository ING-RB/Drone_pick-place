classdef lsm6dsr < sensors.internal.LSM6DSRAnd6DSOBase
    %LSM6DSR connects to the LSM6DSR sensor connected to a hardware object
    %
    %   IMU = lsm6dsr(a) returns a System object, IMU that reads sensor
    %   data from the LSM6DSR sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   IMU = lsm6dsr(a, 'Name', Value, ...) returns a LSM6DSR System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   lsm6dsr Properties
    %   I2CAddress      : Specify the I2C Address of the LSM6DSR.
    %   Bus             : Specify the I2C Bus where sensor is connected.
    %   ReadMode        : Specify whether to return the latest available
    %                     sensor values or the values accumulated from the
    %                     beginning when the 'read' API is executed.
    %                     ReadMode can be either 'latest' or 'oldest'.
    %                     Default value is 'latest'.
    %   SampleRate      : Rate at which samples are read from hardware.
    %                     Default value is 100 (samples/s).
    %   SamplesPerRead  : Number of samples returned per execution of read
    %                     function. Default value is 10.
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
    %   lsm6dsr methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.
    %   readAngularVelocity   : Read one sample of angular velocity values from
    %                           sensor.
    %   readTemperature       : Read one sample of temperature value from sensor.
    %   read                  : Read one frame of acceleration, angular
    %                           velocity and temperature values from
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
    %  Note: For targets other than Arduino, lsm6dsr object is supported 
    %  with limited functionality. For those targets, you can use the
    %  'readAcceleration', 'readAngularVelocity', and 'readTemperature' 
    %  functions, and the 'Bus' and 'I2CAddress' properties.
    %
    %   Example 1: Read one sample of acceleration value from LSM6DSR sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = lsm6dsr(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an LSM6DSR sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = lsm6dsr(a,'SampleRate',100,'SamplesPerRead',50);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from LSM6DSR sensor');
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
    %     [accel,gyro] = read(sensorObj);
    %     addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %     addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %     addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %     count = count + sensorObj.SamplesPerRead;
    %     drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also lsm6dsrh, lsm9ds1, bno055, lsm6dsl, lsm6dso, read,
    %   readAcceleration, readAngularVelocity, readTemperature
    
    %   Copyright 2020 The MathWorks, Inc.
    %#codegen
    properties(Constant,Hidden)
        DeviceName = "LSM6DSR";
        DeviceID = 0x6B; %Value in in WHO_AM_Register
    end
        
    methods
        function obj = lsm6dsr(varargin)
            obj@sensors.internal.LSM6DSRAnd6DSOBase(varargin{:})
        end
    end
end