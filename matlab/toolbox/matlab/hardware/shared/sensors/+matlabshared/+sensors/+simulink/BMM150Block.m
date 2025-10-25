classdef BMM150Block < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for BMM150 .
    %<a href="https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmm150-ds001.pdf">Device Datasheet</a>
    %Copyright 2021-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
        SensorName = "BMM150";
    end

    properties(Nontunable)
        I2CModule=''
        I2CAddress='0x13'
        MagnetometerPreset='Low power'
        DataType = 'single'
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x10','0x11','0x12','0x13'});
        MagnetometerPresetSet = matlab.system.StringSet({'Low power','Regular','Enhanced','High accuracy'});
        DataTypeSet = matlab.system.StringSet({'single','double'});
    end

    properties(Nontunable)
        IsStatus (1, 1) logical = true;
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,1+obj.IsStatus);
            count = 1;
            objMag=matlabshared.sensors.simulink.internal.MagneticField;
            if strcmp(obj.DataType,'single')
                objMag.OutputDataType = 'single';
            end
            out{count} = objMag;
            count = count + 1;
            if obj.IsStatus
                out{count} =matlabshared.sensors.simulink.internal.Status;
                out{count}.OutputName = 'Magnetic field status';
                out{count}.OutputDataType = 'int8';
            end
        end

        function createSensorObjectImpl(obj)
            obj.SensorObject = sensors.internal.bmm150(obj.HwUtilityObject, ...
                "Bus",obj.I2CBus,'I2CAddress',obj.I2CAddress,'IsStatus',obj.IsStatus,'MagnetometerPreset',obj.MagnetometerPreset,'DataType',obj.DataType);
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
                ['text(52,12,' [''' ' 'BMM150' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "BitRate"
                    flag = true;
            end
        end

    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            txtString = ['Measure magnetic field along X, Y, and Z axis from BMM150 sensor.',newline,newline,...
                'The block outputs magnetic field values as a [1X3] vector in units of ' char(181) 'T, along with the status of the measured value. Status is 0 if data read is new and 1 if data read is not new.'];
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'BMM150 3DOF Magnetometer Sensor','Text',txtString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl
            % I2C Properties
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'I2C address');
            bitRate=matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,bitRate});
            % Select outputs
            statusProp= matlab.system.display.internal.Property('IsStatus','Description', 'Status');
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {statusProp});
            % Magnetometer
            magnetometerPreset = matlab.system.display.internal.Property('MagnetometerPreset','Description', 'Preset value');
            magnetometerSettings = matlab.system.display.Section(...
                'Title','Properties',...
                'PropertyList',{magnetometerPreset});
            dataType =  matlab.system.display.internal.Property('DataType', 'Description', 'Data type');
            dataTypeSection = matlab.system.display.Section('PropertyList', {dataType});
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {SampleTimeProp});
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Parameters',...
                'Sections', [i2cProperties,selectOutputs,magnetometerSettings,dataTypeSection,sampleTimeSection]);
            groups=MainGroup;
        end
    end
end