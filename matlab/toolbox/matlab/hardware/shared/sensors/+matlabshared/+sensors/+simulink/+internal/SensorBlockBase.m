classdef SensorBlockBase < matlab.System & matlabshared.sensors.simulink.internal.BlockSampleTime &...
        matlabshared.sensors.simulink.internal.SimulinkStreamingUtilities & ...
        matlabshared.sensors.internal.Accessor
    %SENSORBLOCKBASE class is the parent classes for sensor block

    %   Copyright 2020-2024 The MathWorks, Inc.

    %#codegen
    properties(Nontunable, SetAccess = protected, GetAccess = public, Hidden)
        HwUtilityObject % For the object where the peripheral dependent functionalities are implemented
        SensorObject
        BoardName;
    end

    properties(Hidden,Access=protected)
        % Initialize DDUX product, app component, and event key values
        Product = "ML";
        AppComponent = "ML_HWC";
        EventKey = "ML_HWC_SENSOR_INFO";
    end

    properties(Hidden,Constant)
        %Peripheral class position when stack is used in dataUpdateBlock
        SensorAPIClassPositionInStack = 2;
    end

    properties(Hidden, Nontunable)
        SampleRate
    end

    properties(Nontunable)
        IsActiveTimeStamp(1,1) logical = false
    end

    properties(Access = protected)
        IsIOEnable = 0;
        Logo = 'SENSORS'
    end

    properties(Abstract,Access = protected, Nontunable)
        PeripheralType;
    end

    properties(Access = protected, Abstract, Constant)
         SensorName
    end


    properties(Access = protected, Nontunable)
        NumOutputs;
        OutputModules;
        TimeStampDataType = 'double';
    end

    properties (Access = protected)
        CodegenStartTime;
        IsFirstStep = false;
    end

    methods(Abstract, Access = protected)
        createSensorObjectImpl(obj);
        getActiveOutputsImpl(obj);
    end

    methods(Access = public,Hidden)
        %This method responsible for logging the DDUX data by using the DDUX's logData method
        function dataUpdateBlockFunction(obj,functionName)
            if coder.target('MATLAB')
                try
                    interface = obj.PeripheralType;
                    matlabshared.sensors.coder.matlab.dduxUpdateBlock(obj.IsIOEnable,obj.SensorName,obj.BoardName,interface,obj.IOProtocolObj.StreamingModeOn,functionName); 
                catch
                end 
            end       
        end
    end

    methods(Access = protected)
        function setupImpl(obj)
            % Gets the target name from config set
            coder.extrinsic('matlabshared.sensors.simulink.internal.getTargetHardwareName');
            coder.extrinsic('matlabshared.sensors.coder.matlab.dduxUpdateBlock');
            obj.BoardName=coder.const(matlabshared.sensors.simulink.internal.getTargetHardwareName);
            % Get the filelocation of the SPKG specific files
            coder.extrinsic('matlabshared.sensors.simulink.internal.getTargetSpecificFileLocationForSensors');
            fileLocation = coder.const(@matlabshared.sensors.simulink.internal.getTargetSpecificFileLocationForSensors,obj.BoardName);
            obj.HwUtilityObject = matlabshared.sensors.simulink.internal.SensorBlockBase.getHardwareUtilityObject(fileLocation,obj.PeripheralType);

            if ~isempty(obj.HwUtilityObject)
                if coder.target('MATLAB') && matlabshared.svd.internal.isSimulinkIoEnabled()
                    obj.IsIOEnable = 1;
                    registerStreamingObject(obj,obj.HwUtilityObject.ProtocolObj);
                end
                if coder.target('rtw') || obj.IsIOEnable
                    setPeripheralSpecificProperties(obj);
                    createSensorObjectImpl(obj);
                    if coder.target('rtw')
                        ioenabled=0; %coder.extrinsic needs non-tuneable parameter to be passed as arguments.
                        coder.const(@matlabshared.sensors.coder.matlab.dduxUpdateBlock,ioenabled,obj.SensorName,obj.BoardName);
                    end   
                end
            end

            obj.NumOutputs = numel(getActiveOutputsImpl(obj));
            obj.OutputModules = getActiveOutputsImpl(obj);
            if obj.IsActiveTimeStamp
                obj.CodegenStartTime = cast(0,obj.TimeStampDataType);
            end
        end

        function varargout = stepImpl(obj,varargin)

            if ~isempty(obj.HwUtilityObject) && ((coder.target('rtw') || obj.IsIOEnable))
                values = cell(1,obj.NumOutputs);
                % If input values are there, do not configure streaming
                if nargin > 1
                    [values{:}] = readSensorDataHook(obj,varargin{:});
                    varargout = values;
                else
                    if coder.target('rtw') && obj.IsActiveTimeStamp && ~obj.IsFirstStep
                        obj.CodegenStartTime = getCurrentTimeImpl(obj.HwUtilityObject, obj.TimeStampDataType);
                        obj.IsFirstStep = true;
                    end
                    startSimulinkStreaming(obj);
                    values = cell(1,obj.NumOutputs);
                    if obj.IsActiveTimeStamp
                        [values{:},timestamp] = readSensorDataHook(obj);
                        if obj.IsIOEnable
                            timestamp = getTimestampInIO(obj,timestamp,obj.TimeStampDataType);
                        else
                            timestamp = getCurrentTimeImpl(obj.HwUtilityObject, obj.TimeStampDataType)-obj.CodegenStartTime;
                        end
                        varargout = {values{:},timestamp};
                    else
                        [values{:},timestamp] = readSensorDataHook(obj);
                        varargout = values;
                    end
                    checkForOverruns(obj,timestamp);
                end
            else
                outputSize = cell(1,obj.NumOutputs);
                [outputSize{:}] = getOutputSizeImpl(obj);
                for i = 1:obj.NumOutputs
                    varargout{i} = cast(zeros(outputSize{i}), obj.OutputModules{i}.OutputDataType);
                end
                if obj.IsActiveTimeStamp
                    varargout{i+1} = cast(0, obj.TimeStampDataType);
                end
            end

        end

        function releaseImpl(obj)
            if coder.target('MATLAB')
                if obj.IsIOEnable && ~isempty(obj.SensorObject)
                    release(obj.SensorObject);
                    deleteStreamingUtilities(obj);
                    obj.SensorObject = [];
                    closeIOClient(obj.HwUtilityObject);
                    obj.HwUtilityObject = [];
                end
            end
        end

        function sts = getSampleTimeImpl(obj)
            sts = getSampleTimeImpl@matlabshared.sensors.simulink.internal.BlockSampleTime(obj);
        end

        function varargout = readSensorDataHook(obj)
            % Overload this method if a custom read/step is required.
            if obj.NumOutputs>0
                for i = 1:obj.NumOutputs
                    [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                end
            else
                i=0;
            end
            varargout{i+1} = timestamp(end);
        end
    end

    methods (Static, Access = protected)
        function hwObject = getHardwareUtilityObject(fileLocation,peripheral)
            coder.extrinsic('which');
            coder.extrinsic('error');
            coder.extrinsic('message')
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
                hwObject = funcHandle(peripheral);
                assert(isa(hwObject,'matlabshared.sensors.simulink.internal.SensorSimulinkBase'),message('matlab_sensors:general:invalidHwObjSensorSimulink'));
            else
                hwObject = '';
            end
        end

        function flag = showSimulateUsingImpl
            flag = false;
        end

        function simMode = getSimulateUsingImpl
            simMode = "Interpreted execution";
        end
    end

    methods(Access = protected)
        function N = getNumInputsImpl(~)
            % Specify number of System inputs
            N = 0;
        end

        function N = getNumOutputsImpl(obj)
            % Specify number of System outputs
            modules = getActiveOutputsImpl(obj);
            N = numel(modules);
            if obj. IsActiveTimeStamp
                N=N+1;
            end
        end

        function [varargout] = getOutputNamesImpl(obj)
            % Return output Port names for System block
            sensorModules = getActiveOutputsImpl(obj);
            for i=1:numel(sensorModules)
                varargout{i} = sensorModules{i}.OutputName;
            end
            if obj. IsActiveTimeStamp
                varargout{i+1} = 'TimeStamp';
            end
        end

        function varargout = getOutputSizeImpl(obj)
            % Return size for each output Port
            sensorModules = getActiveOutputsImpl(obj);
            for i = 1:numel(sensorModules)
                varargout{i} = sensorModules{i}.OutputSize;
            end
            if obj. IsActiveTimeStamp
                varargout{i+1} = [1,1];
            end
        end

        function varargout = getOutputDataTypeImpl(obj)
            % Return data type for each output Port
            sensorModules = getActiveOutputsImpl(obj);
            for i=1:numel(sensorModules)
                varargout{i} = sensorModules{i}.OutputDataType;
            end
            if obj. IsActiveTimeStamp
                varargout{i+1} = obj.TimeStampDataType;
            end
        end

        function varargout = isOutputComplexImpl(~)
            % Return true for each output Port with complex data
            for i =1:nargout
                varargout{i} = false;
            end
        end

        function varargout = isOutputFixedSizeImpl(~)
            % Return true for each output Port with fixed size
            for i = 1:nargout
                varargout{i} = true;
            end
        end

        function setPeripheralSpecificProperties(obj)
            switch obj.PeripheralType
                case 'I2C'
                    if isa(obj,'matlabshared.sensors.simulink.internal.I2CSensorBase')
                        setValidatedI2CBus(obj);
                    end
                case 'SPI'
                    if isa(obj,'matlabshared.sensors.simulink.internal.SPISensorBase')
                        setValidatedSPIslaveselect(obj);
                    end
                otherwise
            end
        end
    end
    methods
        function readPeripheralValues(obj)
            readSensorDataHook(obj);
            % Flag to  differentiate between readRegister calls during streaming
            % configuration and actual streaming operations.
            if isa(obj.SensorObject,'matlabshared.sensors.sensorBoard')
                for i = 1:numel(obj.SensorObject.SensorObjects)
                    obj.SensorObject.SensorObjects{i}.Device.OnDemandFlag = 0;
                end
            else
                obj.SensorObject.Device.OnDemandFlag = 0;
            end
        end
    end
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            % QueueSizeFactor, is a hidden parameter for frame based streaming. Only required for
            % sensor which give frame outputs using 'Frame' block
            queueSizeFactor = matlab.system.display.internal.Property('QueueSizeFactor', 'Description', '','IsGraphical',false);
            % Since all targets doesnt support time stamp output, hide it
            % by default. Enable this only for the targets which uses
            % timestamp output in the target specific sensor code
            isActiveTimeStamp = matlab.system.display.internal.Property('IsActiveTimeStamp', 'Description', 'Timestamp (s)','IsGraphical',false);
            % Property list
            PropertyList = {queueSizeFactor,isActiveTimeStamp};
            % Create mask display
            groups = matlab.system.display.Section('PropertyList',PropertyList);
        end
    end
end