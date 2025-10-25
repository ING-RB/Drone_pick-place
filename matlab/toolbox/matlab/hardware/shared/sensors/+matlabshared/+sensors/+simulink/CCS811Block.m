classdef CCS811Block < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for CCS811 .
    %<a href="https://www.sciosense.com/wp-content/uploads/2020/01/SC-001232-DS-2-CCS811B-Datasheet-Revision-2.pdf">Device Datasheet</a>

    %  Copyright 2021-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
         SensorName = "CCS811Block"
    end

    properties(Nontunable)
        I2CModule = ''
        I2CAddress = '0x5A'
        EnvironmentInput = 'Mask dialog'
        DriveMode = '1' % Drivemode is DataAcqusitionInterval %
        DataType = 'single'
        HumidityData = 50
        TemperatureData = 25
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x5A','0x5B'});
        DriveModeSet = matlab.system.StringSet({'0.25','1','10','60'});
        DataTypeSet = matlab.system.StringSet({'single','double'});
        EnvironmentInputSet = matlab.system.StringSet({'Mask dialog','External sensor'});
    end

    properties(Nontunable, Logical)
        IsActiveInterrupt = false;
    end

    methods
        function set.HumidityData(obj,value)
            obj.HumidityData = value;
        end

        function set.TemperatureData(obj,value)
            obj.TemperatureData = value;
        end
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,2+(~obj.IsActiveInterrupt));
            count = 1;
            objCO2=matlabshared.sensors.simulink.internal.EquivalentCarbondioxide;
            objCO2.OutputDataType=obj.DataType;
            out{count} = objCO2;
            count = count + 1;
            objTVOC = matlabshared.sensors.simulink.internal.TotalVolatileOrganicCompounds;
            objTVOC.OutputDataType=obj.DataType;
            out{count} = objTVOC;
            count = count + 1;
            if ~obj.IsActiveInterrupt
                objStatus = matlabshared.sensors.simulink.internal.Status;
                objStatus.OutputDataType = 'uint8';
                out{count} = objStatus;
            end
        end
        function out = getActiveInputsImpl(obj)
            out = cell(1,2);
            count = 1;
            objHumidity=matlabshared.sensors.simulink.internal.Humidity;
            out{count} = objHumidity;
            count = count + 1;
            objTemperature = matlabshared.sensors.simulink.internal.Temperature;
            out{count} = objTemperature;
        end
        function N = getNumInputsImpl(obj)
            % Specify number of System inputs
            if strcmp(obj.EnvironmentInput,'External sensor')
                modules = getActiveInputsImpl(obj);
                N = numel(modules);
            else
                N = 0;
            end
        end
        function createSensorObjectImpl(obj)
            obj.SensorObject = sensors.internal.ccs811(obj.HwUtilityObject, ...
                'Bus',obj.I2CBus,'I2CAddress',obj.I2CAddress,'DriveMode',obj.DriveMode,'IsActiveInterrupt',obj.IsActiveInterrupt,'EnvironmentInput',obj.EnvironmentInput,'HumidityData',obj.HumidityData,'TemperatureData',obj.TemperatureData,'DataType',obj.DataType);
        end
        function varargout = readSensorDataHook(obj,varargin)
            % When status is enabled, status register
            % needs to be read before other measurements. Making this change
            % in getActiveOutputsImpl to read the status first will result in
            % status coming on top of the block display, hence overloading
            % the readSensorDataHook
            numOutput = obj.getNumOutputsImpl();
            [outStatus,timestamp] = obj.OutputModules{end}.readSensor(obj);
            for i = 1:numOutput-1
                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj,varargin{:});
            end
            varargout{i+1} = outStatus;
            varargout{i+2} = timestamp;
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
            if strcmp(obj.EnvironmentInput,'External sensor')
                inport_label = ['port_label(''input'', 1, ''Humidity'');' 'port_label(''input'', 2, ''Temperature'');'];
            else
                inport_label = [];
            end
            maskDisplayCmds = [ ...
                ['color(''white'');',newline],...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...
                ['text(38, 92, ','''',obj.Logo,'''',',''horizontalAlignment'', ''right'');',newline],...
                ['color(''black'');',newline], ...
                ['text(60,50,' [''' ' 'CCS811' ''',''horizontalAlignment'',''right'');' newline]]   ...
                inport_label ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "BitRate"
                    flag = true;
                case "HumidityData"
                    if strcmp(obj.EnvironmentInput,'Mask dialog') == 1
                        flag = false;
                    else
                        flag = true;
                    end
                case "TemperatureData"
                    if strcmp(obj.EnvironmentInput,'Mask dialog') == 1
                        flag = false;
                    else
                        flag = true;
                    end
            end
        end

        function validateInputsImpl(obj,varargin)
            % Check if input is Numeric
            if strcmp(obj.EnvironmentInput,'External sensor') == 1
                for i= 1:nargin-1
                    validateattributes(varargin{i},{'numeric'},{'nonempty','nonnan','scalar'});
                end
            end
        end

    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            txtString = ['Measure equivalent carbon dioxide concentration (eCO2) and equivalent total volatile organic compound concentration (eTVOC) from CCS811 sensor.',newline,newline,...
                'The block outputs eCO2 and eTVOC values in units of ppm (parts per million) and ppb (parts per billion) respectively, along with the status of the measured values. Status is 0 if data read is new and 1 if data read is not new.',newline,newline,...
                'The block also accepts humidity (%) and temperature (',char(0176),'C) values, either from an external sensor via additional input ports or from the values that you specify.'];

            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'CCS811 Air Quality Sensor','Text',txtString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            interruptProp = matlab.system.display.internal.Property('IsActiveInterrupt', 'Description', 'Enable data ready interrupt');
            bitRate=matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            environmentalInput = matlab.system.display.internal.Property('EnvironmentInput','Description', 'Specify environmental conditions');
            humidityDataValue = matlab.system.display.internal.Property('HumidityData', 'Description', 'Humidity (%)');
            temperatureDataValue = matlab.system.display.internal.Property('TemperatureData', 'Description', ['Temperature (',char(0176),'C)']);
            driveMode = matlab.system.display.internal.Property('DriveMode', 'Description', 'Data acquisition interval (s)');
            dataType =  matlab.system.display.internal.Property('DataType', 'Description', 'Data type');
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,driveMode,environmentalInput,humidityDataValue,temperatureDataValue,interruptProp,bitRate,dataType});
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {SampleTimeProp});

            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Parameters',...
                'Sections', [i2cProperties,sampleTimeSection]);
            groups=[MainGroup];
        end
    end
end