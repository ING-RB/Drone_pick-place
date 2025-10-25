classdef ADXL34xBlock < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for ADXL34x family .
    %<a href="https://www.analog.com/media/en/technical-documentation/data-sheets/ADXL345.pdf">Device Datasheet</a>
    %Copyright 2021-2022 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
        SensorName = "ADXL34x";
    end

    properties(Nontunable)
        I2CModule = ''
        I2CAddress = '0x53'
        AccelerationRange = '+/- 4g'
        AccelerometerODR = '12.5 Hz'
        InterruptPin = 'INT1'
        DataType = 'single'
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x53','0x1D'});
        AccelerationRangeSet = matlab.system.StringSet({'+/- 2g','+/- 4g','+/- 8g', '+/- 16g'});
        AccelerometerODRSet = matlab.system.StringSet({'0.10 Hz','0.20 Hz','0.39 Hz','0.78 Hz','1.56 Hz','3.13 Hz','6.25 Hz','12.5 Hz','25 Hz','50 Hz','100 Hz','200 Hz','400 Hz','800 Hz','1600 Hz'});
        InterruptPinSet = matlab.system.StringSet({'INT1','INT2'});
        DataTypeSet = matlab.system.StringSet({'single','double'});
    end

    properties(Nontunable, Logical)
        IsActiveInterrupt = false;
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1, 1);
            count = 1;
            objAccel=matlabshared.sensors.simulink.internal.Acceleration;
            if strcmp(obj.DataType,'single')
                objAccel.OutputDataType = 'single';
            end
            out{count} = objAccel;
            if strcmp(obj.DataType,'single')
                % Change the timestamp datatype if required
                obj.TimeStampDataType = 'single';
            end
        end

        function createSensorObjectImpl(obj)
            obj.SensorObject = adxl345(obj.HwUtilityObject, ...
                'Bus',obj.I2CBus,'I2CAddress',obj.I2CAddress,'AccelerometerRange',obj.AccelerationRange,'AccelerometerODR',obj.AccelerometerODR,'IsActiveInterrupt',obj.IsActiveInterrupt,'InterruptPin',obj.InterruptPin,'DataType',obj.DataType);
        end
    end

    methods(Access = protected)
        % Block mask display
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' ]; %#ok<AGROW>
                end
            end
            maskDisplayCmds = [ ...
                ['color(''white'');',newline],...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...
                ['text(38, 92, ','''',obj.Logo,'''',',''horizontalAlignment'', ''right'');',newline],...
                ['color(''black'');',newline], ...
                ['image(imread(fullfile(matlabshared.sensors.internal.getSensorRootDir,''+matlabshared'',''+sensors'',''+simulink'',''+internal'',''IMU_image.png'')),''center'');', newline], ...
                ['text(52,12,' [''' ' 'ADXL34x' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "InterruptPin"
                    flag = ~obj.IsActiveInterrupt;
                case "BitRate"
                    flag = true;
            end
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'ADXL34x Accelerometer','Text',message('matlab_sensors:blockmask:adxl34xMaskDescription').getString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.sensors.simulink.internal.SensorBlockBase.getPropertyGroupsImpl();
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            interruptProp = matlab.system.display.internal.Property('IsActiveInterrupt', 'Description', 'Enable data ready interrupt');
            interruptPin = matlab.system.display.internal.Property('InterruptPin', 'Description', 'Interrupt generate pin');
            bitRate=matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            isActiveTimestamp = matlab.system.display.internal.Property('IsActiveTimeStamp', 'Description', 'Enable timestamp output','IsGraphical',false);
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,bitRate,isActiveTimestamp});
            % Select outputs
            accelerationRange = matlab.system.display.internal.Property('AccelerationRange','Description', 'Accelerometer range');
            accelerometerODR = matlab.system.display.internal.Property('AccelerometerODR','Description', 'Accelerometer output data rate');
            % PropertyListOut{2}, isActiveTimeStamp
            advancedSettings = matlab.system.display.Section('Title', 'Advanced settings', 'PropertyList', {accelerationRange,accelerometerODR,interruptProp,interruptPin});
            % Accelerometer properties
            dataType =  matlab.system.display.internal.Property('DataType', 'Description', 'Data type');
            dataTypeSection = matlab.system.display.Section('PropertyList', {dataType});
            % Sample time
            sampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            % QueueSizeFactor Hidden parameter for frame based streaming. Only required for
            % sensor which give frame outputs using 'Frame' block
            sampleTimeSection = matlab.system.display.Section('PropertyList', {sampleTimeProp, PropertyListOut{1}});
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Parameters',...
                'Sections', [i2cProperties,advancedSettings,dataTypeSection,sampleTimeSection]);
            groups=MainGroup;
        end
    end
end