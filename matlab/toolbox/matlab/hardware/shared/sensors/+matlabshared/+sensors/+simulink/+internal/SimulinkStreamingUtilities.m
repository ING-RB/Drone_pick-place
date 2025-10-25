classdef SimulinkStreamingUtilities < handle
    % The source blocks which require streaming should inherit from this
    % class. The method registerStreamingObject needs to be called from
    % setup of the driver block.startSimulinkStreaming needs to be called
    % from step of the driver block. The inherited classes should implement
    % recordingRequest which contains the APIs that needs to be streamed.

    % Copyright 2021-2024 The MathWorks, Inc.
    %#codegen
    properties(Access=protected)
        IOProtocolObj
        IsPacingEnabled
        PrevTimeStamp = 0;
        SampleTimeIO = 0;
        ActionOnOverrun = matlabshared.sensors.simulink.internal.ActionOnOverrun.warning;
        BlockName = '';
        OverrunThreshold = 1;
        TotalDataDrops = 0
        IsOverrunWarningThrown = false;
        IsConnectedIOEnable = false;
        StreamingEnabled = false;
        StartTime;
    end

    properties
        QueueSizeFactor = 3;
    end

    methods(Abstract)
        readPeripheralValues(obj);
    end

    methods
        function obj = SimulinkStreamingUtilities()
            coder.allowpcode('plain');
        end

        function set.QueueSizeFactor(obj,value)
            validateattributes(value, {'numeric','char','string'},{'nonempty'},'', 'Samples per frame');
            if ischar(value) || isstring(value)
                value = str2double(value);
            end
            % Check for scalar value after converting the value to numeric.
            % Check for scalar on character value will give incorrect
            % result. For.eg. '12', is not a scalar
            validateattributes(value, {'numeric'},{'scalar','>',0,'<',2^16,'nonnan'},'', 'Samples per frame');
            if value <3
                % Low queuesize factor affects performance hence keeping a
                % mininum of 3
                value = 3;
            end
            obj.QueueSizeFactor  = double(value);
        end
    end

    methods
        function registerStreamingObject(obj,IOProtocolObj)
            if coder.target('MATLAB')
                obj.IsConnectedIOEnable = matlabshared.svd.internal.isSimulinkIoEnabled;
                if obj.IsConnectedIOEnable
                    if isa(IOProtocolObj,'matlabshared.ioclient.IOProtocol')
                        obj.IOProtocolObj = IOProtocolObj;
                        obj.BlockName = ['''',getfullname(gcbh),''''];
                        if IOProtocolObj.IsOnDemandConnectedIO == false
                            obj.ActionOnOverrun = matlabshared.svd.internal.getActionOnOverrun;
                            sampleTimeStruct = getSampleTime(obj);
                            % The blocks with infinite sample time is
                            % expected to be used for one time setups
                            obj.SampleTimeIO = sampleTimeStruct.SampleTime;
                            isSource = isStreamingSourceBlock(obj);
                            if obj.SampleTimeIO ~= inf && isSource
                                obj.IOProtocolObj.StreamingObjects{end+1} = obj;
                                obj.StreamingEnabled = true;
                            end
                        end
                    else
                        IOProtocolObj.IsOnDemandConnectedIO = true;
                    end
                    obj.StartTime = datetime('now');
                end
            end
        end

        function unRegisterStreamingObject(obj)
            obj.IOProtocolObj.StreamingObjects = {};
        end

        function startSimulinkStreaming(obj)
            if coder.target('MATLAB') && obj.StreamingEnabled
                % Check if the target is already streaming, and if
                % target is supposed to stream (IsOnDemandConnectedIO
                % must be false) and if non -zero number of objects are
                % available to stream
                if ~isempty(obj.IOProtocolObj) && ~obj.IOProtocolObj.StreamingModeOn && ...
                        ~isempty(obj.IOProtocolObj.StreamingObjects) && ~obj.IOProtocolObj.IsOnDemandConnectedIO
                    try
                        obj.IOProtocolObj.startConfigureStreaming;
                        setSPFiOProtocol(obj.IOProtocolObj, 1); % Target SPF
                        setIOProtocolReadMode(obj.IOProtocolObj, 'latest');
                        for i=1:numel(obj.IOProtocolObj.StreamingObjects)
                            uniqueIdsBeforeConfig = obj.IOProtocolObj.StoredUniqueId;
                            obj.IOProtocolObj.StreamingObjects{i}.readPeripheralValues();
                            uniqueIdsAfterConfig = obj.IOProtocolObj.StoredUniqueId;
                            % Find new uniqueIDs added
                            uniqueIds = setdiff(uniqueIdsAfterConfig, uniqueIdsBeforeConfig);
                            hostSPF = ones(1,numel(uniqueIds));
                            setHostSamplesPerFrame(obj.IOProtocolObj, hostSPF);
                            setRate(obj.IOProtocolObj, obj.SampleTimeIO);
                            setQueueSizeFactor(obj.IOProtocolObj,obj.QueueSizeFactor);
                        end
                        unRegisterStreamingObject(obj);
                        obj.IOProtocolObj.stopConfigureStreaming;
                        obj.IOProtocolObj.enableTimestamp(1);
                    catch ME
                        unRegisterStreamingObject(obj);
                        obj.IOProtocolObj.stopConfigureStreaming;
                        throwAsCaller(ME);
                    end
                    try
                        if ~isempty(obj.IOProtocolObj.StoredUniqueId)
                            obj.IOProtocolObj.startStreaming;
                            flushBuffers(obj.IOProtocolObj);
                            if strcmpi(get_param(bdroot,'EnablePacing'),'on')
                                % For streaming, disable pacing so as to avoid
                                % potential issues with merging host timings and
                                % target timings
                                set_param(bdroot, 'EnablePacing', 'off');
                                % Store the Actual value of Pacing, so as to
                                % restore this value during end of simulation
                                obj.IsPacingEnabled = true;
                            end
                        end
                    catch ME
                        if obj.IsPacingEnabled
                            set_param(bdroot, 'EnablePacing', 'on');
                        end
                        switch ME.identifier
                            case 'ioserver:general:NotEnoughMemoryForBuffers'
                                error(message('svd:svd:NotEnoughMemoryToStream'));
                                % Need to modify the error to convey issue
                                % of channnel bandwidth
                            case 'ioserver:general:ServerSchedulerInOverrun'
                                error(message('svd:svd:InSufficientChannelBandwidth'));
                            otherwise
                                obj.IOProtocolObj.stopStreaming;
                                rethrow(ME);
                        end
                    end
                end
            end
        end

        function deleteStreamingUtilities(obj)
            if coder.target('MATLAB') && obj.StreamingEnabled
                if obj.ActionOnOverrun == matlabshared.devicedrivers.internal.ActionOnOverrun.warning && obj.IsOverrunWarningThrown == true
                    MSLDiagnostic('svd:svd:StreamingNumDataDrops',obj.BlockName,obj.TotalDataDrops).reportAsInfo;
                end
                if obj.IsPacingEnabled
                    set_param(bdroot, 'EnablePacing', 'on');
                end
                obj.StreamingEnabled = false;
                if isvalid(obj.IOProtocolObj) && ~isempty(obj.IOProtocolObj)
                    if obj.IOProtocolObj.StreamingModeOn == true
                        obj.IOProtocolObj.stopStreaming;
                        unRegisterStreamingObject(obj);
                    end
                end
            end
        end

        function delete(obj)
            deleteStreamingUtilities(obj);
        end

        function checkForOverruns(obj,timeStamp)
            if coder.target('MATLAB') && obj.StreamingEnabled
                if obj.IOProtocolObj.StreamingModeOn && ~isempty(timeStamp)
                    if obj.ActionOnOverrun == matlabshared.sensors.simulink.internal.ActionOnOverrun.warning
                        numSamplesLost = round(abs(((timeStamp - obj.PrevTimeStamp)/obj.SampleTimeIO)-1));
                        obj.PrevTimeStamp = timeStamp;
                        obj.TotalDataDrops = obj.TotalDataDrops + numSamplesLost;
                        if numSamplesLost > obj.OverrunThreshold && ~obj.IsOverrunWarningThrown
                            warning('off', 'backtrace');
                            MSLDiagnostic('svd:svd:StreamingDataDrop',obj.BlockName).reportAsWarning;
                            warning('on', 'backtrace');
                            obj.IsOverrunWarningThrown = true;
                        end
                    elseif obj.ActionOnOverrun == matlabshared.sensors.simulink.internal.ActionOnOverrun.error
                        numSamplesLost = ((timeStamp - obj.PrevTimeStamp)/obj.SampleTimeIO)-1;
                        obj.PrevTimeStamp = timeStamp;
                        obj.TotalDataDrops = obj.TotalDataDrops + numSamplesLost;
                        if numSamplesLost > obj.OverrunThreshold
                            try
                                error(message('svd:svd:StreamingDataDrop',obj.BlockName));
                            catch ME
                                throwAsCaller(ME);
                            end
                        end
                    end
                end
            end
        end
    end

    methods (Access = protected)
        function isStreamingSource = isStreamingSourceBlock(obj)
            % Check the number of input ports and output ports.A block can be
            % considered source, if number of input ports = 0 and number of output
            % ports > 0. The block is considered sink, if number of input
            % ports > 0;
            isStreamingSource = false;
            numInPorts = getNumInputs(obj);
            numOutPorts = getNumOutputs(obj);
            % Check if the block is source
            if numInPorts  == 0 && numOutPorts > 0
                isStreamingSource = true;
            end
            % Check if the source object is inheriting from
            % StreamingUtilities which will provide streaming
            % functionalities
            if ~isa(obj, 'matlabshared.devicedrivers.internal.SimulinkStreamingUtilities') && ...
                    ~isa(obj, 'matlabshared.sensors.simulink.internal.SimulinkStreamingUtilities')
                isStreamingSource = false;
            end
        end

        function timestamp = getTimestampInIO(obj,timestamp,varargin)
            if nargin>2
                datatype = varargin{1};
            else
                datatype = 'double';
            end
            if coder.target('MATLAB')
                % For streaming the IOprotocol APIs returns timestamp is
                % seconds, no need of additional code
                % For connected IO Polling, subtract the current time with
                % start time
                if isa(obj.IOProtocolObj,'matlabshared.ioclient.IOProtocol') && ~obj.IOProtocolObj.StreamingModeOn
                    timestamp = seconds(datetime('now')-obj.StartTime);
                end
                timestamp = cast(timestamp,datatype);
            else
                timestamp = cast(0,datatype);
            end
        end
    end
end