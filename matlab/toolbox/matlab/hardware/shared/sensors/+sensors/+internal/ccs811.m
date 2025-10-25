classdef (Sealed) ccs811 < matlabshared.sensors.TotalVolatileOrganicCompounds & matlabshared.sensors.EquivalentCarbondioxide & matlabshared.sensors.sensorUnit &...
        matlabshared.sensors.I2CSensorProperties
    %CCS811 connects to the CCS811 sensor connected to a hardware object
    %
    %   sensorObj = ccs811(a) returns a System object that reads sensor
    %   data from the CCS811 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   sensorObj = ccs811(a, 'Name', Value, ...) returns a CCS811 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   ccs811 Properties
    %   I2CAddress      : Specify the I2C Address of the CCS811.
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
    %   ccs811 methods
    %
    %   readEquivalentCarbondioxide      : Read one sample of eCO2 data from
    %                           sensor.
    %   readTotalVolatileOrganicCompounds   : Read one sample of eTVOC data from
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
    %
    %   Example: Read one sample of eCO2 value from CCS811 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = ccs811(a);
    %   eCO2Data  =  sensorObj.readEquivalentCarbondioxide;
    %
    %   For Streaming workflow
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = ccs811(a);
    %   read(sensorObj)

    %  Copyright 2021-2022 The MathWorks, Inc.

    %#codegen

    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 0.017;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [1;1];
    end

    properties(Access = protected, Constant)
        MeasureRegister = 0x01;
        EquivalentCarbondioxideDataRegister = 0x02;
        TVOCDataRegister = 0x02;
        WHO_AM_I = 0x20;
        DeviceID = 0x81;
        SoftwareResetRegister = 0xFF;
        APPStartRegister = 0xF4;
        StatusRegister = 0x00;
        EnvironmentRegister = 0x05;
        ODRParameters = [0.0166,0.1,1,4];
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x5A,0x5B];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = protected,Nontunable)
        DriveMode;
        IsActiveInterrupt = false;
        EnvironmentInput = 'Mask dialog';
        HumidityData = 50;
        TemperatureData = 25;
        DataType = 'double';
    end

    properties(Hidden, Constant)
        BytesToRead = 4;
    end

    properties(Access = private)
        Odr;
    end

    methods
        function obj = ccs811(varargin)
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
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                obj.DriveMode = '1';
                obj.EnvironmentInput = 'Mask dialog';
                obj.HumidityData = 50;
                obj.TemperatureData = 25;
                obj.IsActiveInterrupt = false;
                obj.DataType = 'double';
            else
                names =     {'Bus','I2CAddress',...
                    'DriveMode','IsActiveInterrupt','EnvironmentInput','HumidityData','TemperatureData','DataType'};
                defaults =    {0,obj.I2CAddressList(1),...
                    '1',true,'Mask dialog',50,25,'double'};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.DriveMode = p.parameterValue('DriveMode');
                obj.EnvironmentInput = p.parameterValue('EnvironmentInput');
                obj.HumidityData = p.parameterValue('HumidityData');
                obj.TemperatureData = p.parameterValue('TemperatureData');
                obj.IsActiveInterrupt = p.parameterValue('IsActiveInterrupt');
                obj.DataType = p.parameterValue('DataType');
            end
            if strcmp(obj.EnvironmentInput,'Mask dialog')
                writeEnvironmentValues(obj,obj.HumidityData, obj.TemperatureData);
            else
            end
        end

        function set.DriveMode(obj, value)
            switch value
                case '0.25'
                    ByteMask = 0x40;
                case '1'
                    ByteMask = 0x10;
                case '10'
                    ByteMask = 0x20;
                case '60'
                    ByteMask = 0x30;
                otherwise
                    ByteMask = 0x10;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.MeasureRegister);
            writeRegister(obj.Device,obj.MeasureRegister, bitor(bitand(val_CTRL1_XL, uint8(0x8F)), uint8(ByteMask)));
            obj.DriveMode = value;
            setODRValue(obj);
        end

        function set.IsActiveInterrupt(obj, value)
            obj.IsActiveInterrupt = value;
            enableInterrupts(obj);
        end

        function set.EnvironmentInput(obj, value)
            obj.EnvironmentInput = value;
        end

        function set.HumidityData(obj, value)
            validateattributes(value,{'numeric'},{'nonempty','nonnan','scalar'});
            obj.HumidityData = value;
        end

        function set.TemperatureData(obj, value)
            validateattributes(value,{'numeric'},{'nonempty','nonnan','scalar'});
            obj.TemperatureData = value;
        end

    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            softwareReset(obj);
            if  coder.target('rtw')
                obj.Parent.delayFunctionForHardware(100);
            elseif coder.target('MATLAB')
                pause(0.1);
            end
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if(deviceid_value ~= obj.DeviceID)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','CCS811',num2str(obj.DeviceID));
                end
            end
        end

        function enableInterrupts(obj)
            if obj.IsActiveInterrupt
                ByteMask = 0x08;
                val_CTRL1_XL = readRegister(obj.Device, obj.MeasureRegister);
                writeRegister(obj.Device,obj.MeasureRegister, bitor(bitand(val_CTRL1_XL, uint8(0x74)), uint8(ByteMask)));
            end
        end

        function writeEnvironmentValues(obj,hum,temp)
            humidity = double(hum);
            temperature = double(temp);
            %Environmental register has 4 bytes the byte 1 and 2 are
            %related to humidity and 3 and 4 are related to temperature.
            %byte 1 of humidity is the msb, for that we are multiplying the
            %supplied humidity value by 512.
            hum_conv = uint16(humidity * 512 + 0.5);
            %byte 1 of temperature is the msb and it has an offset(adding 25), for that we are multiplying the
            %supplied humidity value by 512.
            temp_conv = uint16((temperature + 25) * 512 + 0.5);
            ByteMask = uint8([bitand(bitshift(hum_conv, -8), 0x00FF), bitand(hum_conv , 0x00FF), bitand(bitshift(temp_conv , -8), 0x00FF), bitand(temp_conv,0x00FF)]);
            writeRegister(obj.Device,obj.EnvironmentRegister, ByteMask);
        end
        function setODRValue(obj)
            % Drive mode represents Data aquisition interval from block
            % mask and ODR = 1/DriveMode
            switch obj.DriveMode
                case '0.25'
                    obj.Odr = 4;
                case '1'
                    obj.Odr = 1;
                case '10'
                    obj.Odr = 0.1;
                case '60'
                    obj.Odr = 0.0166;
                otherwise
                    obj.Odr = 1;
            end
        end
        function initEquivalentCarbondioxideImpl(obj)
            changeFromBootToAppMode(obj);
            if coder.target('Rtw')
                obj.Parent.delayFunctionForHardware(100);
            elseif coder.target('MATLAB')
                pause(0.1);
            end
        end

        function initTotalVolatileOrganicCompoundsImpl(obj)
        end

        function initSensorImpl(obj)
            initEquivalentCarbondioxideImpl(obj);
            initTotalVolatileOrganicCompoundsImpl(obj);
        end

        function [data,status,timestamp]  = readEquivalentCarbondioxideImpl(obj,varargin)
            if nargin > 1
                humidity = varargin{1};
                temperature = varargin{2};
                writeEnvironmentValues(obj,humidity,temperature);
            end
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.EquivalentCarbondioxideDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertECO2Data(obj, data);
        end

        function [data,status,timestamp]  = readTotalVolatileOrganicCompoundsImpl(obj,varargin)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.EquivalentCarbondioxideDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertTVOCData(obj, data);
        end

        function [data,status,timestamp]  = readSensorDataImpl(obj)
            [eco2Data,status,timestamp] = readEquivalentCarbondioxideImpl(obj);
            [tvocData ,~,~] = readTotalVolatileOrganicCompoundsImpl(obj);
            data=[eco2Data,tvocData];
        end

        function data = convertSensorDataImpl(obj, data)
            data=[convertECO2Data(obj, data) convertTVOCData(obj, data)];
        end

        function setODRImpl(obj)
            gasODR = obj.ODRParameters(obj.ODRParameters<=obj.SampleRate);
            obj.Odr = gasODR(end);
        end

        function s = infoImpl(obj)
            s = struct('DriveMode',obj.DriveMode);
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.EquivalentCarbondioxideDataName,obj.TotalVolatileOrganicCompoundsDataName];
        end
    end

    methods(Hidden = true)
        function [status,timestamp] = readStatus(obj)
            %Status can take 2 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
            statusValues = bitget(uint8(temp),4);
            if(isequal(statusValues,1))
                status=uint8(0);
            else
                status=uint8(1);
            end
        end
    end

    methods(Access = private)

        function softwareReset(obj)
            ByteMask = uint8([0x11, 0xE5, 0x72, 0x8A]);
            writeRegister(obj.Device,obj.SoftwareResetRegister, ByteMask);
        end

        function changeFromBootToAppMode(obj)
            write(obj.Device, obj.APPStartRegister);
        end

        function data = convertECO2Data(obj,SensorData)
            if strcmp(obj.DataType,'double')
                data = double(bitor(int16(SensorData(:, 2)), bitshift(int16(SensorData(:, 1)),8)));
            else
                data = single(bitor(int16(SensorData(:, 2)), bitshift(int16(SensorData(:, 1)),8)));
            end
        end

        function data = convertTVOCData(obj,SensorData)
            if strcmp(obj.DataType,'double')
                data = double(bitor(int16(SensorData(:, 4)), bitshift(int16(SensorData(:, 3)),8))) ;
            else
                data = single(bitor(int16(SensorData(:, 4)), bitshift(int16(SensorData(:, 3)),8)));
            end
        end
    end
end