classdef (Sealed) lsm303c < matlabshared.sensors.sensorBoard
    %LSM303C connects to the LSM303C sensor connected to a hardware object
    %
    %   IMU = lsm303c(a) returns a System object, IMU that reads sensor
    %   data from the LSM303C sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   IMU = lsm303c(a, 'Name', Value, ...) returns a LSM303C System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   lsm303c Properties
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
    %   SamplesRead     : Number of samples read from the sensor.
    %
    %   lsm303c methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.
    %   readMagneticField     : Read one sample of magnetic field value from
    %                           sensor.
    %   readTemperature       : Read one sample of temperature value from sensor.
    %   read                  : Read one frame of acceleration, magnetic field and temperature values from
    %                           the sensor along with time stamps and overruns.      
    %   stop/release          : Stop sending data from hardware and
    %                           allow changes to non-tunable properties
    %                           values and input characteristics.
    %   flush                 : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %   info                  : Read sensor information such as output
    %                           data rate, bandwidth and so on.
    %
    %  Note: For targets other than Arduino, lsm303c object is supported 
    %  with limited functionality. For those targets, you can use the
    %  'readAcceleration', 'readMagneticField', and 'readTemperature'
    %  functions, and the 'Bus' and 'I2CAddress' properties.
    %
    %   Example 1: Read one sample of acceleration value from LSM303C sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = lsm303c(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an LSM303C sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = lsm303c(a,'SampleRate',150,'SamplesPerRead',5);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from LSM303C sensor');
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
    %     [accel,mag,temp] = read(sensorObj);
    %     addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %     addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %     addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %     count = count + sensorObj.SamplesPerRead;
    %     drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also icm20948, lsm9ds1, bno055, read, readAcceleration,
    %   readMagneticField
   
    %   Copyright 2020-2021 The MathWorks, Inc.
    
    %#codegen
    properties(Access = public, Hidden)
        SensorObjects = {};
    end
    
    properties(Constant, Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Hidden)
        NumSensorUnits = 2;
    end

    properties(Access = protected,Nontunable)
        AccelerometerODR;
        AccelerometerRange;
        MagnetometerODR;
    end
    
    properties(Hidden, Nontunable)
        isActiveAccelerometer;
        isActiveMagnetometer;
    end
    
    properties(Access=private,Nontunable)
        accelArgumentsForInit=cell(1,2);
        magArgumentsForInit=cell(1,6);
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
   
    methods
        function obj = lsm303c(varargin)
            obj@matlabshared.sensors.sensorBoard(varargin{:})
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                if ~coder.target('MATLAB')
                    names = {'Bus','OutputFormat','TimeFormat','SamplesPerRead', 'SampleRate','ReadMode'};
                    defaults = {[],'timetable','datetime',10, 100,'latest'};
                    p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                    p.parse(varargin{2:end});
                    obj.init(varargin{:});
                else
                    try
                        names = {'Bus','OutputFormat','TimeFormat','SamplesPerRead', 'SampleRate','ReadMode'};
                        defaults = {[],'timetable','datetime',10, 100,'latest'};
                        p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                        p.parse(varargin{2:end});
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
            else
                names = {'Bus','isActiveAccelerometer','isActiveMagnetometer','AccelerometerRange', 'AccelerometerODR','MagnetometerODR'};
                defaults = {0,true,true,'+/- 2g', 100,40};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                bus =  p.parameterValue('Bus');
                obj.isActiveMagnetometer=p.parameterValue('isActiveMagnetometer');
                obj.isActiveAccelerometer=p.parameterValue('isActiveAccelerometer');
                obj.AccelerometerODR =  p.parameterValue('AccelerometerODR');
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.MagnetometerODR =  p.parameterValue('MagnetometerODR');
                obj.accelArgumentsForInit={'AccelerometerRange',obj.AccelerometerRange,'AccelerometerODR',obj.AccelerometerODR};
                obj.magArgumentsForInit={'MagnetometerODR',obj.MagnetometerODR};
                obj.init(varargin{1},'Bus',bus);
                
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
            %   imu = lsm303c(a);
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
            %   imu = lsm303c(a);
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
        
        function [data,varargout] = readTemperature(obj)
            %   Read one sample of Temperature values from imu sensor along with timestamp.
            %
            %   Syntax:
            %   [tempReadings,timestamp] = readTemperature(imu);
            %
            %   Input Argument:
            %   imu - Sensor object.
            %
            %   Output Argument:
            %   tempReadings - Temperature values on x,y and z axis read
            %   from sensor in units of °C.
            %
            %   timestamp - the time at which MATLAB® receives magnetic feild data,
            %   specified as a datetime
            %
            %   Example:
            %   a=arduino();
            %   imu = lsm303c(a);
            %   [tempReadings,timestamp] = readTemperature(imu)
            %
            nargoutchk(0,2);
            if coder.target('MATLAB')
                [data,timeStamp] = readTemperature(obj.SensorObjects{2});
                varargout{1} = timeStamp;
            else
                % To avoid unneccessary function call on hardware, get
                % timestamp from target only if it is requested.
                data = readTemperature(obj.SensorObjects{2});
                if nargout == 2
                    varargout{1} = getCurrentTime(obj.Parent);
                end
            end
        end
    end
    methods(Hidden = true)
        function [status,timestamp] = readAccelerationStatus(obj)
            %Status can take 3 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            timestamp = 0;
            status=uint8([1 1 1]);
            if obj.isActiveAccelerometer
                [status,timestamp] = readAccelerationStatus(obj.SensorObjects{1});
            end
        end
        
        function [status,timestamp] = readMagneticFieldStatus(obj)
            %Status can take 3 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            timestamp = 0;
            status=uint8([1 1 1]);
            if obj.isActiveMagnetometer
                [status,timestamp] = readMagneticFieldStatus(obj.SensorObjects{2});
            end
        end
    end
    methods(Access = protected)
        function createSensorUnitsImpl(obj,varargin)
            if ~obj.isSimulink
                accel = sensors.internal.lsm303c_accel(varargin{:});
                magneto = sensors.internal.lsm303c_mag(varargin{:});
                obj.SensorObjects = {accel, magneto};
            else
                accel = sensors.internal.lsm303c_accel( varargin{:},obj.accelArgumentsForInit{:});
                magneto = sensors.internal.lsm303c_mag(varargin{:},obj.magArgumentsForInit{:});
                obj.SensorObjects = {accel, magneto};
            end
        end
    end

    methods(Access={?matlabshared.sensors.simulink.internal.SensorBlockBase})
        function interface = getSensorInterface(obj)
            interface = obj.Interface;
        end
    end
    
end

