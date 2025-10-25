classdef lsm6ds3 < sensors.internal.LSM6DSBase
    %LSM6DS3 connects to the LSM6DS3 sensor connected to a hardware object
    %
    %   IMU = lsm6ds3(a) returns a System object, IMU that reads sensor
    %   data from the LSM6DS3 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   IMU = lsm6ds3(a, 'Name', Value, ...) returns a LSM6DS3 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   lsm6ds3 Properties
    %   I2CAddress      : Specify the I2C Address of the LSM6DS3.
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
    %   lsm6ds3 methods
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
    %  Note: For targets other than Arduino, lsm6ds3 object is supported 
    %  with limited functionality. For those targets, you can use the
    %  'readAcceleration', 'readAngularVelocity', and 'readTemperature' 
    %  functions, and the 'Bus' and 'I2CAddress' properties.
    %
    %   Example 1: Read one sample of acceleration value from LSM6DS3 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = lsm6ds3(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an LSM6DS3 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = lsm6ds3(a,'SampleRate',100,'SamplesPerRead',50);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from LSM6DS3 sensor');
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
    %   See also lsm6ds3h, lsm9ds1, bno055, lsm6dsl, lsm6dsr, read,
    %   readAcceleration, readAngularVelocity, readTemperature
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    %#codegen
    
    properties(Access = protected, Constant)
        ODRParametersGyro = [12.5, 26, 52, 104, 208, 416, 833, 1666];
        ODRParametersAccel = [12.5, 26, 52, 104, 208, 416, 833, 1666, 3332, 6664];
    end
    
    properties(Constant,Hidden)
        DeviceName = "LSM6DS3";
        DeviceID = 0x69; % Value in WHO_AM_I Register
    end
    
    properties(Hidden,Nontunable)
        EnableAccelBWChange = false; % enable user adjustable bandwidth for Anti aliasing filter in accel
        AccelLPFBW = 400; % Choose the BW of the anti aliasing filter
        AccelSelectCompositeFilters = 0; % select the filters in composite filter block
        AccelLPF2BW = 'ODR/50' ;
        AccelHPFBW = 'ODR/100';
        EnableGyroHPF = false;
        GyroHPFBW= 0.0081;
    end
    
    properties(Hidden,Nontunable)
        AccelerometerODR = 12.5;
        GyroscopeODR = 12.5;
    end
    
    properties(Access = protected,Nontunable)
        TemperatureResolution = 1/16;
    end
    
    methods
        function obj = lsm6ds3(varargin)
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
                obj.AccelLPFBW = 400;
                obj.AccelSelectCompositeFilters = 'No filter';
                obj.AccelLPF2BW = 'ODR/50';
                obj.AccelHPFBW = 'ODR/100';
                obj.EnableGyroHPF = false;
                obj.GyroHPFBW = 0.0081;
            else
                names =     {'Bus','I2CAddress','isActiveAccel','isActiveGyro','isActiveTemp',...
                    'AccelerometerRange', 'AccelerometerODR','EnableAccelBWChange','AccelLPFBW','AccelSelectCompositeFilters', 'AccelLPF2BW', 'AccelHPFBW',...
                    'GyroscopeRange','GyroscopeODR', 'EnableGyroHPF','GyroHPFBW'};
                defaults =    {0,0x6A, true,true,true,...
                    '+/- 2g', 12.5, false, 400, 'No filter','ODR/50','ODR/100',...
                    '125 dps',12.5, false, 0.0081};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                % For simulink, all the other properties,
                % (readmode,outputformat etc) are irrelevant.Only pass
                % Bus and I2C Address to infra classes
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                % set the sensor related properties in the sensor class
                obj.isActiveAccel = p.parameterValue('isActiveAccel');
                obj.isActiveGyro= p.parameterValue('isActiveGyro');
                obj.isActiveTemp = p.parameterValue('isActiveTemp');
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.AccelerometerODR =  p.parameterValue('AccelerometerODR');
                obj.AccelLPFBW = p.parameterValue('AccelLPFBW');
                obj.AccelSelectCompositeFilters = p.parameterValue('AccelSelectCompositeFilters');
                obj.AccelLPF2BW = p.parameterValue('AccelLPF2BW');
                obj.AccelHPFBW = p.parameterValue('AccelHPFBW');
                obj.GyroscopeRange = p.parameterValue('GyroscopeRange');
                obj.GyroscopeODR =  p.parameterValue('GyroscopeODR');
                obj.EnableGyroHPF = p.parameterValue('EnableGyroHPF');
                obj.GyroHPFBW = p.parameterValue('GyroHPFBW');
            end
        end
        
        function set.AccelerometerODR(obj, value)
            % The ODR bits will enable Accelerometer. If Accel output is
            % not required do not change ODR bits
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
                    case 6624
                        ByteMask_CTRL1_XL = 0xA0;
                    otherwise
                        ByteMask_CTRL1_XL = 0x10;
                end
                val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL);
                % First 4 bits of CTRL1_XL register are ODR bits
                writeRegister(obj.Device,obj.CTRL1_XL, bitor(bitand(val_CTRL1_XL, uint8(0x0F)), uint8(ByteMask_CTRL1_XL)));
                obj.AccelerometerODR = value;
            end
        end
        
        function set.EnableAccelBWChange(obj,value)
            if obj.isActiveAccel
                switch value
                    case 0
                        ByteMask_CTRL4_C = 0x00;
                    case 1
                        ByteMask_CTRL4_C = 0x80;
                    otherwise
                        ByteMask_CTRL4_C = 0x00;
                end
                val_CTRL4_C = readRegister(obj.Device, obj.CTRL4_C);
                % 1st bit of CTRL4_C should be changed to allow
                % configuration of BW modification
                writeRegister(obj.Device,obj.CTRL4_C, bitor(bitand(val_CTRL4_C, uint8(0x7F)), uint8(ByteMask_CTRL4_C)));
                obj.EnableAccelBWChange = value;
            else
                obj.EnableAccelBWChange = 0;
            end
        end
        
        function set.AccelLPFBW(obj,value)
            %the below setAccelLPFBW shouldn't be assigned a value which
            %keeps constantly changing as non tunable properties can only
            %be assigned constant values
             setAccelLPFBW(obj,value);
            obj.AccelLPFBW = value;
        end

        function set.AccelSelectCompositeFilters(obj,value)
            if obj.isActiveAccel
                % SLOPE_FDS bit (5th bit) TAP_CFG CTRL8_XL needs to be configured
                %  for selecting composite filters. The CTRL8_XL register
                %  settting will be done along with bandwidth selection of
                %  the composite filters as both of them uses the same
                %  register. This is done inorder to prevent multiple
                %  multiple I2C operations on the same register
                switch value
                    case 'No filter'
                        % NO LPF and HPF
                        ByteMask_TAP_CFG = 0x00;
                    case 'Low pass filter'
                        % LPF
                        ByteMask_TAP_CFG = 0x10;
                    case 'High pass filter'
                        % HPF
                        ByteMask_TAP_CFG = 0x10;
                    otherwise
                        %no filter
                        ByteMask_TAP_CFG  = 0x00;
                        % For no filter set the HP_XL_EN = 0 and LPF2_XL_EN
                        % of CTRL8_XL to 0. For the other cases, this
                        % setting will be done along with bandwidth setting
                        % of the filter
                        val = readRegister(obj.Device, obj.CTRL8_XL);
                        writeRegister(obj.Device,obj.CTRL8_XL, bitand(val,0x7B));
                end
                val = readRegister(obj.Device, obj.TAP_CFG);
                writeRegister(obj.Device,obj.TAP_CFG, bitor(bitand(val, uint8(0xEF)), uint8(ByteMask_TAP_CFG)));
            else
                obj.AccelSelectCompositeFilters = 0;
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
            % First 4 bits of CTRl2_G is used to set the ODR of Gyro
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
            obj.EnableGyroHPF = value;
        end
        
        function set.GyroHPFBW(obj,value)
            setHPFCutOffFreqGyro(obj,value);
            obj.GyroHPFBW= value;
        end
    end
    
    methods(Access = protected)
        function setODRImpl(obj)
            % Select the closet ODR value to the given SampleRate . This
            % workflow is used only for MATLAB where Sample Rate determines
            % ODR
            gyroODR = obj.ODRParametersGyro(obj.ODRParametersGyro<=obj.SampleRate);
            accelODR = obj.ODRParametersAccel(obj.ODRParametersAccel<=obj.SampleRate);
            obj.AccelerometerODR = accelODR(end);
            obj.GyroscopeODR = gyroODR(end);
        end
    end
    
    methods(Access = private)
        function value = setAccelLPFBW(obj,value)
            if obj.EnableAccelBWChange ~= 1
                switch value
                    case 400
                        ByteMask_CTRL1_XL = 0x00;
                    case 200
                        ByteMask_CTRL1_XL = 0x01;
                    case 100
                        ByteMask_CTRL1_XL = 0x02;
                    case 50
                        ByteMask_CTRL1_XL = 0x03;
                    otherwise
                        ByteMask_CTRL1_XL = 0x00;
                end
                % Last 2 bits of CTRL1_XL is used to set the bandwidth
                val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL);
                writeRegister(obj.Device,obj.CTRL1_XL, bitor(bitand(val_CTRL1_XL, uint8(0xFC)), uint8(ByteMask_CTRL1_XL)));
            else
                value = 0;
            end
        end
        
        function setAccelLPF2BW(obj,value)
            if strcmp(obj.AccelSelectCompositeFilters,'Low pass filter')
                % HP_SLOP_XL_EN = 1, LPF2_XL_EN = 1
                % HPCF bits of of CTRl8_XL register
                % are used to set the LPF2 bandwidth
                switch value
                    case 'ODR/50'
                        ByteMask_CTRL8_XL = 0x9F;
                    case 'ODR/100'
                        ByteMask_CTRL8_XL = 0xBF;
                    case 'ODR/9'
                        ByteMask_CTRL8_XL = 0xDF;
                    case 'ODR/400'
                        ByteMask_CTRL8_XL = 0xFF;
                    otherwise
                        ByteMask_CTRL8_XL = 0x9F;
                end
                val = readRegister(obj.Device, obj.CTRL8_XL);
                writeRegister(obj.Device,obj.CTRL8_XL, bitor(bitand(val, 0x14), ByteMask_CTRL8_XL));
            end
        end
        
        function setAccelHPFBW(obj,value)
            % HP_SLOP_XL_EN = 1, LPF2_XL_EN = 0
            % HPCF bits of of CTRl8_XL register
            % are used to set the LPF2 bandwidth
            if strcmp(obj.AccelSelectCompositeFilters,'High pass filter')
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
                writeRegister(obj.Device,obj.CTRL8_XL, bitor(bitand(val, 0x14), ByteMask_CTRL8_XL));
            end
        end
        
        function setHPFCutOffFreqGyro(obj,value)
            if obj.EnableGyroHPF == 1
                switch value
                    case 0.0081
                        ByteMask_CTRL7_G = 0x40;
                    case 0.0324
                        ByteMask_CTRL7_G = 0x50;
                    case 2.07
                        ByteMask_CTRL7_G = 0x60;
                    case 16.32
                        ByteMask_CTRL7_G = 0x70;
                    otherwise
                        ByteMask_CTRL7_G = 0x40;
                end
            else
                ByteMask_CTRL7_G = 0x00;
            end
            val = readRegister(obj.Device, obj.CTRL7_G);
            writeRegister(obj.Device,obj.CTRL7_G, bitor(bitand(val, 0x8F), ByteMask_CTRL7_G));
        end
    end
end