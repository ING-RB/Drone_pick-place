classdef (Sealed) lsm303c_mag < matlabshared.sensors.magnetometer & matlabshared.sensors.sensorUnit &matlabshared.sensors.TemperatureSensor &...
        matlabshared.sensors.I2CSensorProperties
    
    %class for LSM303C Magnetometer Sensor unit consisting of Magnetometer and Temperature.
    
    %Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 1;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = [3;1];
    end
    
    properties(Access = protected, Constant)
        MagnetometerDataRegister = 0x28;
        TemperatureDataRegister= 0x2E;
        StatusRegister=0x27;
        DeviceID=0x3D;
        SetBlockDataUpdate=1;
        TemperatureEnable=1;
        ODRParametersMag=[0.625,1.25,2.5,5,10,20,40,80];
        TemperatureOffset=25;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = 0x1E;
    end
    
    properties(Access = protected,Nontunable)
        MagnetometerRange = '+/- 16 gauss';
        MagnetometerPerformanceZaxis ='MP';
        MagnetometerPerformance ='MP';
        MagnetometerResolution = 0.058;%This Resultion value is in terms of uT
        TemperatureResolution=0.125;%This Resultion value is in terms of °C
        MagnetometerOperationMode='CONT';
        MagnetometerODR;
        TemperatureODR;
    end
    
    properties(Access = private)
        SensitivityAdjustment
    end
    
    properties(Access = private, Hidden, Constant)
        CNTRL_REG1=0x20;
        CNTRL_REG2=0x21;
        CNTRL_REG3=0x22;
        CNTRL_REG4=0x23;
        CNTRL_REG5=0x24;
        INT_CONFG=0x30;
        INT_THS_L=0x32;
        BytesToRead = 6;
        BytesToReadForTemperature =2;
        WHO_AM_I = 0x0F;
    end
    
    methods
        function obj = lsm303c_mag(varargin)
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
                names =     {'Bus','MagnetometerODR'};
                defaults =    {0,40};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'Bus',bus);
                obj.MagnetometerODR =  p.parameterValue('MagnetometerODR');
            end
        end
        
        function set.MagnetometerODR(obj, value)
            switch value
                case 0.625
                    ByteMask_CTRL1_XL = 0x00;
                case 1.25
                    ByteMask_CTRL1_XL = 0x04;
                case 2.5
                    ByteMask_CTRL1_XL = 0x08;
                case 5
                    ByteMask_CTRL1_XL = 0x0C;
                case 10
                    ByteMask_CTRL1_XL = 0x10;
                case 20
                    ByteMask_CTRL1_XL = 0x14;
                case 40
                    ByteMask_CTRL1_XL = 0x18;
                case 80
                    ByteMask_CTRL1_XL = 0x1C;
                otherwise
                    ByteMask_CTRL1_XL = 0x00;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.CNTRL_REG1);
            writeRegister(obj.Device,obj.CNTRL_REG1, bitor(bitand(val_CTRL1_XL, uint8(0xE1)), uint8(ByteMask_CTRL1_XL)));
            obj.MagnetometerODR = value;
        end
        
        function [status,timestamp] = readMagneticFieldStatus(obj)
            %Status can take 2 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
            % last 3 bits represent the status of mag
            status = uint8((~bitget(uint8(temp),3:-1:1)));
        end
    end
    
    methods(Access = protected)
        function initDeviceImpl(obj)
            % check the device ID of lsm303c is as expected.
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if coder.target('MATLAB')
                if(deviceid_value ~= obj.DeviceID)
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','LSM303C magnetometer',num2str(obj.DeviceID));
                end
            end
        end
        
        function initSensorImpl(obj)
            initMagnetometerImpl(obj);
            initTemperatureImpl(obj);
        end
        
        function initMagnetometerImpl(obj)
            resetMagnetometerRegisters(obj);
            setMagPerformance(obj , obj.MagnetometerPerformance);
            setMagOperationMode(obj , obj.MagnetometerOperationMode);
            setMagRange(obj , obj.MagnetometerRange);
            setMagPerformanceZaxis(obj , obj.MagnetometerPerformanceZaxis);
            setBlockDataUpdate(obj,obj.SetBlockDataUpdate);
        end
        
        function initTemperatureImpl(obj)
            setTemperatureEnable(obj,obj.TemperatureEnable);
        end
        
        function [data,status,timestamp] = readMagneticFieldImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.MagnetometerDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertMagnetometerData(obj, data);
        end
        
        function [data,status,timestamp] = readTemperatureImpl(obj)
            numBytes = obj.BytesToReadForTemperature;
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.TemperatureDataRegister, numBytes, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*numBytes))
                    data = reshape(data,[numBytes,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertTemperatureData(obj, data);
        end
        
        function setODRImpl(obj)
            magODR = obj.ODRParametersMag(obj.ODRParametersMag<=obj.SampleRate);
            obj.MagnetometerODR = magODR(end);
        end
        
        function [data,status,timestamp] = readSensorDataImpl(obj)
            [dataMag,status,timestamp] = readMagneticFieldImpl(obj);
            [dataTemp ,~,~] = readTemperatureImpl(obj);
            data=[dataMag,dataTemp];
        end
        
        function data = convertSensorDataImpl(obj, data)
            data=[convertMagnetometerData(obj, data(1:obj.BytesToRead)) convertTemperatureData(obj, data(obj.BytesToRead+1:obj.BytesToRead+obj.BytesToReadForTemperature))];
        end
        
        function s = infoImpl(obj)
            s = struct('MagnetometerODR', obj.MagnetometerODR);
        end
        
        function names = getMeasurementDataNames(obj)
            names = [obj.MagnetometerDataName, obj.TemperatureDataName];
        end
    end
    
    
    methods(Access = private)
        function data = convertMagnetometerData(obj, magSensorData)
            %little endian
            xm = double(bitor(int16(magSensorData(:, 1)), bitshift(int16(magSensorData(:, 2)),8)));
            ym = double(bitor(int16(magSensorData(:, 3)), bitshift(int16(magSensorData(:, 4)),8)));
            zm = double(bitor(int16(magSensorData(:, 5)), bitshift(int16(magSensorData(:, 6)),8)));
            data = [xm, ym, zm]*obj.MagnetometerResolution;
            
        end
        
        function data = convertTemperatureData(obj, tempSensorData)
            %little endian
            t = double(bitor(int16(tempSensorData(:, 1)), bitshift(int16(tempSensorData(:, 2)),8)));
            data = t*obj.TemperatureResolution+obj.TemperatureOffset;
        end
        
        function setMagPerformance(obj,performance)
            switch performance
                case 'LP'
                    ByteMask = 0x00;
                case 'MP'
                    ByteMask = 0x20;
                case 'HP'
                    ByteMask = 0x40;
                case 'UHP'
                    ByteMask = 0x60;
            end
            val = readRegister(obj.Device,obj.CNTRL_REG1);
            writeRegister(obj.Device,obj.CNTRL_REG1, bitor(bitand(val, uint8(0x9D)), uint8(ByteMask)));
        end
        
        function resetMagnetometerRegisters(obj)
            %Enabling Soft Reset of Magnetometer Control registers
            ByteMask = 0x04;
            val = readRegister(obj.Device,obj.CNTRL_REG2);
            writeRegister(obj.Device,obj.CNTRL_REG2, bitor(bitand(val, uint8(0x68)), uint8(ByteMask)));
        end
        
        function setMagOperationMode(obj,mode)
            switch mode
                case 'CONT'
                    ByteMask = 0x00;
                case 'SNGLCONV'
                    ByteMask = 0x01;
                case 'PD'
                    ByteMask = 0x02;
            end
            val = readRegister(obj.Device,obj.CNTRL_REG3);
            writeRegister(obj.Device,obj.CNTRL_REG3, bitor(bitand(val, uint8(0xA4)), uint8(ByteMask)));
        end
        
        function setMagRange(obj,Range)
            switch Range
                case '+/- 16 gauss'
                    ByteMask = 0x60;
            end
            val = readRegister(obj.Device,obj.CNTRL_REG2);
            writeRegister(obj.Device,obj.CNTRL_REG2, bitor(bitand(val, uint8(0x0C)), uint8(ByteMask)));
        end
        
        function setMagPerformanceZaxis(obj,performance)
            switch performance
                case 'LP'
                    ByteMask = 0x00;
                case 'MP'
                    ByteMask = 0x04;
                case 'HP'
                    ByteMask = 0x08;
                case 'UHP'
                    ByteMask = 0x0C;
            end
            val = readRegister(obj.Device,obj.CNTRL_REG4);
            writeRegister(obj.Device,obj.CNTRL_REG4, bitor(bitand(val, uint8(0x02)), uint8(ByteMask)));
        end
        
        function setBlockDataUpdate(obj,blockDataUpdate)
            if blockDataUpdate
                ByteMask = 0x40;
                val = readRegister(obj.Device,obj.CNTRL_REG5);
                writeRegister(obj.Device,obj.CNTRL_REG5, bitor(bitand(val, uint8(0x00)), uint8(ByteMask)));
            end
            
        end
        
        function setTemperatureEnable(obj,temperatureEnable)
            if temperatureEnable
                ByteMask = 0x80;
                val = readRegister(obj.Device,obj.CNTRL_REG1);
                writeRegister(obj.Device,obj.CNTRL_REG1, bitor(bitand(val, uint8(0x7D)), uint8(ByteMask)));
            end
            
        end
    end
end

% LocalWords:  ODR
