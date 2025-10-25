classdef (Sealed) bmp280 < matlabshared.sensors.PressureSensor & matlabshared.sensors.TemperatureSensor & matlabshared.sensors.sensorUnit &...
         matlabshared.sensors.I2CSensorProperties
    %BMP280 connects to the BMP280 sensor connected to a hardware object
    %
    %   sensorObj = bmp280(hwObj) returns a System object that reads sensor
    %   data from the BMP280 sensor connected to the I2C bus of an
    %   hardware board. 'hwObj' is a hardware object.
    %
    %   sensorObj = bmp280(hwObj, 'Name', Value, ...) returns a BMP280 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   bmp280 Properties
    %   I2CAddress      : Specify the I2C Address of the BMP280.
    %   Bus             : Specify the I2C Bus where sensor is connected.
    %   ReadMode        : Specify whether to return the latest available
    %                     sensor values or the values accumulated from the
    %                     beginning when the 'read' API is executed.
    %                     ReadMode can be either 'latest' or 'oldest'.
    %                     Default value is 'latest'.
    %   SampleRate      : Rate at which samples are read from hardware.
    %                     Default value is 50 (samples/s).
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
    %   bmp280 methods
    %
    %   readPressure          : Read one sample of pressure data from
    %                           sensor.
    %   readTemperature       : Read one sample of temperature data from
    %                           sensor.
    %   read                  : Read one frame of pressure and temperature values from
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
    %  Note: For targets other than Arduino, bmp280 object is supported
    %  with limited functionality. For those targets, you can use the
    %  'readPressure function, and the 'Bus' and 'I2CAddress' properties.
    %
    %   Example: Read one sample of Pressure and Temperature value from BMP280 sensor
    %
    %   hwObj = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bmp280(hwObj);
    %   pressureData  =  sensorObj.readPressure;
    %   temperatureData = sensorObj.readTemperature;
    %
    %   Example 2: Read pressure and temperature values from BMP280 sensor
    %
    %   hwObj = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bmp280(hwObj);
    %   read(sensorObj);
    %
    %   See also lps22hb, hts221, read, readPressure, readTemperature

    %   Copyright 2021 The MathWorks, Inc.

    %#codegen
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 1;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [1;1];
    end

    properties(Access = protected, Constant)
        PressureDataRegister = 0xF7;
        TemperatureDataRegister = 0xFA;
        DeviceID = 0x58;
        SoftRegister = 0xE0;
        WHO_AM_I = 0xD0;
        PressTempCtrl_REG = 0xF4;
        Config_Register = 0xF5;
        PressTempCalibration_Register = 0x88;
        StatusRegister = 0xF3;
        ODRParameters = [26.32,50.00,83.33,125.00,166.67]
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x76,0x77];
    end

    properties(Access = protected,Nontunable)
        IsActivePressure = true;
        IsActiveTemperature = true;
        FilterMode = 0;
        PressureSensitivityFactor = 2.62;
        TemperatureSensitivityFactor = 0.005;
        OperationMode = 'Normal';
        DataType = 'double';
        OutputDataRate;
    end

    properties(Hidden, Constant)
        BytesToReadForTemperature = 3;
        BytesToReadForPressure = 3;
        BytesToReadForPressureCoefficients = 25;
    end

    properties(Access = protected)
        dig_T1;
        dig_T2;
        dig_T3;
        dig_P1;
        dig_P2;
        dig_P3;
        dig_P4;
        dig_P5;
        dig_P6;
        dig_P7;
        dig_P8;
        dig_P9;
        t_fine;
    end

    methods
        function obj = bmp280(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                obj.DefaultSampleRate=100;
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                obj.IsActivePressure= true;
                obj.IsActiveTemperature= true;
                obj.FilterMode = 0;
                setStandbyTime(obj);
                obj.PressureSensitivityFactor = 2.62;
                obj.TemperatureSensitivityFactor = 0.005;
                obj.DataType = 'double';
            else
                names =     {'Bus','I2CAddress','IsActivePressure','IsActiveTemperature','FilterMode','PressureSensitivityFactor','TemperatureSensitivityFactor','DataType'};
                defaults =    {0,obj.I2CAddressList(2),true,true,0,2.62,0.005,'double'};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.IsActivePressure= p.parameterValue('IsActivePressure');
                obj.IsActiveTemperature= p.parameterValue('IsActiveTemperature');
                obj.FilterMode = p.parameterValue('FilterMode');
                setStandbyTime(obj);
                obj.TemperatureSensitivityFactor = p.parameterValue('TemperatureSensitivityFactor');
                obj.PressureSensitivityFactor = p.parameterValue('PressureSensitivityFactor');
                obj.DataType = p.parameterValue('DataType');
            end
            readTempPressCalibrationValues(obj);
        end

        function set.DataType(obj, value)
            obj.DataType = value;
        end

        function set.FilterMode(obj, value)
            switch value
                case 0
                    ByteMask = 0x00;
                case 2
                    ByteMask = 0x04;
                case 4
                    ByteMask = 0x08;
                case 8
                    ByteMask = 0x0C;
                case 16
                    ByteMask = 0x10;
                otherwise
                    ByteMask = 0x00;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.Config_Register);
            writeRegister(obj.Device,obj.Config_Register, bitor(bitand(val_CTRL1_XL, uint8(0xE3)), uint8(ByteMask)));
            obj.FilterMode = value;
        end

        function set.PressureSensitivityFactor(obj, value)
            switch value
                case 2.62
                    ByteMask = 0x04;
                case 1.31
                    ByteMask = 0x08;
                case 0.66
                    ByteMask = 0x0C;
                case 0.33
                    ByteMask = 0x10;
                case 0.16
                    ByteMask = 0x14;
                otherwise
                    ByteMask = 0x04;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.PressTempCtrl_REG);
            writeRegister(obj.Device,obj.PressTempCtrl_REG, bitor(bitand(val_CTRL1_XL, uint8(0xE3)), uint8(ByteMask)));
            if obj.isSimulink
                obj.PressureSensitivityFactor = value;
            end

        end

        function set.TemperatureSensitivityFactor(obj, value)
            switch value
                case 0.005
                    ByteMask = 0x20;
                case 0.0025
                    ByteMask = 0x40;
                otherwise
                    ByteMask = 0x20;
            end
            val = readRegister(obj.Device, obj.PressTempCtrl_REG);
            writeRegister(obj.Device,obj.PressTempCtrl_REG, bitor(bitand(val, uint8(0x1F)), uint8(ByteMask)));
            if obj.isSimulink
                obj.TemperatureSensitivityFactor = value;
            end
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if(deviceid_value ~= obj.DeviceID)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','BMP280',num2str(obj.DeviceID));
                end
            end
        end

        function initSensorImpl(obj)
            setOperatingMode(obj);
        end

        function [data,status,timestamp]  = readPressureImpl(obj)
            % we are reading both pressure and temperature because inorder to calculate pressure we require t_fine
            [dataRead,status,timestamp] = obj.Device.readRegisterData(obj.PressureDataRegister, obj.BytesToReadForPressure+obj.BytesToReadForTemperature, "uint8");
            if(isequal(size(dataRead,2),1))
                data = dataRead';
                if(isequal(numel(data),obj.SamplesPerRead*(obj.BytesToReadForTemperature+obj.BytesToReadForPressure)))
                    data = reshape(data,[obj.BytesToReadForTemperature+obj.BytesToReadForPressure,obj.SamplesPerRead])';
                end
            else
                data = dataRead;
            end
            temperatureData = data(:,obj.BytesToReadForPressure+1:end);
            pressureData = data(:,1:obj.BytesToReadForPressure);
            convertTemperatureData(obj, temperatureData);
            data = convertPressureData(obj, pressureData);
        end

        function [data,status,timestamp]  = readTemperatureImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.TemperatureDataRegister, obj.BytesToReadForTemperature, "uint8");
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

        function [data,status,timestamp]  = readSensorDataImpl(obj)
            [pressureData,status,timestamp]  = readPressureImpl(obj);
            [tempData ,~,~] = readTemperatureImpl(obj);
            data=[pressureData,tempData];
        end

        function data = convertSensorDataImpl(obj, data)
            data=[convertPressureData(obj, data(1:obj.BytesToReadForPressure)) convertTemperatureData(obj, data(obj.BytesToReadForPressure+1:obj.BytesToReadForPressure+obj.BytesToReadForTemperature))];
        end

        function setODRImpl(obj)
            if obj.SampleRate<=obj.ODRParameters(end)
                odr = obj.ODRParameters(obj.ODRParameters>=obj.SampleRate);
                pressureSensitivity = 2.62;
                temperatureSensitivity = 0.005;
                switch min(odr)
                    case 26.32
                        pressureSensitivity = 2.62;
                        temperatureSensitivity = 0.005;
                    case 50.00
                        pressureSensitivity = 1.31;
                        temperatureSensitivity = 0.005;
                    case 83.33
                        pressureSensitivity = 0.66;
                        temperatureSensitivity = 0.005;
                    case 125.00
                        pressureSensitivity = 0.33;
                        temperatureSensitivity = 0.005;
                    case 166.67
                        pressureSensitivity = 0.16;
                        temperatureSensitivity = 0.005;
                    otherwise
                        pressureSensitivity = 2.62;
                        temperatureSensitivity = 0.0025;
                end
                obj.PressureSensitivityFactor = pressureSensitivity;
                obj.TemperatureSensitivityFactor = temperatureSensitivity;
                obj.OutputDataRate = min(odr);
            else
                obj.PressureSensitivityFactor = 0.16;
                obj.TemperatureSensitivityFactor = 0.005;
                obj.OutputDataRate = obj.ODRParameters(end);
            end
        end

        function s = infoImpl(obj)
            s = struct('OutputDataRate', obj.OutputDataRate);
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.PressureDataName, obj.TemperatureDataName];
        end
    end

    methods(Hidden = true)
        function [status,timestamp] = readStatus(obj)
            % Status can take 2 values namely 0,1
            % 0 represents new data is available
            % 1 represents new data is not yet available
            timestamp = [];
            status=uint8(0);
            if obj.IsActivePressure
                [temp, ~, timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
                status = bitget(uint8(temp),4);
            end
        end
    end

    methods(Access = private)
        function data = convertTemperatureData(obj, tempSensorData)
            switch obj.DataType
                case 'double'
                    temperature_min = -40;
                    temperature_max = 85;
                    dataMSB = bitor(bitshift(uint32(tempSensorData(:, 1)),12),bitshift(uint32(tempSensorData(:, 2)),4));
                    adc_T = double(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(tempSensorData(:, 3)),-4),uint8(0x0F)))));
                case 'single'
                    temperature_min = single(-40);
                    temperature_max = single(85);
                    dataMSB = bitor(bitshift(uint32(tempSensorData(:, 1)),12),bitshift(uint32(tempSensorData(:, 2)),4));
                    adc_T = single(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(tempSensorData(:, 3)),-4),uint8(0x0F)))));
                case 'uint32'
                    temperature_min = int32(-4000);
                    temperature_max = int32(8500);
                    dataMSB = bitor(bitshift(uint32(tempSensorData(:, 1)),12),bitshift(uint32(tempSensorData(:, 2)),4));
                    adc_T = int32(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(tempSensorData(:, 3)),-4),uint8(0x0F)))));
                otherwise
                    temperature_min = -40;
                    temperature_max = 85;
                    dataMSB = bitor(bitshift(uint32(tempSensorData(:, 1)),12),bitshift(uint32(tempSensorData(:, 2)),4));
                    adc_T = double(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(tempSensorData(:, 3)),-4),uint8(0x0F)))));
            end
            switch obj.DataType
                case 'uint32'
                    var1= bitshift((((bitshift(adc_T,-3)-int32(bitshift(obj.dig_T1,1))))*(int32(obj.dig_T2))),-11);
                    var2= bitshift((bitshift((((bitshift(adc_T,-4))-(int32(obj.dig_T1))).*((bitshift(adc_T,-4))-(int32(obj.dig_T1)))),-12)*(int32(obj.dig_T3))),-14);
                    obj.t_fine = (var1+var2);
                    data = bitshift((obj.t_fine*5+128),-8);
                    if data<0
                        if data < temperature_min
                            data = temperature_min;
                        end
                        maxRangeOfUint64 = 4294967295;
                        data = uint32(int64(maxRangeOfUint64)+int64(data)+int64(1));
                        return;
                    else
                        if data > temperature_max
                            data = uint32(temperature_max);
                            return
                        end
                        data = uint32(data);
                        return;
                    end
                otherwise
                    var1= ((adc_T/16384)-(obj.dig_T1)/1024)*(obj.dig_T2);
                    var2 = ((adc_T/131072) - (obj.dig_T1/8192)) .* ((adc_T/131072)- (obj.dig_T1/8192)) *(obj.dig_T3);
                    obj.t_fine = (var1+var2);
                    data = obj.t_fine/5120;
            end
            if data < temperature_min
                data = temperature_min;
            elseif data > temperature_max
                data = temperature_max;
            end
        end

        function setStandbyTime(obj)
            %Standby time is set to 0.5 msec
            ByteMask = 0x00;
            val_CTRL1_XL = readRegister(obj.Device, obj.Config_Register);
            writeRegister(obj.Device,obj.Config_Register, bitor(bitand(val_CTRL1_XL, uint8(0x1F)), uint8(ByteMask)));
        end

        function setOperatingMode(obj)
            %Setting the sensor mode to normal%
            ByteMask = 0x03;
            val = readRegister(obj.Device, obj.PressTempCtrl_REG);
            writeRegister(obj.Device,obj.PressTempCtrl_REG, bitor(bitand(val, uint8(0xFC)), uint8(ByteMask)));
        end

        function readTempPressCalibrationValues(obj)
            switch obj.DataType
                case 'double'
                    tempPrssureCalibrationData = obj.Device.readRegisterData(obj.PressTempCalibration_Register, obj.BytesToReadForPressureCoefficients,'uint8');
                    obj.dig_T1 = double(bitor(uint16(tempPrssureCalibrationData(1)), bitshift(uint16(tempPrssureCalibrationData(2)),8)));
                    obj.dig_T2 = double(bitor(int16(tempPrssureCalibrationData(3)), bitshift(int16(tempPrssureCalibrationData(4)),8)));
                    obj.dig_T3 = double(bitor(int16(tempPrssureCalibrationData(5)), bitshift(int16(tempPrssureCalibrationData(6)),8)));
                    obj.dig_P1 = double(bitor(uint16(tempPrssureCalibrationData(7)), bitshift(uint16(tempPrssureCalibrationData(8)),8)));
                    obj.dig_P2 = double(bitor(int16(tempPrssureCalibrationData(9)), bitshift(int16(tempPrssureCalibrationData(10)),8)));
                    obj.dig_P3 = double(bitor(int16(tempPrssureCalibrationData(11)), bitshift(int16(tempPrssureCalibrationData(12)),8)));
                    obj.dig_P4 = double(bitor(int16(tempPrssureCalibrationData(13)), bitshift(int16(tempPrssureCalibrationData(14)),8)));
                    obj.dig_P5 = double(bitor(int16(tempPrssureCalibrationData(15)), bitshift(int16(tempPrssureCalibrationData(16)),8)));
                    obj.dig_P6 = double(bitor(int16(tempPrssureCalibrationData(17)), bitshift(int16(tempPrssureCalibrationData(18)),8)));
                    obj.dig_P7 = double(bitor(int16(tempPrssureCalibrationData(19)), bitshift(int16(tempPrssureCalibrationData(20)),8)));
                    obj.dig_P8 = double(bitor(int16(tempPrssureCalibrationData(21)), bitshift(int16(tempPrssureCalibrationData(22)),8)));
                    obj.dig_P9 = double(bitor(int16(tempPrssureCalibrationData(23)), bitshift(int16(tempPrssureCalibrationData(24)),8)));
                    obj.t_fine = double(int16(0));
                case 'single'
                    tempPrssureCalibrationData = obj.Device.readRegisterData(obj.PressTempCalibration_Register, obj.BytesToReadForPressureCoefficients,'uint8');
                    obj.dig_T1 = single(bitor(uint16(tempPrssureCalibrationData(1)), bitshift(uint16(tempPrssureCalibrationData(2)),8)));
                    obj.dig_T2 = single(bitor(int16(tempPrssureCalibrationData(3)), bitshift(int16(tempPrssureCalibrationData(4)),8)));
                    obj.dig_T3 = single(bitor(int16(tempPrssureCalibrationData(5)), bitshift(int16(tempPrssureCalibrationData(6)),8)));
                    obj.dig_P1 = single(bitor(uint16(tempPrssureCalibrationData(7)), bitshift(uint16(tempPrssureCalibrationData(8)),8)));
                    obj.dig_P2 = single(bitor(int16(tempPrssureCalibrationData(9)), bitshift(int16(tempPrssureCalibrationData(10)),8)));
                    obj.dig_P3 = single(bitor(int16(tempPrssureCalibrationData(11)), bitshift(int16(tempPrssureCalibrationData(12)),8)));
                    obj.dig_P4 = single(bitor(int16(tempPrssureCalibrationData(13)), bitshift(int16(tempPrssureCalibrationData(14)),8)));
                    obj.dig_P5 = single(bitor(int16(tempPrssureCalibrationData(15)), bitshift(int16(tempPrssureCalibrationData(16)),8)));
                    obj.dig_P6 = single(bitor(int16(tempPrssureCalibrationData(17)), bitshift(int16(tempPrssureCalibrationData(18)),8)));
                    obj.dig_P7 = single(bitor(int16(tempPrssureCalibrationData(19)), bitshift(int16(tempPrssureCalibrationData(20)),8)));
                    obj.dig_P8 = single(bitor(int16(tempPrssureCalibrationData(21)), bitshift(int16(tempPrssureCalibrationData(22)),8)));
                    obj.dig_P9 = single(bitor(int16(tempPrssureCalibrationData(23)), bitshift(int16(tempPrssureCalibrationData(24)),8)));
                    obj.t_fine = single(int16(0));
                case 'uint32'
                    tempPrssureCalibrationData = obj.Device.readRegisterData(obj.PressTempCalibration_Register, obj.BytesToReadForPressureCoefficients,'uint8');
                    obj.dig_T1 = uint32(bitor(uint16(tempPrssureCalibrationData(1)), bitshift(uint16(tempPrssureCalibrationData(2)),8)));
                    obj.dig_T2 = uint32(bitor(int16(tempPrssureCalibrationData(3)), bitshift(int16(tempPrssureCalibrationData(4)),8)));
                    obj.dig_T3 = uint32(bitor(int16(tempPrssureCalibrationData(5)), bitshift(int16(tempPrssureCalibrationData(6)),8)));
                    obj.dig_P1 = uint32(bitor(uint16(tempPrssureCalibrationData(7)), bitshift(uint16(tempPrssureCalibrationData(8)),8)));
                    obj.dig_P2 = uint32(bitor(int16(tempPrssureCalibrationData(9)), bitshift(int16(tempPrssureCalibrationData(10)),8)));
                    obj.dig_P3 = uint32(bitor(int16(tempPrssureCalibrationData(11)), bitshift(int16(tempPrssureCalibrationData(12)),8)));
                    obj.dig_P4 = uint32(bitor(int16(tempPrssureCalibrationData(13)), bitshift(int16(tempPrssureCalibrationData(14)),8)));
                    obj.dig_P5 = uint32(bitor(int16(tempPrssureCalibrationData(15)), bitshift(int16(tempPrssureCalibrationData(16)),8)));
                    obj.dig_P6 = uint32(bitor(int16(tempPrssureCalibrationData(17)), bitshift(int16(tempPrssureCalibrationData(18)),8)));
                    obj.dig_P7 = uint32(bitor(int16(tempPrssureCalibrationData(19)), bitshift(int16(tempPrssureCalibrationData(20)),8)));
                    obj.dig_P8 = uint32(bitor(int16(tempPrssureCalibrationData(21)), bitshift(int16(tempPrssureCalibrationData(22)),8)));
                    obj.dig_P9 = uint32(bitor(int16(tempPrssureCalibrationData(23)), bitshift(int16(tempPrssureCalibrationData(24)),8)));
                    obj.t_fine = int32(0);
                otherwise
                    tempPrssureCalibrationData = obj.Device.readRegisterData(obj.PressTempCalibration_Register, obj.BytesToReadForPressureCoefficients,'uint8');
                    obj.dig_T1 = single(bitor(uint16(tempPrssureCalibrationData(1)), bitshift(uint16(tempPrssureCalibrationData(2)),8)));
                    obj.dig_T2 = single(bitor(int16(tempPrssureCalibrationData(3)), bitshift(int16(tempPrssureCalibrationData(4)),8)));
                    obj.dig_T3 = single(bitor(int16(tempPrssureCalibrationData(5)), bitshift(int16(tempPrssureCalibrationData(6)),8)));
                    obj.dig_P1 = single(bitor(uint16(tempPrssureCalibrationData(7)), bitshift(uint16(tempPrssureCalibrationData(8)),8)));
                    obj.dig_P2 = single(bitor(int16(tempPrssureCalibrationData(9)), bitshift(int16(tempPrssureCalibrationData(10)),8)));
                    obj.dig_P3 = single(bitor(int16(tempPrssureCalibrationData(11)), bitshift(int16(tempPrssureCalibrationData(12)),8)));
                    obj.dig_P4 = single(bitor(int16(tempPrssureCalibrationData(13)), bitshift(int16(tempPrssureCalibrationData(14)),8)));
                    obj.dig_P5 = single(bitor(int16(tempPrssureCalibrationData(15)), bitshift(int16(tempPrssureCalibrationData(16)),8)));
                    obj.dig_P6 = single(bitor(int16(tempPrssureCalibrationData(17)), bitshift(int16(tempPrssureCalibrationData(18)),8)));
                    obj.dig_P7 = single(bitor(int16(tempPrssureCalibrationData(19)), bitshift(int16(tempPrssureCalibrationData(20)),8)));
                    obj.dig_P8 = single(bitor(int16(tempPrssureCalibrationData(21)), bitshift(int16(tempPrssureCalibrationData(22)),8)));
                    obj.dig_P9 = single(bitor(int16(tempPrssureCalibrationData(23)), bitshift(int16(tempPrssureCalibrationData(24)),8)));
                    obj.t_fine = single(int16(0));
            end
        end

        function data = convertPressureData(obj,pressureSensorData)
            switch obj.DataType
                case 'double'
                    pressure_min = 30000;
                    pressure_max = 110000;
                    dataMSB = bitor(bitshift(uint32(pressureSensorData(:, 1)),12),bitshift(uint32(pressureSensorData(:, 2)),4));
                    adc_P = double(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(pressureSensorData(:, 3)),-4),uint8(0x0F)))));
                    var1 = double((obj.t_fine/2)-64000);
                case 'single'
                    pressure_min = single(30000);
                    pressure_max = single(110000);
                    dataMSB = bitor(bitshift(uint32(pressureSensorData(:, 1)),12),bitshift(uint32(pressureSensorData(:, 2)),4));
                    adc_P = single(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(pressureSensorData(:, 3)),-4),uint8(0x0F)))));
                    var1 = single((obj.t_fine/2)-64000);
                case 'uint32'
                    pressure_min = uint32(30000);
                    pressure_max = uint32(110000);
                    dataMSB = bitor(bitshift(uint32(pressureSensorData(:, 1)),12),bitshift(uint32(pressureSensorData(:, 2)),4));
                    adc_P = uint32(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(pressureSensorData(:, 3)),-4),uint8(0x0F)))));
                    var1 = uint32((obj.t_fine/2)-64000);
                otherwise
                    pressure_min = single(30000);
                    pressure_max = single(110000);
                    dataMSB = bitor(bitshift(uint32(pressureSensorData(:, 1)),12),bitshift(uint32(pressureSensorData(:, 2)),4));
                    adc_P = single(bitor(uint32(dataMSB),uint32(bitand(bitshift(uint8(pressureSensorData(:, 3)),-4),uint8(0x0F)))));
                    var1 = single((obj.t_fine/2)-64000);
            end
            var2 = var1 .* var1 * obj.dig_P6 / 32768.0;
            var2 = var2 + (var1 * obj.dig_P5) * 2.0;
            var2 = (var2 / 4.0) + (obj.dig_P4 * 65536.0);
            var3 = obj.dig_P3 * var1 .* var1 / 524288.0;
            var1 = (var3 + (obj.dig_P2) * var1) / 524288.0;
            var1 = (1.0 + var1 / 32768.0) * (obj.dig_P1);
            if (var1 > (0.0))
                data = 1048576.0 - adc_P;
                data = (data - (var2 / 4096.0)) * 6250.0 ./ var1;
                var1 = (obj.dig_P9) * data.* data / 2147483648.0;
                var2 = data * (obj.dig_P8) / 32768.0;
                data = data + (var1 + var2 + (obj.dig_P7)) / 16.0;
                if data < pressure_min
                    data = pressure_min;
                elseif data > pressure_max
                    data = pressure_max;
                end
            else
                data = pressure_min;
            end
            return;
        end
    end
end