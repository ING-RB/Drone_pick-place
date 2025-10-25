classdef LSM6DSMBlock < matlabshared.sensors.simulink.LSM6DSLBlock
    % LSM6DSM 6 DOF IMU sensor.
    %
    % <a href="https://www.st.com/resource/en/datasheet/lsm6dsm.pdf">Device Datasheet</a>
    
    %   Copyright 2020-2022 The MathWorks, Inc.
    %#codegen
    
    % W.r.t to current features, lsm6dsm is same as lsm6dsl. Only changing the
    % mask text and images in this class
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
                ['text(52,12,' [''' ' 'LSM6DSM' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'LSM6DSM 6DOF IMU Sensor','Text',message('matlab_sensors:blockmask:lsm6dsMaskDescription').getString,'ShowSourceLink', false);
        end
    end
end