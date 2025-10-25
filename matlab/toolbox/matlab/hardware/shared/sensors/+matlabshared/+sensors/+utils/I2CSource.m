classdef I2CSource < matlab.System ...
       & coder.ExternalDependency ...
        & matlabshared.sensors.simulink.internal.I2CSensorBase ...
        & matlabshared.sensors.simulink.internal.BlockSampleTime
    
    % BLOCK_MASK_DESCR
    %#codegen
    %#ok<*EMCA>

    % Copyright 2022-2024 The MathWorks, Inc.
    
    properties
        PROPERTIES_TUNABLE
    end

    properties(Access = protected)
        Logo = 'SENSORS'
    end
    
    properties (Nontunable)
        PROPERTIES_NONTUNABLE
        I2CModule = '';
        I2CAddress = 0x29;
    end
    
    properties (Access = private)
        % Pre-computed constants.
        PROPERTIES_PRIVATE
    end
    
    properties(Nontunable, Access = protected)
        I2CBus;
    end

    methods
        % Constructor
        function obj = I2CSource(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
            VARIABLE_INIT
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj)
            setValidatedI2CBus(obj);
            if coder.target('rtw')
                % Call C-function implementing device initialization
                SETUP_CODER_CINCLUDE
                SETUP_CODER_CEVAL
            end
        end
        
        function STEP_RETURN_PARAMstepImpl(obj) 
            STEP_OUPUT_INIT
            if coder.target('rtw')
                % Call C-function implementing device output
                STEP_CODER_CEVAL
            end
        end
        
        function releaseImpl(obj)
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                RELEASE_CODER_CEVAL
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(obj)
            num = NUM_INPUT;
        end
        
        function num = getNumOutputsImpl(obj)
            num = NUM_OUTPUT;
        end
        
        function varargout = getOutputNamesImpl(obj)
            % Return output port names for System block
             OUTPUT_NAME
        end

        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            OUTPUT_FIXED
        end
        
        function varargout = isOutputComplexImpl(~)
            OUTPUT_COMPLEX
        end
        
        function varargout = getOutputSizeImpl(~)
            OUTPUT_SIZE
        end
        
        function varargout = getOutputDataTypeImpl(~)
            OUTPUT_DATATYPE
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
            icon = 'I2CSource';
            maskDisplayCmds = [ ...
                ['color(''white'');',...
                'plot([100,100,100,100]*1,[100,100,100,100]*1);',...
                'plot([100,100,100,100]*0,[100,100,100,100]*0);',...
                'color(''blue'');', ...
                ['text(38, 92, ','''',obj.Logo,'''',',''horizontalAlignment'', ''right'');',newline],...
                'color(''black'');'], ...
                ['text(52,50,' [''' ' icon ''',''horizontalAlignment'',''center'');' newline]]   ...
                outport_label
                ];
        end

         function sts = getSampleTimeImpl(obj)
            sts = getSampleTimeImpl@matlabshared.sensors.simulink.internal.BlockSampleTime(obj);
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'I2CSource';
        end
        
        function tf = isSupportedContext(~)
            tf = true;
        end
        
        function updateBuildInfo(buildInfo, context)
                 % Update buildInfo
                %srcDir = fullfile(fileparts(mfilename('fullpath')),'src'); 
                coder.extrinsic('matlabshared.sensors.simulink.internal.getTargetHardwareName');
                targetname = coder.const(matlabshared.sensors.simulink.internal.getTargetHardwareName);
                % Get the filelocation of the SPKG specific files
                coder.extrinsic('matlabshared.sensors.simulink.internal.getTargetSpecificFileLocationForSensors');
                fileLocation = coder.const(@matlabshared.sensors.simulink.internal.getTargetSpecificFileLocationForSensors,targetname);
                coder.extrinsic('which');
                coder.extrinsic('error');
                coder.extrinsic('message');
                % target author will have to specify the file location in
                % function "'filelocation'.getTargetSensorUtilities"
                funcName = [fileLocation,'.getTargetSensorUtilities'];
                functionPath = coder.const(@which,funcName);
                % Only if the the path exist
                if ~isempty(fileLocation)
                    % internal error to see if the target author has provided
                    % the expected function in the specified file location
                    assert(~isempty(functionPath),message('matlab_sensors:general:FunctionNotAvailableSimulinkSensors','getTargetSensorUtilities'));
                    funcHandle = str2func(funcName);
                    hwUtilityObject = funcHandle('I2C');
                    assert(isa(hwUtilityObject,'matlabshared.sensors.simulink.internal.SensorSimulinkBase'),message('matlab_sensors:general:invalidHwObjSensorSimulink'));
                else
                    hwUtilityObject = '';
                end
                hwUtilityObject.updateBuildInfo(buildInfo, context);
                spkgrootDir = matlabshared.sensors.internal.getSensorRootDir;
                if contains(fileLocation,'Arduino','IgnoreCase',true)
                    buildInfo.addIncludePaths(fullfile(spkgrootDir,'thirdparty','3psensors','incForArduino'));
                else
                    buildInfo.addIncludePaths(fullfile(spkgrootDir,'thirdparty','3psensors','inc'));
                    addSourceFiles(buildInfo,'Arduino.cpp',fullfile(spkgrootDir,'thirdparty','3psensors','src'));
                    addSourceFiles(buildInfo,'Wire.cpp',fullfile(spkgrootDir,'thirdparty','3psensors','src'));
                end
                HEARDERPATHS
                SOURCEFILE
           
        end
    end
end
