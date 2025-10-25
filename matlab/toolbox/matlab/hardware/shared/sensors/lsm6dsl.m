classdef lsm6dsl < sensors.internal.LSM6DSBase
    %LSM6DSL connects to the LSM6DSL sensor connected to a hardware object
    %
    %   IMU = lsm6dsl(a) returns a System object, IMU that reads sensor
    %   data from the LSM6DSL sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   IMU = lsm6dsl(a, 'Name', Value, ...) returns a LSM6DSL System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   lsm6dsl Properties
    %   I2CAddress      : Specify the I2C Address of the LSM6DSL.
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
    %   lsm6dsl methods
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
    %  Note: For targets other than Arduino, lsm6dsl object is supported 
    %  with limited functionality. For those targets, you can use the
    %  'readAcceleration', 'readAngularVelocity', and 'readTemperature' 
    %  functions, and the 'Bus' and 'I2CAddress' properties.
    %
    %   Example 1: Read one sample of acceleration value from LSM6DSL sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = lsm6dsl(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an LSM6DSL sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = lsm6dsl(a,'SampleRate',100,'SamplesPerRead',50);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from the sensor');
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
    %   See also lsm6ds3, lsm6ds3h, lsm9ds1, lsm6dsl,lsm6dsr, read, readAcceleration,
    %   readAngularVelocity, readTemperature
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    %#codegen
    properties(Access = protected, Constant)
        ODRParametersGyro =[12.5, 26, 52, 104, 208, 416, 833, 1666, 3332, 6664];
        ODRParametersAccel = [12.5, 26, 52, 104, 208, 416, 833, 1666, 3332, 6664];
    end
    
    properties(Constant, Hidden)
        DeviceName = "LSM6DSL";
        DeviceID = 0x6A;
    end
    
    properties(Hidden,Nontunable)
        % The sensor default condition. Only make the properties Abortset ,
        % if the values are sensor defaults
        AccelLPF1BW = 'ODR/2';
        AccelSelectCompositeFilters = 'No filter';
        AccelLPF2BW = 'ODR/50';
        AccelHPFBW ='ODR/100';
        EnableGyroHPF = false;
        GyroHPFBW = 0.016;
        EnableGyroLPF = false;
        GyroLPFBWMode = 0;
    end
    
    properties(Hidden,Nontunable)
        GyroscopeODR = 12.5;
        AccelerometerODR = 12.5;
    end
    
    properties(Access = protected,Nontunable)
        TemperatureResolution = 1/256;
    end
    
    methods
        function obj = lsm6dsl(varargin)
            obj@sensors.internal.LSM6DSBase(varargin{:})
            if ~obj.isSimulink
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                % For MATLAB, activate all the sensors and set the
                % default values for the properties. No need of
                % setting accel and gyro odr here, since those will be
                % set in setODRImpl();
                obj.isActiveAccel = true;
                obj.isActiveGyro = true;
                obj.isActiveTemp = true;
                obj.AccelerometerRange = '+/- 2g';
                obj.GyroscopeRange = '125 dps';
                obj.AccelLPF1BW = 'ODR/2';
                obj.AccelSelectCompositeFilters = 'No filter';
                obj.AccelLPF2BW = 'ODR/50';
                obj.AccelHPFBW = 'ODR/100';
                obj.EnableGyroHPF = false;
                obj.GyroHPFBW = 0.016;
                obj.EnableGyroLPF = false;
                obj.GyroLPFBWMode =  0;
            else
                names =     {'Bus','I2CAddress','isActiveAccel','isActiveGyro','isActiveTemp',...
                    'AccelerometerRange', 'AccelerometerODR', 'AccelLPF1BW','AccelSelectCompositeFilters', 'AccelLPF2BW', 'AccelHPFBW',...
                    'GyroscopeRange','GyroscopeODR', 'EnableGyroHPF', 'GyroHPFBW' ,'EnableGyroLPF', 'GyroLPFBWMode'};
                defaults =    {0,0x6A, true,true,true,...
                    '+/- 2g', 12.5,'ODR/2', 'No filter','ODR/50','ODR/100',...
                    '125 dps',12.5, false, 0.016, false, 0};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                % For simulink, all the other properties,
                % (readmode,outputformat etc) are irrelevant.
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.isActiveAccel = p.parameterValue('isActiveAccel');
                obj.isActiveGyro= p.parameterValue('isActiveGyro');
                obj.isActiveTemp = p.parameterValue('isActiveTemp');
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.AccelerometerODR =  p.parameterValue('AccelerometerODR');
                obj.AccelLPF1BW = p.parameterValue('AccelLPF1BW');
                obj.AccelSelectCompositeFilters = p.parameterValue('AccelSelectCompositeFilters');
                obj.AccelLPF2BW = p.parameterValue('AccelLPF2BW');
                obj.AccelHPFBW = p.parameterValue('AccelHPFBW');
                obj.GyroscopeRange = p.parameterValue('GyroscopeRange');
                obj.GyroscopeODR =  p.parameterValue('GyroscopeODR');
                obj.EnableGyroHPF = p.parameterValue('EnableGyroHPF');
                obj.GyroHPFBW = p.parameterValue('GyroHPFBW');
                obj.EnableGyroLPF =p.parameterValue('EnableGyroLPF');
                obj.GyroLPFBWMode =  p.parameterValue('GyroLPFBWMode');
            end
        end
        
        function set.AccelerometerODR(obj, value)
            % First 4 bits of CTRL1_XL is used to set the ODR
            if obj.isActiveAccel
                switch value
                    case 12.5
                        ByteMask_CTRL1_XL = 0x10;
                    case 26
                        ByteMask_CTRL1_XL = 0x20;
                    case 52
                        ByteMask_CTRL1_XL = 0x30;
                    case 104
                        ByteMask_CTRL1_XL = 0x40;
                    case 208
                        ByteMask_CTRL1_XL = 0x50;
                    case 416
                        ByteMask_CTRL1_XL = 0x60;
                    case 833
                        ByteMask_CTRL1_XL = 0x70;
                    case 1666
                        ByteMask_CTRL1_XL = 0x80;
                    case 3332
                        ByteMask_CTRL1_XL = 0x90;
                    case 6664
                        ByteMask_CTRL1_XL = 0xA0;
                    otherwise
                        ByteMask_CTRL1_XL = 0x10;
                end
                val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL);
                writeRegister(obj.Device,obj.CTRL1_XL, bitor(bitand(val_CTRL1_XL, uint8(0x0F)), uint8(ByteMask_CTRL1_XL)));
                obj.AccelerometerODR = value;
            end
        end
        
        function set.AccelLPF1BW(obj,value)
            if obj.isActiveAccel
                % Use input composite bit of CTRL8_XL and LPF1_BW_SEL of CTRL1_XL
                % to select the BW
                switch value
                    case 'ODR/2'
                        val = readRegister(obj.Device, obj.CTRL1_XL);
                        writeRegister(obj.Device,obj.CTRL1_XL, bitand(val, 0xFD));
                        val = readRegister(obj.Device, obj.CTRL8_XL);
                        writeRegister(obj.Device,obj.CTRL8_XL, bitand(val, 0xF7));
                    case 'ODR/4'
                        val = readRegister(obj.Device, obj.CTRL1_XL);
                        writeRegister(obj.Device,obj.CTRL1_XL, bitor(val, 0x02));
                        val = readRegister(obj.Device, obj.CTRL8_XL);
                        writeRegister(obj.Device,obj.CTRL8_XL, bitor(val, 0x08));
                    otherwise
                end
                obj.AccelLPF1BW = value;
            end
        end
        
        function set.AccelSelectCompositeFilters(obj,value)
            if obj.isActiveAccel
                % Corresposnding register bits will be set along the
                % bandwidth setting 
                obj.AccelSelectCompositeFilters = value;
            else
                obj.AccelSelectCompositeFilters = 'No filter';
            end
        end
        
        function set.AccelLPF2BW(obj,value)
            setAccelLPF2BW(obj,value);
            obj.AccelLPF2BW = value;
        end
        
        function set.AccelHPFBW(obj,value)
            setAccelHPFBW(obj,value);
            obj.AccelHPFBW = value;
        end
        
        function set.GyroscopeODR(obj,value)
            % First 4 bits of CTRL2_G is used to set the ODR
            if obj.isActiveGyro
                switch value
                    case 12.5
                        ByteMask_CTRL2_G = 0x10;
                    case 26
                        ByteMask_CTRL2_G = 0x20;
                    case 52
                        ByteMask_CTRL2_G = 0x30;
                    case 104
                        ByteMask_CTRL2_G = 0x40;
                    case 208
                        ByteMask_CTRL2_G = 0x50;
                    case 416
                        ByteMask_CTRL2_G = 0x60;
                    case 833
                        ByteMask_CTRL2_G = 0x70;
                    case 1666
                        ByteMask_CTRL2_G = 0x80;
                    case 3332
                        ByteMask_CTRL2_G = 0x90;
                    case 6664
                        ByteMask_CTRL2_G = 0xA0;
                    otherwise
                        ByteMask_CTRL2_G = 0x30;
                end
                val = readRegister(obj.Device, obj.CTRL2_G);
                writeRegister(obj.Device, obj.CTRL2_G ,bitor(bitand(val, uint8(0x0F)), uint8(ByteMask_CTRL2_G)));
                obj.GyroscopeODR = value;
            else
                obj.GyroscopeODR = 0;
            end
        end
        
        function set.EnableGyroHPF(obj,value)
            % register bits will be set along the Bandwidth setting (same
            % register is used for both)
            obj.EnableGyroHPF = value;
        end
        
        function set.GyroHPFBW(obj,value)
            setGyroHPFBW(obj,value);
            obj.GyroHPFBW = value;
        end
        
        function set.EnableGyroLPF(obj,value)
            setEnableGyroLPF(obj,value);
            obj.EnableGyroLPF = value;
        end
        
        function set.GyroLPFBWMode(obj,value)
            setLPFCutOffFreqModeGyro(obj,value);
            obj.GyroLPFBWMode = value;
        end
    end
    
    methods(Access = protected)
        function setODRImpl(obj)
            % used only for MATLAB
            gyroODR = obj.ODRParametersGyro(obj.ODRParametersGyro<=obj.SampleRate);
            accelODR = obj.ODRParametersAccel(obj.ODRParametersAccel<=obj.SampleRate);
            obj.AccelerometerODR = accelODR(end);
            obj.GyroscopeODR = gyroODR(end);
        end
    end
    
    methods(Access = private) 
        function setAccelLPF2BW(obj,value)
            if strcmpi(obj.AccelSelectCompositeFilters,'Low pass filter')
                % enable low pass filter and set the frequency
                switch value
                    case 'ODR/50'
                        ByteMask_CTRL8_XL = 0x80;
                    case 'ODR/100'
                        ByteMask_CTRL8_XL = 0xA0;
                    case 'ODR/9'
                        ByteMask_CTRL8_XL = 0xC0;
                    case 'ODR/400'
                        ByteMask_CTRL8_XL = 0xE0;
                    otherwise
                        ByteMask_CTRL8_XL = 0x20;
                end
                val = readRegister(obj.Device, obj.CTRL8_XL);
                writeRegister(obj.Device,obj.CTRL8_XL, bitor(bitand(val, uint8(0x1B)), uint8(ByteMask_CTRL8_XL)));
            end
        end
        
        function setAccelHPFBW(obj,value)
            if  strcmp(obj.AccelSelectCompositeFilters,'High pass filter')
                % enable high pass filter and set the frequency
                switch value
                    case 'ODR/100'
                        ByteMask_CTRL8_XL = 0x24;
                    case 'ODR/9'
                        ByteMask_CTRL8_XL = 0x44;
                    case 'ODR/400'
                        ByteMask_CTRL8_XL = 0x64;
                    otherwise
                        ByteMask_CTRL8_XL = 0x24;
                end
                val = readRegister(obj.Device, obj.CTRL8_XL);
                writeRegister(obj.Device,obj.CTRL8_XL, bitor(bitand(val, 0x1B), ByteMask_CTRL8_XL));
            end
        end
        
        function setGyroHPFBW(obj,value)
            if obj.EnableGyroHPF
                % set the bits to enable High pass filter and set the cut
                % of frequecy
                switch value
                    case 0.016
                        ByteMask_CTRL7_G = 0x40;
                    case 0.065
                        ByteMask_CTRL7_G = 0x50;
                    case 0.260
                        ByteMask_CTRL7_G = 0x60;
                    case 1.04
                        ByteMask_CTRL7_G = 0x70;
                    otherwise
                        ByteMask_CTRL7_G = 0x40;
                end
                val = readRegister(obj.Device, obj.CTRL7_G);
                writeRegister(obj.Device,obj.CTRL7_G, bitor(bitand(val, uint8(0x8F)), uint8(ByteMask_CTRL7_G)));
            end
        end
        
        function setEnableGyroLPF(obj,value)
            if obj.isActiveGyro
                if value
                    val = readRegister(obj.Device, obj.CTRL4_C);
                    writeRegister(obj.Device,obj.CTRL4_C, bitor(val, 0x02));
                else
                    val = readRegister(obj.Device, obj.CTRL4_C);
                    writeRegister(obj.Device,obj.CTRL4_C, bitand(val, 0xFD));
                end
            end
        end
        
        function setLPFCutOffFreqModeGyro(obj,value)
            if obj.EnableGyroLPF
                switch value
                    case 0
                        ByteMask_CTRL6_C  = 0x00;
                    case 1
                        ByteMask_CTRL6_C  = 0x01;
                    case 2
                        ByteMask_CTRL6_C = 0x02;
                    case 3
                        ByteMask_CTRL6_C  = 0x03;
                    otherwise
                        ByteMask_CTRL6_C  = 0x00;
                end
                val = readRegister(obj.Device, obj.CTRL6_C);
                andMask = 0xFC;
                writeRegister(obj.Device,obj.CTRL6_C, bitor(bitand(val,andMask), ByteMask_CTRL6_C));
            end
        end
    end
end