classdef (Sealed) lis3dh < matlabshared.sensors.accelerometer & matlabshared.sensors.sensorUnit & matlabshared.sensors.TemperatureSensor & matlabshared.sensors.VoltageSensor &...
        matlabshared.sensors.I2CSensorProperties
    %LIS3DH connects to the LIS3DH sensor connected to a hardware board
    %
    %   sensorObj = lis3dh(hardwareObj) returns a System object that reads sensor
    %   data from the LIS3DH sensor connected to the I2C bus of an
    %   hardware board. 'hardwareObj' is a hardware object.
    %
    %   sensorObj = lis3dh(hardwareObj, Name=Value, ...) returns a lis3dh System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1=Value1,...,NameN=ValueN).
    %
    %   LIS3DH properties
    %   I2CAddress      : Specify the I2C Address of the LIS3DH.
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
    %   AvailableADCPins: Analog pins available on LIS3DH sensor connected
    %                     to hardware (e.g Arduino, Raspberry Pi).
    %
    %   LIS3DH methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.
    %   readTemperature       : Read one sample of temperature data from
    %                           sensor.
    %   readVoltage           : Read voltage from analog pin on LIS3DH sensor.
    %
    %   read                  : Read one frame of acceleration and temperature value from
    %                           the sensor along with time stamps and
    %                           overruns.
    %   stop/release          : Stop sending data from hardware and
    %                           allow changes to non-tunable properties
    %                           values and input characteristics.
    %   flush                 : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %   info                  : Read sensor information such as output
    %                           data rate, bandwidth and so on.
    %
    %  Note: For targets other than Arduino, LIS3DH object is supported
    %  with limited functionality. For those targets, you can use the
    %  'readAcceleration' function, and the 'Bus' and 'I2CAddress' properties.
    %
    %  Example 1: Read one sample of Acceleration value from LIS3DH sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = lis3dh(a);
    %   accelData  =  readAcceleration(sensorObj);
    %
    %  Example 2: Read and plot acceleration values at a specific rate from an LIS3DH sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = lis3dh(a,'SampleRate',100,'SamplesPerRead',15);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from LIS3DH sensor');
    %   x_val = animatedline('Color','r');
    %   y_val = animatedline('Color','g');
    %   z_val = animatedline('Color','b');
    %   axis tight;
    %   legend('Acceleration in X-axis','Acceleration in Y-axis','Acceleration in Z-axis');
    %   stop_time = 10; %  time in seconds
    %   count = 1;
    %   tic;
    %   while(toc <= stop_time)
    %   [accel,~,~] = read(sensorObj);
    %   addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %   addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %   addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %   count = count + sensorObj.SamplesPerRead;
    %   drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also icm20948, lsm9ds1, bno055, read, readAcceleration

    %   Copyright 2022 - 2024, The MathWorks, Inc.
    %#codegen
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 0.1;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [3;1];
    end

    properties (Access=protected,Constant)
        %In order to read multiple bytes, it is necessary to assert the most significant bit of the sub-address field.
        %In other words, SUB(7) must be equal to 1 while SUB(6-0) represents the address of first register to be read.
        AccelerometerDataRegister = 0xA8; % 0x28 -> 0xA8
        VoltageDataRegister = 0x88;       % 0x08 -> 0x88
        TemperatureDataRegister = 0x8C;   % 0x0C -> 0x8C
    end

    properties(Access = protected, Constant)
        DeviceID = 0x33;
        WHO_AM_I = 0x0F;
        ODR1ParametersAccel = [1,10,25,50,100,200,400,1344];
        ODR2ParametersAccel = [1,10,25,50,100,200,400,1600,5376];
        BytesToReadMaximumValue=30;
        BytesToReadForADC = 2;
        SequentialBytesToReadForADC = 6;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x18,0x19];
    end

    properties(Access = protected)
        IsADC3TemperatureConfigured = true; %Property to track ADC3 configuration
    end

    properties(Access = protected,Nontunable)
        AccelerometerRange = 2;
        Mode = '12-bit';
        EnableHPF = 0;
        Cutoff=8;
        AccelerometerODR=400;
        IsActiveDataReadyInterrupt = false;
        IsActiveFIFOOverrunInterrupt = false;
        IsFIFOEnabled = false;
        FIFOSamples = 1;
        InterruptPin = 'INT1';
        DataType = "double";
        ConfigurableDetections1Parameters = [0,0,0,0,0,0,0,0,0,0,0,0];
        ConfigurableDetections2Parameters = [0,0,0,0,0,0,0,0,0,0,0,0];
        ClickParameters  = [0,0,0,0,0,0,0,0,0,0,0];
        BytesToReadFromAccel = 6;
        EnableTemperature=1;
        EnableStatus=0;
        EnableADC=0;
        NumADCPins=1;
    end

    properties(Access=protected)
        %The property is used to temporarily hold the previous FIFO data
        tempFIFOData = 0;
    end

    properties(Hidden)
        ADCDataResolution = 10;
        TemperatureDataResolution = 8;
        BitResolution = 12;

        %Sensitivity values provided in table 4 of datasheet is used to arrive at the following parameters
        AccelerometerSensitivityFactorBasedOnFullScale=12;
        AccelerometerSensitivityFactorBasedOnMode = 1e-3;
        AccelerometerResolution = 12e-3;
        %

        ADCCF = 0.0012;
        ADCIteration=1;
        IsDataReady=boolean(1);

        TemporaryADCData = uint8(zeros(6,1));
        TemporaryADCStatus = 0;
        TemporaryADCTimestamp = 0;
    end

    properties(Hidden, Constant)
        TEMP_CHG_FLAG=0x1F;     %Controls auxiliary ADC and embedded temperature enable
        CTRL_REG1=0x20;         %Controls ODR, low power mode enable, axis e
        CTRL_REG2=0x21;         %Controls HPF mode, HPF cutoff, Filter data
        CTRL_REG3=0x22;         %Controls interrupt generation on INT1
        CTRL_REG4=0x23;         %Controls BDU, range, high resolution enable
        CTRL_REG5=0x24;         %Controls FIFO enable
        CTRL_REG6=0x25;         %Controls interrupt generation on INT2 and interrupt polarity of INT1 & INT2
        STATUS_REG=0x27;        %Status register for normal mode - overrun & data ready
        FIFO_CTRL_REG=0x2E;     %Controls FIFO mode and FIFO samples
        FIFO_SRC_REG=0x2F;      %Status register for FIFO mode - samples pending in FIFO buffer, watermark and overrun
        INT1_CFG=0x30;          %Register to configure Free-fall, Inertial wake-up, 6D and 4D detections
        INT1_STATUS=0x31;       %Status register for Free-fall, Inertial wake-up, 6D and 4D detections
        INT1_THS=0x32;          %Register to set the acceleration value at which the events should be detected
        INT1_DUR=0x33;          %Register to set the time duration above which the event is considered legal
        INT2_CFG=0x34;          %Register to configure Free-fall, Inertial wake-up, 6D and 4D detections
        INT2_STATUS=0x35;       %Status register for Freef-all, Inertial wake-up, 6D and 4D detections
        INT2_THS=0x36;          %Register to set the acceleration value at which the events should be detected
        INT2_DUR=0x37;          %Register to set the time duration above which the event is considered legal
        CLICK_CFG=0x38;         %Click configuration register
        CLICK_STATUS=0x39;      %Status register for click event
        CLICK_THS=0x3A;         %Register to set the acceleration value at which the events should be detected
        TIME_LIMIT=0x3B;        %Register to set the time duration above which the event is considered legal
        TIME_LATENCY=0x3C;      %Register to set the time interval after the first click detection where the click-detection procedure is disabled
        TIME_WINDOW=0x3D;       %Register to set the time duration that can elapse after the end of the latency interval in which the click-detection procedure can start, in cases the device is configured for double-click detection
        TemperatureConstant=25; %Constant used for temperature calculation
    end

    methods
        function obj = lis3dh(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})
            obj.showSensorPropertiesPosition='bottom';
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                clearSensor(obj); %Reset sensor registers
                obj.AccelerometerRange = 2;
                obj.Mode = '12-bit';
                obj.Cutoff = 8;
                obj.EnableHPF = 0;

                %Do not interchange obj.FIFOSamples and obj.IsFIFOEnabled
                %obj.FIFOSamples is used in the IsFIFOEnabled setter function
                obj.FIFOSamples = 2;
                obj.IsFIFOEnabled = false;
                %Place interrupt after FIFO
                %Interrupt register value depends on FIFO enable
                obj.IsActiveDataReadyInterrupt = 0;
                obj.IsActiveFIFOOverrunInterrupt=0;
                obj.InterruptPin = 'INT1';

                %Place temperature before ADC
                %Uninitialize ADC has a temperature guard
                obj.EnableTemperature=1;
                obj.EnableADC=0; %Since readVoltageImpl is not exposed by default ADC is disabled

                obj.DataType = "double";
                obj.IsDataReady=boolean(0);
                obj.EnableStatus=0;
            else
                names = {'Bus','I2CAddress','AccelerometerRange','AccelerometerODR','IsActiveDataReadyInterrupt','IsActiveFIFOOverrunInterrupt','InterruptPin','DataType','Mode','HPF','Cutoff','FIFO','FIFOSamples','Temperature','Status','ADC','ADCPinCount','Click','ConfigurableDetections1','ConfigurableDetections2'};
                defaults = {0,obj.I2CAddressList(1),2,400,false,false,'INT1',"double",'12-bit',0,8,false,2,1,1,1,1,[0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0]};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});

                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);

                clearSensor(obj); %Reset sensor registers
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.Mode = p.parameterValue('Mode');
                obj.AccelerometerODR = p.parameterValue('AccelerometerODR');
                obj.Cutoff = p.parameterValue('Cutoff');
                obj.EnableHPF = p.parameterValue('HPF');

                %Do not interchange obj.FIFOSamples and obj.IsFIFOEnabled
                %obj.FIFOSamples is used in the IsFIFOEnabled setter function
                obj.FIFOSamples = p.parameterValue('FIFOSamples');
                obj.IsFIFOEnabled = p.parameterValue('FIFO');

                %Place interrupt after FIFO
                %Interrupt register value depends on FIFO enable
                obj.IsActiveDataReadyInterrupt = p.parameterValue('IsActiveDataReadyInterrupt');
                obj.IsActiveFIFOOverrunInterrupt = p.parameterValue('IsActiveFIFOOverrunInterrupt');
                obj.InterruptPin = p.parameterValue('InterruptPin');

                %Place temperature before ADC
                %Uninitialize ADC has a temperature guard
                obj.EnableTemperature = p.parameterValue('Temperature');
                obj.EnableADC=p.parameterValue('ADC');
                obj.NumADCPins=p.parameterValue('ADCPinCount');

                obj.DataType = p.parameterValue('DataType');
                obj.EnableStatus=p.parameterValue('Status');

                %Structures holding click and event parameters
                obj.ClickParameters = p.parameterValue('Click');
                obj.ConfigurableDetections1Parameters = p.parameterValue('ConfigurableDetections1');
                obj.ConfigurableDetections2Parameters = p.parameterValue('ConfigurableDetections2');
            end

            enableInterrupts(obj);  %Enable data read interrupt and overflow interrupt at the end
        end

        %The function initializes/uninitializes the click feature of LIS3DH
        function set.ClickParameters(obj,value)
            obj.ClickParameters = value;
            configureClickRegisters(obj);
        end

        %The function can initializes/uninitializes any one of the following LIS3DH feature on INT1_CFG
        %   1. Free-fall
        %   2. Inertial wake-up
        %   3. 6D movement
        %   4. 6D position
        function set.ConfigurableDetections1Parameters(obj,value)
            obj.ConfigurableDetections1Parameters = value;
            % configureConfigurableDetections1Registers(obj);
            configureEventRegisters(obj,obj.ConfigurableDetections1Parameters,1);
        end

        %The function can initializes/uninitializes any one of the following LIS3DH feature on INT2_CFG
        %   1. Free-fall
        %   2. Inertial wake-up
        %   3. 6D movement
        %   4. 6D position
        function set.ConfigurableDetections2Parameters(obj,value)
            obj.ConfigurableDetections2Parameters = value;
            % configureConfigurableDetections2Registers(obj);
            configureEventRegisters(obj,obj.ConfigurableDetections2Parameters,2);
        end

        %The function initializes/uninitializes the embedded temperature sensor in LIS3DH based on EnableTemperature property
        %Since the set method of a property should not access another property the initialization/uninitialization is split into individual functions
        function set.EnableTemperature(obj,value)
            obj.EnableTemperature = value;
            if obj.EnableTemperature
                initializeTemperature(obj);
            else
                uninitializeTemperature(obj);
            end
        end

        %The function initializes/uninitializes the auxiliary ADC sensor in LIS3DH based on EnableADC property
        %Since the set method of a property should not access another property the initialization/uninitialization is split into individual functions
        function set.EnableADC(obj,value)
            obj.EnableADC=value;
            if obj.EnableADC
                initializeADC(obj);
            else
                uninitializeADC(obj);
            end
        end

        %The function sets the ODR of LIS3DH sensor based on the AccelerometerODR property
        %Different ODRs possible are
        %            8-bit: 1Hz,10Hz,25Hz,50Hz,100Hz,200Hz,400Hz,1600Hz and 5375Hz
        %10-bit and 12-bit: 1Hz,10Hz,25Hz,50Hz,100Hz,200Hz,400Hz,1344
        function set.AccelerometerODR(obj, value)
            switch value
                case 1
                    bytemask = 16;
                case 10
                    bytemask = 32;
                case 25
                    bytemask = 48;
                case 50
                    bytemask = 64;
                case 100
                    bytemask = 80;
                case 200
                    bytemask = 96;
                case 400
                    bytemask = 112;
                case 1600
                    bytemask = 128;
                case 1344
                    bytemask = 144;
                case 5376
                    bytemask = 144;
                otherwise
                    bytemask = 16;
            end

            %Bits 7:4 of register 0x20 associated with ODR is modified
            writeRegister(obj.Device,obj.CTRL_REG1, bitor(bitand(readRegister(obj.Device,obj.CTRL_REG1), uint8(0b00001111)),bytemask));
            obj.AccelerometerODR = value;
        end

        %The function sets the acceleration range of LIS3DH sensor based on AccelerometerRange property value
        %Ranges possible are "+/-2g","+/-4g","+/-8g", and "+/-16g"
        function set.AccelerometerRange(obj, value)
            setAccelRange(obj,value);
            obj.AccelerometerRange=value;
        end

        %The function enable/disables high pass filter based on EnableHPF property value
        function set.EnableHPF(obj,value)
            obj.EnableHPF = value;
            if obj.EnableHPF
                setHPFRefMode(obj);
            else
                clearHPFRefMode(obj);
            end
        end

        %The function configures the operating mode of LIS3DH sensor based on Mode property
        %Three modes are possible
        %   8-bit - Low power mode
        %  10-bit - Normal mode
        %  12-bit - High resolution mode
        function set.Mode(obj,value)
            setResolution(obj,value);
            obj.Mode = value;
        end

        %The function configures the FIFO of LIS3DH sensor based on IsFIFOEnabled property
        function set.IsFIFOEnabled(obj,value)
            obj.IsFIFOEnabled = value;
            enableFIFO(obj);
        end

        function set.FIFOSamples(obj,value)
            obj.FIFOSamples = value;
        end

        function set.Cutoff(obj,value)
            obj.Cutoff = value;
        end
    end

    %The following properties are overloaded to include AvailableADCPins
    methods(Hidden)
        function showSensorProperties(~)
            fprintf('                   AvailableADCPins: %s\n\n',"[""ADC1"",""ADC2"",""ADC3""]");
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            if obj.isSimulink && coder.target('MATLAB')
                try
                    % Note: Incase of LIS3DH the readRegister operation fails on the first attempt in connected IO.
                    deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
                catch ME
                    %If the first attempt to read the register fails, catch the exception and attempt to read the register again.
                    % This is based on the observed behavior that subsequent attempts (2nd, 3rd, etc.) to read the register succeed after an initial failure.
                    deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
                end
            else
                %If not in a Simulink MATLAB target environment, directly attempt to read the register without the try-catch block, as the issue of first-attempt failure is not present.
                deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            end
            if(~any(ismember(deviceid_value,obj.DeviceID)))
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','LIS3DH',num2str(obj.DeviceID));
                end
            end
        end

        %The following function checks if the interrupt is enabled in the
        %Block mask and configures the appropriate interrupt
        function enableInterrupts(obj)
            if obj.IsActiveDataReadyInterrupt
                value = uint8(1);
            else
                value = uint8(0);
            end
            if obj.IsFIFOEnabled
                %If FIFO is enabled bit 2 / bit 4 of register 0x22 is to set watermark interrupt / overrun interrupt
                ctrlreg3value = readRegister(obj.Device,obj.CTRL_REG3);
                ctrlreg3value = bitand(ctrlreg3value,uint8(0b11111001));
                ctrlreg3value = bitor(ctrlreg3value , bitshift(value,2) + bitshift(uint8(obj.IsActiveFIFOOverrunInterrupt),1));
                writeRegister(obj.Device,obj.CTRL_REG3,ctrlreg3value);
            else
                %If FIFO is disabled bit 4 of register 0x22 is set
                ctrlreg3value = readRegister(obj.Device,obj.CTRL_REG3);
                ctrlreg3value = bitand(ctrlreg3value, uint8(0b11110111));
                ctrlreg3value = bitor(ctrlreg3value, uint8(bitshift(value,4)));
                writeRegister(obj.Device,obj.CTRL_REG3,ctrlreg3value);
            end
        end

        function initAccelerometerImpl(~)
        end

        function initSensorImpl(~)
        end

        %The function reads the acceleration output from the data register of LIS3DH
        %Based on either IsFIFOEnabled property the dimension of data output varies
        function [data,status,timestamp]  = readAccelerationImpl(obj)
            bytestoreadfromsensor=obj.BytesToReadFromAccel; %This changes based on whether the FIFO is enabled or disabled;
            if obj.IsFIFOEnabled
                %If FIFO is enabled, reading the data register before it gets updated will cause I2C bus error.
                %So, isDataReady check is necessary. IsDataReady variable is updated in the readStatus function.
                %If status output is disabled by the user then FIFO will always read zero.
                %The following code is used to overcome this condition.
                %This condition occurs only in FIFO mode, in normal mode reading the register before update doesn't cause bus error.
                if obj.IsActiveDataReadyInterrupt
                    obj.IsDataReady=boolean(0);
                else
                    if ~obj.EnableStatus
                        [data,~] = obj.Device.readRegisterData(0x2F, 1, 'uint8');
                        obj.IsDataReady = boolean(~bitget(uint8(data),8));
                    end
                end
                %The X,Y and Z-axis output registers are of size 2 bytes
                %To read the complete X,Y and Z data as a set the total bytes to be read is 6 bytes
                %The maximum number of bytes that can be read from over I2C is 32
                %So, for FIFO operation maximum number of bytes that can be read is limitted to 30 in order to read X,Y,Z axis data as a set
                if ~obj.IsDataReady
                    obj.IsDataReady=boolean(0);
                    dataIndex=0;
                    while bytestoreadfromsensor>obj.BytesToReadMaximumValue
                        obj.tempFIFOData((1+dataIndex*obj.BytesToReadMaximumValue):(obj.BytesToReadMaximumValue+dataIndex*obj.BytesToReadMaximumValue)) = obj.Device.readRegisterData(obj.AccelerometerDataRegister,obj.BytesToReadMaximumValue, "uint8");
                        bytestoreadfromsensor=bytestoreadfromsensor-obj.BytesToReadMaximumValue;
                        dataIndex=dataIndex+1;
                    end
                    [obj.tempFIFOData((1+(dataIndex*obj.BytesToReadMaximumValue)):(bytestoreadfromsensor+(dataIndex*obj.BytesToReadMaximumValue))),status,timestamp] = obj.Device.readRegisterData(obj.AccelerometerDataRegister,bytestoreadfromsensor, "uint8");
                else
                    %If IsDataReady is not set then previous samples stored in tempFIFOData will be returned
                    status = 0;
                    timestamp = 0;
                end

                if(isequal(numel(obj.tempFIFOData),obj.FIFOSamples*6)&&(obj.FIFOSamples~=1))
                    data = reshape(obj.tempFIFOData,[6,obj.FIFOSamples])';
                else
                    data = obj.tempFIFOData;
                end
            else
                [accelData,status,timestamp]=obj.Device.readRegisterData(obj.AccelerometerDataRegister,bytestoreadfromsensor, "uint8");
                if(isequal(size(accelData,2),1))
                    data = accelData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToReadFromAccel))
                        data = reshape(data,[obj.BytesToReadFromAccel,obj.SamplesPerRead])';
                    end
                else
                    data = accelData;
                end
            end

            data = convertAccelData(obj, data);
        end

        %The function reads temperature from LIS3DH registers
        function [data,status,timestamp]  = readTemperatureImpl(obj)
            %Configure temperature on ADC3 pin if previously configured as analog input
            %Guard is added to ensure unnecessary I2C operation
            if ~obj.IsADC3TemperatureConfigured
                obj.initializeTemperature();
            end

            [temperatureData,status,timestamp] = obj.Device.readRegisterData(obj.TemperatureDataRegister, obj.BytesToReadForADC, "uint8");
            if(isequal(size(temperatureData,2),1))
                data = temperatureData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToReadForADC))
                    data = reshape(data,[obj.BytesToReadForADC,obj.SamplesPerRead])';
                end
            else
                data = temperatureData;
            end
            data = convertTemperatureData(obj, data);
        end

        %The function reads ADC value from LIS3DH external pins
        function [data,status,timestamp] = readVoltageImpl(obj,pinName)
            if ~obj.isSimulink
                validatestring(pinName,{'ADC3','ADC1','ADC2'},mfilename,'pinName');
            end
            switch pinName
                case "ADC1"
                    offset = 0;
                case "ADC2"
                    offset = 2;
                case "ADC3"
                    offset = 4;
                    %Configure analog input on ADC3 pin if already configured as temperature
                    %Guard is added to ensure unnecessary I2C operation
                    if obj.IsADC3TemperatureConfigured
                        obj.uninitializeTemperature();
                    end
                otherwise
                    offset = 0;
            end
            %If more than 1 ADC pins are choosen, the data of all three registers are read in a single read.
            %Though the data is read together, the data will sent one at a time based on the pinName specified.
            %This is done to decrease the number of I2C reads.
            if obj.NumADCPins>1
                if obj.ADCIteration == 1
                    [obj.TemporaryADCData,obj.TemporaryADCStatus,obj.TemporaryADCTimestamp] = obj.Device.readRegisterData(obj.VoltageDataRegister, obj.SequentialBytesToReadForADC, "uint8");
                end
                obj.ADCIteration = obj.ADCIteration + 1;
                if obj.ADCIteration>obj.NumADCPins
                    obj.ADCIteration = 1;
                end
                ADCData = obj.TemporaryADCData((1+offset):(2+offset));
                status = obj.TemporaryADCStatus;
                timestamp = obj.TemporaryADCTimestamp;
            else
                %If only one ADC pin is chosen, only one read is performed.
                %The register address depends on the pinName specified.
                [ADCData,status,timestamp] = obj.Device.readRegisterData(obj.VoltageDataRegister+offset, obj.BytesToReadForADC, "uint8");
            end
            if(isequal(size(ADCData,2),1))
                data = ADCData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToReadForADC))
                    data = reshape(data,[obj.BytesToReadForADC,obj.SamplesPerRead])';
                end
            else
                data = ADCData;
            end
            data = convertADCData(obj,data);
        end

        function [data,status,timestamp]  = readSensorDataImpl(obj)
            [accelData,status,timestamp]  = readAccelerationImpl(obj);
            [temperatureData,~,~] = readTemperatureImpl(obj);
            data = [accelData,temperatureData];
        end

        function data = convertSensorDataImpl(obj, data)
            data = [convertAccelData(obj, data(1:obj.BytesToReadFromAccel)) convertTemperatureData(obj, data(obj.BytesToReadFromAccel+1:obj.BytesToReadFromAccel+2))];
        end

        function setODRImpl(obj)
            % used only for MATLAB
            if strcmpi(obj.Mode,'8-bit')
                if obj.SampleRate>=max(obj.ODR2ParametersAccel)
                    obj.AccelerometerODR = max(obj.ODR2ParametersAccel); %Cap for the ODR
                else
                    accelODR = obj.ODR2ParametersAccel(obj.ODR2ParametersAccel>=obj.SampleRate);
                    obj.AccelerometerODR = accelODR(1);
                end
            else
                if obj.SampleRate>=max(obj.ODR1ParametersAccel)
                    obj.AccelerometerODR = max(obj.ODR1ParametersAccel); %Cap for the ODR
                else
                    accelODR = obj.ODR1ParametersAccel(obj.ODR1ParametersAccel>=obj.SampleRate);
                    obj.AccelerometerODR = accelODR(1);
                end
            end
        end

        %The function clears the LIS3DH registers during initialization
        function clearSensor(obj)
            %The line is used to clear the interrupt before initializing the sensor
            writeRegister(obj.Device,obj.CTRL_REG2,uint8(0));
            writeRegister(obj.Device,obj.CTRL_REG3,uint8(0));
            writeRegister(obj.Device,obj.CTRL_REG5,uint8(0));
            writeRegister(obj.Device,obj.CTRL_REG6,uint8(0));
            writeRegister(obj.Device,obj.FIFO_CTRL_REG,uint8(0));
            writeRegister(obj.Device,obj.INT1_CFG,uint8(0));
            writeRegister(obj.Device,obj.INT2_CFG,uint8(0));
            writeRegister(obj.Device,obj.CLICK_CFG,uint8(0));
        end

        function s = infoImpl(obj)
            if coder.target('MATLAB')
                s = struct('AccelerometerODR',obj.AccelerometerODR);
            else
                coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
            end
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName,obj.TemperatureDataName];
        end
    end

    methods(Hidden = true)
        function [SamplesPending,timestamp] = readPendingSamples(obj)
            [data,timestamp] = obj.Device.readRegisterData(0x2F, 1, 'uint8');
            SamplesPending = uint8(double(bitand(uint8(data),0x1F)));
        end

        %The following code is used for reading the status of the device
        %0 - new data available
        %1 - no new data
        %2 - overrun condition occurred
        function [status,timestamp] = readStatus(obj)
            if obj.IsFIFOEnabled
                [data,timestamp] = obj.Device.readRegisterData(0x2F, 1, 'uint8');
                obj.IsDataReady = boolean(~bitget(uint8(data),8));
                if bitget(uint8(data),7)
                    status=uint8(2);
                else
                    status = uint8(obj.IsDataReady);
                end
            else
                [data,timestamp] = obj.Device.readRegisterData(0x27, 1, 'uint8');
                obj.IsDataReady = double(~bitget(uint8(data),4));
                if bitget(uint8(data),8)
                    status=uint8(2);
                else
                    status = uint8(obj.IsDataReady);
                end
            end
        end

        function [eventStatus,timestamp] = readEventStatus(obj,event)

            if strcmpi(event,'Click')
                %Read click status register
                [data,timestamp] = obj.Device.readRegisterData(obj.CLICK_STATUS, 1, 'uint8');

                %Check if the event detected bit is set in the status register
                if ~bitget(data,7)
                    eventStatus = uint8([0,0,0]);
                else
                    %Send only the axis details on which the interrupt occurred
                    eventStatus = uint8([bitget(data,1) , bitget(data,2), bitget(data,3)]);
                end
            end

            if strcmpi(event,'ConfigurableDetections1')
                %Read event status register
                [data,timestamp] = obj.Device.readRegisterData(obj.INT1_STATUS, 1, 'uint8');

                %Check if the event detected bit is set in the status register
                if ~bitget(data,7)
                    if strcmpi(obj.ConfigurableDetections1Parameters.EventType,'4D Position') || strcmpi(obj.ConfigurableDetections1Parameters.EventType,'4D Movement')
                        eventStatus = uint8([0,0,0,0]);
                    else
                        if strcmpi(obj.ConfigurableDetections1Parameters.EventType,'Inertial wake-up')
                            eventStatus = uint8([0,0,0]);
                        else
                            if strcmpi(obj.ConfigurableDetections1Parameters.EventType,'Free-fall')
                                eventStatus = uint8(0);
                            else
                                eventStatus = uint8([0,0,0,0,0,0]);
                            end
                        end
                    end
                else
                    %During testing it was seen that the register contained all the axis details on which the condition satisfied.
                    %For example assume user configures inertial wake-up interrupt only on X and Y axis. Though Z is not selected, since acceleration of Z axis is 9.81m/s^2 in the register the Z axis bit will always be high.
                    %Since the user asked only for the X and Y axis details, those specific data are given as output since changing the size of output will cause confusion.
                    if strcmpi(obj.ConfigurableDetections1Parameters.EventType,'4D Position') || strcmpi(obj.ConfigurableDetections1Parameters.EventType,'4D Movement')
                        eventStatus = uint8(zeros(1,4));
                        eventStatus(1) = uint8(bitget(data,2) * obj.ConfigurableDetections1Parameters.EventAxis(2));
                        eventStatus(2) = uint8(bitget(data,1) * obj.ConfigurableDetections1Parameters.EventAxis(1));
                        eventStatus(3) = uint8(bitget(data,4) * obj.ConfigurableDetections1Parameters.EventAxis(4));
                        eventStatus(4) = uint8(bitget(data,3) * obj.ConfigurableDetections1Parameters.EventAxis(3));
                    else
                        if strcmpi(obj.ConfigurableDetections1Parameters.EventType,'Inertial wake-up')
                            eventStatus = uint8(zeros(1,3));
                            eventStatus(1) = uint8(bitget(data,2) * obj.ConfigurableDetections1Parameters.EventAxis(2));
                            eventStatus(2) = uint8(bitget(data,4) * obj.ConfigurableDetections1Parameters.EventAxis(4));
                            eventStatus(3) = uint8(bitget(data,6) * obj.ConfigurableDetections1Parameters.EventAxis(6));
                        else
                            if strcmpi(obj.ConfigurableDetections1Parameters.EventType,'Free-fall')
                                eventStatus = uint8(1);
                            else
                                eventStatus = uint8(zeros(1,6));
                                eventStatus(1) = uint8(bitget(data,2) * obj.ConfigurableDetections1Parameters.EventAxis(2));
                                eventStatus(2) = uint8(bitget(data,1) * obj.ConfigurableDetections1Parameters.EventAxis(1));
                                eventStatus(3) = uint8(bitget(data,4) * obj.ConfigurableDetections1Parameters.EventAxis(4));
                                eventStatus(4) = uint8(bitget(data,3) * obj.ConfigurableDetections1Parameters.EventAxis(3));
                                eventStatus(5) = uint8(bitget(data,6) * obj.ConfigurableDetections1Parameters.EventAxis(6));
                                eventStatus(6) = uint8(bitget(data,5) * obj.ConfigurableDetections1Parameters.EventAxis(5));
                            end
                        end
                    end
                end
            end

            if strcmpi(event,'ConfigurableDetections2')
                %Read event status register
                [data,timestamp] = obj.Device.readRegisterData(obj.INT2_STATUS, 1, 'uint8');
                %Check if the event detected bit is set in the status register
                if ~bitget(data,7)
                    if strcmpi(obj.ConfigurableDetections2Parameters.EventType,'4D Position') || strcmpi(obj.ConfigurableDetections2Parameters.EventType,'4D Movement')
                        eventStatus = uint8([0,0,0,0]);
                    else
                        if strcmpi(obj.ConfigurableDetections2Parameters.EventType,'Inertial wake-up')
                            eventStatus = uint8([0,0,0]);
                        else
                            if strcmpi(obj.ConfigurableDetections2Parameters.EventType,'Free-fall')
                                eventStatus = uint8(0);
                            else
                                eventStatus = uint8([0,0,0,0,0,0]);
                            end
                        end
                    end
                else
                    %During testing it was seen that the register contained all the axis details on which the condition satisfied.
                    %For example assume user configures inertial wake-up interrupt only on X and Y axis. Though Z is not selected, since acceleration of Z axis is 9.81m/s^2 in the register the Z axis bit will always be high.
                    %Since the user asked only for the X and Y axis details, those specific data are given as output since changing the size of output will cause confusion.
                    if strcmpi(obj.ConfigurableDetections2Parameters.EventType,'4D Position') || strcmpi(obj.ConfigurableDetections2Parameters.EventType,'4D Movement')
                        eventStatus = uint8(zeros(1,4));
                        eventStatus(1) = uint8(bitget(data,2) * obj.ConfigurableDetections2Parameters.EventAxis(2));
                        eventStatus(2) = uint8(bitget(data,1) * obj.ConfigurableDetections2Parameters.EventAxis(1));
                        eventStatus(3) = uint8(bitget(data,4) * obj.ConfigurableDetections2Parameters.EventAxis(4));
                        eventStatus(4) = uint8(bitget(data,3) * obj.ConfigurableDetections2Parameters.EventAxis(3));
                    else
                        if strcmpi(obj.ConfigurableDetections2Parameters.EventType,'Inertial wake-up')
                            eventStatus = uint8(zeros(1,3));
                            eventStatus(1) = uint8(bitget(data,2) * obj.ConfigurableDetections2Parameters.EventAxis(2));
                            eventStatus(2) = uint8(bitget(data,4) * obj.ConfigurableDetections2Parameters.EventAxis(4));
                            eventStatus(3) = uint8(bitget(data,6) * obj.ConfigurableDetections2Parameters.EventAxis(6));
                        else
                            if strcmpi(obj.ConfigurableDetections2Parameters.EventType,'Free-fall')
                                eventStatus = uint8(1);
                            else
                                eventStatus = uint8(zeros(1,6));
                                eventStatus(1) = uint8(bitget(data,2) * obj.ConfigurableDetections2Parameters.EventAxis(2));
                                eventStatus(2) = uint8(bitget(data,1) * obj.ConfigurableDetections2Parameters.EventAxis(1));
                                eventStatus(3) = uint8(bitget(data,4) * obj.ConfigurableDetections2Parameters.EventAxis(4));
                                eventStatus(4) = uint8(bitget(data,3) * obj.ConfigurableDetections2Parameters.EventAxis(3));
                                eventStatus(5) = uint8(bitget(data,6) * obj.ConfigurableDetections2Parameters.EventAxis(6));
                                eventStatus(6) = uint8(bitget(data,5) * obj.ConfigurableDetections2Parameters.EventAxis(5));
                            end
                        end
                    end
                end
            end

        end
    end

    methods(Access = private)
        function data = convertAccelData(obj,accelSensorData)
            xa = bitshift(bitor(bitshift(int16(accelSensorData(:,2)),8),int16(accelSensorData(:,1))),obj.BitResolution-16);
            ya = bitshift(bitor(bitshift(int16(accelSensorData(:,4)),8),int16(accelSensorData(:,3))),obj.BitResolution-16);
            za = bitshift(bitor(bitshift(int16(accelSensorData(:,6)),8),int16(accelSensorData(:,5))),obj.BitResolution-16);
            switch obj.DataType
                case "double"
                    data = obj.AccelerometerResolution.*double([xa, ya, za]);
                    data = data*9.81;
                case "single"
                    data = obj.AccelerometerResolution.*single([xa, ya, za]);
                    data = data*9.81;
                case "int16"
                    data = [xa,ya,za];
            end
        end

        function temperatureData = convertTemperatureData(obj,data)
            T = bitor(bitshift(int16(data(:,2)),8),int16(data(:,1)));
            switch obj.DataType
                case "double"
                    temperatureData =(double(T)/(2.^obj.TemperatureDataResolution))+obj.TemperatureConstant;
                case "single"
                    temperatureData =(single(T)/(2.^obj.TemperatureDataResolution))+obj.TemperatureConstant;
                case "int16"
                    temperatureData =T;
            end
        end

        function ADCData = convertADCData(obj,rawADCData)
            ADC = bitshift(bitor(bitshift(int16(rawADCData(:,2)),8),int16(rawADCData(:,1))),obj.ADCDataResolution-16);
            switch obj.DataType
                case "double"
                    %The following expression is calculated based on two point formula
                    %Points are obtained as (max/min voltage,max/min output register value)
                    %The points are (0.8,512) and (1.6,-512) for 10-bit resolution
                    %The points are (0.8,128) and (1.6,-128) for 8-bit resolution
                    %Resolution depends on accelerometer resolution setting
                    ADCData =  ((0.8/(-1*(2.^obj.ADCDataResolution))).*(double(ADC)-((2.^obj.ADCDataResolution)/2)))+0.8;
                case "single"
                    ADCData =  ((0.8/(-1*(2.^obj.ADCDataResolution))).*(single(ADC)-((2.^obj.ADCDataResolution)/2)))+0.8;
                case "int16"
                    ADCData = ADC;
            end
        end

        %The function is used to set the mode of the sensor
        %mode -> 8-bit, 10-bit, 12-bit mode
        function setResolution(obj,mode)
            switch mode
                case '8-bit'
                    %Bit 3 of 0x20 is set
                    writeRegister(obj.Device,obj.CTRL_REG1, bitor(bitand(readRegister(obj.Device,obj.CTRL_REG1), uint8(0b11110111)), 8));
                    %Bit 3 of 0x23 is cleared
                    writeRegister(obj.Device,obj.CTRL_REG4, bitand(readRegister(obj.Device,obj.CTRL_REG4), uint8(0b11110111)));
                    obj.BitResolution = 8;
                    obj.ADCDataResolution = 8;
                    obj.AccelerometerSensitivityFactorBasedOnMode = 16e-3;
                    obj.AccelerometerResolution = obj.AccelerometerSensitivityFactorBasedOnMode * obj.AccelerometerSensitivityFactorBasedOnFullScale;
                case '10-bit'
                    %Bit 3 of 0x20 is cleared
                    writeRegister(obj.Device,obj.CTRL_REG1, bitand(readRegister(obj.Device, obj.CTRL_REG1), uint8(0b11110111)));
                    %Bit 3 of 0x23 is cleared
                    writeRegister(obj.Device,obj.CTRL_REG4, bitand(readRegister(obj.Device, obj.CTRL_REG4), uint8(0b11110111)));
                    obj.BitResolution = 10;
                    obj.ADCDataResolution = 10;
                    obj.AccelerometerSensitivityFactorBasedOnMode = 4e-3;
                    obj.AccelerometerResolution = obj.AccelerometerSensitivityFactorBasedOnMode * obj.AccelerometerSensitivityFactorBasedOnFullScale;
                case '12-bit'
                    %Bit 3 of 0x20 is cleared
                    writeRegister(obj.Device,obj.CTRL_REG1, bitand(readRegister(obj.Device, obj.CTRL_REG1), uint8(0b11110111)));
                    %Bit 3 of 0x23
                    writeRegister(obj.Device,obj.CTRL_REG4, bitor(bitand(readRegister(obj.Device, obj.CTRL_REG4), uint8(0b11110111)), 8));
                    obj.BitResolution = 12;
                    obj.ADCDataResolution = 10;
                    obj.AccelerometerSensitivityFactorBasedOnMode = 1e-3;
                    obj.AccelerometerResolution = obj.AccelerometerSensitivityFactorBasedOnMode * obj.AccelerometerSensitivityFactorBasedOnFullScale;
            end
            obj.ADCCF = ( 1.2 / (2.^obj.ADCDataResolution) ) ;
        end

        %The function is used to modify the range of the accelerometer
        %Ranges-> +/-2g, "+/-4g", "+/-8g", "+/-16g"
        function setAccelRange(obj,Range)
            switch Range
                case 2
                    obj.AccelerometerSensitivityFactorBasedOnFullScale = 1;
                    bytemask = 0;
                case 4
                    obj.AccelerometerSensitivityFactorBasedOnFullScale = 2;
                    bytemask = 16;
                case 8
                    obj.AccelerometerSensitivityFactorBasedOnFullScale = 4;
                    bytemask = 32;
                case 16
                    obj.AccelerometerSensitivityFactorBasedOnFullScale = 12;
                    bytemask = 48;
            end
            %Bits 4 and 5 of 0x23 is modified
            writeRegister(obj.Device,obj.CTRL_REG4, bitor(bitand(readRegister(obj.Device, obj.CTRL_REG4), uint8(0b11001111)), bytemask));
        end

        %The function enables HPF in normal mode
        function setHPFRefMode(obj)
            %Bits 7:4 of 0x21 are modified
            ctrlreg2value = readRegister(obj.Device,obj.CTRL_REG2);
            ctrlreg2value = bitand(ctrlreg2value,uint8(0b00001111));
            ctrlreg2value = bitor(ctrlreg2value,obj.Cutoff);
            writeRegister(obj.Device,obj.CTRL_REG2, ctrlreg2value);
        end

        %The function disables HPF
        function clearHPFRefMode(obj)
            %Bits 7:4 of 0x21 are cleared
            ctrlreg2value = readRegister(obj.Device,obj.CTRL_REG2);
            ctrlreg2value = bitand(ctrlreg2value,uint8(0b00001111));
            writeRegister(obj.Device,obj.CTRL_REG2, ctrlreg2value);
        end

        %The function enables FIFO
        %The function also sets the bytes to be read from accelerometer based on FIFO condition
        function enableFIFO(obj)
            if obj.IsFIFOEnabled
                %Bit 6 of 0x24 is set
                writeRegister(obj.Device,obj.CTRL_REG5, bitor(bitand(readRegister(obj.Device, obj.CTRL_REG5), uint8(0b10111111)), 64));
                %Bits 0:5 and 6:7 are modified
                writeRegister(obj.Device,obj.FIFO_CTRL_REG, bitor(bitand(readRegister(obj.Device, obj.FIFO_CTRL_REG), uint8(0b00100000)), 128+(obj.FIFOSamples-1)));
                obj.BytesToReadFromAccel = obj.FIFOSamples*6;
            else
                %Bit 6 of 0x24 is cleared
                writeRegister(obj.Device,obj.CTRL_REG5,bitand(readRegister(obj.Device, obj.CTRL_REG5), uint8(0b10111111)));
                %Bits 0:5 and 6:7 are cleared
                writeRegister(obj.Device,obj.FIFO_CTRL_REG,bitand(readRegister(obj.Device,obj.FIFO_CTRL_REG ), uint8(0b00100000)));
                obj.BytesToReadFromAccel = 6;
            end
            obj.tempFIFOData = uint8(zeros(1,obj.BytesToReadFromAccel)); %property to hold previous FIFO data is cleared
        end

        %Function initializes the auxiliary ADC sensor
        %Functionality of ADC3 pin depends on embedded temperature sensor
        function initializeADC(obj)
            %Bit 7 of 0x23 is set
            writeRegister(obj.Device,obj.CTRL_REG4, bitor(bitand(readRegister(obj.Device, obj.CTRL_REG4), uint8(0b01111111)), 128));
            %Bit 7 of 0x1F is set
            writeRegister(obj.Device,obj.TEMP_CHG_FLAG, bitor(bitand(readRegister(obj.Device,obj.TEMP_CHG_FLAG), uint8(0b01111111)), 128));
        end

        %Function uninitializes the auxiliary ADC sensor
        function uninitializeADC(obj)
            %For temperature measurement to work, the ADC must be enabled.
            %Before uninitializing ADC check if user has enabled temperature
            %If temperature is enabled don't uninitialize the ADC.
            if ~obj.EnableTemperature
                %Bit 7 of 0x23 is cleared
                writeRegister(obj.Device,obj.CTRL_REG4, bitand(readRegister(obj.Device, obj.CTRL_REG4), uint8(0b01111111)));
                %Bit 7 of 0x1F is cleared
                writeRegister(obj.Device,obj.TEMP_CHG_FLAG,bitand(readRegister(obj.Device,obj.TEMP_CHG_FLAG), uint8(0b01111111)));
            end
        end

        %Function initializes the embedded temperature sensor
        %ADC3 pin cannot be used for external input
        %The IsADC3TemperatureConfigured is set to true if temperature sensing is initialized
        function initializeTemperature(obj)
            %Bit 7 of 0x23 is set
            writeRegister(obj.Device,obj.CTRL_REG4, bitor(bitand(readRegister(obj.Device,obj.CTRL_REG4), uint8(0b01111111)), 128));
            %Bit 7 and 6 of 0x1F is set
            %For temperature measurement to work, both ADC and Temperature sensor must be enabled
            writeRegister(obj.Device,obj.TEMP_CHG_FLAG, bitor(bitand(readRegister(obj.Device,obj.TEMP_CHG_FLAG), uint8(0b10111111)), 192));
            obj.IsADC3TemperatureConfigured = true;
        end

        %Function uninitializes the embedded temperature sensor
        %ADC3 pin will be available for external input
        %The obj.IsADC3TemperatureConfigured is set to false if temperature sensing is not initialized
        function uninitializeTemperature(obj)
            %Bit 7 of 0x23 is cleared
            writeRegister(obj.Device,obj.CTRL_REG4, bitand(readRegister(obj.Device, obj.CTRL_REG4), uint8(0b01111111)));
            %Bit 6 of 0x1F is cleared
            writeRegister(obj.Device,obj.TEMP_CHG_FLAG,bitand(readRegister(obj.Device, obj.TEMP_CHG_FLAG), uint8(0b10111111)));
            obj.IsADC3TemperatureConfigured = false;
        end

        %Function initializes/uninitializes the click feature of LIS3DH
        function configureClickRegisters(obj)
            %The parameters are initialized as zero. In case click feature is not configured then these values will be written into the respective registers causing uninitialization of the feature.
            configurationvalue = uint8(0);
            thresholdvalue = uint8(0);
            timelimitvalue = uint8(0);
            timelatencyvalue = uint8(0);
            timewindowvalue = uint8(0);

            %If click feature is enabled
            if obj.ClickParameters.IsClick
                %Determine single click or double click
                if strcmpi(obj.ClickParameters.ClickType,'Single click')
                    %Bit positions 0 2 and 6 are modified, in case of single click
                    configurationvalue = uint8(double(obj.ClickParameters.ClickAxis(1)) + bitshift(double(obj.ClickParameters.ClickAxis(2)),2) + bitshift(double(obj.ClickParameters.ClickAxis(3)),4));
                else
                    %Bit positions 1 3 and 5 are modified, in case of double click
                    configurationvalue = uint8(bitshift(double(obj.ClickParameters.ClickAxis(1)),1) + bitshift(double(obj.ClickParameters.ClickAxis(2)),3) + bitshift(double(obj.ClickParameters.ClickAxis(3)),5));
                end

                %Value to be written into CLICK_THS is computed
                thresholdvalue   = uint8((double(obj.ClickParameters.ClickThreshold)*127)/(9.81*obj.AccelerometerRange));

                timelimitvalue   = uint8(double(obj.AccelerometerODR)*double(obj.ClickParameters.ClickTimeLimit));                  %Value to be written into TIME_LIMIT is computed
                timelatencyvalue = uint8(double(obj.ClickParameters.ClickTimeLatency) * obj.AccelerometerODR);              %Value to be written into TIME_LATENCY is computed
                timewindowvalue  = uint8(double(obj.ClickParameters.ClickTimeWindow) * obj.AccelerometerODR);               %Value to be written into TIME_WINDOW is computed
                %Depending on the pin on which the interrupt should be mapped
                %the appropriate register is configured
                if obj.ClickParameters.ClickInterrupt
                    %if click is enabled
                    if strcmpi(obj.ClickParameters.ClickInterruptPin,'INT1')
                        %if interrupt pin is chosen as INT1
                        %The bit 7 of 0x22h is modified
                        writeRegister(obj.Device,obj.CTRL_REG3, bitor(readRegister(obj.Device, obj.CTRL_REG3), uint8(0b10000000)));
                    else
                        %if interrupt pin is chosen as INT2
                        %The bit 7 of 0x25h is modified
                        writeRegister(obj.Device,obj.CTRL_REG6, bitor(readRegister(obj.Device, obj.CTRL_REG6), uint8(0b10000000)));
                    end
                end
            else
                writeRegister(obj.Device,obj.CTRL_REG3, bitand(readRegister(obj.Device, obj.CTRL_REG3), uint8(0b01111111)));
                writeRegister(obj.Device,obj.CTRL_REG6, bitand(readRegister(obj.Device, obj.CTRL_REG6), uint8(0b01111111)));
            end

            writeRegister(obj.Device,obj.CLICK_CFG,configurationvalue);
            writeRegister(obj.Device,obj.CLICK_THS,thresholdvalue);
            writeRegister(obj.Device,obj.TIME_LIMIT,timelimitvalue);
            writeRegister(obj.Device,obj.TIME_LATENCY,timelatencyvalue);
            writeRegister(obj.Device,obj.TIME_WINDOW,timewindowvalue);
        end

        %Function initializes/uninitializes any one of the following feature of LIS3DH
        % 1. Inertial wake-up
        % 2. Free-fall
        % 3. 6D
        % 4. 4D
        function configureEventRegisters(obj,eventparameters,eventnumber)
            configurationvalue = uint8(0);
            thresholdvalue = uint8(0);
            durationvalue = uint8(0);
            is4Denable = 0;
            if eventparameters.IsEvent
                %Compute the value to be written into the INT1_CFG register
                switch eventparameters.EventType
                    case 'Inertial wake-up'
                        configurationvalue = uint8(bitshift(eventparameters.EventAxis(2),1)+bitshift(eventparameters.EventAxis(4),3)+bitshift(eventparameters.EventAxis(6),5));
                        is4Denable = 0;
                    case 'Free-fall'
                        configurationvalue = uint8(149);
                        is4Denable = 0;
                    case '6D position'
                        configurationvalue = uint8(eventparameters.EventAxis(1)+bitshift(eventparameters.EventAxis(2),1)...
                            +bitshift(eventparameters.EventAxis(3),2)+bitshift(eventparameters.EventAxis(4),3)+...
                            bitshift(eventparameters.EventAxis(5),4)+bitshift(eventparameters.EventAxis(6),5))+uint8(192);
                        is4Denable = 1;
                    case '6D movement'
                        configurationvalue = uint8(eventparameters.EventAxis(1)+bitshift(eventparameters.EventAxis(2),1)...
                            +bitshift(eventparameters.EventAxis(3),2)+bitshift(eventparameters.EventAxis(4),3)+...
                            bitshift(eventparameters.EventAxis(5),4)+bitshift(eventparameters.EventAxis(6),5))+uint8(64);
                        is4Denable = 1;
                    case '4D position'
                        configurationvalue = uint8(eventparameters.EventAxis(1)+bitshift(eventparameters.EventAxis(2),1)...
                            +bitshift(eventparameters.EventAxis(3),2)+bitshift(eventparameters.EventAxis(4),3))+uint8(192);
                        is4Denable = 1;
                    case '4D movement'
                        configurationvalue = uint8(eventparameters.EventAxis(1)+bitshift(eventparameters.EventAxis(2),1)...
                            +bitshift(eventparameters.EventAxis(3),2)+bitshift(eventparameters.EventAxis(4),3))+uint8(64);
                        is4Denable = 1;
                end

                %Compute the value to be written into the INT1_THS register
                thresholdvalue = uint8((eventparameters.EventThreshold*127.0)/(9.81*obj.AccelerometerRange));

                %Compute the value to be written into the INT1_DUR register
                durationvalue = uint8(eventparameters.EventDuration * obj.AccelerometerODR);
            end

            if eventnumber == 1
                writeRegister(obj.Device,obj.INT1_CFG, configurationvalue);
                writeRegister(obj.Device,obj.INT1_THS, thresholdvalue);
                writeRegister(obj.Device,obj.INT1_DUR, durationvalue);
            end

            if eventnumber == 2
                writeRegister(obj.Device,obj.INT2_CFG, configurationvalue);
                writeRegister(obj.Device,obj.INT2_THS, thresholdvalue);
                writeRegister(obj.Device,obj.INT2_DUR, durationvalue);
            end

            %To enable 4D detection, CTRL_REG5 bit 2 must be set high
            ctrlreg5value = readRegister(obj.Device, obj.CTRL_REG5);
            if is4Denable
                if eventnumber == 1
                    ctrlreg5value = bitor( ctrlreg5value,  uint8(0b00000100) );
                end

                if eventnumber == 2
                    ctrlreg5value = bitor( ctrlreg5value,  uint8(0b00000001) );
                end
            else
                if eventnumber == 1
                    ctrlreg5value = bitand( ctrlreg5value, uint8(0b11111011) );
                end

                if eventnumber == 2
                    ctrlreg5value = bitand( ctrlreg5value, uint8(0b11111110) );
                end
            end

            writeRegister(obj.Device,obj.CTRL_REG5, ctrlreg5value);

            %Depending on the pin on which the interrupt should be mapped
            %the appropriate register is configured
            if eventparameters.EventInterrupt && eventparameters.IsEvent
                %if interrupt pin is chosen as INT1
                %The bit 6 of register 0x22h is modified
                if strcmpi(eventparameters.EventInterruptPin,'INT1')
                    if eventnumber == 1
                        writeRegister(obj.Device,obj.CTRL_REG3, bitor(readRegister(obj.Device, obj.CTRL_REG3), uint8(0b01000000)));
                    end

                    if eventnumber == 2
                        writeRegister(obj.Device,obj.CTRL_REG3, bitor(readRegister(obj.Device, obj.CTRL_REG3), uint8(0b00100000)));
                    end
                else
                    %if interrupt pin is chosen as INT2
                    %The bit 6 of 0x25h is modified
                    if eventnumber == 1
                        writeRegister(obj.Device,obj.CTRL_REG6, bitor(readRegister(obj.Device, obj.CTRL_REG6), uint8(0b01000000)));
                    end

                    if eventnumber == 2
                        writeRegister(obj.Device,obj.CTRL_REG6, bitor(readRegister(obj.Device, obj.CTRL_REG6), uint8(0b00100000)));
                    end
                end
            else
                if eventnumber == 1
                    writeRegister(obj.Device,obj.CTRL_REG3, bitand(readRegister(obj.Device, obj.CTRL_REG3), uint8(0b10111111)));
                    writeRegister(obj.Device,obj.CTRL_REG6, bitand(readRegister(obj.Device, obj.CTRL_REG6), uint8(0b10111111)));
                end

                if eventnumber == 2
                    writeRegister(obj.Device,obj.CTRL_REG3, bitand(readRegister(obj.Device, obj.CTRL_REG3), uint8(0b11011111)));
                    writeRegister(obj.Device,obj.CTRL_REG6, bitand(readRegister(obj.Device, obj.CTRL_REG6), uint8(0b11011111)));
                end
            end
        end
    end
end