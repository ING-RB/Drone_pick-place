classdef LIS3MDLBlock < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for LIS3MDL.
    %<a href="https://www.st.com/resource/en/datasheet/lis3mdl.pdf">Device Datasheet</a>
    %Copyright 2021-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
         SensorName = "LIS3MDL";
    end

    properties(Nontunable)
        I2CModule=''
        I2CAddress = '0x1E'
        MagnetometerRange = '+/- 400 uT'
        MagnetometerODR = '10 Hz'
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Hidden, Constant)
        MagnetometerRangeSet = matlab.system.StringSet({'+/- 400 uT','+/- 800 uT','+/- 1200 uT','+/- 1600 uT'});
        MagnetometerODRSet = matlab.system.StringSet({'0.625 Hz','1.25 Hz','2.5 Hz','5 Hz','10 Hz','20 Hz','40 Hz','80 Hz','155 Hz','300 Hz','560 Hz','1000 Hz'});
        I2CAddressSet = matlab.system.StringSet({'0x1E','0x1F'});
    end

    properties(Nontunable)
        IsActiveMagnetometer (1, 1) logical = true;
        IsActiveTemperature (1, 1) logical = true;
        IsStatus (1, 1) logical=true;
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveMagnetometer + obj.IsActiveTemperature + obj.IsStatus);
            count = 1;
            if obj.IsActiveMagnetometer
                out{count} = matlabshared.sensors.simulink.internal.MagneticField;
                count = count + 1;
            end
            if obj.IsActiveTemperature
                out{count} = matlabshared.sensors.simulink.internal.Temperature;
                count = count + 1;
            end
            if obj.IsStatus
                out{count} =matlabshared.sensors.simulink.internal.Status;
                out{count}.OutputSize = [1, 3];
                out{count}.OutputDataType = 'uint8';
            end
        end

        function createSensorObjectImpl(obj)
            coder.extrinsic('matlabshared.sensors.simulink.internal.getNumericValue');
            numericValue = coder.const(@matlabshared.sensors.simulink.internal.getNumericValue,obj.MagnetometerODR);
            magODR =  numericValue;
            obj.SensorObject = sensors.internal.lis3mdl(obj.HwUtilityObject, "I2CAddress", ...
                obj.I2CAddress, ...
                "Bus",obj.I2CBus,'IsActiveMagnetometer',obj.IsActiveMagnetometer,'IsActiveTemperature',obj.IsActiveTemperature,'MagnetometerODR',magODR,'MagnetometerRange',obj.MagnetometerRange);
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
            magoffsetx = 'accoffsetx = 23;';
            magoffsety = 'accoffsety = 15;';
            maskimagemagnet = [...
                ['r = 0.15*100;' char(10)]...
                [magoffsetx char(10)]...
                [magoffsety char(10)]...
                ['offsetx = 20+accoffsetx;' char(10)]...
                ['offsety = 35+accoffsety;' char(10)]...
                ['theta = linspace(0,2*pi);' char(10)]...
                ['x = r*cos(theta) + offsetx;' char(10)]...
                ['y = r*sin(theta) + offsety;' char(10)]...
                ['plot(x,y);' char(10)]...
                ['u1 = [offsetx-r/4 offsetx offsetx+r/4];' char(10)]...
                ['u2 = [offsety offsety+r-2     offsety];' char(10)]...
                ['plot(u1,u2);' char(10)]...
                ['d1 = [offsetx-r/4 offsetx offsetx+r/4];' char(10)]...
                ['d2 = [offsety offsety-r+2 offsety];' char(10)]...
                ['patch(d1,d2,[0 0 0]);' char(10)]...
                ];
            maskDisplayCmds = [ ...
                ['color(''white'');',newline],...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...
                ['text(38, 92, ','''',obj.Logo,'''',',''horizontalAlignment'', ''right'');',newline],...
                ['color(''black'');',newline], ...
                [maskimagemagnet char(10)] ...
                ['text(52,12,' [''' ' 'LIS3MDL' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "MagnetometerRange"
                    flag = ~obj.IsActiveMagnetometer;
                case "MagnetometerODR"
                    flag = ~obj.IsActiveMagnetometer;
            end
        end

        function validatePropertiesImpl(obj)
            %Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveMagnetometer  && ~obj.IsActiveTemperature && ~obj.IsStatus
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            txtString = ['Measure magnetic field along X, Y and Z axis and measure temperature. ',...
                'The block outputs magnetic field values as a [1X3] vector of double values in ' char(181) 'T' ...
                ', temperature value in ',char(0176),'C, Magnetic Field status of the values [X, Y, Z] as a [1x3] vector where 0 indicates that the data read is new and 1 indicates that data read is not new.'];
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'LIS3MDL Magnetometer Sensor','Text',txtString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl
            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule, i2cAddress});
            % Select outputs
            magneticFieldProp = matlab.system.display.internal.Property('IsActiveMagnetometer', 'Description', 'Magnetic field (µT)');
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description', ['Temperature (',char(0176),'C)']);
            statusProp= matlab.system.display.internal.Property('IsStatus','Description', 'Status');
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {magneticFieldProp, temperatureProp,statusProp});
            % Magnetometer
            magnetometerRange = matlab.system.display.internal.Property('MagnetometerRange', 'Description', 'Magnetometer range');
            magnetometerODR = matlab.system.display.internal.Property('MagnetometerODR', 'Description', 'Magnetometer output data rate');
            magnetometerSettings = matlab.system.display.Section(...
                'Title','Advanced settings',...
                'PropertyList',{magnetometerRange, magnetometerODR});
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {SampleTimeProp});
            % Form the group of sections
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Main',...
                'Sections', [i2cProperties,selectOutputs,sampleTimeSection]);

            AdvancedGroup = matlab.system.display.SectionGroup(...
                'Title','Advanced',...
                'Sections',  magnetometerSettings);
            groups=[ MainGroup, AdvancedGroup];
        end
    end
end