classdef BMP280Block < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for BMP280 .
    %<a href="https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp280-ds001.pdf">Device Datasheet</a>
    %Copyright 2021-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
         SensorName = "BMP280";
    end

    properties(Nontunable)
        I2CModule='';
        I2CAddress='0x76';
        FilterMode (1,:) char {matlab.system.mustBeMember(FilterMode,{'0','2','4','8','16'})} = '0';
        PressureSensitivityFactor (1,:) char {matlab.system.mustBeMember(PressureSensitivityFactor,{'2.62','1.31','0.66','0.33','0.16'})} = '2.62';
        TemperatureSensitivityFactor (1,:) char {matlab.system.mustBeMember(TemperatureSensitivityFactor,{'0.005','0.0025'})} = '0.005';
        DataType (1,:) char {matlab.system.mustBeMember(DataType,{'single','double','uint32'})} = 'double';
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x76','0x77'});
    end

    properties(Nontunable, Logical)
        IsActivePressure = true;
        IsActiveTemperature = true;
        IsStatus = true;
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActivePressure+obj.IsActiveTemperature+(obj.IsStatus&&obj.IsActivePressure));
            count = 1;
            if obj.IsActivePressure
                objPrssr=matlabshared.sensors.simulink.internal.Pressure;
                switch obj.DataType
                    case 'single'
                        objPrssr.OutputDataType = 'single';
                    case 'uint32'
                        objPrssr.OutputDataType = 'uint32';
                end
                out{count} = objPrssr;
                count = count + 1;
            end
            if obj.IsActiveTemperature
                objTemp=matlabshared.sensors.simulink.internal.Temperature;
                switch obj.DataType
                    case 'single'
                        objTemp.OutputDataType = 'single';
                    case 'uint32'
                        objTemp.OutputDataType = 'uint32';
                end
                out{count} = objTemp;
                count = count + 1;
            end
            if obj.IsStatus && obj.IsActivePressure
                out{count} =matlabshared.sensors.simulink.internal.Status;
            end
        end

        function createSensorObjectImpl(obj)
            obj.SensorObject = bmp280(obj.HwUtilityObject, ...
                "Bus",obj.I2CBus,'I2CAddress',obj.I2CAddress,'IsActivePressure',obj.IsActivePressure,'IsActiveTemperature',obj.IsActiveTemperature,'FilterMode',str2double(obj.FilterMode),'PressureSensitivityFactor',str2double(obj.PressureSensitivityFactor),'TemperatureSensitivityFactor',str2double(obj.TemperatureSensitivityFactor),'DataType',obj.DataType);
        end

        function varargout = readSensorDataHook(obj)
            timestamp = 0;
            for i = 1:obj.NumOutputs
                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
            end
            idx = i;
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
                ['text(52,12,' [''' ' 'BMP280' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "PressureSensitivityFactor"
                    flag = ~obj.IsActivePressure;
                case "TemperatureSensitivityFactor"
                    flag = ~obj.IsActiveTemperature;
                case "FilterMode"
                    flag = ~(obj.IsActivePressure || obj.IsActiveTemperature);
                case "BitRate"
                    flag = true;
                case "IsStatus"
                    flag = ~obj.IsActivePressure;
            end
        end

        function validatePropertiesImpl(obj)
            % Validate related or interdependent property values
            % Check whether all outputs are disabled. In that case an error is
            % thrown asking user to enable atleast one output
            if ~obj.IsActivePressure && ~(obj.IsStatus&&obj.IsActivePressure) && ~obj.IsActiveTemperature
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end

        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            txtString = ['Measure barometric air pressure and ambient temperature from BMP280 sensor. Block is operating in normal mode with a standby time of 0.5 msec.',newline,newline,...
                'The block outputs barometric air pressure in Pascal (Pa), and ambient temperature in ',char(0176),'C, along with the status of the measured values. Status is 0 if data read is new and 1 if data read is not new.',newline,newline,...
                'When datatype is uint32, temperature output is scaled by a factor of 100.'];
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'BMP280 Pressure Sensor','Text',txtString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl
            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            bitRate=matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,bitRate});
            % Select outputs
            PressureProp = matlab.system.display.internal.Property('IsActivePressure', 'Description','Pressure (Pa)');
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description', ['Temperature (',char(0176),'C)']);
            StatusProp= matlab.system.display.internal.Property('IsStatus','Description', 'Status');
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {PressureProp,temperatureProp,StatusProp});
            % Magnetometer
            filterModeProp=matlab.system.display.internal.Property('FilterMode','Description', 'Filter coefficient', 'Row', matlab.system.display.internal.Row.new);
            filterModeSettings = matlab.system.display.Section(...
                'Title','IIR filter settings',...
                'PropertyList',{filterModeProp});
            iirfilterFormula = matlab.system.display.Image('file','filtercoefficentformula.png','Label','Latest measurement calculation when filter is enabled','Description','','Placement','last');
            filterModeSettings.Image = iirfilterFormula;
            PressureOverSamplingProp=matlab.system.display.internal.Property('PressureSensitivityFactor','Description', 'Pressure sensitivity factor (Pa)', 'Row', matlab.system.display.internal.Row.new);
            temperatureOverSamplingProp=matlab.system.display.internal.Property('TemperatureSensitivityFactor','Description', ['Temperature sensitivity factor (',char(0176),'C)'], 'Row', matlab.system.display.internal.Row.new);
            environmentSettings = matlab.system.display.Section(...
                'Title','Sensitivity',...
                'PropertyList',{PressureOverSamplingProp,temperatureOverSamplingProp});
            dataType =  matlab.system.display.internal.Property('DataType', 'Description', 'Data type');
            dataTypeSection = matlab.system.display.Section('PropertyList', {dataType});
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {SampleTimeProp});
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Parameters',...
                'Sections', [i2cProperties,selectOutputs,filterModeSettings,environmentSettings,dataTypeSection,sampleTimeSection]);
            groups=MainGroup;
        end
    end
end