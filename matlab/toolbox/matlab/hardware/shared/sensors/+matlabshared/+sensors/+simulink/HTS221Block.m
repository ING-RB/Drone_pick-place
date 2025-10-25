classdef HTS221Block < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for HTS221 .
    
    %Copyright 2020-2023 The MathWorks, Inc.
    
    %#codegen
    properties(Access = protected, Constant)
         SensorName = "HTS221"
    end

    properties(Nontunable)
        I2CModule=''
        I2CAddress='0x5F'
        OutputDataRate='1 Hz'
    end
    
    properties(Nontunable, Access = protected)
        I2CBus
    end
    
    properties(Access = protected)
        PeripheralType = 'I2C'
    end
    
    properties(Hidden, Constant)
        OutputDataRateSet = matlab.system.StringSet({'1 Hz','7 Hz','12.5 Hz'})
        
    end
    
    properties(Nontunable)
        IsActiveHumidity (1, 1) logical = true
        IsActiveTemperature (1, 1) logical = true
        IsStatus (1, 1) logical=false;
    end
    
    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveHumidity + obj.IsActiveTemperature+obj.IsStatus);
            count = 1;
            if obj.IsActiveHumidity
                out{count} = matlabshared.sensors.simulink.internal.Humidity;
                count = count + 1;
            end
            if obj.IsActiveTemperature
                out{count} = matlabshared.sensors.simulink.internal.Temperature;
                count = count + 1;
            end
            if obj.IsStatus
                out{count} =matlabshared.sensors.simulink.internal.Status;
                out{count}.OutputSize = [1, 2];
                out{count}.OutputDataType = 'double';
            end
        end
        
        function createSensorObjectImpl(obj)
            coder.extrinsic('matlabshared.sensors.simulink.internal.getNumericValue');
            numericValue = coder.const(@matlabshared.sensors.simulink.internal.getNumericValue,obj.OutputDataRate);
            humidityTemperatureODR = numericValue(1);
            obj.SensorObject = hts221(obj.HwUtilityObject, ...
                "Bus",obj.I2CBus,'IsActiveHumidity',obj.IsActiveHumidity, ...
                'IsActiveTemperature',obj.IsActiveTemperature,'OutputDataRate',humidityTemperatureODR);
        end
        
      function varargout = readSensorDataHook(obj)
            % when status is enabled, status register
            % needs to be read before other measurements. Making this change
            % in getActiveOutputsImpl to read the status first will result in
            % status coming on top of the block display, hence overloading
            % the readSensorDataHook
            timestamp = 0;
            idx = 0;
            if obj.IsStatus
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
                ['image(imread(fullfile(matlabshared.sensors.internal.getSensorRootDir,''resources'',''humiditySensorImage.jpg'')),''center'');', newline], ...
                ['text(52,12,' [''' ' 'HTS221' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end
        
        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "OutputDataRate"
                    flag = ~(obj.IsActiveHumidity||obj.IsActiveTemperature);
            end
        end
        
        function validatePropertiesImpl(obj)
            % Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveHumidity && ~obj.IsActiveTemperature && ~obj.IsStatus
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl()
            txtString = ['Measure relative humidity and ambient temperature.',newline,...
                'The block outputs relative humidity as a double in (%), ambient temperature as a double in (',char(0176),'C) and status of the values as a [1x2] vector whose values can be -1 if sensor is not selected, 0 if data read is new and 1 if data read is not new.'];
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'HTS221 Humidity Sensor','Text',txtString,'ShowSourceLink',false);
        end
        
        function groups = getPropertyGroupsImpl
            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C Address','IsGraphical',false);
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress});
            % Select outputs
            HumidityProp = matlab.system.display.internal.Property('IsActiveHumidity', 'Description', 'Humidity (%)');
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description', ['Temperature (',char(0176),'C)']);
            statusProp= matlab.system.display.internal.Property('IsStatus','Description', 'Status');
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {HumidityProp, temperatureProp,statusProp});
            % Pressure
            humidityTemperatureODR = matlab.system.display.internal.Property('OutputDataRate', 'Description', 'Output data rate(ODR)');
            humiditySettings = matlab.system.display.Section(...
                'Title','',...
                'PropertyList',{humidityTemperatureODR});
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {SampleTimeProp});
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Parameters',...
                'Sections', [i2cProperties,selectOutputs,humiditySettings,sampleTimeSection]);
            groups=MainGroup;
        end
    end
end