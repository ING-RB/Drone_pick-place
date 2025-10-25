classdef LSM6DSLBlock < matlabshared.sensors.simulink.internal.LSM6BlockBase
    % LSM6DSL 6 DOF IMU sensor.
    %
    % <a href="https://www.st.com/resource/en/datasheet/lsm6dsl.pdf">Device Datasheet</a>

    %   Copyright 2020-2022 The MathWorks, Inc.
    %#codegen
    
    properties(Access = protected, Constant)
      SensorName = "LSM6DSL";
    end

    properties(Nontunable)
        AccelerometerRange = '+/- 2g';
        AccelerometerODR = '12.5 Hz';
        AccelLPF1BW  = 'ODR/2';
        GyroscopeRange = '250 dps'
        GyroscopeODR = '12.5 Hz';
        AccelSelectCompositeFilter = 'No filter';
        AccelLPF2BW = 'ODR/50';
        AccelHPFBW = 'ODR/100';
        GyroHPFBW = '0.016 Hz';
        GyroLPFBWMode = '0';

        EnableGyroHPF (1, 1) logical = false;
        EnableGyroLPF (1, 1) logical = false;
    end

    properties(Hidden, Constant)
        AccelerometerRangeSet = matlab.system.StringSet({'+/- 2g', '+/- 4g', '+/- 8g', '+/- 16g'})
        GyroscopeRangeSet = matlab.system.StringSet({'125 dps', '250 dps', '500 dps', '1000 dps', '2000 dps'});
        GyroscopeODRSet = matlab.system.StringSet({'12.5 Hz', '26 Hz', '52 Hz', '104 Hz', '208 Hz', '416 Hz', '833 Hz', '1666 Hz','3332 Hz', '6664 Hz'});
        AccelerometerODRSet = matlab.system.StringSet({'12.5 Hz', '26 Hz', '52 Hz', '104 Hz', '208 Hz', '416 Hz', '833 Hz', '1666 Hz', '3332 Hz', '6664 Hz'})
        AccelLPF1BWSet = matlab.system.StringSet({'ODR/2','ODR/4'});
        AccelSelectCompositeFilterSet = matlab.system.StringSet({'No filter', 'High pass filter', 'Low pass filter'});
        AccelLPF2BWSet = matlab.system.StringSet({'ODR/50', 'ODR/100', 'ODR/9', 'ODR/400'})
        AccelHPFBWSet = matlab.system.StringSet({'ODR/100', 'ODR/9', 'ODR/400'})
        GyroHPFBWSet = matlab.system.StringSet({'0.016 Hz', '0.065 Hz', '0.260 Hz', '1.04 Hz'});
        GyroLPFBWModeSet = matlab.system.StringSet({'0', '1', '2', '3'});
    end

    methods(Access = protected)
        function createSensorObjectImpl(obj)
            % getNumericValue() function returns numeric values corresponding to input
            % cell array. If '14.3 Hz' is passed, the below function
            % returns 14.3.
            coder.extrinsic('matlabshared.sensors.simulink.internal.getNumericValue');
            numericValue = coder.const(@matlabshared.sensors.simulink.internal.getNumericValue,obj.AccelerometerODR,obj.GyroscopeODR,obj.GyroHPFBW,obj.GyroLPFBWMode);
            accelODR = numericValue(1);
            gyroODR =  numericValue(2);
            gyroHPFBW = numericValue(3);
            gyroLPFBWMode = numericValue(4);
            obj.SensorObject = lsm6dsl(obj.HwUtilityObject,"Bus",obj.I2CBus,'I2CAddress',obj.I2CAddress,'isActiveAccel',obj.IsActiveAcceleration, ....
                'isActiveGyro',obj.IsActiveAngularRate,'isActiveTemp',obj.IsActiveTemperature,...
                'AccelerometerRange',obj.AccelerometerRange, 'AccelerometerODR',accelODR, 'AccelLPF1BW', obj.AccelLPF1BW ,...
                'AccelSelectCompositeFilters', obj.AccelSelectCompositeFilter,  'AccelLPF2BW', obj.AccelLPF2BW,...
                'AccelHPFBW', obj.AccelHPFBW, 'GyroscopeODR',gyroODR,...
                'GyroscopeRange',obj.GyroscopeRange,'EnableGyroHPF',obj. EnableGyroHPF, 'GyroHPFBW',gyroHPFBW,...
                'EnableGyroLPF',obj. EnableGyroLPF, 'GyroLPFBWMode',gyroLPFBWMode);
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
                ['text(52,12,' [''' ' 'LSM6DSL' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "AccelerometerRange"
                    flag = ~obj.IsActiveAcceleration;
                case "AccelerometerODR"
                    flag = ~obj.IsActiveAcceleration;
                case "AccelLPF1BW"
                    flag = ~obj.IsActiveAcceleration;
                case "AccelSelectCompositeFilter"
                    flag = ~obj.IsActiveAcceleration;
                case "LPF1Bandwidth"
                    flag = ~(obj.IsActiveAcceleration && obj.SelectAnalogBW);
                case "AccelLPF2BW"
                    flag = ~(obj.IsActiveAcceleration && strcmpi(obj.AccelSelectCompositeFilter, "Low Pass Filter"));
                case "AccelHPFBW"
                    flag = ~(obj.IsActiveAcceleration && strcmpi(obj.AccelSelectCompositeFilter, "High Pass Filter"));
                case "GyroscopeRange"
                    flag = ~obj.IsActiveAngularRate;
                case "GyroscopeODR"
                    flag = ~obj.IsActiveAngularRate;
                case "EnableGyroHPF"
                    flag = ~obj.IsActiveAngularRate;
                case "GyroHPFBW"
                    flag = ~(obj.IsActiveAngularRate && obj.EnableGyroHPF);
                case "EnableGyroLPF"
                    flag = ~obj.IsActiveAngularRate;
                case "GyroLPFBWMode"
                    flag = ~(obj.IsActiveAngularRate && obj.EnableGyroLPF);
            end
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'LSM6DSL 6DOF IMU Sensor','Text',message('matlab_sensors:blockmask:lsm6dsMaskDescription').getString,'ShowSourceLink', false);
        end

        function groups = getPropertyGroupsImpl
            main = matlabshared.sensors.simulink.internal.LSM6BlockBase.getPropertyGroupsImpl();
            % Accel advanced paramaters
            accelerationRange = matlab.system.display.internal.Property('AccelerometerRange','Description', 'Full scale range');
            accelerometerODR = matlab.system.display.internal.Property('AccelerometerODR','Description', 'Output data rate');
            accelerometerDigitalLPFBW = matlab.system.display.internal.Property('AccelLPF1BW','Description', 'Digital low pass filter bandwidth');
            AccelSelectCompositeFilter = matlab.system.display.internal.Property('AccelSelectCompositeFilter', 'Description', 'Select composite filter');
            AccelLPF2BW = matlab.system.display.internal.Property('AccelLPF2BW', 'Description', 'Low pass filter bandwidth');
            AccelHPFBW = matlab.system.display.internal.Property('AccelHPFBW','Description', 'High pass filter bandwidth');
            accelSection = matlab.system.display.Section(...
                'Title', 'Accelerometer', ...
                'PropertyList', {accelerationRange, accelerometerODR, accelerometerDigitalLPFBW,AccelSelectCompositeFilter, AccelLPF2BW, AccelHPFBW});%,'SectionType', matlab.system.display.SectionType.collapsiblepanel);
            % Gyro advanced paramaters
            gyroscopeRange = matlab.system.display.internal.Property('GyroscopeRange', 'Description', 'Full scale range');
            gyroscopeODR = matlab.system.display.internal.Property('GyroscopeODR', 'Description', 'Output data rate');
            selectGyroscopeHPF = matlab.system.display.internal.Property('EnableGyroHPF','Description', 'Enable high pass filter');
            GyroHPFBW = matlab.system.display.internal.Property('GyroHPFBW', 'Description', 'High pass filter bandwidth');
            selectGyroscopeLPF = matlab.system.display.internal.Property('EnableGyroLPF','Description', 'Enable low pass filter');
            GyroLPFBWMode= matlab.system.display.internal.Property('GyroLPFBWMode', 'Description', 'Low pass filter bandwidth mode');
            gyroSection = matlab.system.display.Section(...
                'Title', 'Gyroscope', ...
                'PropertyList', {gyroscopeRange, gyroscopeODR, selectGyroscopeHPF, GyroHPFBW,selectGyroscopeLPF, GyroLPFBWMode});
            advanced = matlab.system.display.SectionGroup(...
                'Title','Advanced', ...
                'Sections',[accelSection,gyroSection]);
            groups = [main,advanced];
        end
    end
end