classdef LSM6DS3HBlock < matlabshared.sensors.simulink.LSM6DS3Block
    % LSM6DS3H 6 DOF IMU sensor.
    %
    % <a href="https://www.st.com/resource/en/datasheet/lsm6ds3h.pdf">Device Datasheet</a>
    
    %   Copyright 2020-2022 The MathWorks, Inc.
    %#codegen
    
    % w.r.t to the features currently supported LSM6DS3H is equivalent to
    % LSM6DS3
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
                ['image(imread(fullfile(matlabshared.sensors.internal.getSensorRootDir,''+matlabshared'',''+sensors'',''+simulink'',''+internal'',''IMU_image.png'')),''center'');', newline] ...
                ['text(52,12,' [''' ' 'LSM6DS3H' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'LSM6DS3H 6DOF IMU Sensor','Text',message('matlab_sensors:blockmask:lsm6dsMaskDescription').getString,'ShowSourceLink', false);
        end
    end
end