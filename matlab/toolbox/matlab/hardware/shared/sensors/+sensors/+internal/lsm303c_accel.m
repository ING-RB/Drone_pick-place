classdef (Sealed) lsm303c_accel < matlabshared.sensors.accelerometer & matlabshared.sensors.sensorUnit &...
        matlabshared.sensors.I2CSensorProperties
    
    %class for LSM303C Accelerometer Sensor unit consisting of Accelerometer.
    
    %Copyright 2020 The MathWorks, Inc.
    
    
    %#codegen
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 11;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = 3;
    end
    
    properties(Access = protected, Constant)
        AccelerometerDataRegister = 0x28;
        StatusRegister = 0x27;
        DeviceID = 0x41;
        ODRParametersAccel = [10,50,100,200,400,800];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = 0x1D;
    end
    
    properties(Access = protected,Nontunable)
        AccelerometerRange
        AccelerometerResolution;
        AccelerometerODR;
    end
    
    properties(Hidden, Constant)
        CNTRL_REG1=0x20;
        CNTRL_REG4=0x23;
        CNTRL_REG5=0x24;
        WHO_AM_I = 0x0F;
        BytesToRead = 6;
    end
    
    methods
        function obj = lsm303c_accel(varargin)
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
                obj.AccelerometerRange = '+/- 2g';
                obj.AccelerometerResolution = getAccelerometerResolution(obj);
            else
                names =     {'Bus','AccelerometerRange', 'AccelerometerODR'};
                defaults =    {0,'+/- 2g', 100};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'Bus',bus);
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.AccelerometerODR =  p.parameterValue('AccelerometerODR');
                obj.AccelerometerResolution = getAccelerometerResolution(obj);
                
            end
        end
        
        function set.AccelerometerODR(obj, value)
            switch value
                case 10
                    ByteMask_CTRL1_XL = 0x10;
                case 50
                    ByteMask_CTRL1_XL = 0x20;
                case 100
                    ByteMask_CTRL1_XL = 0x30;
                case 200
                    ByteMask_CTRL1_XL = 0x40;
                case 400
                    ByteMask_CTRL1_XL = 0x50;
                case 800
                    ByteMask_CTRL1_XL = 0x60;
                otherwise
                    ByteMask_CTRL1_XL = 0x10;
            end
            val_CTRL1_XL = readRegister(obj.Device, obj.CNTRL_REG1);
            writeRegister(obj.Device,obj.CNTRL_REG1, bitor(bitand(val_CTRL1_XL, uint8(0x0F)), uint8(ByteMask_CTRL1_XL)));
            obj.AccelerometerODR = value;
        end
        
        function [status,timestamp] = readAccelerationStatus(obj)
            %Status can take 2 values namely 0,1
            %0 represents  new data is available
            %1 represents  new data is not yet available
            [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
            % last 3 bits represent the status of accel
            status = uint8(~(bitget(uint8(temp),3:-1:1)));
        end
        
        function set.AccelerometerRange(obj, value)
            setAccelRange(obj,value);
            obj.AccelerometerRange=value;
        end
    end
    
    methods(Access = protected)
        
        function initDeviceImpl(obj)
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if coder.target('MATLAB')
                if(deviceid_value ~= obj.DeviceID)
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','LSM303C accelerometer',num2str(obj.DeviceID));
                end
            end
        end
        
        function initAccelerometerImpl(obj)
            resetAccelerometerRegisters(obj);
            setAccelerometerConfigRegister1(obj);
        end
        
        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
        end
        
        function [data,status,timestamp]  = readAccelerationImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.AccelerometerDataRegister, obj.BytesToRead, "uint8");
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
        
        function [data,status,timestamp]  = readSensorDataImpl(obj)
            [data,status,timestamp]  = readAccelerationImpl(obj);
            
        end
        
        function data = convertSensorDataImpl(obj, data)
            data = convertAccelData(obj, data(1:obj.BytesToRead));
        end
        
        function setODRImpl(obj)
            % used only for MATLAB
            accelODR = obj.ODRParametersAccel(obj.ODRParametersAccel<=obj.SampleRate);
            obj.AccelerometerODR = accelODR(end);
        end
        
        function s = infoImpl(obj)
            s = struct('AccelerometerODR',obj.AccelerometerODR);
        end
        
        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName];
        end
    end
    
    methods(Access = private)
        
        function g = getAccelerometerResolution(obj)
            switch  obj.AccelerometerRange
                case sprintf('+/- 2g')
                    g = 1/16384;
                case sprintf('+/- 4g')
                    g = 1/8192;
                case sprintf('+/- 8g')
                    g = 1/4096;
            end
        end
        
        function data = convertAccelData(obj,accelSensorData)
            %little endian
            xa = double(bitor(int16(accelSensorData(:, 1)), bitshift(int16(accelSensorData(:, 2)),8))) ;
            ya = double(bitor(int16(accelSensorData(:, 3)), bitshift(int16(accelSensorData(:, 4)),8))) ;
            za = double(bitor(int16(accelSensorData(:, 5)), bitshift(int16(accelSensorData(:, 6)),8))) ;
            data = obj.AccelerometerResolution.*[xa, ya, za];
            % Convert the data from g-scale to m/s^2 scale
            data = data*9.81;
        end
        
        function setAccelRange(obj,Range)
            switch Range
                case '+/- 2g'
                    ByteMask = 0x00;
                case '+/- 4g'
                    ByteMask = 0x20;
                case '+/- 8g'
                    ByteMask = 0x30;
            end
            val = readRegister(obj.Device,obj.CNTRL_REG4);
            writeRegister(obj.Device,obj.CNTRL_REG4,bitor(uint8(val),ByteMask));
        end
        
        function resetAccelerometerRegisters(obj)
            %Enabling Soft Reset of Accelerometer Control registers
            ByteMask = 0x40;
            val = readRegister(obj.Device,obj.CNTRL_REG5);
            writeRegister(obj.Device,obj.CNTRL_REG5,bitor(uint8(val),ByteMask));
        end
        
        function setAccelerometerConfigRegister1(obj)
            ByteMask = 0x0E;
            val = readRegister(obj.Device,obj.CNTRL_REG1);
            writeRegister(obj.Device,obj.CNTRL_REG1,bitor(uint8(val),ByteMask));
        end
        
    end
end