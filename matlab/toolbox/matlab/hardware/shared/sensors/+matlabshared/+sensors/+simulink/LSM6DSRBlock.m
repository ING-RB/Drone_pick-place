classdef LSM6DSRBlock < matlabshared.sensors.simulink.internal.LSM6DSRAnd6DSOBlockBase
    % LSM6DSR 6 DOF IMU sensor.
    %
    % <a href="https://www.st.com/resource/en/datasheet/lsm6dsr.pdf">Device Datasheet</a>
    
    %   Copyright 2020-2022 The MathWorks, Inc.
    %#codegen
    properties(Access = protected, Constant)
        SensorName = "LSM6DSR";
    end

    properties(Nontunable)
        % LSM6DSR has a range upto 4000 dps
        GyroscopeRange = '250 dps'
    end
    
    properties(Hidden, Constant)
        GyroscopeRangeSet = matlab.system.StringSet({'125 dps','250 dps', '500 dps', '1000 dps', '2000 dps','4000 dps'});
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
            obj.SensorObject = lsm6dsr(obj.HwUtilityObject,"Bus",obj.I2CBus,'I2CAddress',obj.I2CAddress,...
                'isActiveAccel',obj.IsActiveAcceleration, 'isActiveGyro',obj. IsActiveAngularRate,'isActiveTemp',obj.IsActiveTemperature,...
                'AccelerometerRange',obj.AccelerometerRange, 'AccelerometerODR',accelODR,...
                'AccelSelectCompositeFilter', obj.AccelSelectCompositeFilter,  'AccelLPF2BW', obj.AccelLPF2BW,'AccelHPFBW', obj.AccelHPFBW,...
                'GyroscopeODR',gyroODR, 'GyroscopeRange',obj.GyroscopeRange,...
                'EnableGyroHPF',obj.EnableGyroHPF, 'GyroHPFBW',gyroHPFBW,'EnableGyroLPF',obj.EnableGyroLPF, 'GyroLPFBWMode',gyroLPFBWMode);
        end
        
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
                ['image(imread(fullfile(matlabshared.sensors.internal.getSensorRootDir,''+matlabshared'',''+sensors'',''+simulink'',''+internal'',''IMU_image.png'')),''center'');', newline] ...
                ['text(52,12,' [''' ' 'LSM6DSR' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl()     
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'LSM6DSR 6DOF IMU Sensor','Text',message('matlab_sensors:blockmask:lsm6dsMaskDescription').getString,'ShowSourceLink', false);
        end
    end
end