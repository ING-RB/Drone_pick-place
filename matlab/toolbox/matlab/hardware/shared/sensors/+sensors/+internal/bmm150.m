classdef (Sealed) bmm150 < matlabshared.sensors.magnetometer & matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    %BMM150 connects to the BMM150 sensor connected to a hardware object
    %
    %   sensorObj = bmm150(a) returns a System object that reads sensor
    %   data from the BMM150 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   sensorObj = bmm150(a, 'Name', Value, ...) returns a BMM150 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   bmm150 Properties
    %   I2CAddress      : Specify the I2C Address of the BMM150.
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
    %   bmm150 methods
    %
    %   readMagneticField     : Read one sample of Magnetic Field data from
    %                           sensor.
    %   read                  : Read one frame of Magnetic Field value from
    %                           the sensor along with time stamps and
    %                           overruns.
    %   stop/release          : Stop sending data from hardware and
    %                           allow changes to non-tunable properties
    %                           values and input characteristics.
    %   flush                 : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %   info                  : Read sensor information such as output
    %                           data rate.
    %
    %
    %   Example: Read one sample of Magnetic Field value from BMM150 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bmm150(a);
    %   magneticFieldData  =  sensorObj.readMagneticField;
    %
    %   For Streaming workflow
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = bmm150(a);
    %   read(sensorObj)

    %   Copyright 2021 The MathWorks, Inc.

    %#codegen

    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 10;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [3;1];
    end

    properties(Access = protected, Constant)
        MagnetometerDataRegister = 0x42;
        DeviceID = 0x32;
        PowerMode_REG = 0x4B;
        OperationMode_REG = 0x4C;
        XYRep_REG = 0x51;
        ZRep_REG = 0x52;
        WHO_AM_I = 0x40;
        ODRParametersMag = [10,20];
        StatusRegister = 0x48;

    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x10,0x11,0x12,0x13];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = protected,Nontunable)
        MagnetometerResolution = 0.3;%Interms of micro tesla
        MagnetometerODR = 10;
        IsStatus = true;
        MagnetometerPresetValue = 'Regular';
        DataType = 'single'
    end

    properties(Hidden, Constant)
        BytesToRead = 6;
    end

    methods
        function obj = bmm150(varargin)
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
                obj.IsStatus = false;
                obj.MagnetometerPresetValue = 'Low power';
                obj.DataType = 'single';
            else
                names =  {'Bus','I2CAddress'...
                    'IsStatus','MagnetometerPresetValue','DataType'};
                defaults =    {0,obj.I2CAddressList(2),...
                    false,'Low power','single'};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.IsStatus= p.parameterValue('IsStatus');
                obj.MagnetometerPresetValue = p.parameterValue('MagnetometerPresetValue');
                obj.DataType = p.parameterValue('DataType');
            end
        end

        function setMagnetometerODR(obj, value)
            switch value
                case 10
                    ByteMask_CTRL1_XL = 0x00;
                case 20
                    ByteMask_CTRL1_XL = 0x05;
                otherwise
                    ByteMask_CTRL1_XL = 0x00;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.OperationMode_REG);
            writeRegister(obj.Device,obj.OperationMode_REG, bitor(bitand(val_CTRL1_XL, uint8(0xC7)), uint8(ByteMask_CTRL1_XL)));
            if obj.isSimulink
                obj.MagnetometerODR = value;
            end
        end

        function set.MagnetometerPresetValue(obj, value)
            switch value
                case 'Low power'
                    setMagnetometerODR(obj,obj.ODRParametersMag(1));
                    ByteMask_XY = 1;
                    ByteMask_Z = 2;
                case 'Regular'
                    setMagnetometerODR(obj,obj.ODRParametersMag(1));
                    ByteMask_XY = 4;
                    ByteMask_Z = 14;
                case 'Enhanced'
                    setMagnetometerODR(obj,obj.ODRParametersMag(1));
                    ByteMask_XY = 7;
                    ByteMask_Z = 26;
                case 'High accuracy'
                    setMagnetometerODR(obj,obj.ODRParametersMag(2));
                    ByteMask_XY = 23;
                    ByteMask_Z = 82;
            end
            val_xy = readRegister(obj.Device, obj.XYRep_REG);
            writeRegister(obj.Device,obj.XYRep_REG, bitor(bitand(val_xy, uint8(0x00)), uint8(ByteMask_XY)));
            val_z = readRegister(obj.Device, obj.ZRep_REG);
            writeRegister(obj.Device,obj.ZRep_REG, bitor(bitand(val_z, uint8(0x00)), uint8(ByteMask_Z)));
            obj.MagnetometerPresetValue = value;
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            suspendToSleepMode(obj);
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if(deviceid_value ~= obj.DeviceID)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID',num2str(obj.DeviceID));
                end
            end
        end

        function initMagnetometerImpl(obj)
            enableNormalMode(obj);
        end

        function initSensorImpl(obj)
            initMagnetometerImpl(obj);
        end

        function [data,status,timestamp]  = readMagneticFieldImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.MagnetometerDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertMagData(obj, data);
        end

        function [data,status,timestamp]  = readSensorDataImpl(obj)
            [magData,status,timestamp]  = readMagneticFieldImpl(obj);
            data=[magData];
        end

        function data = convertSensorDataImpl(obj, data)
            data=convertMagnetometerData(obj, data(1:obj.BytesToRead));
        end

        function setODRImpl(obj)
            % used only for MATLAB
            magODR = obj.ODRParametersMag(obj.ODRParametersMag<=obj.SampleRate);
            obj.MagnetometerODR = magODR(end);
        end

        function s = infoImpl(obj)
            s = struct('MagnetometerODR', obj.MagnetometerODR);
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.MagnetometerDataName];
        end
    end

    methods(Hidden = true)
        function [status,timestamp] = readStatus(obj)
            %Status can take 2 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
            statusValues = bitget(uint8(temp),1);
            if(isequal(statusValues,1))
                status=int8(0);
            else
                status=int8(1);
            end
        end
    end

    methods(Access = private)
        function suspendToSleepMode(obj)
            val_xy = readRegister(obj.Device, obj.PowerMode_REG);
            writeRegister(obj.Device,obj.PowerMode_REG, bitor(bitand(val_xy, uint8(0x86)), uint8(0x01)));
            val_z = readRegister(obj.Device, obj.OperationMode_REG);
            writeRegister(obj.Device,obj.OperationMode_REG, bitor(bitand(val_z, uint8(0xF9)), uint8(0X06)));
            obj.Parent.delayFunctionForHardware(1);
        end

        function enableNormalMode(obj)
            val_xy = readRegister(obj.Device, obj.PowerMode_REG);
            writeRegister(obj.Device,obj.PowerMode_REG, bitor(bitand(val_xy, uint8(0x86)), uint8(0x01)));
            val_z = readRegister(obj.Device, obj.OperationMode_REG);
            writeRegister(obj.Device,obj.OperationMode_REG, bitor(bitand(val_z, uint8(0xF9)), uint8(0X00)));
            obj.Parent.delayFunctionForHardware(1);
        end

        function data = convertMagData(obj,gyroSensorData)
            %little endian
            if strcmp(obj.DataType,'double')
                xa = double(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(gyroSensorData(:, 1), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 2)),5)),13 ));
                ya = double(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(gyroSensorData(:, 3), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 4)),5)),13)) ;
                za = double(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(gyroSensorData(:, 5), uint8(0xFE)),-1)), bitshift(int16(gyroSensorData(:, 6)),7)),15)) ;
                data = obj.MagnetometerResolution.*[xa, ya, za];
            else
                xa = single(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(gyroSensorData(:, 1), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 2)),5)),13 ));
                ya = single(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(gyroSensorData(:, 3), uint8(0xF8)),-3)), bitshift(int16(gyroSensorData(:, 4)),5)),13)) ;
                za = single(obj.conversionOfTwosComplementTodecimal(bitor(int16(bitshift(bitand(gyroSensorData(:, 5), uint8(0xFE)),-1)), bitshift(int16(gyroSensorData(:, 6)),7)),15)) ;
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

    end
end