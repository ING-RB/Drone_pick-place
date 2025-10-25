classdef ADIS16505Block < matlabshared.sensors.simulink.internal.SensorBlockBase & matlabshared.sensors.simulink.internal.SPISensorBase
    % ADIS16505 6 DOF IMU sensor.
    %
    % <a href="https://www.analog.com/media/en/technical-documentation/data-sheets/adis16505.pdf">Device Datasheet</a>

    %   Copyright 2023 The MathWorks, Inc.
    %#codegen

    properties(Access = protected, Constant)
        SensorName = "ADIS16505";
        DesiredODRLowerLimit = 1;
        DesiredODRUpperLimit = 2000;
    end

    properties(Nontunable, Access = protected)
        PeripheralType = 'SPI'
    end

    properties(Nontunable, Logical)
        IsActiveAcceleration = true;
        IsActiveAngularRate = true;
        IsActiveTemperature = true;
        IsActiveStatus = false;
    end

    properties(Nontunable)
        DataType(1,:) char {matlab.system.mustBeMember(DataType,{'single','double','int32'})} = 'double';
        InterruptType (1,:) char {matlab.system.mustBeMember(InterruptType,{'Active low','Active high'})} = 'Active high';
        bartlettFilterValue(1,:) char {matlab.system.mustBeMember(bartlettFilterValue,{'1','2','4','8','16','32','64'})} = '1';
        SlaveSelectPin= '10';
        DesiredOdr=1;
        SPIModule = 0;
    end

    methods(Access = protected)
        function createSensorObjectImpl(obj)
            obj.SensorObject = adis16505(obj.HwUtilityObject, ...
                'SPIChipSelectPin',obj.SlaveSelectPin,'DataType',obj.DataType,'InterruptType',obj.InterruptType,'NumTapsBartlettFilter',real(str2double(obj.bartlettFilterValue)),'DesiredODR',obj.DesiredOdr);
        end
    end

    methods
        function set.DesiredOdr(obj,val)
            validateattributes(val, {'numeric'}, ...
                { '>=', obj.DesiredODRLowerLimit, '<=', obj.DesiredODRUpperLimit, 'real', 'nonnan','nonempty','integer', 'scalar'}, ...
                '', 'Desired output data rate');
            obj.DesiredOdr = double(val);
        end
    end

    methods(Access = protected)


        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveAcceleration+obj.IsActiveAngularRate + obj.IsActiveTemperature + obj.IsActiveStatus);
            count = 1;
            if obj.IsActiveAcceleration
                out{count} = matlabshared.sensors.simulink.internal.Acceleration;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int32'
                        out{count}.OutputDataType = 'int32';
                end
                count = count + 1;
            end
            if obj.IsActiveAngularRate
                out{count} = matlabshared.sensors.simulink.internal.AngularVelocity;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int32'
                        out{count}.OutputDataType = 'int32';
                end
                count = count + 1;
            end
            if obj.IsActiveTemperature
                out{count} = matlabshared.sensors.simulink.internal.Temperature;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int32'
                        out{count}.OutputDataType = 'int32';
                end
                count = count + 1;
            end
            if obj.IsActiveStatus
                out{count} = matlabshared.sensors.simulink.internal.Status;
            end

            switch obj.DataType
                case 'single'
                    obj.TimeStampDataType = 'single';
                case 'double'
                    obj.TimeStampDataType = 'double';
                case 'int32'
                    obj.TimeStampDataType = 'int32';
            end
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
                ['text(52,12,' [''' ' 'ADIS16505' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function validatePropertiesImpl(obj)
            %Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveAcceleration && ~obj.IsActiveTemperature && ~obj.IsActiveAngularRate && ~obj.IsActiveStatus && ~obj.IsActiveTimeStamp
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end

        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object 
            % configuration, for the command line and System block dialog

            if matches(prop,'SPIModule')
                flag = true;
            else
                flag = false;
            end
            
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'ADIS16505 6DOF IMU Sensor','Text',message('matlab_sensors:blockmask:adis16505MaskDescription').getString,'ShowSourceLink', false);
        end

        function groups = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.sensors.simulink.internal.SensorBlockBase.getPropertyGroupsImpl();
            spimodule_Prop = matlab.system.display.internal.Property('SPIModule', 'Description', 'SPI module');
            slaveSelectPinProp = matlab.system.display.internal.Property('SlaveSelectPin', 'Description', 'matlab_sensors:blockmask:adis16505ChipSelectPin');
            interruptTypeProp = matlab.system.display.internal.Property('InterruptType','Description', 'matlab_sensors:blockmask:adis16505InterruptType');
            spiProperties = matlab.system.display.Section('PropertyList', {spimodule_Prop,slaveSelectPinProp,interruptTypeProp});

            % Select outputs
            accelerationProp = matlab.system.display.internal.Property('IsActiveAcceleration', 'Description', 'matlab_sensors:blockmask:adis16505Accel');
            angulaVelocityProp = matlab.system.display.internal.Property('IsActiveAngularRate', 'Description', 'matlab_sensors:blockmask:adis16505Gyro','Row',matlab.system.display.internal.Row.current);
            txt =  ['Temperature (',char(176),'C)'];
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description',message('matlab_sensors:blockmask:adis16505Temp',char(0176)).getString);
            statusProp = matlab.system.display.internal.Property('IsActiveStatus', 'Description', 'matlab_sensors:blockmask:adis16505Status','Row',matlab.system.display.internal.Row.current);
           % PropertyListOut{2}.IsGraphical=true;
            % PropertyListOut{2} is IsActiveTimestamp which determine
            % whether to give timestamp output
            PropertyListOut{2}.Row = matlab.system.display.internal.Row.current;
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {accelerationProp, angulaVelocityProp, temperatureProp, statusProp,PropertyListOut{2}});
            desiredOdrProp = matlab.system.display.internal.Property('DesiredOdr','Description', 'matlab_sensors:blockmask:adis16505DesiredODR');
            bartlettFilterProp = matlab.system.display.internal.Property('bartlettFilterValue', 'Description', 'matlab_sensors:blockmask:adis16505bartlettFilter');
            dataTypeProp =  matlab.system.display.internal.Property('DataType', 'Description', 'matlab_sensors:blockmask:adis16505Datatype');

            % Sample time
            sampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'matlab_sensors:blockmask:adis16505Sampletime');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {desiredOdrProp,bartlettFilterProp,dataTypeProp,sampleTimeProp,PropertyListOut{1}});
            groups = matlab.system.display.SectionGroup('Title','Main', 'Sections', [spiProperties,selectOutputs,sampleTimeSection]);
        end
    end


    methods(Static)
        function odrVal = getAchievedODR(desiredODR)
            if ischar(desiredODR)
                desiredODR = str2double(desiredODR);
            end
            SupportedODR =  2000./(1:2000);
            odrVal = string(min(SupportedODR(SupportedODR >= desiredODR)));
        end
    end
end
