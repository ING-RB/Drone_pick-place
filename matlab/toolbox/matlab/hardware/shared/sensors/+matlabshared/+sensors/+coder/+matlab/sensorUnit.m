classdef (Hidden) sensorUnit < matlabshared.sensors.coder.matlab.sensorBase
    % Parent class for sensor with single dye (single I2CAddress).coder
    %class

    % Copyright 2020-2022 The MathWorks, Inc.

    %#codegen

    properties(Hidden)
        Device;
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface})
        showSensorPropertiesPosition='top';
    end

    properties(Access = protected)
        LastReadTime = 0;
        startTime;
    end

    % properties(Access = protected,Nontunable)
    %     BusI2CDriver;
    % end

    properties(Abstract,Nontunable)
        DoF
    end

    methods(Abstract, Access = protected)
        initDeviceImpl(obj) % for initialization which is common to all the sensors on the device (Example: powering up the mag unit in MPU9250)
        initSensorImpl(obj) % for individual sensor inits
        data = convertSensorDataImpl(obj); % to convert the raw bytes obtained while 'peeking' the values from IO Protocol buffer
        data = readSensorDataImpl(obj);
    end

    methods
        function obj = sensorUnit(varargin)
            obj@matlabshared.sensors.coder.matlab.sensorBase(varargin{:});
        end
    end

    methods
        function [varargout] = read(obj)
            [varargout{:}] = step(obj);
        end

        function flush(obj)
            % flush(imu); Equivalent to the System object 'reset' method.
            % It resets 'SamplesRead'.
            reset(obj);
        end

        function stop(obj)
            % stop(imu);
            % Equivalent to the System object 'release' method.
            % stop(imu), unlocks the system objects
            release(obj);
        end
    end

    methods(Access = protected)
        function init(obj, varargin)
            % At least parameter must be passed
            narginchk(2,inf);
            coder.internal.prefer_const(varargin);
            obj.Parent = varargin{1};
            names =     {'I2CAddress','Bus','SampleRate','SamplesPerRead','ReadMode','OutputFormat','TimeFormat','SPIChipSelectPin'};
            defaults =    {uint32(0),uint32(0),uint32(0),uint32(0),'0','0','0','0'};
            p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
            p.parse(varargin{2:end});

            cspin = p.parameterValue('SPIChipSelectPin');
            bus = p.parameterValue('Bus');
            samplerate = p.parameterValue('SampleRate');
            samplesperread = p.parameterValue('SamplesPerRead');
            readmode = p.parameterValue('ReadMode');
            outputformat = p.parameterValue('OutputFormat');
            timeformat = p.parameterValue('TimeFormat');
            i2caddress = p.parameterValue('I2CAddress');

            coder.internal.errorIf(~strcmp(readmode,'0'), 'matlab_sensors:general:propertyValueFixedCodegen','ReadMode', 'latest');
            coder.internal.errorIf(~strcmp(outputformat,'0'), 'matlab_sensors:general:propertyValueFixedCodegen','OutputFormat', 'matrix');
            coder.internal.errorIf(~strcmp(timeformat,'0'), 'matlab_sensors:general:propertyValueFixedCodegen','TimeFormat', 'duration');
            coder.internal.errorIf(samplesperread ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','SamplesPerRead', '1');


            if ismember(obj.SupportedInterfaces,'SPI')
                matlabshared.sensors.coder.matlab.SPIsensorDevice.validateSPISensorArguments(cspin,i2caddress);
                obj.Device = matlabshared.sensors.coder.matlab.SPIsensorDevice(obj,cspin);
            elseif ismember(obj.SupportedInterfaces,'I2C')
                matlabshared.sensors.coder.matlab.I2CsensorDevice.validateI2CSensorArguments(cspin);
                obj.Device = matlabshared.sensors.coder.matlab.I2CsensorDevice(obj,obj.isSimulink,obj.I2CAddressList,bus,i2caddress,varargin);
            end

            obj.Device.OnDemandFlag = 1;
            initDeviceImpl(obj);
            initSensorImpl(obj);
            % Set the sample rate of the device. It is done after device
            % initialization. Otherwise the changes may not have any
            % effect.

            if samplerate ~=0
                obj.SampleRate = samplerate;
            else
                obj.SampleRate = obj.DefaultSampleRate;
            end
        end

        function varargout = stepImpl(obj)
            % There might be multiple entities to read from a sensor unit.
            % Read all those.
            [data,~,~] = readSensorDataImpl(obj);
            index = 1;
            for i = 1:numel(obj.DoF)
                varargout{i} = data(:,index:index+obj.DoF(i)-1);
                index = index + obj.DoF(i);
            end
            obj.SamplesRead = obj.SamplesRead + obj.SamplesPerRead;
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            if nargout == numel(obj.DoF)+1
                timestamp = getCurrentTime(obj.Parent);
                varargout{i+1} = timestamp;
            end
        end

        function s = infoImpl(~)
            % Info is not supported for code generation. But if infoImpl is
            % filled in the concrete sensor class, in code generetaion
            % context the same error has to be thrown
            s = [];
            coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
        end

        function resetImpl(obj)
            obj.SamplesRead = 0;
        end

        function releaseImpl(obj)
            obj.SamplesRead = 0;
            closeDev(obj.Device);
        end

        function num = getNumOutputsImpl(obj)
            % last output is timestamp
            num = numel(obj.DoF)+1;
        end
    end
end
