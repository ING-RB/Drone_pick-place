classdef LSM303CBlock < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for LSM303C.
    
    %Copyright 2020-2023 The MathWorks, Inc.
    
    %#codegen
    properties(Access = protected, Constant)
        SensorName = "LSM303C";
    end

    properties(Nontunable)
        I2CAddress={'0x1D','0x1E'}
        I2CModule=''
        AccelerationRange='+/- 2g'
        MagnetometerRange
        MagnetometerODR='0.625 Hz'
        AccelerometerODR='10 Hz'
    end
    
    properties(Nontunable, Access = protected)
        I2CBus
    end
    
    properties(Access = protected)
        PeripheralType = 'I2C'
    end
    
    properties(Hidden, Constant)
        AccelerationRangeSet = matlab.system.StringSet({'+/- 2g', '+/- 4g', '+/- 8g'})
        MagnetometerRangeSet = matlab.system.StringSet({'+/- 16 gauss'});
        MagnetometerODRSet = matlab.system.StringSet({'0.625 Hz','1.25 Hz','2.5 Hz','5 Hz','10 Hz','20 Hz','40 Hz','80 Hz'});
        AccelerometerODRSet = matlab.system.StringSet({'10 Hz','50 Hz','100 Hz','200 Hz','400 Hz','800 Hz'})
    end
    
    properties(Nontunable)
        IsActiveAccelerometer (1, 1) logical = true
        IsActiveMagnetometer (1, 1) logical = true
        IsActiveTemperature (1, 1) logical = true
        IsAccelStatus (1, 1) logical=false;
        IsMagStatus (1, 1) logical=false;
    end
    
    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveAccelerometer+obj.IsActiveMagnetometer + obj.IsActiveTemperature+obj.IsAccelStatus+obj.IsMagStatus);
            count = 1;
            if obj.IsActiveAccelerometer
                out{count} = matlabshared.sensors.simulink.internal.Acceleration;
                count = count + 1;
            end
            if obj.IsActiveMagnetometer
                out{count} = matlabshared.sensors.simulink.internal.MagneticField;
                count = count + 1;
            end
            if obj.IsActiveTemperature
                out{count} = matlabshared.sensors.simulink.internal.Temperature;
                count = count + 1;
            end
            if obj.IsActiveAccelerometer  &&  obj.IsAccelStatus
                out{count} =matlabshared.sensors.simulink.internal.AccelerationStatus;
                out{count}.OutputSize = [1, 3];
                out{count}.OutputDataType = 'uint8';
                count = count + 1;
            end
            if obj.IsActiveMagnetometer  &&  obj.IsMagStatus
                out{count} =matlabshared.sensors.simulink.internal.MagneticFieldStatus;
                out{count}.OutputSize = [1, 3];
                out{count}.OutputDataType = 'uint8';
            end
        end
        
        function createSensorObjectImpl(obj)
            coder.extrinsic('matlabshared.sensors.simulink.internal.getNumericValue');
            numericValue = coder.const(@matlabshared.sensors.simulink.internal.getNumericValue,obj.AccelerometerODR,obj.MagnetometerODR);
            accelODR = numericValue(1);
            magODR =  numericValue(2);
            obj.SensorObject = lsm303c(obj.HwUtilityObject, ...
                "Bus",obj.I2CBus,'IsActiveAccelerometer',obj.IsActiveAccelerometer, ....
                'IsActiveMagnetometer',obj.IsActiveMagnetometer,"AccelerometerRange",obj.AccelerationRange,'AccelerometerODR',accelODR,'MagnetometerODR',magODR);
        end
        
        function varargout = readSensorDataHook(obj)
            % For LSM sensors, when status is enabled, status register
            % needs to be read before other measurements. Making this change
            % in getActiveOutputsImpl to read the status first will result in
            % status coming on top of the block display, hence overloading
            % the readSensorDataHook
            if obj.IsAccelStatus
                if obj.IsMagStatus
                    [outAccel,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                    outMag = obj.OutputModules{end}.readSensor(obj);
                    % If more that status is required
                    if obj.NumOutputs>2
                        for i = 1:obj.NumOutputs-2
                            [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                        end
                        varargout{i+1} = outAccel;
                        varargout{i+2} = outMag;
                        varargout{i+3} = timestamp;
                    else
                        varargout{1} = outAccel;
                        varargout{2} = outMag;
                        varargout{3} = timestamp;
                    end
                else
                    [out,timestamp] = obj.OutputModules{end}.readSensor(obj);
                    % If more that status is required
                    if obj.NumOutputs>1
                        for i = 1:obj.NumOutputs-1
                            [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                        end
                    else
                        i = 0;
                    end
                    varargout{i+1} = out;
                    varargout{i+2} = timestamp;
                end
            else
                if obj.IsMagStatus
                    [out,timestamp] = obj.OutputModules{end}.readSensor(obj);
                    % If more that status is required
                    if obj.NumOutputs>1
                        for i = 1:obj.NumOutputs-1
                            [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                        end
                    else
                        i = 0;
                    end
                    varargout{i+1} = out;
                    varargout{i+2} = timestamp;
                else
                    for i = 1:obj.NumOutputs
                        [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                    end
                    varargout{i+1} = timestamp;
                end
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
                ['text(52,12,' [''' ' 'LSM303C' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end
        
        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "AccelerationRange"
                    flag = ~obj.IsActiveAccelerometer;
                case "AccelerometerODR"
                    flag = ~obj.IsActiveAccelerometer;
                case "IsAccelStatus"
                    flag = ~obj.IsActiveAccelerometer;
                case "MagnetometerRange"
                    flag = ~obj.IsActiveMagnetometer;
                case "MagnetometerODR"
                    flag = ~obj.IsActiveMagnetometer;
                case "IsMagStatus"
                    flag = ~obj.IsActiveMagnetometer;
            end
        end
        
        function validatePropertiesImpl(obj)
            %Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveMagnetometer && ~obj.IsActiveAccelerometer && ~obj.IsActiveTemperature && ~obj.IsAccelStatus && ~obj.IsMagStatus && ~obj.IsActiveTimeStamp
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl()
            txtString = message('matlab_sensors:blockmask:lsm303cMaskDescription').getString;
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'LSM303C 6DOF COMPASS Sensor','Text',txtString,'ShowSourceLink',false);
        end
        
        function groups = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.sensors.simulink.internal.SensorBlockBase.getPropertyGroupsImpl();
            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule});
            % Select outputs
            accelerationProp = matlab.system.display.internal.Property('IsActiveAccelerometer', 'Description', 'Acceleration (m/s^2)');
            magneticFieldProp = matlab.system.display.internal.Property('IsActiveMagnetometer', 'Description', ['Magnetic field (',char(181),'T)']');
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description', ['Temperature (',char(0176),'C)']);
            accelStatusProp= matlab.system.display.internal.Property('IsAccelStatus','Description', 'Acceleration Status');
            magStatusProp= matlab.system.display.internal.Property('IsMagStatus','Description', 'Magnetic Field Status');
            % PropertyListOut{2} is IsActiveTimestamp which determine
            % whether to give timestamp output
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {accelerationProp, magneticFieldProp, temperatureProp,accelStatusProp,magStatusProp,PropertyListOut{2}});
            % Accelerometer
            accelerationRange = matlab.system.display.internal.Property('AccelerationRange','Description', 'Accelerometer range');
            accelerometerODR = matlab.system.display.internal.Property('AccelerometerODR','Description', 'Accelerometer output data rate');
            % Magnetometer
            magnetometerRange = matlab.system.display.internal.Property('MagnetometerRange', 'Description', 'Magnetometer range');
            magnetometerODR = matlab.system.display.internal.Property('MagnetometerODR', 'Description', 'Magnetometer output data rate');
            accelerometerSettings = matlab.system.display.Section(...
                'Title','Accelerometer',...
                'PropertyList',{accelerationRange, accelerometerODR});
            magnetometerSettings = matlab.system.display.Section(...
                'Title','Magnetometer',...
                'PropertyList',{magnetometerRange, magnetometerODR});
            % Sample time
            sampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            % QueueSizeFactor Hidden parameter for frame based streaming. Only required for
            % sensor which give frame outputs using 'Frame' block
            sampleTimeSection = matlab.system.display.Section('PropertyList', {sampleTimeProp, PropertyListOut{1}});
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Main',...
                'Sections', [i2cProperties,selectOutputs,sampleTimeSection]);
            AdvancedGroup = matlab.system.display.SectionGroup(...
                'Title','Advanced',...
                'Sections',  [accelerometerSettings,magnetometerSettings]);
            groups=[ MainGroup, AdvancedGroup];
        end
    end
end