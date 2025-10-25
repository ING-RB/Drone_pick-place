classdef BME280Block < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for BME280 .
    %<a href="https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme280-ds002.pdf">Device Datasheet</a>
    %Copyright 2021-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
        SensorName = "BME280";
    end

    properties(Nontunable)
        I2CModule=''
        I2CAddress
        FilterMode='0';
        StandbyTime='0.5 ms';
        PressureOverSampling='1';
        HumidityOverSampling='1';
        TemperatureOverSampling='1';
        DataType = 'single'
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x76','0x77'});
        FilterModeSet = matlab.system.StringSet({'0','2','4','8','16'});
        StandbyTimeSet = matlab.system.StringSet({'0.5 ms','10 ms','20 ms','62.5 ms','125 ms','250 ms','500 ms','1000 ms'});
        PressureOverSamplingSet = matlab.system.StringSet({'1','2','4','8','16'});
        HumidityOverSamplingSet = matlab.system.StringSet({'1','2','4','8','16'});
        TemperatureOverSamplingSet = matlab.system.StringSet({'1','2','4','8','16'});
        DataTypeSet = matlab.system.StringSet({'single','double'});
    end

    properties(Nontunable)
        IsActiveHumidity (1, 1) logical = true;
        IsActivePressure (1, 1) logical = true;
        IsActiveTemperature (1, 1) logical = true;
        IsStatus (1, 1) logical = true;
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActivePressure+obj.IsActiveTemperature+obj.IsActiveHumidity+obj.IsStatus);
            count = 1;
            if obj.IsActivePressure
                objPrssr=matlabshared.sensors.simulink.internal.Pressure;
                if strcmp(obj.DataType,'single')
                    objPrssr.OutputDataType = 'single';
                end
                out{count} = objPrssr;
                count = count + 1;
            end
            if obj.IsActiveTemperature
                objTemp=matlabshared.sensors.simulink.internal.Temperature;
                if strcmp(obj.DataType,'single')
                    objTemp.OutputDataType = 'single';
                end
                out{count} = objTemp;
                count = count + 1;
            end
            if obj.IsActiveHumidity
                objHum=matlabshared.sensors.simulink.internal.Humidity;
                if strcmp(obj.DataType,'single')
                    objHum.OutputDataType = 'single';
                end
                out{count} = objHum;
                count = count + 1;
            end
            if obj.IsStatus
                out{count} =matlabshared.sensors.simulink.internal.Status;
            end
        end

        function createSensorObjectImpl(obj)
            obj.SensorObject = sensors.internal.bme280(obj.HwUtilityObject, ...
                "Bus",obj.I2CBus,'I2CAddress',obj.I2CAddress,'StandbyTime',obj.StandbyTime,'IsActivePressure',obj.IsActivePressure,'IsActiveTemperature',obj.IsActiveTemperature,'IsActiveHumidity',obj.IsActiveHumidity,'FilterMode',obj.FilterMode,'PressureOverSampling',obj.PressureOverSampling,'HumidityOverSampling',obj.HumidityOverSampling,'TemperatureOverSampling',obj.TemperatureOverSampling,'DataType',obj.DataType);
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
                ['image(imread(fullfile(matlabshared.sensors.internal.getSensorRootDir,''resources'',''pressureSensorImage.jpg'')),''center'');', newline], ...
                ['text(52,12,' [''' ' 'BME280' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "PressureOverSampling"
                    flag = ~obj.IsActivePressure;
                case "HumidityOverSampling"
                    flag = ~obj.IsActiveHumidity;
                case "TemperatureOverSampling"
                    flag = ~obj.IsActiveTemperature;
                case "FilterMode"
                    flag = ~(obj.IsActivePressure || obj.IsActiveTemperature);
                case "StandbyTime"
                    flag = ~(obj.IsActivePressure || obj.IsActiveTemperature || obj.IsActiveHumidity);
                case "BitRate"
                    flag = true;
            end
        end

        function validatePropertiesImpl(obj)
            % Validate related or interdependent property values
            % Check whether all outputs are disabled. In that case an error is
            % thrown asking user to enable atleast one output
            if ~obj.IsActivePressure && ~obj.IsActiveHumidity && ~obj.IsStatus && ~obj.IsActiveTemperature
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end

        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            txtString = ['Measure barometric air pressure, relative humidity, and ambient temperature from BME280 sensor.',newline,newline,...
                'The block outputs barometric air pressure in Pascal (Pa), relative humidity in %, and ambient temperature in ',char(0176),'C, along with the status of the measured values. Status is 0 if data read is new and 1 if data read is not new.'];
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'BME280 Environmental Sensor','Text',txtString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl
            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            bitRate=matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,bitRate});
            % Select outputs
            humidityProp = matlab.system.display.internal.Property('IsActiveHumidity', 'Description','Humidity (%)');
            PressureProp = matlab.system.display.internal.Property('IsActivePressure', 'Description','Pressure (Pa)');
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description', ['Temperature (',char(0176),'C)']);
            StatusProp= matlab.system.display.internal.Property('IsStatus','Description', 'Status');
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {PressureProp,temperatureProp,humidityProp,StatusProp});
            % Magnetometer
            filterModeProp=matlab.system.display.internal.Property('FilterMode','Description', 'Filter coefficient', 'Row', matlab.system.display.internal.Row.new);
            standbyTimeProp=matlab.system.display.internal.Property('StandbyTime','Description', 'Stand by time', 'Row', matlab.system.display.internal.Row.new);
            PressureOverSamplingProp=matlab.system.display.internal.Property('PressureOverSampling','Description', 'Pressure oversampling factor', 'Row', matlab.system.display.internal.Row.new);
            HumidityOverSamplingProp=matlab.system.display.internal.Property('HumidityOverSampling','Description', 'Humidity oversampling factor', 'Row', matlab.system.display.internal.Row.new);
            temperatureOverSamplingProp=matlab.system.display.internal.Property('TemperatureOverSampling','Description', 'Temperature oversampling factor', 'Row', matlab.system.display.internal.Row.new);
            environmentSettings = matlab.system.display.Section(...
                'Title','Advanced settings',...
                'PropertyList',{filterModeProp,standbyTimeProp,PressureOverSamplingProp,HumidityOverSamplingProp,temperatureOverSamplingProp},...
                'Type',matlab.system.display.SectionType.collapsiblepanel);
            dataType =  matlab.system.display.internal.Property('DataType', 'Description', 'Data type');
            dataTypeSection = matlab.system.display.Section('PropertyList', {dataType});
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {SampleTimeProp});
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Parameters',...
                'Sections', [i2cProperties,selectOutputs,environmentSettings,dataTypeSection,sampleTimeSection]);
            groups=MainGroup;
        end
    end
end