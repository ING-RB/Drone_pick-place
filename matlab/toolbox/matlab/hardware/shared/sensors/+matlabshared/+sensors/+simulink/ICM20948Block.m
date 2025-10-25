classdef ICM20948Block < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    % ICM20948 9 DOF IMU sensor.
    %
    % <a href="https://invensense.tdk.com/wp-content/uploads/2016/06/DS-000189-ICM-20948-v1.3.pdf">Device Datasheet</a>

    %   Copyright 2021-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
         SensorName = "ICM20948";
    end

    properties(Nontunable)
        I2CAddress = '0x69';
        I2CModule=''
        AccelerometerRange(1,:) char {matlab.system.mustBeMember(AccelerometerRange,{'+/-2g', '+/-4g', '+/-8g','+/-16g'})} = '+/-2g';
        AccelerometerODR = 1125;
        AccelerometerBW(1,:) char {matlab.system.mustBeMember(AccelerometerBW,{'5.7 Hz', '11.5 Hz', '23.9 Hz','50.4 Hz','111.4 Hz', '246 Hz', '473 Hz'})} = '23.9 Hz';
        GyroscopeRange(1,:) char {matlab.system.mustBeMember(GyroscopeRange,{'+/-250 dps', '+/-500 dps', '+/-1000 dps','+/-2000 dps'})} = '+/-250 dps';
        GyroscopeODR = 1125;
        GyroscopeBW (1,:) char {matlab.system.mustBeMember(GyroscopeBW,{'5.7 Hz', '11.6 Hz', '23.9 Hz','51.2 Hz','119.5 Hz', '151.8 Hz', '196.6 Hz','361.4 Hz'})} = '23.9 Hz';
        TemperatureBW (1,:) char {matlab.system.mustBeMember(TemperatureBW,{'8.8 Hz', '17.3 Hz', '34.1 Hz', '65.9 Hz','123.5 Hz','217.9 Hz', '7932.0 Hz'})} = '34.1 Hz';
        MagnetometerODR(1,:) char {matlab.system.mustBeMember(MagnetometerODR,{'10 Hz','20 Hz','50 Hz','100 Hz'})} = '100 Hz';
        DataType(1,:) char {matlab.system.mustBeMember(DataType,{'single','double'})} = 'double';
        InterruptType (1,:) char {matlab.system.mustBeMember(InterruptType,{'Active low','Active high'})} = 'Active high';
    end

    properties(Nontunable, Logical)
        IsActiveAccel = true;
        IsActiveGyro = true;
        IsActiveMag = true;
        IsActiveTemp = true;
        IsActiveStatus = false;
        EnableDRDY = false;
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x68','0x69'})
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Access=protected, Constant)
        GyroODRUpperLimit = 1125;
        GyroODRLowerLimit = round(1125/256,1,'decimal');
        AccelODRUpperLimit = 1125;
        AccelODRLowerLimit = round(1125/4096,1,'decimal');
    end

    methods
        function set.GyroscopeODR(obj,val)
            validateattributes(val, {'numeric'}, ...
                { '>=', obj.GyroODRLowerLimit, '<=', obj.GyroODRUpperLimit, 'real', 'nonnan','nonempty','integer', 'scalar'}, ...
                '', 'Gyroscope output data rate');
            obj.GyroscopeODR = double(val);
        end

        function set.AccelerometerODR(obj,val)
            validateattributes(val, {'numeric'}, ...
                { '>=', obj.AccelODRLowerLimit, '<=', obj.AccelODRUpperLimit, 'real', 'nonnan','nonempty','integer', 'scalar'}, ...
                '', 'Accelerometer output data rate');
            obj.AccelerometerODR = double(val);
        end
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveAccel + obj.IsActiveGyro + obj.IsActiveMag + obj.IsActiveTemp + (obj.IsActiveStatus && ~obj.EnableDRDY));
            count = 1;
            if obj.IsActiveAccel
                out{count} = matlabshared.sensors.simulink.internal.Acceleration;
                if strcmp(obj.DataType,'single')
                    out{count}.OutputDataType = 'single';
                end
                count = count + 1;
            end
            if obj.IsActiveGyro
                out{count} = matlabshared.sensors.simulink.internal.AngularVelocity;
                if strcmp(obj.DataType,'single')
                    out{count}.OutputDataType = 'single';
                end
                count = count + 1;
            end
            if obj.IsActiveMag
                out{count} = matlabshared.sensors.simulink.internal.MagneticField;
                if strcmp(obj.DataType,'single')
                    out{count}.OutputDataType = 'single';
                end
                count = count + 1;
            end
            if obj.IsActiveTemp
                out{count} = matlabshared.sensors.simulink.internal.Temperature;
                if strcmp(obj.DataType,'single')
                    out{count}.OutputDataType = 'single';
                end
                count = count + 1;
            end
            if obj.IsActiveStatus && ~obj.EnableDRDY
                out{count} = matlabshared.sensors.simulink.internal.Status;
                out{count}.OutputSize = [1,2];
            end
            if strcmp(obj.DataType,'single')
                % Change the timestamp datatype if required
                obj.TimeStampDataType = 'single';
            end
        end

        function createSensorObjectImpl(obj)
            coder.extrinsic('matlabshared.sensors.simulink.internal.getNumericValue');
            coder.extrinsic('sscanf');
            coder.extrinsic('strcmpi');
            accelRange = coder.const(sscanf(obj.AccelerometerRange,'+/-%fg'));
            numericValue = coder.const(@matlabshared.sensors.simulink.internal.getNumericValue,obj.AccelerometerBW,obj.GyroscopeRange(4:end),obj.GyroscopeBW,obj.MagnetometerODR,obj.TemperatureBW);
            isActiveLow = coder.const(@strcmpi,obj.InterruptType,'Active low');
            isOutDoubleType = coder.const(@strcmpi,obj.DataType,'double');
            accelBW = numericValue(1);
            gyroRange = numericValue(2);
            gyroBW = numericValue(3);
            magODR =  numericValue(4);
            tempBw = numericValue(5);
            % I2C address of mag is fixed
            i2cAddress = [hex2dec(obj.I2CAddress),0x0C];
            obj.SensorObject = icm20948(obj.HwUtilityObject,"Bus",obj.I2CBus,"I2CAddress",i2cAddress, 'IsOutDoubleType',isOutDoubleType,...
                'IsActiveAccel',obj.IsActiveAccel,'IsActiveGyro',obj.IsActiveGyro,'IsActiveMag',obj.IsActiveMag,'IsActiveTemp',obj.IsActiveTemp,....
                "AccelerometerRange",accelRange,"AccelerometerBW",accelBW,"AccelerometerODR",obj.AccelerometerODR,...
                "GyroscopeRange",gyroRange,"GyroscopeBW",gyroBW,"GyroscopeODR",obj.GyroscopeODR,...
                'MagnetometerODR',magODR,"TemperatureBW",tempBw,"EnableDRDY",obj.EnableDRDY,"IsActiveLow",isActiveLow);
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
                ['text(52,12,' [''' ' 'ICM20948' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "AccelerometerRange"
                    flag = ~obj.IsActiveAccel;
                case "AccelerometerODR"
                    flag = ~obj.IsActiveAccel;
                case "AccelerometerBW"
                    flag = ~obj.IsActiveAccel;
                case "GyroscopeRange"
                    flag = ~obj.IsActiveGyro;
                case "GyroscopeODR"
                    flag = ~obj.IsActiveGyro;
                case "GyroscopeBW"
                    flag = ~obj.IsActiveGyro;
                case "MagnetometerODR"
                    flag = ~obj.IsActiveMag;
                case "TemperatureBW"
                    flag = ~obj.IsActiveTemp;
                case "InterruptType"
                    flag = ~obj.EnableDRDY;
                case "IsActiveStatus"
                    flag = obj.EnableDRDY;
            end
        end

        function validatePropertiesImpl(obj)
            %Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveMag && ~obj.IsActiveAccel && ~obj.IsActiveTemp && ~obj.IsActiveGyro && ~obj.IsActiveStatus && ~obj.IsActiveTimeStamp
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'ICM20948 9DOF IMU Sensor','Text',message('matlab_sensors:blockmask:icm20948MaskDescription').getString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.sensors.simulink.internal.SensorBlockBase.getPropertyGroupsImpl();
            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            bitRate = matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            % DRDY interrupt
            enableDrdy = matlab.system.display.internal.Property('EnableDRDY','Description', 'Generate data ready interrupt');
            interruptType = matlab.system.display.internal.Property('InterruptType','Description', 'Interrupt type');
            topSection = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,bitRate,enableDrdy,interruptType});

            % Select outputs
            accelerationProp = matlab.system.display.internal.Property('IsActiveAccel', 'Description', 'Acceleration (m/s^2)');
            angularRateProp = matlab.system.display.internal.Property('IsActiveGyro', 'Description', 'Angular rate (rad/s)','Row',matlab.system.display.internal.Row.current);
            magneticFieldProp = matlab.system.display.internal.Property('IsActiveMag', 'Description', ['Magnetic field (',char(181),'T)']','Row',matlab.system.display.internal.Row.current);
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemp', 'Description', ['Temperature (',char(0176),'C)']);
            statusProp = matlab.system.display.internal.Property('IsActiveStatus', 'Description', 'Status','Row',matlab.system.display.internal.Row.current);
            % PropertyListOut{2} is IsActiveTimestamp which determine
            % whether to give timestamp output
            PropertyListOut{2}.Row = matlab.system.display.internal.Row.current;
            selectOutputsSection = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {accelerationProp, angularRateProp,  magneticFieldProp, temperatureProp,statusProp,PropertyListOut{2}});
            % Accel advanced paramaters
            accelerationRange = matlab.system.display.internal.Property('AccelerometerRange','Description', 'Full scale range');
            accelerometerBW = matlab.system.display.internal.Property('AccelerometerBW','Description',  'Bandwidth');
            accelerometerODR = matlab.system.display.internal.Property('AccelerometerODR','Description', 'Output data rate (0.3 Hz - 1125 Hz)');
            accelSection = matlab.system.display.Section('Title', 'Accelerometer settings','PropertyList', {accelerationRange, accelerometerODR, accelerometerBW},'Type', matlab.system.display.SectionType.collapsiblepanel);
            % Gyro advanced paramaters
            gyroscopeRange = matlab.system.display.internal.Property('GyroscopeRange', 'Description', 'Full scale range');
            gyroscopeBW = matlab.system.display.internal.Property('GyroscopeBW', 'Description', 'Bandwidth');
            gyroscopeODR = matlab.system.display.internal.Property('GyroscopeODR', 'Description', 'Output data rate (4.4 Hz - 1125 Hz)');
            gyroSection = matlab.system.display.Section('Title', 'Gyroscope settings','PropertyList', {gyroscopeRange, gyroscopeODR, gyroscopeBW},'Type', matlab.system.display.SectionType.collapsiblepanel);
            % Mag advanced section
            magnetometerODR = matlab.system.display.internal.Property('MagnetometerODR', 'Description', 'Output data rate');
            magSection = matlab.system.display.Section('Title', 'Magnetometer settings','PropertyList', {magnetometerODR},'Type', matlab.system.display.SectionType.collapsiblepanel);
            % Temperature advanced section
            TemperatureBW = matlab.system.display.internal.Property('TemperatureBW', 'Description', 'Bandwidth');
            tempSection = matlab.system.display.Section('Title', 'Temperature sensor settings','PropertyList', {TemperatureBW},'Type', matlab.system.display.SectionType.collapsiblepanel);
            % Data type
            dataTypeProp = matlab.system.display.internal.Property('DataType', 'Description', 'Output data type');
            % Sample time
            sampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            % QueueSizeFactor Hidden parameter for frame based streaming. Only required for
            % sensor which give frame outputs using 'Frame' block
            bottomSection = matlab.system.display.Section('PropertyList', {dataTypeProp,sampleTimeProp, PropertyListOut{1}});
            groups = matlab.system.display.SectionGroup('Title','Parameters','Sections',[topSection, selectOutputsSection,accelSection,gyroSection,magSection,tempSection,bottomSection]);
        end
    end

    methods(Access = protected)
        function varargout = readSensorDataHook(obj)
            % For ICM20948 sensors, when status is enabled, status register
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
end