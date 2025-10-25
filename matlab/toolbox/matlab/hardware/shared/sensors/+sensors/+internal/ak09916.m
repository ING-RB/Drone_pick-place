classdef (Sealed) ak09916 < matlabshared.sensors.magnetometer & matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    %AK09916 connects to the AK09916 sensor connected to the I2C bus of the hardware board.
    %
    %   IMU = ak09916(hardwareObj) returns a AK09916 System object with 
    %   default property values. The argument 'hardwareObj' represents the 
    %   connection to the hardware board. The ak09916 object can be used to 
    %   read sensor data from the AK09916 sensor connected to the I2C bus   
    %   of the hardware board. 
    %
    %   IMU = ak09916(hardwareObj, 'Name', Value, ...) returns a AK09916 
    %   System object with each specified property name set to the specified 
    %   value. You can specify additional name-value pair arguments in any 
    %   order as (Name1, Value1, ...,NameN, ValueN).
    %
    %   ak09916 Properties:
    %
    %   I2CAddress      : Specify the I2C Address of the AK09916 sensor.
    %   Bus             : Specify the I2C Bus where sensor is connected.
    %   ReadMode        : Specify whether to return the latest available
    %                     sensor values or the values accumulated from the
    %                     beginning when the 'read' API is executed.
    %                     ReadMode can be either 'latest' or 'oldest'.
    %                     Default value is 'latest'.
    %   SampleRate      : Rate at which samples are read from hardware.
    %                     Default value is 100 (samples/s).
    %   SamplesPerRead  : Number of samples returned per execution of read
    %                     function. Default value is 10
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
    %   ak09916 methods:
    %
    %   readMagneticField     : Returns one sample of magnetic field data on  
    %                           x, y, and z axes read from the sensor along
    %                           with the timestamp.                        
    %   read                  : Returns one frame of magnetic field values
    %                           read from the sensor at the specified
    %                           rate along with timestamps and overruns.
    %                           The number of samples depends on the
    %                           'SamplesPerRead' value specified while
    %                           creating the sensor object.
    %  stop/release           : Stops sending data from the hardware and 
    %                           allow changes to non-tunable properties 
    %                           values.
    %  flush                  : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %  info                   : Read sensor information such as output
    %                           data rate, bandwidth and so on.
    %
    %  Note: For Arduino, real-time data rate acquisition from AK09916 
    %  sensor can be achieved by using the 'Samplerate' property and read 
    %  function. For hardware boards other than Arduino, ak09916 object is 
    %  supported with limited functionality. For those hardware boards, you 
    %  can use the readMagneticField function and the 'Bus' and 'I2CAddress' 
    %  properties to acquire data from the AK09916 sensor.
    %
    %  Example 1: Read one sample of magnetic field value from AK09916 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = ak09916(a);
    %   accelData  =  sensorObj.readMagneticFeild;
    %
    %  Example 2: Read and plot magnetic field values from an AK09916 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = ak09916(a,'SampleRate',120,'SamplesPerRead',15);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Magnetic Field');
    %   title('Magnetic Field values from AK09916 sensor');
    %   x_val = animatedline('Color','r');
    %   y_val = animatedline('Color','g');
    %   z_val = animatedline('Color','b');
    %   axis tight;
    %   legend('Magnetic Field in X-axis','Magnetic Field in Y-axis',...
    %      'Magnetic Field in Z-axis');
    %   stop_time = 10; %  time in seconds
    %   count = 1;
    %   tic;
    %   while(toc <= stop_time)
    %     mag = read(sensorObj);
    %     addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %     addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %     addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %     count = count + sensorObj.SamplesPerRead;
    %     drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also mpu6050, lsm9ds1, bno055, read, readAcceleration,
    %   readTemperature, readAngularVelocity, readMagneticField

    %   Copyright 2021 The MathWorks, Inc.

    %#codegen

    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 10;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = 3;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = 0x0C;
    end

    properties(Access = protected)
        MagnetometerResolution = 0.15;
    end

    properties(Hidden, Nontunable)
        IsActiveMag = true;
        MagnetometerODR = 100;
        IsOutDoubleType = true;
    end

    properties(Access = protected, Constant)
        DeviceName = 'AK09916';
        WIA = 0x01;
        DeviceID = 0x09;
        ST1 = 0x10;
        MagnetometerDataRegister = 0x11;
        ST2 = 0x18; % Mandatory to read this register after data register read
        CNTL2 = 0x31;
        SupportedODR = [10,20,50,100];
        CNTL3 = 0x32; % Soft reset
        BytesToRead = 6;
        MagnetometerRange = 4900;
    end

    methods
        function obj = ak09916(varargin)
            % Code generation does not support try-catch block. So init
            % function call is made separately in both codegen and IO
            % context.
            obj@matlabshared.sensors.sensorUnit(varargin{:});
            if ~obj.isSimulink
                % For MATLAB workflow, ensure only below name value pairs
                % are used.
                names = {'Bus','OutputFormat','TimeFormat','SamplesPerRead', 'SampleRate','ReadMode','I2CAddress'};
                defaults = {[],'timetable','datetime', 10, 100, 'latest',[]};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME)
                    end
                end
                obj.IsActiveMag = true;
                obj.IsOutDoubleType = true;
            else
                names = {'Bus','I2CAddress','IsActiveMag','MagnetometerODR','IsOutDoubleType'};
                defaults = {0,[],true,100,true};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                obj.init(varargin{1},'Bus',p.parameterValue('Bus'),'I2CAddress',p.parameterValue('I2CAddress'));
                obj.IsActiveMag = p.parameterValue('IsActiveMag');
                obj.MagnetometerODR = p.parameterValue('MagnetometerODR');
                obj.IsOutDoubleType = p.parameterValue('IsOutDoubleType');
            end
        end

        function set.MagnetometerODR(obj,odr)
            andMask = 0xE0;
            switch odr
                case 10
                    orValue = 0x02;
                case 20
                    orValue = 0x04;
                case 50
                    orValue = 0x06;
                case 100
                    orValue = 0x08;
                otherwise
                    orValue = 0x08;
            end
            value = uint8(readRegister(obj.Device,obj.CNTL2,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.CNTL2,value);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
            obj.MagnetometerODR = odr;
        end
    end
    methods(Hidden)
        function [statusData,timestamp]  = readStatus(obj)
            [tempData,~,timestamp] = obj.Device.readRegisterData(obj.ST1, 1, "uint8");
            if bitget(uint8(tempData),1)
                statusData = uint8(0);
            else
                statusData = uint8(1);
            end
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            % Check if device ID in WHO_AM_Register is as expected
            deviceid_value = readRegister(obj.Device,obj.WIA,1,'uint8');
            if(deviceid_value ~= obj.DeviceID)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID',obj.DeviceName,num2str(obj.DeviceID));
                end
            end
            % Soft reset of all registers
            val = uint8(readRegister(obj.Device,obj.CNTL3,1,'uint8'));
            val = uint8(bitor(val,0x01));
            writeRegister(obj.Device,obj.CNTL3,val);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function initSensorImpl(~)
        end

        function initMagnetometerImpl(~)
        end

        function [data,status,timestamp] = readMagneticFieldImpl(obj)
            % +2 is to indicate data is read. This step is mandatory for
            % this sensor so that the sensor data register will be freed up
            % for next set of data
            numBytes = obj.BytesToRead+2;
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.MagnetometerDataRegister, numBytes, "uint8");  % 7th byte indicates data is read
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*numBytes))
                    data = reshape(data,[numBytes,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = data(:,1:obj.BytesToRead);
            data = convertMagnetometerData(obj, data);
        end

        function setODRImpl(obj)
            if obj.SampleRate >= max(obj.SupportedODR)
                obj.MagnetometerODR = max(obj.SupportedODR);
            else
                obj.MagnetometerODR = min(obj.SupportedODR(obj.SampleRate<=obj.SupportedODR));
            end
        end

        function [data,status,timestamp] = readSensorDataImpl(obj)
            [data,status,timestamp] = readMagneticFieldImpl(obj);
        end

        function data = convertSensorDataImpl(obj, data)
            data = convertMagnetometerData(obj, data(1:obj.BytesToRead));
        end

        function s = infoImpl(obj)
            if coder.target('MATLAB')
                s = struct('MagnetometerODR', obj.MagnetometerODR);
            else
                coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
            end
        end

        function names = getMeasurementDataNames(obj)
            names = obj.MagnetometerDataName;
        end

        function data = convertMagnetometerData(obj, magSensorData)
            xm = bitor(int16(magSensorData(:, 1)), bitshift(int16(magSensorData(:, 2)),8));
            ym = bitor(int16(magSensorData(:, 3)), bitshift(int16(magSensorData(:, 4)),8));
            zm = bitor(int16(magSensorData(:, 5)), bitshift(int16(magSensorData(:, 6)),8));
            if obj.IsOutDoubleType
                data = double(obj.MagnetometerResolution).*double([xm, ym, zm]);
            else
                data = single(obj.MagnetometerResolution).*single([xm, ym, zm]);
            end
        end
    end
end

% LocalWords:  ODR
