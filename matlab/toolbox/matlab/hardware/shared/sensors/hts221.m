classdef (Sealed) hts221 < matlabshared.sensors.HumiditySensor & matlabshared.sensors.sensorUnit & matlabshared.sensors.TemperatureSensor &...
        matlabshared.sensors.I2CSensorProperties
    %HTS221 connects to the HTS221 sensor connected to a hardware object
    %
    %   sensorObj = hts221(a) returns a System object that reads sensor
    %   data from the HTS221 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   sensorObj = hts221(a, 'Name', Value, ...) returns a HTS221 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   hts221 Properties
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
    %   hts221 methods
    %
    %   readHumidity          : Read one sample of humidity data from
    %                           sensor.
    %   readTemperature       : Read one sample of temperature value from sensor.
    %   read                  : Read one frame of humiidty and temperature values from
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
    %   Note: For targets other than Arduino, hts221 object is supported 
    %   with limited functionality. For those targets, you can use the
    %  'readHumidity', and 'readTemperature' functions, and the 'Bus'
    %   and 'I2CAddress' properties.
    %
    %   Example: Read one sample of Humidity value from HTS221 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = hts221(a);
    %   humidityData  =  sensorObj.readHumidity;
    %
    %   See also lsm6dsl, lsm6ds3, hts221, lsm9ds1, read, readTemperature,
    %   readHumidity

    %   Copyright 2020-2021 The MathWorks, Inc.
    
    %#codegen
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 1;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = [1;1];
    end
    
    properties(Access = protected, Constant)
        HumidityDataRegister = 0x28;
        TemperatureDataRegister= 0x2A;
        StatusRegister = 0x27;
        DeviceID = 0xBC;
        ODRParametersHumidity = [1,7,12.5];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = 0x5F;
    end
    
    properties(Access = protected,Nontunable)
        HumidityResolution=1/256;
        TemperatureResolution=1/64;
        OutputDataRate;
        IsActiveHumidity=true;
        IsActiveTemperature=true;
    end
    
    properties(Hidden, Constant)
        CNTRL_REG1=0x20;
        CNTRL_REG2=0x21;
        CNTRL_REG3=0x22;
        CALIB_0_REG=0x30;
        WHO_AM_I = 0x0F;
        BytesToRead = 2;
        BytesToReadForTemperature = 2;
        BytesToReadForCalibration = 16;
    end
    
    properties (Access = protected)
        T0_degC
        T1_degC
        T0_out
        T1_out
        H0_rh
        H1_rh
        H0_T0_out
        H1_T0_out
    end
    
    methods
        function obj = hts221(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                if ~coder.target('MATLAB')
                    names = {'Bus','OutputFormat','TimeFormat','SamplesPerRead', 'SampleRate','ReadMode'};
                    defaults = {[],'timetable','datetime',10, 12.5,'latest'};
                    p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                    p.parse(varargin{2:end});
                    obj.init(varargin{:});
                else
                    try
                        names = {'Bus','OutputFormat','TimeFormat','SamplesPerRead', 'SampleRate','ReadMode'};
                        defaults = {[],'timetable','datetime',10, 12.5,'latest'};
                        p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                        p.parse(varargin{2:end});
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
            else
                names =     {'Bus',...
                    'IsActiveHumidity','IsActiveTemperature','OutputDataRate'};
                defaults =    {0,...
                    true,true,1};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'Bus',bus);
                obj.IsActiveHumidity=p.parameterValue('IsActiveHumidity');
                obj.IsActiveTemperature=p.parameterValue('IsActiveTemperature');
                if obj.IsActiveHumidity || obj.IsActiveTemperature
                    obj.OutputDataRate =  p.parameterValue('OutputDataRate');
                end
            end
        end
        
        function set.OutputDataRate(obj, value)
            ByteMaskForCNTRLREG1=0xFC;
            switch value
                case 1
                    ByteMask_CTRL1_XL = 0x01;
                case 7
                    ByteMask_CTRL1_XL = 0x02;
                case 12.5
                    ByteMask_CTRL1_XL = 0x03;
                otherwise
                    ByteMask_CTRL1_XL = 0x01;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.CNTRL_REG1);
            writeRegister(obj.Device,obj.CNTRL_REG1, bitor(bitand(val_CTRL1_XL, uint8(ByteMaskForCNTRLREG1)), uint8(ByteMask_CTRL1_XL)));
            obj.OutputDataRate = value;
        end
        
    end
    
    methods(Access = protected)
        
        function initDeviceImpl(obj)
            if coder.target('MATLAB')
                deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
                if(deviceid_value ~= obj.DeviceID)
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','HTS221',num2str(obj.DeviceID));
                end
            end
        end
        
        function initHumidityImpl(obj)
            resetRegisters(obj);
            setHumidityConfigRegister1(obj);
            % Inorder to get the T0_degC, T1_degC, T0_out, T1_out, H0_rh, H1_rh, H0_T0_out and H1_T0_out coefficients we have to read 16 Bytes from Address 0x30
            data = uint8(readRegister(obj.Device, bitor(obj.CALIB_0_REG, 0x80), 16));
            % Divide by eight is done following the datasheet for T0_degC and T1_degC
            obj.T0_degC = double(typecast([data(3) bitand(data(6),3)],'int16'))/8;
            obj.T1_degC = double(typecast([data(4) bitshift(bitand(data(6),hex2dec('C')),-2)],'int16'))/8;
            obj.T0_out  = double(typecast(data(13:14),'int16'));
            obj.T1_out  = double(typecast(data(15:16),'int16'));
            % Divide by two is done following the datasheet for H0_rh and H1_rh
            obj.H0_rh = double(data(1))/2;
            obj.H1_rh = double(data(2))/2;
            obj.H0_T0_out = double(typecast(data(7:8),'int16'));
            obj.H1_T0_out = double(typecast(data(11:12),'int16'));
        end
        
        function initSensorImpl(obj)
            initHumidityImpl(obj);
        end
        
        function [data,status,timestamp]  = readHumidityImpl(obj)
            %The OR operation is required because for write operation the 8th bit has to be 1
            ByteMaskForHmdtyDataReg=0x80;
            [tempData,status,timestamp] = obj.Device.readRegisterData(bitor(obj.HumidityDataRegister,ByteMaskForHmdtyDataReg), obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            
            data = convertHumidityData(obj, data);
        end
        
        function [data,status,timestamp]  = readTemperatureImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(bitor(obj.TemperatureDataRegister,0x80), obj.BytesToReadForTemperature, "uint8");
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
            [humidityData,status,timestamp]  = readHumidityImpl(obj);
            [dataTemp ,~,~] = readTemperatureImpl(obj);
            data=[humidityData,dataTemp];
        end
        
        function data = convertSensorDataImpl(obj, data)
            data=[convertHumidityData(obj, data(1:obj.BytesToRead)) convertTemperatureData(obj, data(obj.BytesToRead+1:obj.BytesToRead+obj.BytesToReadForTemperature))];
        end
        
        function setODRImpl(obj)
            % used only for MATLAB
            outputDataRate = obj.ODRParametersHumidity(obj.ODRParametersHumidity<=obj.SampleRate);
            obj.OutputDataRate = outputDataRate(end);
        end
        
        function s = infoImpl(obj)
            s = struct('OutputDataRate',obj.OutputDataRate);
        end
        
        function names = getMeasurementDataNames(obj)
            names = [obj.HumidityDataName, obj.TemperatureDataName];
        end
    end
    
    methods(Hidden = true)
        
        function [status,timestamp] = readStatus(obj)
            %Status can take 3 values namely -1,0,1
            %-1 represents the sensor is not used
            %0 represents  new data is available
            %1 represents  new data is not yet available
            timestamp = [];
            status=[-1,-1];
            if obj.IsActiveHumidity
                [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
                statusValues = bitget(uint8(temp),2);
                if(isequal(statusValues,1))
                    status(1)=0;
                else
                    status(1)=1;
                end
            end
            if obj.IsActiveTemperature
                [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
                statusValues = bitget(uint8(temp),1);
                if(isequal(statusValues,1))
                    status(2)=0;
                else
                    status(2)=1;
                end
            end
        end
    end
    
    methods(Access = private)
        
        function data = convertHumidityData(obj,humiditySensorData)
            %little endian
            Hout = double(bitor(int16(humiditySensorData(:, 1)), bitshift(int16(humiditySensorData(:, 2)),8))) ;
            data = (Hout - obj.H0_T0_out) / (obj.H1_T0_out - obj.H0_T0_out) * (obj.H1_rh - obj.H0_rh) + obj.H0_rh;
            if isnan(data)
                data = double(0);
            end
        end
        
        function data = convertTemperatureData(obj, tempSensorData)
            %little endian
            Tout = double(bitor(int16(tempSensorData(:, 1)), bitshift(int16(tempSensorData(:, 2)),8)));
            data = (Tout - obj.T0_out)/(obj.T1_out - obj.T0_out) * (obj.T1_degC - obj.T0_degC) + obj.T0_degC;
            if isnan(data)
                data = double(0);
            end
        end
        
        function resetRegisters(obj)
            %Enabling Soft Reset of registers
            ByteMask = 0x80;
            val = readRegister(obj.Device,obj.CNTRL_REG2);
            writeRegister(obj.Device,obj.CNTRL_REG2,bitor(bitand(val, uint8(0x7F)),ByteMask));
        end
        
        function setHumidityConfigRegister1(obj)
            ByteMask = 0x84;
            val = readRegister(obj.Device,obj.CNTRL_REG1);
            writeRegister(obj.Device,obj.CNTRL_REG1,bitor(bitand(val, uint8(0x7B)),ByteMask));
        end
    end
end