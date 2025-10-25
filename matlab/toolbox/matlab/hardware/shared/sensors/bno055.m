classdef bno055 < sensors.internal.BNO055Base
    %BNO055 connects to the BNO055 sensor connected to a hardware object
    %
    %   IMU = bno055(a) returns a System object, IMU that reads sensor
    %   data from the BNO055 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   IMU = bno055(a, 'Name', Value, ...) returns a BNO055 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   bno055 Properties
    %   OperatingMode   : Specify the operating mode of the BNO055 sensor.
    %                     Operating mode can be either "ndof" or "amg".
    %                     Default value is "ndof".
    %   I2CAddress      : Specify the I2C Address of the BNO055.
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
    %   bno055 methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.The function gives calibrated values
    %                           if the 'OperatingMode' is set to 'ndof'.
    %   readAngularVelocity   : Read one sample of angular velocity values from
    %                           sensor. The function gives calibrated values if
    %                           the 'OperatingMode' is set to 'ndof'.
    %   readMagneticFeild     : Read one sample of magnetic field values from
    %                           sensor. The function gives calibrated values
    %                           if the 'OperatingMode' is set to 'ndof'.
    %   readOrientation       : Read one sample of orientation values in euler
    %                           angles (yaw,pitch roll) from the sensor. The
    %                           function is not available when the
    %                           'OperatingMode' of object is set as 'amg'.
    %   readCalibrationStatus : Read calibration status of the sensor. The
    %                           function not available when the
    %                           'OperatingMode' of object is set as 'amg'.
    %   read                  : Read one frame of acceleration, angular
    %                           velocity, magnetic field, and orientation
    %                           values from the sensor along with time
    %                           stamps and overruns. Orientation values are
    %                           only available if the 'OperatingMode' of
    %                           object is set as 'ndof'.
    %  stop/release           : Stop sending data from hardware and
    %                           allow changes to non-tunable properties
    %                           values and input characteristics.
    %  flush                  : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %  info                   : Read sensor information such as output
    %                           data rate, bandwidth and so on. The function
    %                           is not available when the 'OperatingMode'
    %                           of object is set as 'ndof'.
    %
    %   Note: For targets other than Arduino, bno055 object is supported 
    %   with limited functionality. For those targets, you can use the
    %   'readAcceleration','readAngularVelocity', 'readMagneticField', 
    %   'readOrientation' and 'readCalibrationStatus' functions, and the
    %   'OperatingMode', 'Bus', and 'I2CAddress' properties.
    %
    %   Example 1: Read uncalibrated acceleration value from BNO055 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bno055(a,'OperatingMode','amg');
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read Orientation data from BNO055 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = bno055(a,'OperatingMode','ndof');
    %   eulerAngles = readOrientation(sensorObj)
    %
    %   Example 3: Read and plot acceleration values from an BNO055 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = bno055(a,'SampleRate',100,'SamplesPerRead',50,'OperatingMode','amg');
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from BNO055 sensor');
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
    %   See also mpu6050, mpu9250, lsm9ds1, read, readAcceleration,
    %   readAngularVelocity, readMagneticField, readOrientation,
    %   readCalibrationStatus
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    %#codegen
    
    properties(GetAccess = public,SetAccess = immutable)
        OperatingMode;
    end
    
    properties(GetAccess = public, SetAccess = immutable,Hidden)
        OperatingModeEnum = matlabshared.sensors.internal.BNO055OperatingMode.ndof;
    end
    
    properties(Nontunable, Hidden)
        DoF;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x28,0x29];
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.bno055';
        end
    end

    methods(Access = public)
        function obj = bno055(varargin)
            try
                % At least one parameter must be passed
                narginchk(1,inf);
                [mode,argumentsForInit] = getParsedArguments(obj,varargin{:});
                obj.OperatingMode = mode;
                obj.OperatingModeEnum = obj.OperatingMode;
                if obj.OperatingMode == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    obj.DoF = [3;3;3;3];
                else
                    obj.DoF = [3;3;3];
                end
                obj.init(argumentsForInit{:});
            catch ME
                throwAsCaller(ME)
            end
        end
  
        function [val,timestamp] = readCalibrationStatus(obj)
            %  Read Calibration Status of BNO055 Sensor
            %
            %   Syntax:
            %   [CALIBRATIONSTATUS] = readCalibrationStatus(sensorObj) returns Calibration Status (full,partial, uncalibrated) of BNO055 sensorobj as a structure
            %   [CALIBRATIONSTATUS,TIMESTAMP] = readCalibrationStatus(sensorObj) returns Calibration Status (full,partial, uncalibrated) of BNO055 sensorobj as a structure and the timestamp in 'dd-MMM-uuuu HH:mm:ss.SSS' format
            %
            %   Example:
            %       % Construct an arduino object
            %       a = arduino;
            %
            %       % Construct BNO055 object
            %       sensorObj = bno055(a);
            %
            %       % Read calibrationstatus of sensor
            %       calibrationStatus = readCalibrationStatus(sensorObj);
            %       [calibrationStatus,timestamp] = readCalibrationStatus(sensorObj);
            %
            %
            %   See also readAcceleration, readAngularVelocity, readMagneticField, readOrientation
            try
                if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    numericStatus = readCalibrationStatusInternal(obj);
                    timestamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                    status = strings(1,4);
                    for i = 1:4
                        switch(numericStatus(i))
                            case 0
                                status(i) = "uncalibrated";
                            case {1,2}
                                status(i) = "partial";
                            case 3
                                status(i) = "full";
                            otherwise
                                status(i) = "uncalibrated";
                        end
                    end
                    val = struct('System', status(1),'Accelerometer', status(2),'Gyroscope', status(3),'Magnetometer',status(4));
                else
                    error(message('matlab_sensors:general:unsupportedFunctionBNO055','readCalibrationStatus','amg','ndof'));
                end
            catch ME
                throwAsCaller(ME)
            end
        end
        
        function [data,timestamp] = readAcceleration(obj)
            %   Measure Acceleraion. Returns calibrated values
            %   if the property 'OperatingMode' is set as 'ndof' or
            %   uncalibrated values if the property 'OperatingMode' is set
            %   as 'amg'
            %
            %   Syntax:
            %   [VAL] = readAcceleration(sensorObj) returns the Accelerometer reading from BNO055 sensorObj
            %   [VAL,TIMESTAMP] = readAcceleration(sensorObj) returns the Accelerometer reading from BNO055 sensorObj and the
            %   timestamp in 'dd-MMM-uuuu HH:mm:ss.SSS' format
            %
            %
            %   Example:
            %       % Construct an arduino object include I2C library
            %       a = arduino('COM3','Uno','libraries','I2C');
            %
            %       % Construct BNO055 add-on object
            %       sensorObj = bno055(a);
            %
            %       % Read Accelerometer output
            %       val = readAcceleration(sensorObj);
            %       [val, timestamp] = readAcceleration(sensorObj);
            %
            %   See also readAngularVelocity, readCalibrationStatus, readMagneticField, readOrientation
            try
                if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    numericStatus  = readCalibrationStatusInternal(obj);
                    if numericStatus(2)== 0
                        error(message('matlab_sensors:general:uncalibratedSensor','Accelerometer'));
                    end
                end
                [data,timestamp] = readAcceleration@matlabshared.sensors.accelerometer(obj);
            catch ME
                throwAsCaller(ME)
            end
        end
        
        function [data,timestamp] = readAngularVelocity(obj)
            %   Measure Angular Velocity. Returns calibrated values
            %   if the property 'OperatingMode' is set as 'ndof' or
            %   uncalibrated values if the property 'OperatingMode' is set
            %   as 'amg'
            %
            %   Syntax:
            %   [VAL] = readAngularVelocity(sensorObj) returns the Gyroscope reading from BNO055 sensorObj
            %   [VAL,TIMESTAMP] = readAngularVelocity(sensorObj) returns the Gyroscope reading from BNO055 sensorObj and the
            %   timestamp in 'dd-MMM-uuuu HH:mm:ss.SSS' format
            %
            %   Example:
            %       % Construct an arduino object include I2C library
            %       a = arduino('COM3','Uno','libraries','I2C');
            %       % Construct BNO055 object
            %       sensorObj = bno055(a);
            %
            %       % Read Gyroscope output
            %       val = readAngularVelocity(sensorObj);
            %       [val, timestamp] = readAngularVelocity(sensorObj);
            %
            %   See also readAcceleration, readCalibrationStatus, readMagneticField, readOrientation
            try
                if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    numericStatus  = readCalibrationStatusInternal(obj);
                    if numericStatus(3)== 0
                        error(message('matlab_sensors:general:uncalibratedSensor','Gyroscope'));
                    end
                end
                [data,timestamp] =  readAngularVelocity@matlabshared.sensors.gyroscope(obj);
            catch ME
                throwAsCaller(ME)
            end
        end
        
        function [data,timestamp] = readMagneticField(obj)
            %   Measure magnetic field strength. Returns calibrated values
            %   if the property 'OperatingMode' is set as 'ndof' or
            %   uncalibrated values if the property 'OperatingMode' is set
            %   as 'amg'
            %
            %   Syntax:
            %   VAL = readMagneticField(sensorObj) returns the Magnetometer reading from BNO055 sensorObj
            %   [VAL,TIMESTAMP] = readMagneticField(sensorObj) returns the Magnetometer reading from BNO055 sensorObj and the
            %   timestamp in 'dd-MMM-uuuu HH:mm:ss.SSS' format
            %
            %   Example:
            %       % Construct an arduino object including I2C library
            %       a = arduino('COM3','Uno','libraries','I2C');
            %
            %       % Construct BNO055 object
            %       sensorObj = bno055(a);
            %
            %       % Read Magnetometer output
            %       val = readMagneticField(sensorObj)
            %       [val,timestamp] = readMagneticField(sensorObj)
            %
            %   See also readAcceleration, readAngularVelocity, readCalibrationStatus, readOrientation
            try
                if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    numericStatus  = readCalibrationStatusInternal(obj);
                    if numericStatus(4)== 0
                        error(message('matlab_sensors:general:uncalibratedSensor','Magnetometer'));
                    end
                end
                [data,timestamp] =  readMagneticField@matlabshared.sensors.magnetometer(obj);
            catch ME
                throwAsCaller(ME)
            end
        end
        
        function [data,timestamp] = readOrientation(obj)
            %   Measure Orientation
            %
            %   Syntax:
            %   [VAL] = readOrientation(sensorObj) returns the Heading, Pitch and Roll in radians from the BNO055 sensorObj
            %   [VAL,TIMESTAMP] = readOrientation(sensorObj) returns the Heading, Pitch and Roll in radians from the BNO055 sensorObj and the
            %   timestamp in 'dd-MMM-uuuu HH:mm:ss.SSS' format
            %
            %   Example:
            %       % Construct an arduino object including I2C library
            %       a = arduino('COM3','Uno','libraries','I2C');
            %
            %       % Construct BNO055 object
            %       sensorObj = bno055(a);
            %
            %       % Read Orientation of sensor
            %       val = readOrientation(sensorObj);
            %       [val, timestamp] = readOrientation(sensorObj);
            %
            %   See also readAcceleration, readAngularVelocity, readCalibrationStatus, readMagneticField
            try
                if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    numericStatus  = readCalibrationStatusInternal(obj);
                    if ~all(numericStatus)
                        error(message('matlab_sensors:general:uncalibratedSensor','BNO055 sensor'));
                    end
                    [data,timestamp] =  readOrientation@matlabshared.sensors.Orientation(obj);
                else
                    error(message('matlab_sensors:general:unsupportedFunctionBNO055','readOrientation','amg','ndof'));
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end
    
    methods(Access = protected)
        function s =  infoImpl(obj)
            % function not supported in NDOF mode
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.amg
                s = struct('AccelerometerBandwidth',obj.AccelerometerBandwidth,'GyroscopeBandwidth',obj.GyroscopeBandwidth,'MagnetometerODR',obj.MagnetometerODR);
            else
                error(message('matlab_sensors:general:unsupportedFunctionBNO055','info','ndof','amg'));
            end
        end
        
        function sampleRate = setSampleRateHook(obj,value)
            % Setting ODR not supported in NDOF mode
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                if(value ~= obj.NdofSampleRate)
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:unsupportedSampleRate');
                end
                sampleRate = obj.NdofSampleRate;
            else
                sampleRate = value;
            end
        end
    end
    
    methods(Access = private)
        function [mode,argumentsForInit] = getParsedArguments(obj,varargin)
            p = inputParser;
            p.CaseSensitive = 0;
            p.PartialMatching = 1;
            p.KeepUnmatched = true;
            addParameter(p, 'OperatingMode',matlabshared.sensors.internal.BNO055OperatingMode.ndof, @(x)any(validatestring(x,obj.SupportedModes)));
            parse(p, varargin{2:end});
            mode = matlabshared.sensors.internal.BNO055OperatingMode(p.Results.OperatingMode);
            fields = fieldnames(p.Unmatched);
            fieldValues = struct2cell(p.Unmatched);
            num = numel(fields)+numel(fieldValues);
            argumentsForInit{1} = varargin{1};
            if(numel(varargin)>2)
                k = 2;
                for i = 1:1:num/2
                    argumentsForInit{k} =  fields{i};
                    k = k+1;
                    argumentsForInit{k} =  fieldValues{i};
                    k = k+1;
                end
            elseif numel(varargin)>1
                argumentsForInit{2} = varargin{2};
            end
        end
    end
    
    methods(Hidden)
        function showSensorProperties(obj)
            fprintf('                      OperatingMode: "%s" \n\n', obj.OperatingMode);
        end
    end
end
