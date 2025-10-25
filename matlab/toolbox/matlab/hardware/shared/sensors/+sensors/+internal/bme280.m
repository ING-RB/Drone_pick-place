classdef (Sealed) bme280 < matlabshared.sensors.PressureSensor & matlabshared.sensors.HumiditySensor & matlabshared.sensors.TemperatureSensor & matlabshared.sensors.sensorUnit &...
        matlabshared.sensors.I2CSensorProperties
    %BME280 connects to the BME280 sensor connected to a hardware object
    %
    %   sensorObj = bme280(hwObj) returns a System object that reads sensor
    %   data from the BME280 sensor connected to the I2C bus of an
    %   hardware board. 'hwObj ' is a hardware object.
    %
    %   sensorObj = bme280(hwObj, 'Name', Value, ...) returns a BME280 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   bme280 Properties
    %   I2CAddress      : Specify the I2C Address of the BME280.
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
    %   bme280 methods
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
    %  Note: For targets other than Arduino, bme280 object is supported
    %  with limited functionality. For those targets, you can use the
    %  'readPressure function, and the 'Bus' and 'I2CAddress' properties.
    %
    %   Example: Read one sample of Pressure and Temperature value from BME280 sensor
    %
    %   hwObj = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bme280(hwObj);
    %   pressureData  =  sensorObj.readPressure;
    %   temperatureData = sensorObj.readTemperature;
    %   humidityData = sensorObj.readHumidity;
    %
    %   For Streaming workflow
    %   hwObj = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bme280(hwObj);
    %   read(sensorObj);
    %
    %   See also lps22hb, hts221, read, readPressure, readHumidity
    %   Copyright 2021 The MathWorks, Inc.

    %#codegen
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 1;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [1;1;1];
    end

    properties(Access = protected, Constant)
        HumidityDataRegister = 0xFD;
        PressureDataRegister = 0xF7;
        TemperatureDataRegister = 0xFA;
        DeviceID = 0x60;
        SoftRegister = 0xE0;
        WHO_AM_I = 0xD0;
        HumidityCtrl_REG = 0xF2;
        PressTempCtrl_REG = 0xF4;
        Config_Register = 0xF5;
        PressTempCalibration_Register = 0x88;
        HumidityCalibration_Register = 0xE1;
        StatusRegister = 0xF3;
        ODRParameters = [27.39,40.81,44.44,60.606,80,117.64]
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x76,0x77];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = protected,Nontunable)
        IsActiveHumidity = true;
        IsActivePressure = true;
        IsActiveTemperature = true;
        FilterMode = 0;
        StandbyTime = '0.5 ms';
        PressureOversampling = '1';
        HumidityOversampling = '1';
        TemperatureOverSampling = '1';
        OperationMode = 'Normal';
        DataType = 'single';
        OutputDataRate;
    end

    properties(Hidden, Constant)
        BytesToReadForHumidity = 2;
        BytesToReadForTemperature = 3;
        BytesToReadForPressure = 3;
        BytesToReadForPressureCoefficients = 25;
        BytesToReadForHumidityCoefficients = 8;
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
        dig_H1;
        dig_H2;
        dig_H3;
        dig_H4;
        dig_H5;
        dig_H6;
        t_fine;
    end

    methods
        function obj = bme280(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                        obj.SampleRate = 50;
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                obj.IsActivePressure= true;
                obj.IsActiveTemperature= true;
                obj.IsActiveHumidity= true;
                obj.StandbyTime = '0.5 ms';
                obj.FilterMode = '0';
                obj.PressureOversampling = '1';
                obj.HumidityOversampling = '1';
                obj.TemperatureOverSampling = '1';
                obj.DataType = 'single';
            else
                names =     {'Bus','I2CAddress','StandbyTime','IsActivePressure','IsActiveTemperature','IsActiveHumidity','FilterMode','PressureOversampling','HumidityOversampling','TemperatureOverSampling','DataType'};
                defaults =    {0,obj.I2CAddressList(2),'0.5 ms',true,true,true,'0','1','1','1','single'};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.IsActivePressure= p.parameterValue('IsActivePressure');
                obj.IsActiveTemperature= p.parameterValue('IsActiveTemperature');
                obj.IsActiveHumidity= p.parameterValue('IsActiveHumidity');
                obj.StandbyTime = p.parameterValue('StandbyTime');
                obj.FilterMode = p.parameterValue('FilterMode');
                obj.HumidityOversampling = p.parameterValue('HumidityOversampling');
                obj.TemperatureOverSampling = p.parameterValue('TemperatureOverSampling');
                obj.PressureOversampling = p.parameterValue('PressureOversampling');
                obj.DataType = p.parameterValue('DataType');
            end
        end

        function set.DataType(obj, value)
            obj.DataType = value;
            readTempPressCalibrationValues(obj);
            readHumidityCalibrationValues(obj);
        end

        function readTempPressCalibrationValues(obj)
            if strcmp(obj.DataType,'double')
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
                obj.dig_H1 = double(tempPrssureCalibrationData(25));
                obj.t_fine = double(int16(0));
            else
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
                obj.dig_H1 = single(tempPrssureCalibrationData(25));
                obj.t_fine = single(int16(0));
            end
        end

        function readHumidityCalibrationValues(obj)
            if strcmp(obj.DataType,'double')
                humidityCalibrationData = obj.Device.readRegisterData(obj.HumidityCalibration_Register, obj.BytesToReadForHumidityCoefficients,'uint8');
                obj.dig_H2 = double(bitor(int16(humidityCalibrationData(1)), bitshift(int16(humidityCalibrationData(2)),8)));
                obj.dig_H3 = double(humidityCalibrationData(3));
                obj.dig_H4 = double(bitor(int16(bitand(humidityCalibrationData(5),uint8(0x0F))), bitshift(int16(humidityCalibrationData(4)),4)));
                obj.dig_H5 = double(bitor(int16(bitand(bitshift(humidityCalibrationData(6),-4),uint8(0x0F))), bitshift(int16(humidityCalibrationData(7)),4)));
                obj.dig_H6 = double(int8(humidityCalibrationData(8)));
            else
                humidityCalibrationData = obj.Device.readRegisterData(obj.HumidityCalibration_Register, obj.BytesToReadForHumidityCoefficients,'uint8');
                obj.dig_H2 = single(bitor(int16(humidityCalibrationData(1)), bitshift(int16(humidityCalibrationData(2)),8)));
                obj.dig_H3 = single(humidityCalibrationData(3));
                obj.dig_H4 = single(bitor(int16(bitand(humidityCalibrationData(5),uint8(0x0F))), bitshift(int16(humidityCalibrationData(4)),4)));
                obj.dig_H5 = single(bitor(int16(bitand(bitshift(humidityCalibrationData(6),-4),uint8(0x0F))), bitshift(int16(humidityCalibrationData(7)),4)));
                obj.dig_H6 = single(int8(humidityCalibrationData(8)));
            end
        end

        function set.FilterMode(obj, value)
            switch value
                case '0'
                    ByteMask = 0x00;
                case '2'
                    ByteMask = 0x04;
                case '4'
                    ByteMask = 0x08;
                case '8'
                    ByteMask = 0x0C;
                case '16'
                    ByteMask = 0x10;
                otherwise
                    ByteMask = 0x00;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.Config_Register);
            writeRegister(obj.Device,obj.Config_Register, bitor(bitand(val_CTRL1_XL, uint8(0xE3)), uint8(ByteMask)));
            obj.FilterMode = value;
        end

        function set.StandbyTime(obj, value)
            switch value
                case '0.5 ms'
                    ByteMask = 0x00;
                case '10 ms'
                    ByteMask = 0xC0;
                case '20 ms'
                    ByteMask = 0xE0;
                case '62.5 ms'
                    ByteMask = 0x20;
                case '125 ms'
                    ByteMask = 0x40;
                case '250 ms'
                    ByteMask = 0x60;
                case '500 ms'
                    ByteMask = 0x80;
                case '1000 ms'
                    ByteMask = 0xA0;
                otherwise
                    ByteMask = 0x00;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.Config_Register);
            writeRegister(obj.Device,obj.Config_Register, bitor(bitand(val_CTRL1_XL, uint8(0x1F)), uint8(ByteMask)));
            obj.StandbyTime = value;
        end

        function set.PressureOversampling(obj, value)
            switch value
                case '1'
                    ByteMask = 0x04;
                case '2'
                    ByteMask = 0x08;
                case '4'
                    ByteMask = 0x0C;
                case '8'
                    ByteMask = 0x10;
                case '16'
                    ByteMask = 0x14;
                otherwise
                    ByteMask = 0x04;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.PressTempCtrl_REG);
            writeRegister(obj.Device,obj.PressTempCtrl_REG, bitor(bitand(val_CTRL1_XL, uint8(0xE3)), uint8(ByteMask)));
            obj.PressureOversampling = value;
        end

        function set.TemperatureOverSampling(obj, value)
            switch value
                case '1'
                    ByteMask = 0x20;
                case '2'
                    ByteMask = 0x40;
                case '4'
                    ByteMask = 0x60;
                case '8'
                    ByteMask = 0x80;
                case '16'
                    ByteMask = 0xA0;
                otherwise
                    ByteMask = 0x20;
            end
            val = readRegister(obj.Device, obj.PressTempCtrl_REG);
            writeRegister(obj.Device,obj.PressTempCtrl_REG, bitor(bitand(val, uint8(0x1F)), uint8(ByteMask)));
            obj.TemperatureOverSampling = value;
        end

        function set.HumidityOversampling(obj, value)
            switch value
                case '1'
                    ByteMask = 0x01;
                case '2'
                    ByteMask = 0x02;
                case '4'
                    ByteMask = 0x03;
                case '8'
                    ByteMask = 0x04;
                case '16'
                    ByteMask = 0x05;
                otherwise
                    ByteMask = 0x01;
            end
            val = readRegister(obj.Device, obj.HumidityCtrl_REG);
            writeRegister(obj.Device,obj.HumidityCtrl_REG, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
            obj.HumidityOversampling = value;
        end

        function setOperatingMode(obj)
            %Setting the sensor mode to normal%
            ByteMask = 0x03;
            val = readRegister(obj.Device, obj.PressTempCtrl_REG);
            writeRegister(obj.Device,obj.PressTempCtrl_REG, bitor(bitand(val, uint8(0xFC)), uint8(ByteMask)));
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if(deviceid_value ~= obj.DeviceID)
                %TO DO add codegen warning
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','BME280',num2str(obj.DeviceID));
                end
            end
        end

        function initHumidityImpl(obj)
            setOperatingMode(obj);
        end

        function initSensorImpl(obj)
            initHumidityImpl(obj);
        end

        function [data,status,timestamp]  = readHumidityImpl(obj)
            % we are reading both pressure and temperature because inorder to calculate humidity we require t_fine
            [dataRead,status,timestamp] = obj.Device.readRegisterData(obj.PressureDataRegister, obj.BytesToReadForHumidity+obj.BytesToReadForPressure+obj.BytesToReadForTemperature, "uint8");
            if(isequal(size(dataRead,2),1))
                data = dataRead';
                if(isequal(numel(data),obj.SamplesPerRead*(obj.BytesToReadForTemperature+obj.BytesToReadForPressure+obj.BytesToReadForHumidity)))
                    data = reshape(data,[obj.BytesToReadForTemperature+obj.BytesToReadForPressure+obj.BytesToReadForHumidity,obj.SamplesPerRead])';
                end
            else
                data = dataRead;
            end
            temperatureData = data(obj.BytesToReadForPressure+1:obj.BytesToReadForPressure+obj.BytesToReadForTemperature);
            humidityData = data(obj.BytesToReadForPressure+obj.BytesToReadForTemperature+1:end);
            convertTemperatureData(obj, temperatureData);
            data = convertHumidityData(obj, humidityData);
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
            temperatureData = data(obj.BytesToReadForPressure+1:end);
            pressureData = data(1:obj.BytesToReadForPressure);
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
            [pressureData,~,~]  = readPressureImpl(obj);
            [tempData ,~,~] = readTemperatureImpl(obj);
            [humidityData,status,timestamp]  = readHumidityImpl(obj);
            data=[pressureData,tempData,humidityData];

        end

        function data = convertSensorDataImpl(obj, data)
            data=[convertPressureData(obj, data(1:obj.BytesToReadForPressure)) convertTemperatureData(obj, data(obj.BytesToReadForPressure+1:obj.BytesToReadForPressure+obj.BytesToReadForTemperature)) convertHumidityData(obj,data(obj.BytesToReadForPressure+obj.BytesToReadForTemperature+1:obj.obj.BytesToReadForPressure+obj.BytesToReadForTemperature+obj.BytesToReadForHumidity))];
        end

        function setODRImpl(obj)
            % used only for MATLAB
            if obj.SampleRate<=obj.ODRParameters(end)
                odr = obj.ODRParameters(obj.ODRParameters>=obj.SampleRate);
                pressureOversampling = '8';
                temperatureOversampling = '1';
                humidityOversampling = '1';
                switch odr(end)
                    case 27.39
                        pressureOversampling = '8';
                        temperatureOversampling = '1';
                        humidityOversampling = '8';
                    case 40.81
                        pressureOversampling = '8';
                        temperatureOversampling = '1';
                        humidityOversampling = '2';
                    case 44.44
                        pressureOversampling = '8';
                        temperatureOversampling = '1';
                        humidityOversampling = '1';
                    case 60.606
                        pressureOversampling = '4';
                        temperatureOversampling = '1';
                        humidityOversampling = '2';
                    case 80
                        pressureOversampling = '2';
                        temperatureOversampling = '1';
                        humidityOversampling = '2';
                    case 117.64
                        pressureOversampling = '1';
                        temperatureOversampling = '1';
                        humidityOversampling = '1';
                    otherwise
                        pressureOversampling = '8';
                        temperatureOversampling = '1';
                        humidityOversampling = '1';
                end
                obj.PressureOversampling = pressureOversampling;
                obj.TemperatureOversampling = temperatureOversampling;
                obj.HumidityOversampling = humidityOversampling;
                obj.OutputDataRate = min(odr);
            else
                obj.PressureOversampling = '8';
                obj.TemperatureOversampling = '1';
                obj.HumidityOversampling = '1';
                obj.OutputDataRate = obj.ODRParameters(end);
            end
        end

        function s = infoImpl(obj)
            s = struct('OutputDataRate', obj.OutputDataRate);
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.PressureDataName, obj.TemperatureDataName, obj.HumidityDataName ];
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
            if strcmp(obj.DataType,'double')
                temperature_min = -40;
                temperature_max = 85;
                dataMSB = bitor(bitshift(uint32(tempSensorData(:, 1)),12),bitshift(uint32(tempSensorData(:, 2)),4));
                adc_T = double(bitor(uint32(dataMSB),uint32(bitand(bitshift(tempSensorData(:, 3),-4),uint8(0x0F)))));
            else
                temperature_min = single(-40);
                temperature_max = single(85);
                dataMSB = bitor(bitshift(uint32(tempSensorData(:, 1)),12),bitshift(uint32(tempSensorData(:, 2)),4));
                adc_T = single(bitor(uint32(dataMSB),uint32(bitand(bitshift(tempSensorData(:, 3),-4),uint8(0x0F)))));
            end
            var1= ((adc_T/16384)-(obj.dig_T1)/1024)*(obj.dig_T2);
            var2 = ((adc_T/131072) - (obj.dig_T1/8192)) * ((adc_T/131072)- (obj.dig_T1/8192)) *(obj.dig_T3);
            obj.t_fine = (var1+var2);
            data = obj.t_fine/5120;
            if data < temperature_min
                data = temperature_min;
            elseif data > temperature_max
                data = temperature_max;
            end
        end

        function data = convertHumidityData(obj,humiditySensorData)
            if strcmp(obj.DataType,'double')
                humidity_min = 0;
                humidity_max = 100;
                adc_H = double(bitor(uint32(humiditySensorData(:, 2)),bitshift(uint32(humiditySensorData(:, 1)),8)));
            else
                humidity_min = single(0);
                humidity_max = single(100);
                adc_H = single(bitor(uint32(humiditySensorData(:, 2)),bitshift(uint32(humiditySensorData(:, 1)),8)));
            end
            var1 = (obj.t_fine) - 76800.0;
            var2 = ((obj.dig_H4) * 64.0 + ((obj.dig_H5) / 16384.0) * var1);
            var3 = adc_H - var2;
            var4 = (obj.dig_H2) / 65536.0;
            var5 = (1.0 + ((obj.dig_H3) / 67108864.0) * var1);
            var6 = 1.0 + ((obj.dig_H6) / 67108864.0) * var1 * var5;
            var6 = var3 * var4 * (var5 * var6);
            data = var6 * (1.0 - ((obj.dig_H1) * var6 / 524288.0));
            if (data > humidity_max)
                data = humidity_max;
            elseif (data < humidity_min)
                data = humidity_min;
            end
        end

        function data = convertPressureData(obj,pressureSensorData)
            if strcmp(obj.DataType,'double')
                pressure_min = 30000;
                pressure_max = 110000;
                dataMSB = bitor(bitshift(uint32(pressureSensorData(:, 1)),12),bitshift(uint32(pressureSensorData(:, 2)),4));
                adc_P = double(bitor(uint32(dataMSB),uint32(bitand(bitshift(pressureSensorData(:, 3),-4),uint8(0x0F)))));
            else
                pressure_min = single(30000);
                pressure_max = single(110000);
                dataMSB = bitor(bitshift(uint32(pressureSensorData(:, 1)),12),bitshift(uint32(pressureSensorData(:, 2)),4));
                adc_P = single(bitor(uint32(dataMSB),uint32(bitand(bitshift(pressureSensorData(:, 3),-4),uint8(0x0F)))));
            end
            var1 = (obj.t_fine/2)-64000;
            var2 = var1 * var1 * obj.dig_P6 / 32768.0;
            var2 = var2 + (var1 * obj.dig_P5) * 2.0;
            var2 = (var2 / 4.0) + (obj.dig_P4 * 65536.0);
            var3 = obj.dig_P3 * var1 * var1 / 524288.0;
            var1 = (var3 + (obj.dig_P2) * var1) / 524288.0;
            var1 = (1.0 + var1 / 32768.0) * (obj.dig_P1);
            if (var1 > (0.0))
                data = 1048576.0 - adc_P;
                data = (data - (var2 / 4096.0)) * 6250.0 / var1;
                var1 = (obj.dig_P9) * data * data / 2147483648.0;
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