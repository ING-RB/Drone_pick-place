classdef (Sealed) lps22hb < matlabshared.sensors.PressureSensor & matlabshared.sensors.sensorUnit & matlabshared.sensors.TemperatureSensor &...
        matlabshared.sensors.I2CSensorProperties
    %LPS22HB connects to the LPS22HB sensor connected to a hardware object
    %
    %   sensorObj = lps22hb(a) returns a System object that reads sensor
    %   data from the LPS22HB sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   sensorObj = lps22hb(a, 'Name', Value, ...) returns a LPS22HB System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   lps22hb Properties
    %   I2CAddress      : Specify the I2C Address of the LPS22HB.
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
    %   lps22hb methods
    %
    %   readPressure          : Read one sample of pressure data from
    %                           sensor.
    %   readTemperature       : Read one sample of temperature value from sensor.
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
    %  Note: For targets other than Arduino, lps22hb object is supported 
    %  with limited functionality. For those targets, you can use the
    %  'readPressure', and 'readTemperature' functions, and the 'Bus'
    %   and 'I2CAddress' properties.
    %
    %   Example: Read one sample of Pressure value from LPS22HB sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = lps22hb(a);
    %   pressureData  =  sensorObj.readPressure;
    %
    %   See also lsm6dsl, lsm6ds3, hts221, lsm9ds1, read, readTemperature,
    %   readPressure
  
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
        PressureDataRegister = 0x28;
        TemperatureDataRegister= 0x2B;
        StatusRegister = 0x27;
        DeviceID = 0xB1;
        ODRParametersPressure = [1,10,25,50,75];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x5C,0x5D];
    end
    
    properties(Access = protected,Nontunable)
        PressureResolution=1/40.96;%for converting hpa to pa
        TemperatureResolution=0.01;
        OutputDataRate;
        IsActivePressure=true;
        IsActiveLowPassFilter=false;
        IsActiveTemperature=true;
        BandWidth;
    end
    
    properties(Hidden, Constant)
        CNTRL_REG1=0x10;
        CNTRL_REG2=0x11;
        CNTRL_REG5=0x24;
        WHO_AM_I = 0x0F;
        BytesToRead = 3;
        BytesToReadForTemperature = 2;
    end
    
    methods
        function obj = lps22hb(varargin)
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
            else
                names =     {'I2CAddress','Bus',...
                    'IsActivePressure','IsActiveTemperature','OutputDataRate','IsActiveLowPassFilter','BandWidth'};
                defaults =    {obj.I2CAddressList(1),0,...
                    true,true,1,0,'ODR/9'};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.OutputDataRate =  p.parameterValue('OutputDataRate');
                obj.IsActivePressure=p.parameterValue('IsActivePressure');
                obj.IsActiveTemperature=p.parameterValue('IsActiveTemperature');
                obj.IsActiveLowPassFilter=p.parameterValue('IsActiveLowPassFilter');
                obj.BandWidth=p.parameterValue('BandWidth');
            end
        end
        
        function set.BandWidth(obj, value)
            setBandWidth(obj, value);
            obj.BandWidth = value;
        end
        
        function set.OutputDataRate(obj, value)
            switch value
                case 1
                    ByteMask_CTRL1_XL = 0x10;
                case 10
                    ByteMask_CTRL1_XL = 0x20;
                case 25
                    ByteMask_CTRL1_XL = 0x30;
                case 50
                    ByteMask_CTRL1_XL = 0x40;
                case 75
                    ByteMask_CTRL1_XL = 0x50;
                otherwise
                    ByteMask_CTRL1_XL = 0x10;
            end
            ByteMaskForCTRL_REG1=0x0F;
            val_CTRL1_XL = readRegister(obj.Device, obj.CNTRL_REG1);
            %For setting ODR0, ODR1, ODR2 which are at 4th, 5th and 6th Positions
            %we have to and val_CTRL1_XL with 0x0F
            writeRegister(obj.Device,obj.CNTRL_REG1, bitor(bitand(val_CTRL1_XL, uint8(ByteMaskForCTRL_REG1)), uint8(ByteMask_CTRL1_XL)));
            obj.OutputDataRate = value;
        end
    end
    
    methods(Access = protected)
        function initDeviceImpl(obj)
            if coder.target('MATLAB')
                deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
                if(deviceid_value ~= obj.DeviceID)
                    %TO DO add codegen warning
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','LPS22HB',num2str(obj.DeviceID));
                end
            end
        end
        
        function initPressureImpl(obj)
            resetRegisters(obj);
            setBlockDataUpdate(obj);
        end
        
        function initSensorImpl(obj)
            initPressureImpl(obj);
        end
        
        function [data,status,timestamp]  = readPressureImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.PressureDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertPressureData(obj, data);
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
            [dataTemp ,~,~] = readTemperatureImpl(obj);
            data=[pressureData,dataTemp];
        end
        
        function data = convertSensorDataImpl(obj, data)
            data=[convertPressureData(obj, data(1:obj.BytesToRead)) convertTemperatureData(obj, data(obj.BytesToRead+1:obj.BytesToRead+obj.BytesToReadForTemperature))];
        end
        
        function setODRImpl(obj)
            % used only for MATLAB
            pressureTemperatureODR = obj.ODRParametersPressure(obj.ODRParametersPressure<=obj.SampleRate);
            obj.OutputDataRate = pressureTemperatureODR(end);
        end
        
        function s = infoImpl(obj)
            s = struct('OutputDataRate',obj.OutputDataRate);
        end
        
        function names = getMeasurementDataNames(obj)
            names = [obj.PressureDataName, obj.TemperatureDataName];
        end
    end
    
    methods(Hidden = true)
        function [status,timestamp] = readStatus(obj)
            %Status can take 3 values namely -1,0,1
            %-1 represents the sensor is not used
            %0 represents  new data is available
            %1 represents  new data is not yet available
            status=[-1,-1];
            timestamp = [];
            if obj.IsActivePressure
                [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
                statusValues = bitget(uint8(temp),1);
                if(isequal(statusValues,1))
                    status(1)=0;
                else
                    status(1)=1;
                end
            end
            if obj.IsActiveTemperature
                [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
                statusValues = bitget(uint8(temp),2);
                if(isequal(statusValues,1))
                    status(2)=0;
                else
                    status(2)=1;
                end
            end
        end
    end
    
    methods(Access = private)
        function data = convertPressureData(obj,pressureSensorData)
            %little endian
            firstTwoBytes= bitor(int32(pressureSensorData(:, 1)), bitshift(int32(pressureSensorData(:, 2)),8));
            data=double(bitor(firstTwoBytes,bitshift(int32(pressureSensorData(:, 3)),16)));
            data = obj.PressureResolution*data;
        end
        
        function data = convertTemperatureData(obj, tempSensorData)
            %little endian
            data = double(bitor(int16(tempSensorData(:, 1)), bitshift(int16(tempSensorData(:, 2)),8)));
            data = data*obj.TemperatureResolution;
        end
        
        function resetRegisters(obj)
            %Enabling Soft Reset of registers
            ByteMask = 0x04;
            val = readRegister(obj.Device,obj.CNTRL_REG2);
            writeRegister(obj.Device,obj.CNTRL_REG2,bitor(uint8(val),ByteMask));
        end
        
        function setBlockDataUpdate(obj)
            ByteMask = 0x02;
            val = readRegister(obj.Device,obj.CNTRL_REG1);
            writeRegister(obj.Device,obj.CNTRL_REG1,bitor(uint8(val),ByteMask));
        end
        
        function setBandWidth(obj,value)
            if obj.IsActivePressure
                if obj.IsActiveLowPassFilter
                    switch value
                        case 'ODR/9'
                            ByteMask_CTRL1_XL = 0x08;
                        case 'ODR/20'
                            ByteMask_CTRL1_XL = 0x0C;
                        otherwise
                            ByteMask_CTRL1_XL = 0x08;
                    end
                    ByteMaskForCTRL_REG1=0x73;
                    val_CTRL1_XL = readRegister(obj.Device, obj.CNTRL_REG1);
                    %For setting  EN_LPFP, LPFP_CFG which are at 2nd and 3rd
                    %positions we have to and val_CTRL1_XL with 0x73
                    writeRegister(obj.Device,obj.CNTRL_REG1, bitor(bitand(val_CTRL1_XL, ByteMaskForCTRL_REG1), uint8(ByteMask_CTRL1_XL)));
                end
            end
        end
    end
end