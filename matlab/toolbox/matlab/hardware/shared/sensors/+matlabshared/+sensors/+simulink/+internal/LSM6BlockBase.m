classdef LSM6BlockBase < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Base class for LSM6DS Blocks

    %   Copyright 2020-2023 The MathWorks, Inc.
    %#codegen
    properties(Nontunable)
        I2CModule = '';
        I2CAddress = '0x6A';
    end

    properties(Nontunable, Access = protected)
        PeripheralType = 'I2C'
        I2CBus
    end

    properties(Nontunable)
        IsActiveAcceleration (1, 1) logical = true
        IsActiveAngularRate (1, 1) logical = true
        IsActiveTemperature (1, 1) logical = true
        IsActiveStatus (1, 1) logical = false
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x6A','0x6B'})
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveAcceleration+obj.IsActiveAngularRate + obj.IsActiveTemperature + obj.IsActiveStatus);
            count = 1;
            if obj.IsActiveAcceleration
                out{count} = matlabshared.sensors.simulink.internal.Acceleration;
                count = count + 1;
            end
            if obj.IsActiveAngularRate
                out{count} = matlabshared.sensors.simulink.internal.AngularVelocity;
                count = count + 1;
            end
            if obj.IsActiveTemperature
                out{count} = matlabshared.sensors.simulink.internal.Temperature;
                count = count + 1;
            end
            if obj.IsActiveStatus
                out{count} = matlabshared.sensors.simulink.internal.Status;
                out{count}.OutputDataType = 'int8';
                out{count}.OutputSize = [1,3];
            end
        end

        function validatePropertiesImpl(obj)
            % Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveAcceleration && ~obj.IsActiveAngularRate && ~obj.IsActiveTemperature && ~obj.IsActiveStatus && ~obj.IsActiveTimeStamp
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end

        function varargout = readSensorDataHook(obj)
            % For LSM sensors, when status is enabled, status register
            % needs to be read before other measurements. Making this change
            % in getActiveOutputsImpl to read the status first will result in
            % status coming on top of the block display, hence overloading
            % the readSensorDataHook
            timestamp = 0;
            idx = 0;
            if obj.IsActiveStatus
                [out,timestamp] = obj.OutputModules{end}.readSensor(obj);
                % Check if outputs other than status is required
                if obj.NumOutputs>1
                    for i = 1:obj.NumOutputs-1
                        [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                    end
                    idx = i;
                end
                idx = idx + 1;
                varargout{idx} = out;
            else
                for i = 1:obj.NumOutputs
                    [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                end
                idx = i;
            end
            idx = idx + 1 ;
            varargout{idx} = timestamp;
        end
    end

    methods(Access = protected, Static)
        function groups = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.sensors.simulink.internal.SensorBlockBase.getPropertyGroupsImpl();

            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule, i2cAddress});

            % Select outputs
            accelerationProp = matlab.system.display.internal.Property('IsActiveAcceleration', 'Description', 'Acceleration (m/s^2)');
            angulaVelocityProp = matlab.system.display.internal.Property('IsActiveAngularRate', 'Description', 'Angular velocity (rad/s)');
            txt =  ['Temperature (',char(176),'C)'];
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description',txt);
            statusProp = matlab.system.display.internal.Property('IsActiveStatus', 'Description', 'Status');
            % PropertyListOut{2} is IsActiveTimestamp which determine
            % whether to give timestamp output
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {accelerationProp, angulaVelocityProp, temperatureProp, statusProp,PropertyListOut{2}});

            % Sample time
            sampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            % QueueSizeFactor Hidden parameter for frame based streaming. Only required for
            % sensor which give frame outputs using 'Frame' block
            sampleTimeSection = matlab.system.display.Section('PropertyList', {sampleTimeProp, PropertyListOut{1}});
            groups = matlab.system.display.SectionGroup('Title','Main', 'Sections', [ i2cProperties, selectOutputs, sampleTimeSection]);
        end
    end
end