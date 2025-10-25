classdef (Sealed) bmi160 < matlabshared.sensors.accelerometer & matlabshared.sensors.gyroscope & matlabshared.sensors.magnetometer &...
        matlabshared.sensors.sensorUnit & matlabshared.sensors.TemperatureSensor & matlabshared.sensors.I2CSensorProperties
    %BMI160 connects to the BMI160 sensor connected to a hardware object
    %
    %   sensorObj = bmi160(a) returns a System object that reads sensor
    %   data from the BMI160 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   sensorObj = bmi160(a, 'Name', Value, ...) returns a BMI160 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   bmi160 Properties
    %   I2CAddress      : Specify the I2C Address of the BMI160.
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
    %   bmmi160 methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.
    %   readAngularVelocity   : Read one sample of angular velocity values from
    %                           sensor.
    %   readMagneticField     : Read one sample of magnetic field value from
    %                           sensor.
    %   readTemperature       : Read one sample of temperature value from sensor.
    %   read                  : Read one frame of acceleration, angular velocity, magnetic field and temperature values from
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
    %
    %   Example: Read one sample of Acceleration value from BMI160 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bmi160(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   For Streaming workflow
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bmi160(a);
    %   read(sensorObj)

    %   Copyright 2021-22 The MathWorks, Inc.

    %#codegen

    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 25;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [3;3;3;1];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = protected, Constant)
        AccelerometerDataRegister = 0x12;
        DeviceID = 0xD1;
        DeviceID_Mag = 0x32;
        CMD_REG = 0X7E;
        WHO_AM_I = 0x00;
        WHO_AM_I_MAG = 0x40;
        AccelerometerRangeRegister = 0x41;
        AccelerometerODRRegister = 0x40;
        ODRParametersAccel = [12.5,25,50,100,200,400,800,1600];
        ODRParametersGyro = [25,50,100,200,400,800,1600,3200];
        GyroscopeDataRegister = 0x0C;
        GyroscopeRangeRegister = 0x43;
        GyroscopeODRRegister = 0x42;
        TemperatureDataRegister = 0x20;
        MagnetometerDataHighRegister = 0x05;
        MagnetometerConfRegister = 0x44;
        StatusRegister = 0x1B;
        InterruptStatusRegister = 0x1C;
        Magnetometer_IF_0 = 0x4B;
        PageRegister = 0x7F;
        Magnetometer_IF_1 = 0x4C;
        Magnetometer_IF_2 = 0x4D
        Magnetometer_IF_3 = 0x4E
        Magnetometer_IF_4 = 0x4F
        Magnetometer_IFConfig = 0x6B;
        MagnetometerDataRegister = 0x04;
        AnyMotionConfigurationRegister = 0x5F;
        AnyMotionAmplitudeConfigRegister = 0x60;
        SlowMotionAmplitudeConfigRegister = 0x61;
        HighGDetectionTimeRegister = 0x5D;
        HighGDetectionAmplitudeRegister = 0x5E;
        SingleTapConfigurationRegister = 0x63;
        SingleTapAmplitudeConfigurationRegister = 0x64;
        FlatThetaRegister=0x67;
        FlatTimeRegister = 0x68;
        TemperatureOffset = 23; %Interms of deg C
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x68,0x69];
    end

    properties(Access = protected,Nontunable)
        GyroscopeRange = '125 dps';
        GyroscopeResolution;
        GyroscopeODR;
        GyroscopeFilterMode = 'Normal';
        IsActiveGyro = true;
        AccelerometerRange = '+/- 2g';
        AccelerometerResolution;
        AccelerometerODR;
        MagnetometerODR;
        AccelerometerFilterMode = 'Normal';
        IsActiveAccel = true;
        MagnetometerI2CAddress;
        IsActiveMag = true;
        EnableSecondaryMag = true;
        IsAccelStatus = false;
        IsGyroStatus = false;
        IsMagStatus = false;
        IsAnyMotion = false;
        IsSingleTap = false;
        IsDoubleTap = false;
        IsHighGDetection = false;
        IsSlowMotion = false;
        IsFlatDetection = false;
        IsDataReady = false;
        IsActiveTemperature = false;
        MagnetometerResolution = 0.3;%Interms of micro tesla
        DegreesPerSecToRadiansPerSec = 0.017453;
        TemperatureResolution = 1/512;%This Resolution value is in terms of deg C
        InterruptPinAnyMotion = 'INT1';
        InterruptPinSingleTap = 'INT1';
        InterruptPinDoubleTap = 'INT1';
        InterruptPinHighG = 'INT1';
        InterruptPinSlowMotion = 'INT1';
        InterruptPinDataReady= 'INT1';
        InterruptPinFlat = 'INT1';
        InterruptPinFIFO = 'INT1';
        AnyMotionTimeThreshold = '0';
        AnyMotionAmplitudeThreshold = 0.1;
        SingleTapQuietTimeThreshold = '30 ms';
        SingleTapShockTimeThreshold = '50 ms';
        SingleTapAmplitudeThreshold = 0.1;
        DoubleTapDurationTimeThreshold = '50 ms';
        SlowMotionTimeThreshold = '0';
        SlowMotionAmplitudeThreshold = 0.1;
        HighGTimeThreshold = 2.5;
        HighGAmplitudeThreshold =0.1;
        FlatThetaThreshold = 5.0;
        FlatTimeThreshold = '640 ms';
        DataType = 'single';

    end

    properties(Hidden)
        StatusRegisterValues = zeros(1,4);
        IsMagConnected = false;
        TimeStamp = 0;
    end

    properties(Hidden, Constant)
        BytesToRead = 6;
        BytesToReadForTemperature = 2;
    end

    methods
        function obj = bmi160(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                    obj.MagnetometerI2CAddress = 0x13;
                else
                    try
                        obj.init(varargin{:});
                        parserObj = parseSensorArguments(obj,varargin{:});
                        parsedResults = parserObj.Results;
                        if length(parsedResults.I2CAddress) == 2
                            I2caddresses= parsedResults.I2CAddress;
                            obj.MagnetometerI2CAddress =I2caddresses(2);
                        else
                            obj.MagnetometerI2CAddress = 0x13;
                        end
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                obj.IsActiveAccel = true;
                obj.IsActiveGyro = true;
                obj.IsActiveMag = true;
                obj.DataType = 'double';
                obj.EnableSecondaryMag = true;
                obj.AccelerometerRange = '+/- 16g';
                obj.AccelerometerResolution = getAccelerometerResolution(obj);
                obj.AccelerometerFilterMode = 'Normal';
                obj.GyroscopeRange = '2000 dps';
                obj.MagnetometerODR = '100 Hz';
                obj.GyroscopeResolution = getGyroscopeResolution(obj);
                obj.GyroscopeFilterMode = 'Normal';
                obj.IsAccelStatus = false;
                obj.IsGyroStatus = false;
                obj.IsMagStatus = false;
                obj.IsActiveTemperature = true;
                obj.IsAnyMotion = false;
                obj.IsSingleTap = false;
                obj.IsDoubleTap = false;
                obj.IsHighGDetection = false;
                obj.IsSlowMotion = false;
                obj.IsFlatDetection = false;
                obj.IsDataReady = false;
                obj.AnyMotionTimeThreshold = '0';
                obj.AnyMotionAmplitudeThreshold = 0.1;
                obj.SingleTapQuietTimeThreshold = '30 ms';
                obj.SingleTapShockTimeThreshold = '50 ms';
                obj.SingleTapAmplitudeThreshold = 0.1;
                obj.DoubleTapDurationTimeThreshold = '50 ms';
                obj.SlowMotionTimeThreshold = '0';
                obj.SlowMotionAmplitudeThreshold = 0.1;
                obj.HighGTimeThreshold = 2.5;
                obj.HighGAmplitudeThreshold =0.1;
                obj.InterruptPinAnyMotion = 'INT1';
                obj.InterruptPinSingleTap = 'INT1';
                obj.InterruptPinDoubleTap =  'INT1';
                obj.InterruptPinHighG = 'INT1';
                obj.InterruptPinSlowMotion = 'INT1';
                obj.InterruptPinDataReady = 'INT1';
                obj.FlatThetaThreshold = 5.0;
                obj.FlatTimeThreshold = '640 ms';
                obj.InterruptPinFlat = 'INT1';
            else
                names =     {'Bus','I2CAddress','MagnetometerI2CAddress'...
                    'IsActiveMag','IsActiveGyro','GyroscopeRange','GyroscopeODR','IsActiveAccel','AccelerometerRange','AccelerometerODR','AccelerometerFilterMode','GyroscopeFilterMode','IsAccelStatus','IsGyroStatus','IsMagStatus','EnableSecondaryMag','IsAnyMotion', 'IsSingleTap','IsDoubleTap','IsHighGDetection','IsSlowMotion','IsFlatDetection','IsDataReady','IsActiveTemperature','MagnetometerODR','InterruptPinAnyMotion','InterruptPinSingleTap','InterruptPinDoubleTap','InterruptPinHighG','InterruptPinSlowMotion','InterruptPinFlat','InterruptPinDataReady','AnyMotionTimeThreshold','AnyMotionAmplitudeThreshold','SingleTapQuietTimeThreshold','SingleTapShockTimeThreshold','SingleTapAmplitudeThreshold','DoubleTapDurationTimeThreshold','SlowMotionTimeThreshold','SlowMotionAmplitudeThreshold','HighGTimeThreshold','HighGAmplitudeThreshold','FlatThetaThreshold','FlatTimeThreshold','DataType'};
                defaults =    {0,obj.I2CAddressList(2),0x13,...
                    true,true,'125 dps',12.5,true,'+/- 2g', 25, 'Normal', 'Normal',false,false,false,false,false,false,false,false,false,false,false,false,'25 Hz','INT1','INT1','INT1','INT1','INT1','INT1','INT1','0', 0.1,'30 ms','50 ms',0.1,'50 ms','0',0.1,2.5,0.1,5.0,'640 ms','single'};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                obj.MagnetometerI2CAddress = p.parameterValue('MagnetometerI2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.IsActiveAccel= p.parameterValue('IsActiveAccel');
                obj.IsActiveGyro= p.parameterValue('IsActiveGyro');
                obj.IsActiveMag= p.parameterValue('IsActiveMag');
                obj.DataType = p.parameterValue('DataType');
                obj.EnableSecondaryMag = p.parameterValue('EnableSecondaryMag');
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.AccelerometerResolution = getAccelerometerResolution(obj);
                obj.AccelerometerODR = p.parameterValue('AccelerometerODR');
                obj.AccelerometerFilterMode = p.parameterValue('AccelerometerFilterMode');
                obj.GyroscopeRange = p.parameterValue('GyroscopeRange');
                obj.GyroscopeResolution = getGyroscopeResolution(obj);
                obj.GyroscopeODR = p.parameterValue('GyroscopeODR');
                obj.GyroscopeFilterMode = p.parameterValue('GyroscopeFilterMode');
                obj.IsAccelStatus = p.parameterValue('IsAccelStatus');
                obj.IsGyroStatus = p.parameterValue('IsGyroStatus');
                obj.IsMagStatus = p.parameterValue('IsMagStatus');
                obj.IsActiveTemperature = p.parameterValue('IsActiveTemperature');
                obj.IsAnyMotion = p.parameterValue('IsAnyMotion');
                obj.IsSingleTap = p.parameterValue('IsSingleTap');
                obj.IsDoubleTap = p.parameterValue('IsDoubleTap');
                obj.IsHighGDetection = p.parameterValue('IsHighGDetection');
                obj.IsSlowMotion = p.parameterValue('IsSlowMotion');
                obj.IsFlatDetection = p.parameterValue('IsFlatDetection');
                obj.IsDataReady = p.parameterValue('IsDataReady');
                obj.MagnetometerODR = p.parameterValue('MagnetometerODR');
                obj.AnyMotionTimeThreshold = p.parameterValue('AnyMotionTimeThreshold');
                obj.AnyMotionAmplitudeThreshold = p.parameterValue('AnyMotionAmplitudeThreshold');
                obj.SingleTapQuietTimeThreshold = p.parameterValue('SingleTapQuietTimeThreshold');
                obj.SingleTapShockTimeThreshold = p.parameterValue('SingleTapShockTimeThreshold');
                obj.SingleTapAmplitudeThreshold = p.parameterValue('SingleTapAmplitudeThreshold');
                obj.DoubleTapDurationTimeThreshold = p.parameterValue('DoubleTapDurationTimeThreshold');
                obj.SlowMotionTimeThreshold = p.parameterValue('SlowMotionTimeThreshold');
                obj.SlowMotionAmplitudeThreshold = p.parameterValue('SlowMotionAmplitudeThreshold');
                obj.HighGTimeThreshold = p.parameterValue('HighGTimeThreshold');
                obj.HighGAmplitudeThreshold = p.parameterValue('HighGAmplitudeThreshold');
                obj.InterruptPinAnyMotion = p.parameterValue('InterruptPinAnyMotion');
                obj.InterruptPinSingleTap = p.parameterValue('InterruptPinSingleTap');
                obj.InterruptPinDoubleTap = p.parameterValue('InterruptPinDoubleTap');
                obj.InterruptPinHighG = p.parameterValue('InterruptPinHighG');
                obj.InterruptPinSlowMotion = p.parameterValue('InterruptPinSlowMotion');
                obj.InterruptPinDataReady = p.parameterValue('InterruptPinDataReady');
                obj.FlatThetaThreshold = p.parameterValue('FlatThetaThreshold');
                obj.FlatTimeThreshold = p.parameterValue('FlatTimeThreshold');
                obj.InterruptPinFlat = p.parameterValue('InterruptPinFlat');
            end
        end

        function set.GyroscopeODR(obj, value)
            switch value
                case '25 Hz'
                    ByteMask = 0x06;
                case '50 Hz'
                    ByteMask = 0x07;
                case '100 Hz'
                    ByteMask = 0x08;
                case '200 Hz'
                    ByteMask = 0x09;
                case '400 Hz'
                    ByteMask = 0x0A;
                case '800 Hz'
                    ByteMask = 0x0B;
                case '1600 Hz'
                    ByteMask = 0x0C;
                case '3200 Hz'
                    ByteMask = 0x0D;
                otherwise
                    ByteMask = 0x06;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.GyroscopeODRRegister);
            writeRegister(obj.Device,obj.GyroscopeODRRegister, bitor(bitand(val_CTRL1_XL, uint8(0xF0)), uint8(ByteMask)));
            obj.GyroscopeODR = value;
        end

        function set.GyroscopeFilterMode(obj, value)
            %OSR full form Over sampling rate. OSR2 implies Sampling rate*2
            switch value
                case 'Normal'
                    ByteMask = 0x20;
                case 'OSR2'
                    ByteMask = 0x10;
                case 'OSR4'
                    ByteMask = 0x00;
                otherwise
                    ByteMask = 0x20;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.GyroscopeODRRegister);
            writeRegister(obj.Device,obj.GyroscopeODRRegister, bitor(bitand(val_CTRL1_XL, uint8(0xCF)), uint8(ByteMask)));
            obj.GyroscopeFilterMode = value;
        end

        function set.MagnetometerODR(obj,value)
            switch value
                case '0.78125 Hz'
                    ByteMask = 0x01;
                case '1.5625 Hz'
                    ByteMask = 0x02;
                case '3.125 Hz'
                    ByteMask = 0x03;
                case '6.25 Hz'
                    ByteMask = 0x04;
                case '12.5 Hz'
                    ByteMask = 0x05;
                case '25 Hz'
                    ByteMask = 0x06;
                case '50 Hz'
                    ByteMask = 0x07;
                case '100 Hz'
                    ByteMask = 0x08;
                case '200 Hz'
                    ByteMask = 0x09;
                case '400 Hz'
                    ByteMask = 0x0A;
                case '800 Hz'
                    ByteMask = 0x0B;
                otherwise
                    ByteMask = 0x06;
            end
            val = readRegister(obj.Device, obj.MagnetometerConfRegister);
            writeRegister(obj.Device,obj.MagnetometerConfRegister, bitor(bitand(val, uint8(0xF0)), uint8(ByteMask)));
            enableMagDataMode(obj);
        end

        function set.AccelerometerODR(obj, value)
            switch value
                case '12.5 Hz'
                    ByteMask = 0x05;
                case '25 Hz'
                    ByteMask = 0x06;
                case '50 Hz'
                    ByteMask = 0x07;
                case '100 Hz'
                    ByteMask = 0x08;
                case '200 Hz'
                    ByteMask = 0x09;
                case '400 Hz'
                    ByteMask = 0x0A;
                case '800 Hz'
                    ByteMask = 0x0B;
                case '1600 Hz'
                    ByteMask = 0x0C;
                otherwise
                    ByteMask = 0x05;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.AccelerometerODRRegister);
            writeRegister(obj.Device,obj.AccelerometerODRRegister, bitor(bitand(val_CTRL1_XL, uint8(0x70)), uint8(ByteMask)));
            obj.AccelerometerODR = value;
        end

        function set.AccelerometerFilterMode(obj, value)
            switch value
                case 'Normal'
                    ByteMask = 0x20;
                case 'OSR2'
                    ByteMask = 0x10;
                case 'OSR4'
                    ByteMask = 0x00;
                otherwise
                    ByteMask = 0x20;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.AccelerometerODRRegister);
            writeRegister(obj.Device,obj.AccelerometerODRRegister, bitor(bitand(val_CTRL1_XL, uint8(0x0F)), uint8(ByteMask)));
            obj.AccelerometerFilterMode = value;
        end

        function set.GyroscopeRange(obj, value)
            setGyroRange(obj,value);
            obj.GyroscopeRange=value;
        end

        function set.AccelerometerRange(obj, value)
            setAccelRange(obj,value);
            obj.AccelerometerRange=value;
        end

        function set.IsActiveAccel(obj, value)
            if value
                accelPMUModeCommandRegister(obj);
            end
            obj.IsActiveAccel = value;
        end

        function set.IsActiveGyro(obj, value)
            if value
                gyroPMUModeCommandRegister(obj);
            end
            obj.IsActiveGyro = value;
        end

        function set.EnableSecondaryMag(obj, value)
            if value
                initSecondaryMagnetometer(obj);
            end
            obj.EnableSecondaryMag = value;
        end

        function set.InterruptPinAnyMotion(obj, value)
            enableAnyMotionInterrupts(obj,value);
            obj.InterruptPinAnyMotion = value;
        end

        function set.InterruptPinSingleTap(obj, value)
            enableSingleTapInterrupt(obj,value);
            obj.InterruptPinSingleTap = value;
        end

        function set.HighGTimeThreshold(obj, value)
            setHighGTimeThreshold(obj,value);
            obj.HighGTimeThreshold = value;
        end

        function set.FlatThetaThreshold(obj, value)
            setFlatThetaThreshold(obj,value);
            obj.FlatThetaThreshold = value;
        end

        function set.FlatTimeThreshold(obj,value)
            % This method sets the time threshold for flat interrupt. So
            % the interrupt will only be triggered if the flat interrupt is
            % active for the times specified here.
            setFlatTimeThreshold(obj,value);
            obj.FlatTimeThreshold = value;
        end
        function set.HighGAmplitudeThreshold(obj, value)
            setHighGAmplitudeThreshold(obj,value);
            obj.HighGAmplitudeThreshold = value;
        end
        function set.SingleTapQuietTimeThreshold(obj,value)
            setQuietTimeReg(obj,value);
            obj.SingleTapQuietTimeThreshold = value;
        end

        function set.AnyMotionTimeThreshold(obj,value)
            setAnymotionTimeThreshold(obj,value);
            obj.AnyMotionTimeThreshold = value;
        end

        function set.AnyMotionAmplitudeThreshold(obj,value)
            setAnymotionAmplitudeThreshold(obj,value);
            obj.AnyMotionAmplitudeThreshold = value;
        end

        function set.SlowMotionAmplitudeThreshold(obj,value)
            setSlowmotionAmplitudeThreshold(obj,value);
            obj.SlowMotionAmplitudeThreshold = value;
        end

        function set.SingleTapShockTimeThreshold(obj,value)
            setShockTimeReg(obj,value);
            obj.SingleTapShockTimeThreshold = value;
        end

        function set.DoubleTapDurationTimeThreshold(obj,value)
            setDurationTimeReg(obj,value);
            obj.DoubleTapDurationTimeThreshold = value;
        end

        function set.SingleTapAmplitudeThreshold(obj,value)
            setSingleTapAmplitudeReg(obj,value);
            obj.SingleTapAmplitudeThreshold = value;
        end

        function set.SlowMotionTimeThreshold(obj,value)
            setSlowmotionTimeThreshold(obj,value);
            obj.SlowMotionTimeThreshold = value;
        end

        function set.InterruptPinDoubleTap(obj, value)
            enableDoubleTapInterrupt(obj,value);
            obj.InterruptPinDoubleTap = value;
        end

        function set.InterruptPinHighG(obj, value)
            enableHighGInterrupt(obj,value);
            obj.InterruptPinHighG = value;
        end

        function set.InterruptPinSlowMotion(obj, value)
            enableSlowMotionInterrupt(obj,value);
            obj.InterruptPinSlowMotion = value;
        end

        function set.InterruptPinDataReady(obj, value)
            enableDataReadyInterrupt(obj,value);
            obj.InterruptPinDataReady = value;
        end

        function set.InterruptPinFlat(obj, value)
            enableFlatInterrupt(obj,value);
            obj.InterruptPinFlat = value;
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if(deviceid_value ~= obj.DeviceID)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','BMI160',num2str(obj.DeviceID));
                end
            end
        end

        function initGyroscopeImpl(obj)
        end

        function initAccelerometerImpl(obj)
        end

        function initMagnetometerImpl(obj)
        end

        function initSensorImpl(obj)
            resetCommandRegister(obj);
            fastOffsetCommandRegister(obj);
        end

        function [data,status,timestamp]  = readAccelerationImpl(obj)
            if obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady || obj.IsFlatDetection
                % we need to disable interrupts to avoid nested interrupts
                disableInterrupts(obj);
                [tempData,status,timestamp] = readRegisterData(obj.Device,obj.AccelerometerDataRegister, obj.BytesToRead, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                        data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertAccelData(obj, data);
                % After performing the read interrupts should be enabled
                % again
                enableAnyMotionInterrupts(obj,obj.InterruptPinAnyMotion);
                enableSingleTapInterrupt(obj,obj.InterruptPinSingleTap);
                enableDoubleTapInterrupt(obj,obj.InterruptPinDoubleTap);
                enableHighGInterrupt(obj,obj.InterruptPinHighG);
                enableSlowMotionInterrupt(obj,obj.InterruptPinSlowMotion);
                enableDataReadyInterrupt(obj,obj.InterruptPinDataReady);
                enableFlatInterrupt(obj,obj.InterruptPinFlat);
            else
                [tempData,status,timestamp] = readRegisterData(obj.Device,obj.AccelerometerDataRegister, obj.BytesToRead, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                        data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertAccelData(obj, data);
            end
        end


        function [data,status,timestamp]  = readAngularVelocityImpl(obj)
            if obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady || obj.IsFlatDetection
                disableInterrupts(obj);
                [tempData,status,timestamp] = readRegisterData(obj.Device,obj.GyroscopeDataRegister, obj.BytesToRead, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                        data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertGyroData(obj, data);
                enableAnyMotionInterrupts(obj,obj.InterruptPinAnyMotion);
                enableSingleTapInterrupt(obj,obj.InterruptPinSingleTap);
                enableDoubleTapInterrupt(obj,obj.InterruptPinDoubleTap);
                enableHighGInterrupt(obj,obj.InterruptPinHighG);
                enableSlowMotionInterrupt(obj,obj.InterruptPinSlowMotion);
                enableDataReadyInterrupt(obj,obj.InterruptPinDataReady);
                enableFlatInterrupt(obj,obj.InterruptPinFlat);
            else
                [tempData,status,timestamp] = readRegisterData(obj.Device,obj.GyroscopeDataRegister, obj.BytesToRead, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                        data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertGyroData(obj, data);
            end
        end

        function [data,status,timestamp]  = readMagneticFieldImpl(obj)
            if obj.IsMagConnected
                if obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady || obj.IsFlatDetection
                    disableInterrupts(obj);
                    [tempData,status,timestamp] = readRegisterData(obj.Device,obj.MagnetometerDataRegister, obj.BytesToRead, "uint8");
                    if(isequal(size(tempData,2),1))
                        data = tempData';
                        if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                            data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                        end
                    else
                        data = tempData;
                    end
                    data = convertMagData(obj, data);
                    enableAnyMotionInterrupts(obj,obj.InterruptPinAnyMotion);
                    enableSingleTapInterrupt(obj,obj.InterruptPinSingleTap);
                    enableDoubleTapInterrupt(obj,obj.InterruptPinDoubleTap);
                    enableHighGInterrupt(obj,obj.InterruptPinHighG);
                    enableSlowMotionInterrupt(obj,obj.InterruptPinSlowMotion);
                    enableDataReadyInterrupt(obj,obj.InterruptPinDataReady);
                    enableFlatInterrupt(obj,obj.InterruptPinFlat);
                else
                    [tempData,status,timestamp] = readRegisterData(obj.Device,obj.MagnetometerDataRegister, obj.BytesToRead, "uint8");
                    if(isequal(size(tempData,2),1))
                        data = tempData';
                        if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                            data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                        end
                    else
                        data = tempData;
                    end
                    data = convertMagData(obj, data);
                    % data = NaN([obj.SamplesPerRead 3]);
                end
            else
                [tempData,status,timestamp] = readRegisterData(obj.Device,obj.MagnetometerDataRegister, obj.BytesToRead, "uint8");
                if mod(length(tempData),obj.SamplesPerRead)
                    if strcmp(obj.DataType,'double')
                        data = NaN([1 3]);
                    else
                        data = single(NaN([1 3]));
                    end
                else
                    if strcmp(obj.DataType,'double')
                        data = NaN([obj.SamplesPerRead 3]);
                    else
                        data = single(NaN([obj.SamplesPerRead 3]));
                    end
                end
            end
        end

        function [data,status,timestamp]  = readTemperatureImpl(obj)
            if obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady || obj.IsFlatDetection
                disableInterrupts(obj);
                [tempData,status,timestamp] = readRegisterData(obj.Device,obj.TemperatureDataRegister, obj.BytesToReadForTemperature, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToReadForTemperature))
                        data = reshape(data,[obj.BytesToReadForTemperature,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertTemperatureData(obj, data);
                enableAnyMotionInterrupts(obj,obj.InterruptPinAnyMotion);
                enableSingleTapInterrupt(obj,obj.InterruptPinSingleTap);
                enableDoubleTapInterrupt(obj,obj.InterruptPinDoubleTap);
                enableHighGInterrupt(obj,obj.InterruptPinHighG);
                enableSlowMotionInterrupt(obj,obj.InterruptPinSlowMotion);
                enableDataReadyInterrupt(obj,obj.InterruptPinDataReady);
                enableFlatInterrupt(obj,obj.InterruptPinFlat);
            else
                [tempData,status,timestamp] = readRegisterData(obj.Device,obj.TemperatureDataRegister, obj.BytesToReadForTemperature, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToReadForTemperature))
                        data = reshape(data,[obj.BytesToReadForTemperature,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertTemperatureData(obj, data);
            end
        end

        function [data,status,timestamp]  = readSensorDataImpl(obj)
            [accelData,~,~]  = readAccelerationImpl(obj);
            [gyroData,~,~] = readAngularVelocityImpl(obj);
            [magData,status,timestamp]=readMagneticFieldImpl(obj);
            [tempData ,~,~] = readTemperatureImpl(obj);
            data=[accelData,gyroData,magData,tempData];
        end

        function data = convertSensorDataImpl(obj, data)
            data=[convertAccelData(obj, data(1:obj.BytesToRead)) convertGyroData(obj, data(obj.BytesToRead+1:obj.BytesToRead*2)) convertMagData(obj, data(obj.BytesToRead*2+1:obj.BytesToRead*3)) convertTemperatureData(obj, data(obj.BytesToRead*3+1:obj.BytesToRead*3+obj.BytesToReadForTemperature))];
        end

        function setODRImpl(obj)
            % used only for MATLAB
            accelODR = obj.ODRParametersAccel(obj.ODRParametersAccel>=obj.SampleRate);
            obj.AccelerometerODR = accelODR(end);
            gyroODR = obj.ODRParametersGyro(obj.ODRParametersGyro>=obj.SampleRate);
            obj.GyroscopeODR = gyroODR(end);
        end

        function s = infoImpl(obj)
            s = struct('AccelerometerODR',obj.AccelerometerODR,'GyroscopeODR',obj.GyroscopeODR);
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName, obj.GyroscopeDataName ,obj.MagnetometerDataName,obj.TemperatureDataName];
        end
    end

    methods(Hidden = true)
        function [status,timestamp] = readAccelerationStatus(obj)
            %Status can take 2 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            [temp,~,timestamp] = readRegisterData(obj.Device,obj.StatusRegister, 1, 'uint8');
            statusValues = bitget(uint8(temp),8);
            if(isequal(statusValues,1))
                status=int8(0);
            else
                status=int8(1);
            end
        end
        function [status,timestamp] = readAngularRateStatus(obj)
            %Status can take 2 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            [temp,~,timestamp] = readRegisterData(obj.Device,obj.StatusRegister, 1, 'uint8');
            statusValues = bitget(uint8(temp),7);
            if(isequal(statusValues,1))
                status=int8(0);
            else
                status=int8(1);
            end
        end
        function [status,timestamp] = readMagneticFieldStatus(obj)
            %Status can take 2 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            timestamp = [];
            if obj.EnableSecondaryMag
                [temp,~,timestamp] = readRegisterData(obj.Device,obj.StatusRegister, 1, 'uint8');
                statusValues = bitget(uint8(temp),6);
                if(isequal(statusValues,1))
                    status=int8(0);
                else
                    status=int8(1);
                end
            end
        end
        function [status,timestamp] = readInterruptSource(obj)
            %Status can take 3 values namely 0,1 and -1
            %0 represents that specific interrupt occured
            %1 represents that specific interrupt didnot occur
            %-1 represents that specific interrupt is not enabled by the user
            % Interrupt status information is divided into 4 status
            % registers hence I am burst reading the status register
            % values.
            timestamp = [];
            obj.StatusRegisterValues = uint8([0,0,0,0]);
            temp = [0,0,0,0];
            [temp(:),~,obj.TimeStamp] = readRegisterData(obj.Device,obj.InterruptStatusRegister,4, 'uint8');
            obj.StatusRegisterValues(:,1)= temp(:,1);
            obj.StatusRegisterValues(:,2)= temp(:,2);
            obj.StatusRegisterValues(:,3)= temp(:,3);
            obj.StatusRegisterValues(:,4)= temp(:,4);
            timestamp= obj.TimeStamp;
            if obj.IsFlatDetection && obj.IsActiveAccel
                statusValues = bitget(uint8(obj.StatusRegisterValues(:, 1)),8);
                if(isequal(statusValues,1))
                    statusFlat=int8(1);
                else
                    statusFlat=int8(0);
                end
            else
                statusFlat =int8(-1);
            end

            if obj.IsSingleTap && obj.IsActiveAccel
                statusValues = bitget(uint8(obj.StatusRegisterValues(:, 1)),6);
                if(isequal(statusValues,1))
                    statusSingleTap=int8(1);
                else
                    xaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),5);
                    yaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),6);
                    zaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),7);
                    statusSingleTap=int8(xaxisevent || yaxisevent || zaxisevent);
                end
            else
                statusSingleTap =int8(-1);
            end

            if obj.IsDoubleTap && obj.IsActiveAccel
                statusValues = bitget(uint8(obj.StatusRegisterValues(:, 1)),5);
                if(isequal(statusValues,1))
                    statusDoubleTap=int8(1);
                else
                    xaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),5);
                    yaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),6);
                    zaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),7);
                    statusDoubleTap=int8(xaxisevent || yaxisevent || zaxisevent);
                end
            else
                statusDoubleTap =int8(-1);
            end

            if obj.IsSlowMotion && obj.IsActiveAccel
                statusValues = bitget(uint8(obj.StatusRegisterValues(:, 2)),8);
                if(isequal(statusValues,1))
                    statusSlowMotion=int8(1);
                else
                    statusSlowMotion=int8(0);
                end
            else
                statusSlowMotion =int8(-1);
            end

            if obj.IsAnyMotion && obj.IsActiveAccel
                statusValues = bitget(uint8(obj.StatusRegisterValues(:, 1)),3);
                if(isequal(statusValues,1))
                    statusAnyMotion=int8(1);
                else
                    statusAnyMotion=int8(0);
                end
            else
                statusAnyMotion =int8(-1);
            end

            if obj.IsDataReady && (obj.IsActiveAccel || obj.IsActiveGyro || obj.IsActiveMag)
                statusValues = bitget(uint8(obj.StatusRegisterValues(:, 2)),5);
                if(isequal(statusValues,1))
                    statusDataReady=int8(1);
                else
                    statusDataReady=int8(0);
                end
            else
                statusDataReady =int8(-1);
            end

            if obj.IsHighGDetection && obj.IsActiveAccel
                statusValues = bitget(uint8(obj.StatusRegisterValues(:, 2)),3);
                if(isequal(statusValues,1))
                    statusHighG=int8(1);
                else
                    xaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 4)),1);
                    yaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 4)),2);
                    zaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 4)),3);
                    statusHighG=int8(xaxisevent || yaxisevent || zaxisevent);
                end
            else
                statusHighG =int8(-1);
            end
            status=[statusSingleTap, statusDoubleTap, statusHighG,statusAnyMotion,statusSlowMotion,statusFlat,statusDataReady];
        end

        function [status,timestamp] = readTapEventSource(obj)
            timestamp = obj.TimeStamp;
            if (obj.IsSingleTap || obj.IsDoubleTap) && obj.IsActiveAccel
                signvalue = bitget(uint8(obj.StatusRegisterValues(:, 3)),8);
                xaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),5);
                yaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),6);
                zaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),7);
                if(isequal(signvalue,1))
                    signvalue=uint8(0);
                else
                    signvalue=uint8(1);
                end
                if(isequal(xaxisevent,1))
                    xaxisevent=uint8(1);
                else
                    xaxisevent=uint8(0);
                end
                if(isequal(yaxisevent,1))
                    yaxisevent=uint8(1);
                else
                    yaxisevent=uint8(0);
                end
                if(isequal(zaxisevent,1))
                    zaxisevent=uint8(1);
                else
                    zaxisevent=uint8(0);
                end
            else
                signvalue=uint8(0);
                xaxisevent=uint8(0);
                yaxisevent=uint8(0);
                zaxisevent=uint8(0);
            end
            status=[xaxisevent,yaxisevent,zaxisevent,signvalue];
        end

        function [status,timestamp] = readHighGEventSource(obj)
            timestamp = obj.TimeStamp;
            if (obj.IsHighGDetection) && obj.IsActiveAccel
                signvalue = bitget(uint8(obj.StatusRegisterValues(:, 4)),4);
                xaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 4)),1);
                yaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 4)),2);
                zaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 4)),3);
                if(isequal(signvalue,1))
                    signvalue=uint8(0);
                else
                    signvalue=uint8(1);
                end
                if(isequal(xaxisevent,1))
                    xaxisevent=uint8(1);
                else
                    xaxisevent=uint8(0);
                end
                if(isequal(yaxisevent,1))
                    yaxisevent=uint8(1);
                else
                    yaxisevent=uint8(0);
                end
                if(isequal(zaxisevent,1))
                    zaxisevent=uint8(1);
                else
                    zaxisevent=uint8(0);
                end
            else
                signvalue=uint8(0);
                xaxisevent=uint8(0);
                yaxisevent=uint8(0);
                zaxisevent=uint8(0);
            end
            status=[xaxisevent,yaxisevent,zaxisevent,signvalue];
        end

        function [status,timestamp] = readAnyMotionEventSource(obj)
            timestamp = obj.TimeStamp;
            if (obj.IsAnyMotion) && obj.IsActiveAccel
                signvalue = bitget(uint8(obj.StatusRegisterValues(:, 3)),4);
                xaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),1);
                yaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),2);
                zaxisevent = bitget(uint8(obj.StatusRegisterValues(:, 3)),3);
                if(isequal(signvalue,1))
                    signvalue=uint8(0);
                else
                    signvalue=uint8(1);
                end
                if(isequal(xaxisevent,1))
                    xaxisevent=uint8(1);
                else
                    xaxisevent=uint8(0);
                end
                if(isequal(yaxisevent,1))
                    yaxisevent=uint8(1);
                else
                    yaxisevent=uint8(0);
                end
                if(isequal(zaxisevent,1))
                    zaxisevent=uint8(1);
                else
                    zaxisevent=uint8(0);
                end
            else
                signvalue=uint8(0);
                xaxisevent=uint8(0);
                yaxisevent=uint8(0);
                zaxisevent=uint8(0);
            end
            status=[xaxisevent,yaxisevent,zaxisevent,signvalue];
        end
    end

    methods(Access = private)
        function initSecondaryMagnetometer(obj)
            setMagInterface(obj);
            enablingPullUpRegistersForMag(obj);
            setMagHigherByte(obj);
            setAuxI2CAddress(obj);
            enableMagSetup(obj);
            setIFConfig(obj);
            enableSleepMode(obj);
            checkSecondaryMag(obj);
            setRepititions(obj);
            enableForceMode(obj);
            setDataReadAddress(obj);
        end

        function data = convertTemperatureData(obj, tempSensorData)
            %little endian
            if strcmp(obj.DataType,'double')
                data = double(bitor(int16(tempSensorData(:, 1)), bitshift(int16(tempSensorData(:, 2)),8)));
                data = data*obj.TemperatureResolution + obj.TemperatureOffset;
            else
                data = single(bitor(int16(tempSensorData(:, 1)), bitshift(int16(tempSensorData(:, 2)),8)));
                data = single(data*obj.TemperatureResolution + obj.TemperatureOffset);
            end
        end

        function resetCommandRegister(obj)
            ByteMask = 0xB6;
            writeRegister(obj.Device,obj.CMD_REG, ByteMask);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(60);
            else
                pause(0.06);
            end
        end

        function fastOffsetCommandRegister(obj)
            ByteMask = 0x03;
            writeRegister(obj.Device,obj.CMD_REG, ByteMask);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(60);
            else
                pause(0.06);
            end
        end

        function gyroPMUModeCommandRegister(obj)
            ByteMask = 0x15;
            writeRegister(obj.Device,obj.CMD_REG, ByteMask);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(85);
            else
                pause(0.085);
            end
        end

        function g = getGyroscopeResolution(obj)
            switch  obj.GyroscopeRange
                case sprintf('125 dps')
                    g = 1/262.4;
                case sprintf('250 dps')
                    g = 1/131.2;
                case sprintf('500 dps')
                    g = 1/65.6;
                case sprintf('1000 dps')
                    g = 1/32.8;
                case sprintf('2000 dps')
                    g = 1/16.4;
            end
        end

        function data = convertGyroData(obj,gyroSensorData)
            if strcmp(obj.DataType,'double')
                xa = double(bitor(int16(gyroSensorData(:, 1)), bitshift(int16(gyroSensorData(:, 2)),8))) ;
                ya = double(bitor(int16(gyroSensorData(:, 3)), bitshift(int16(gyroSensorData(:, 4)),8))) ;
                za = double(bitor(int16(gyroSensorData(:, 5)), bitshift(int16(gyroSensorData(:, 6)),8))) ;
                data = (obj.DegreesPerSecToRadiansPerSec * obj.GyroscopeResolution).*[xa, ya, za];
            else
                xa = single(bitor(int16(gyroSensorData(:, 1)), bitshift(int16(gyroSensorData(:, 2)),8))) ;
                ya = single(bitor(int16(gyroSensorData(:, 3)), bitshift(int16(gyroSensorData(:, 4)),8))) ;
                za = single(bitor(int16(gyroSensorData(:, 5)), bitshift(int16(gyroSensorData(:, 6)),8))) ;
                data = single((obj.DegreesPerSecToRadiansPerSec * obj.GyroscopeResolution).*[xa, ya, za]);
            end
        end

        function setGyroRange(obj,Range)
            switch Range
                case '125 dps'
                    ByteMask = 0x04;
                case '250 dps'
                    ByteMask = 0x03;
                case '500 dps'
                    ByteMask = 0x02;
                case '1000 dps'
                    ByteMask = 0x01;
                case '2000 dps'
                    ByteMask = 0x00;
            end
            val = readRegister(obj.Device,obj.GyroscopeRangeRegister);
            writeRegister(obj.Device,obj.GyroscopeRangeRegister,bitor( bitand(val, uint8(0xF8)),uint8(ByteMask)));
        end

        function g = getAccelerometerResolution(obj)
            switch  obj.AccelerometerRange
                case sprintf('+/- 2g')
                    g = 1/16384;
                case sprintf('+/- 4g')
                    g = 1/8192;
                case sprintf('+/- 8g')
                    g = 1/4096;
                case sprintf('+/- 16g')
                    g = 1/2048;
            end
        end

        function data = convertAccelData(obj,accelSensorData)
            %little endian
            if strcmp(obj.DataType,'double')
                xa = double(bitor(int16(accelSensorData(:, 1)), bitshift(int16(accelSensorData(:, 2)),8))) ;
                ya = double(bitor(int16(accelSensorData(:, 3)), bitshift(int16(accelSensorData(:, 4)),8))) ;
                za = double(bitor(int16(accelSensorData(:, 5)), bitshift(int16(accelSensorData(:, 6)),8))) ;
                data = obj.AccelerometerResolution.*[xa, ya, za];
                data = data*9.81;
            else
                xa = single(bitor(int16(accelSensorData(:, 1)), bitshift(int16(accelSensorData(:, 2)),8))) ;
                ya = single(bitor(int16(accelSensorData(:, 3)), bitshift(int16(accelSensorData(:, 4)),8))) ;
                za = single(bitor(int16(accelSensorData(:, 5)), bitshift(int16(accelSensorData(:, 6)),8))) ;
                data = single(obj.AccelerometerResolution.*[xa, ya, za]);
                data = single(data*9.81);
            end
        end

        function data = convertMagData(obj,gyroSensorData)
            %little endian
            if strcmp(obj.DataType,'double')
                xa = double(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(uint8(gyroSensorData(:, 1)), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 2)),5)),13 ));
                ya = double(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(uint8(gyroSensorData(:, 3)), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 4)),5)),13)) ;
                za = double(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(uint8(gyroSensorData(:, 5)), uint8(0xFE)),-1)), bitshift(int16(gyroSensorData(:, 6)),7)),15)) ;
                data = obj.MagnetometerResolution.*[xa, ya, za];
            else
                xa = single(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(uint8(gyroSensorData(:, 1)), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 2)),5)),13 ));
                ya = single(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(uint8(gyroSensorData(:, 3)), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 4)),5)),13)) ;
                za = single(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(uint8(gyroSensorData(:, 5)), uint8(0xFE)),-1)), bitshift(int16(gyroSensorData(:, 6)),7)),15)) ;
                data = single(obj.MagnetometerResolution.*[xa, ya, za]);
            end
        end

        function decimal = conversionOfTwosComplementTodecimal(obj,Input,bits)
            %  convert two's complement to decimal
            %  data - single value or array to convert
            %  bits - how many bits wide is the data
            len = length(Input);
            decimal=zeros(len,1);
            for i=1:len
                if bitget(Input(i),bits) == 1
                    decimal(i) = int16((bitxor(Input(i),2^bits-1)+1))*-1;
                else
                    decimal(i) = Input(i);
                end
            end
        end

        function setAccelRange(obj,Range)
            switch Range
                case '+/- 2g'
                    ByteMask = 0x03;
                case '+/- 4g'
                    ByteMask = 0x05;
                case '+/- 8g'
                    ByteMask = 0x08;
                case '+/- 16g'
                    ByteMask = 0x0C;
            end
            val = readRegister(obj.Device,obj.AccelerometerRangeRegister);
            writeRegister(obj.Device,obj.AccelerometerRangeRegister,bitor(bitand(val, uint8(0xF0)),uint8(ByteMask)));
        end

        function accelPMUModeCommandRegister(obj)
            ByteMask = 0x11;
            writeRegister(obj.Device,obj.CMD_REG, ByteMask);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(5);
            else
                pause(0.005);
            end
        end

        function setMagInterface(obj)
            ByteMask = 0x19;
            writeRegister(obj.Device,obj.CMD_REG, ByteMask);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(60);
            else
                pause(0.06);
            end
        end

        function enablingPullUpRegistersForMag(obj)
            ByteMask_EN_PULL_UP_REG_1 = 0x37;
            ByteMask_EN_PULL_UP_REG_2 = 0x9A;
            ByteMask_EN_PULL_UP_REG_3 = 0xC0;
            writeRegister(obj.Device,obj.CMD_REG, ByteMask_EN_PULL_UP_REG_1);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
            writeRegister(obj.Device,obj.CMD_REG, ByteMask_EN_PULL_UP_REG_2);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
            writeRegister(obj.Device,obj.CMD_REG, ByteMask_EN_PULL_UP_REG_3);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function enablingPullUpRegister4ForPage(obj)
            ByteMask_EN_PULL_UP_REG_4 = 0x90 ;
            writeRegister(obj.Device,obj.PageRegister, ByteMask_EN_PULL_UP_REG_4);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function enablingPullUpRegister5ForPage(obj)
            ByteMask_EN_PULL_UP_REG_5 = 0x80 ;
            writeRegister(obj.Device,obj.PageRegister, ByteMask_EN_PULL_UP_REG_5);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function setAuxI2CAddress(obj)
            val = readRegister(obj.Device, obj.Magnetometer_IF_0);
            if obj.isSimulink
                temp=uint8(bitor(bitand(uint8(val), uint8(0x01)), bitshift(uint8(hex2dec(obj.MagnetometerI2CAddress)),1)));
            else
                temp=uint8(bitor(bitand(uint8(val), uint8(0x01)), bitshift(uint8(obj.MagnetometerI2CAddress),1)));
            end
            writeRegister(obj.Device,obj.Magnetometer_IF_0, temp);
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function enableMagSetup(obj)
            ByteMask_EN_PULL_UP_REG_5 = 0x83 ;
            val = readRegister(obj.Device, obj.Magnetometer_IF_1);
            writeRegister(obj.Device,obj.Magnetometer_IF_1, bitor(bitand(val, uint8(0x00)), uint8(ByteMask_EN_PULL_UP_REG_5)));
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function setIFConfig(obj)
            ByteMask = 0x20 ;
            val = readRegister(obj.Device, obj.Magnetometer_IFConfig);
            writeRegister(obj.Device,obj.Magnetometer_IFConfig, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function enableSleepMode(obj)
            ByteMask = 0x01 ;
            ByteMask1 = 0x4B;
            val = readRegister(obj.Device, obj.Magnetometer_IF_4);
            val2 = readRegister(obj.Device, obj.Magnetometer_IF_3);
            writeRegister(obj.Device,obj.Magnetometer_IF_4, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
            writeRegister(obj.Device,obj.Magnetometer_IF_3, bitor(bitand(val2, uint8(0x00)), uint8(ByteMask1)));
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function checkSecondaryMag(obj)
            writeRegister(obj.Device,obj.Magnetometer_IF_2, uint8(0x40));
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
            [tempData,status,timestamp] = readRegisterData(obj.Device,obj.MagnetometerDataRegister, 1, "uint8");
            if(tempData ~= obj.DeviceID_Mag)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','BMM150',num2str(obj.DeviceID_Mag));
                end
                obj.IsMagConnected = false;
            else
                obj.IsMagConnected = true;
            end

        end

        function setRepititions(obj)
            ByteMask = 0x04;
            ByteMask1 = 0x51;
            ByteMask2 = 0x0E;
            ByteMask3 = 0x52;
            val = readRegister(obj.Device, obj.Magnetometer_IF_4);
            val2 = readRegister(obj.Device, obj.Magnetometer_IF_3);
            writeRegister(obj.Device,obj.Magnetometer_IF_4, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
            writeRegister(obj.Device,obj.Magnetometer_IF_3, bitor(bitand(val2, uint8(0x00)), uint8(ByteMask1)));
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
            val = readRegister(obj.Device, obj.Magnetometer_IF_4);
            val2 = readRegister(obj.Device, obj.Magnetometer_IF_3);
            writeRegister(obj.Device,obj.Magnetometer_IF_4, bitor(bitand(val, uint8(0x00)), uint8(ByteMask2)));
            writeRegister(obj.Device,obj.Magnetometer_IF_3, bitor(bitand(val2, uint8(0x00)), uint8(ByteMask3)));
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function enableForceMode(obj)
            ByteMask = 0x02;
            ByteMask1 = 0x4C;
            val = readRegister(obj.Device, obj.Magnetometer_IF_4);
            val2 = readRegister(obj.Device, obj.Magnetometer_IF_3);
            writeRegister(obj.Device,obj.Magnetometer_IF_4, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
            writeRegister(obj.Device,obj.Magnetometer_IF_3, bitor(bitand(val2, uint8(0x00)), uint8(ByteMask1)));
        end

        function setDataReadAddress(obj)
            ByteMask = 0x42;
            val = readRegister(obj.Device, obj.Magnetometer_IF_2);
            writeRegister(obj.Device,obj.Magnetometer_IF_2, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
        end

        function setMagConf(obj)
            ByteMask = 0x06;
            val = readRegister(obj.Device, obj.MagnetometerConfRegister);
            writeRegister(obj.Device,obj.MagnetometerConfRegister, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
        end

        function enableMagDataMode(obj)
            ByteMask_EN_PULL_UP_REG_5 = 0x00 ;
            val = readRegister(obj.Device, obj.Magnetometer_IF_1);
            writeRegister(obj.Device,obj.Magnetometer_IF_1, bitor(bitand(val, uint8(0x3F)), uint8(ByteMask_EN_PULL_UP_REG_5)));
            if ~coder.target('MATLAB')
                obj.Parent.delayFunctionForHardware(1);
            else
                pause(0.001);
            end
        end

        function setMagHigherByte(obj)
            ByteMask = 0x20;
            writeRegister(obj.Device,obj.MagnetometerDataHighRegister,uint8(ByteMask));
        end

        function enableAnyMotionInterrupts(obj,value)
            if obj.IsAnyMotion
                if strcmp(value,'INT1')
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0xF0)),uint8(0x0A)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x55);
                    writeRegister(obj.Device,0x55, bitor(bitand(val_CTRL1_XL, uint8(0xFB)),uint8(0x04)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0xF8)),uint8(0x07)));
                else
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0x0F)),uint8(0xA0)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x57);
                    writeRegister(obj.Device,0x57, bitor(bitand(val_CTRL1_XL, uint8(0xFB)),uint8(0x04)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0xF8)),uint8(0x07)));
                end
            end
        end

        function enableSingleTapInterrupt(obj,value)
            if obj.IsSingleTap
                if strcmp(value,'INT1')
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0xF0)),uint8(0x0A)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x55);
                    writeRegister(obj.Device,0x55, bitor(bitand(val_CTRL1_XL, uint8(0xDF)),uint8(0x20)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0xDF)),uint8(0x20)));
                else
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0x0F)),uint8(0xA0)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x57);
                    writeRegister(obj.Device,0x57, bitor(bitand(val_CTRL1_XL, uint8(0xDF)),uint8(0x20)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0xDF)),uint8(0x20)));
                end
            end
        end

        function setAnymotionTimeThreshold(obj,anyMotionTime)
            if obj.IsAnyMotion
                switch anyMotionTime
                    case '1'
                        ByteMask = 0x00;
                    case '2'
                        ByteMask = 0x01;
                    case '3'
                        ByteMask = 0x02;
                    case '4'
                        ByteMask = 0x03;
                end
                val_CTRL1_XL = readRegister(obj.Device, obj.AnyMotionConfigurationRegister);
                writeRegister(obj.Device,obj.AnyMotionConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0xFC)),uint8(ByteMask)));
            end
        end

        function setSlowmotionTimeThreshold(obj,slowMotionTime)
            if obj.IsSlowMotion
                switch slowMotionTime
                    case '1'
                        ByteMask = 0x00;
                    case '2'
                        ByteMask = 0x04;
                    case '3'
                        ByteMask = 0x08;
                    case '4'
                        ByteMask = 0x0C;
                end
                val_CTRL1_XL = readRegister(obj.Device, obj.AnyMotionConfigurationRegister);
                writeRegister(obj.Device,obj.AnyMotionConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0xF3)),uint8(ByteMask)));
            end
        end

        function setAnymotionAmplitudeThreshold(obj,anyMotionAmplitude)
            if obj.IsAnyMotion
                switch obj.AccelerometerRange
                    case '+/- 2g'
                        initialOffset=0.00195;
                        rangeSpecificStep=0.00391;
                    case '+/- 4g'
                        initialOffset=0.00391;
                        rangeSpecificStep=0.00781;
                    case '+/- 8g'
                        initialOffset=0.00781;
                        rangeSpecificStep=0.01563;
                    case '+/- 16g'
                        initialOffset=0.01563;
                        rangeSpecificStep=0.03125;
                end
                suppliedAmplitude=anyMotionAmplitude;
                adjustedAmplitude = suppliedAmplitude - initialOffset;
                if (adjustedAmplitude<0)
                    adjustedAmplitude = 0;
                end
                maxAmplitudePossible = ((255.*rangeSpecificStep) + initialOffset);
                if suppliedAmplitude>maxAmplitudePossible
                    adjustedAmplitude = maxAmplitudePossible;
                end
                amplitudeVal = uint8(adjustedAmplitude/rangeSpecificStep);
                val_CTRL1_XL = readRegister(obj.Device, obj.AnyMotionAmplitudeConfigRegister);
                writeRegister(obj.Device,obj.AnyMotionAmplitudeConfigRegister, bitor(bitand(val_CTRL1_XL, uint8(0x00)),uint8(amplitudeVal)));
            end
        end

        function setSlowmotionAmplitudeThreshold(obj,slowMotionAmplitude)
            if obj.IsSlowMotion
                switch obj.AccelerometerRange
                    case '+/- 2g'
                        initialOffset=0.00195;
                        rangeSpecificStep=0.00391;
                    case '+/- 4g'
                        initialOffset=0.00391;
                        rangeSpecificStep=0.00781;
                    case '+/- 8g'
                        initialOffset=0.00781;
                        rangeSpecificStep=0.01563;
                    case '+/- 16g'
                        initialOffset=0.01563;
                        rangeSpecificStep=0.03125;
                end
                suppliedAmplitude=slowMotionAmplitude;
                adjustedAmplitude = suppliedAmplitude - initialOffset;
                if (adjustedAmplitude<0)
                    adjustedAmplitude = 0;
                end
                maxAmplitudePossible = ((255.*rangeSpecificStep) + initialOffset);
                if suppliedAmplitude>maxAmplitudePossible
                    adjustedAmplitude = maxAmplitudePossible;
                end
                amplitudeVal = uint8(adjustedAmplitude/rangeSpecificStep);
                val_CTRL1_XL = readRegister(obj.Device, obj.SlowMotionAmplitudeConfigRegister);
                writeRegister(obj.Device,obj.SlowMotionAmplitudeConfigRegister, bitor(bitand(val_CTRL1_XL, uint8(0x00)),uint8(amplitudeVal)));
            end
        end

        function setQuietTimeReg(obj,quietTime)
            if obj.IsSingleTap || obj.IsDoubleTap
                val_CTRL1_XL = readRegister(obj.Device, obj.SingleTapConfigurationRegister);
                if strcmp(quietTime,'30 ms')
                    writeRegister(obj.Device,obj.SingleTapConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0x7F)), uint8(0x00)));
                else
                    writeRegister(obj.Device,obj.SingleTapConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0x7F)), uint8(0x80)));
                end
            end
        end

        function setHighGTimeThreshold(obj,highGTime)
            if obj.IsHighGDetection
                suppliedTime=highGTime;
                step = 2.5;
                timeVal = ((suppliedTime/step)-1);
                timeVal = uint8(timeVal);
                val_CTRL1_XL = readRegister(obj.Device, obj.HighGDetectionTimeRegister);
                writeRegister(obj.Device,obj.HighGDetectionTimeRegister, bitor(bitand(val_CTRL1_XL, uint8(0x00)),uint8(timeVal)));
            end
        end

        function setFlatThetaThreshold(obj,flatThreshold)
            if obj.IsFlatDetection
                suppliedTheta=flatThreshold;
                step = 0.7;
                timeVal = ((suppliedTheta/step)-1);
                timeVal = uint8(timeVal);
                val_CTRL1_XL = readRegister(obj.Device, obj.FlatThetaRegister);
                writeRegister(obj.Device,obj.FlatThetaRegister, bitor(bitand(val_CTRL1_XL, uint8(0xC0)),uint8(timeVal)));
            end
        end

        function setFlatTimeThreshold(obj,flatTimeThreshold)
            if obj.IsFlatDetection
                switch flatTimeThreshold
                    case '0 ms'
                        ByteMask = 0x00;
                    case '640 ms'
                        ByteMask = 0x10;
                    case '1280 ms'
                        ByteMask = 0x20;
                    case '2560 ms'
                        ByteMask = 0x30;
                end
                val_CTRL1_XL = readRegister(obj.Device, obj.FlatTimeRegister);
                writeRegister(obj.Device,obj.FlatTimeRegister, bitor(bitand(val_CTRL1_XL, uint8(0xCF)),ByteMask));
            end
        end

        function setHighGAmplitudeThreshold(obj,highGAmplitude)
            if obj.IsHighGDetection
                switch obj.AccelerometerRange
                    case '+/- 2g'
                        initialOffset=0.00391;
                        rangeSpecificStep=0.00781;
                    case '+/- 4g'
                        initialOffset=0.00781;
                        rangeSpecificStep=0.01563;
                    case '+/- 8g'
                        initialOffset=0.01563;
                        rangeSpecificStep=0.03125;
                    case '+/- 16g'
                        initialOffset=0.03125;
                        rangeSpecificStep=0.0625;
                end
                suppliedAmplitude=highGAmplitude;
                adjustedAmplitude = suppliedAmplitude - initialOffset;
                if (adjustedAmplitude<0)
                    adjustedAmplitude = 0;
                end
                maxAmplitudePossible = ((255.*rangeSpecificStep) + initialOffset);
                if suppliedAmplitude>maxAmplitudePossible
                    adjustedAmplitude = maxAmplitudePossible;
                end
                amplitudeVal = uint8(adjustedAmplitude/rangeSpecificStep);
                val_CTRL1_XL = readRegister(obj.Device, obj.HighGDetectionAmplitudeRegister);
                writeRegister(obj.Device,obj.HighGDetectionAmplitudeRegister, bitor(bitand(val_CTRL1_XL, uint8(0x00)),uint8(amplitudeVal)));
            end
        end

        function setShockTimeReg(obj,shockTime)
            if obj.IsSingleTap || obj.IsDoubleTap
                val_CTRL1_XL = readRegister(obj.Device, obj.SingleTapConfigurationRegister);
                if strcmp(shockTime,'50 ms')
                    writeRegister(obj.Device,obj.SingleTapConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0xBF)), uint8(0x00)));
                else
                    writeRegister(obj.Device,obj.SingleTapConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0xBF)), uint8(0x40)));
                end
            end
        end

        function setDurationTimeReg(obj,durationTime)
            if obj.IsDoubleTap
                switch durationTime
                    case '50 ms'
                        ByteMask = 0x00;
                    case '100 ms'
                        ByteMask = 0x01;
                    case '150 ms'
                        ByteMask = 0x02;
                    case '200 ms'
                        ByteMask = 0x03;
                    case '250 ms'
                        ByteMask = 0x04;
                    case '375 ms'
                        ByteMask = 0x05;
                    case '500 ms'
                        ByteMask = 0x06;
                    case '700 ms'
                        ByteMask = 0x07;
                end
                val_CTRL1_XL = readRegister(obj.Device, obj.SingleTapConfigurationRegister);
                writeRegister(obj.Device,obj.SingleTapConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0xF8)), ByteMask));
            end
        end

        function setSingleTapAmplitudeReg(obj,tapAmplitude)
            if obj.IsSingleTap || obj.IsDoubleTap
                %                     if strcmp(obj.singleTapQuietTimeThreshold,'0.03125')
                %                         amplitudeVal = 0;
                %                     else
                switch obj.AccelerometerRange
                    case '+/- 2g'
                        initialOffset=0.03125;
                        rangeSpecificStep=0.0625;
                    case '+/- 4g'
                        initialOffset=0.0625;
                        rangeSpecificStep=0.125;
                    case '+/- 8g'
                        initialOffset=0.125;
                        rangeSpecificStep=0.25;
                    case '+/- 16g'
                        initialOffset=0.25;
                        rangeSpecificStep=0.5;
                end
                suppliedAmplitude=tapAmplitude;
                adjustedAmplitude = suppliedAmplitude - initialOffset;
                if (adjustedAmplitude<0)
                    adjustedAmplitude = 0;
                end
                maxAmplitudePossible = ((31.*rangeSpecificStep) + initialOffset);
                if suppliedAmplitude>maxAmplitudePossible
                    adjustedAmplitude = maxAmplitudePossible;
                end
                amplitudeVal = uint8(adjustedAmplitude/rangeSpecificStep);
                %                     end
                val_CTRL1_XL = readRegister(obj.Device, obj.SingleTapAmplitudeConfigurationRegister);
                writeRegister(obj.Device,obj.SingleTapAmplitudeConfigurationRegister, bitor(bitand(val_CTRL1_XL, uint8(0xE0)),uint8(amplitudeVal)));
            end
        end

        function enableDoubleTapInterrupt(obj,value)
            if obj.IsDoubleTap
                if strcmp(value,'INT1')
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0xF0)),uint8(0x0A)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x55);
                    writeRegister(obj.Device,0x55, bitor(bitand(val_CTRL1_XL, uint8(0xEF)),uint8(0x10)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0xEF)),uint8(0x10)));
                else
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0x0F)),uint8(0xA0)));
                    val_CTRL1_XL = readRegister(obj.Device,0x57);
                    writeRegister(obj.Device,0x57, bitor(bitand(val_CTRL1_XL, uint8(0xEF)),uint8(0x10)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0xEF)),uint8(0x10)));
                end
            end
        end

        function enableHighGInterrupt(obj,value)
            if obj.IsHighGDetection
                if strcmp(value,'INT1')
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0xF0)),uint8(0x0A)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x55);
                    writeRegister(obj.Device,0x55, bitor(bitand(val_CTRL1_XL, uint8(0xFD)),uint8(0x02)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x51);
                    writeRegister(obj.Device,0x51, bitor(bitand(val_CTRL1_XL, uint8(0xF8)),uint8(0x07)));
                else
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0x0F)),uint8(0xA0)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x57);
                    writeRegister(obj.Device,0x57, bitor(bitand(val_CTRL1_XL, uint8(0xFD)),uint8(0x02)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x51);
                    writeRegister(obj.Device,0x51, bitor(bitand(val_CTRL1_XL, uint8(0xF8)),uint8(0x07)));
                end
            end
        end

        function enableSlowMotionInterrupt(obj,value)
            if obj.IsSlowMotion
                if strcmp(value,'INT1')
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0xF0)),uint8(0x0A)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x55);
                    writeRegister(obj.Device,0x55, bitor(bitand(val_CTRL1_XL, uint8(0xF7)),uint8(0x08)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x52);
                    writeRegister(obj.Device,0x52, bitor(bitand(val_CTRL1_XL, uint8(0xF8)),uint8(0x07)));
                else
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0x0F)),uint8(0xA0)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x57);
                    writeRegister(obj.Device,0x57, bitor(bitand(val_CTRL1_XL, uint8(0xF7)),uint8(0x08)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x52);
                    writeRegister(obj.Device,0x52, bitor(bitand(val_CTRL1_XL, uint8(0xF8)),uint8(0x07)));
                end
            end
        end

        function enableDataReadyInterrupt(obj,value)
            if obj.IsDataReady
                if strcmp(value,'INT1')
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0xF0)),uint8(0x0A)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x56);
                    writeRegister(obj.Device,0x56, bitor(bitand(val_CTRL1_XL, uint8(0x7F)),uint8(0x80)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x51);
                    writeRegister(obj.Device,0x51, bitor(bitand(val_CTRL1_XL, uint8(0xEF)),uint8(0x10)));
                else
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0x0F)),uint8(0xA0)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x56);
                    writeRegister(obj.Device,0x56, bitor(bitand(val_CTRL1_XL, uint8(0xF7)),uint8(0x08)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x51);
                    writeRegister(obj.Device,0x51, bitor(bitand(val_CTRL1_XL, uint8(0xEF)),uint8(0x10)));
                end
            end
        end

        function enableFlatInterrupt(obj,value)
            if obj.IsFlatDetection
                if strcmp(value,'INT1')
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0xF0)),uint8(0x0A)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x55);
                    writeRegister(obj.Device,0x55, bitor(bitand(val_CTRL1_XL, uint8(0x7F)),uint8(0x80)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0x7F)),uint8(0x80)));
                else
                    val_CTRL1_XL = readRegister(obj.Device, 0x53);
                    writeRegister(obj.Device,0x53, bitor(bitand(val_CTRL1_XL, uint8(0x0F)),uint8(0xA0)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x57);
                    writeRegister(obj.Device,0x57, bitor(bitand(val_CTRL1_XL, uint8(0x7F)),uint8(0x80)));
                    val_CTRL1_XL = readRegister(obj.Device, 0x50);
                    writeRegister(obj.Device,0x50, bitor(bitand(val_CTRL1_XL, uint8(0x7F)),uint8(0x80)));
                end
            end
        end

        function disableInterrupts(obj)
            writeRegister(obj.Device,0x53,0x00);
            writeRegister(obj.Device,0x55,0x00);
            writeRegister(obj.Device,0x56,0x00);
            writeRegister(obj.Device,0x57,0x00);
            writeRegister(obj.Device,0x51,0x00);
            writeRegister(obj.Device,0x52,0x00);
            writeRegister(obj.Device,0x50,0x00);
        end
    end
end