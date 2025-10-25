classdef(Sealed,Hidden) gpsHardware < matlab.System & ...
        matlabshared.sensors.internal.Accessor
    
    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties(Access = protected, Hidden)
        TargetSamplesPerFrame = 1;
        StreamingObjRegister % listener object. 
    end
    
    properties(Access = private)
        IsFirstRead = 0; % This property is to identify the first read.This is used for flushing the target Buffer.
        CallingObj
        StoredData=''; % This is to store the partial data recieved for On-Demand
        timeForSecondRMCSet = 0;
        timeForFirstRMCSet = 0;
        streaming = 0;
        startMsg = "RMC";
        startMsgChanged = 0;
        protocolObj;
    end
    
    properties(Hidden)
        TargetSerialBufferSize; % This property will be different for different boards
        Device;
        BytesToRead = 30;
        Parent;
        RateReadfromTarget = 40;
        UniqueIds;
        UpdateRate = [];
    end
    
    methods
        function obj =  gpsHardware(callingObj,Parent,streaming,SerialPort,BaudRate)
            obj.Parent = Parent;
            obj.protocolObj = obj.Parent.getProtocolObject();
            obj.streaming = streaming;
            if matlabshared.sensors.isTraceEnabled(obj.Parent)
                error(message('matlab_sensors:general:unSupportedCommandLogs','GPS'))
            end
            % If there is board specific implementation implement it in
            % this in this function
            getBoardSpecificPropertiesGPS(obj.Parent,obj,SerialPort);
            obj.Device = obj.Parent.getDevice(obj.Parent,'SerialPort',SerialPort,'BaudRate',BaudRate,'TimeOut',0);
            if(obj.streaming == true)
                % Stores the handle in master class.In case of Multiple
                % Streaming Objects this is required to start streaming
                % simultaneously.
                obj.CallingObj = callingObj;
            end
            validateGpsData(obj);
            if isa(obj.Parent,'matlabshared.sensors.MultiStreamingUtilities')
                obj.StreamingObjRegister = event.proplistener(obj.Parent, obj.Parent.findprop( 'RegisterStreamingObjectsEvent'), 'PostSet',  @(~, ~)(obj.Parent.registerStreamingObjects(obj.CallingObj)));
            end
        end
    end
    
    methods(Access = protected)
        function obj = setupImpl(obj)
            if isa(obj.Parent, 'matlabshared.sensors.MultiStreamingUtilities')
                if obj.Parent.isStreaming
                    error(message('matlab_sensors:general:streamingInProgress'));
                else
                    if(obj.streaming == 1)
                        try
                            % The check is required, if someone explicitily
                            % calls setup, registration should not happen again
                            if   ~obj.Parent.SensorsRegistered
                                obj.Parent.RegisterStreamingObjectsEvent = 1; % Trigger the listeners, which will register all the sensor objects
                                obj.Parent.SensorsRegistered = true; % Once all the sensors are registered, make this flag true
                                startStreamingAllObjects(obj.Parent,obj.CallingObj);
                                % Once the streaming starts unregister all the objects registered
                                unRegisterStreamingObjects(obj.Parent);
                            end
                        catch ME
                            unRegisterStreamingObjects(obj.Parent);
                            throwAsCaller(ME);
                        end
                    end
                end
            end
            obj.IsFirstRead = 0;
        end
        
        function varargout = stepImpl(obj)
            RawGPSData =[];
            if(obj.streaming==1)
                processBufferedData(obj.protocolObj);
                % deqeue all the data available in IO protocol Buffer for
                % GPS
                [data,time] = dequeueStreamedDataAll(obj.protocolObj,obj.UniqueIds);
                if(obj.CallingObj.ReadMode == "latest")
                    % processBuffered data will decode and enqeue data for all
                    % UniqueIDs.This will decode sensor data and place it in IO protocol buffer.
                    % When next time user reads sensor data, user will get old
                    % data which is present in IO protocol buffer.In order to
                    % avoid this, after calling the function processBuffered, deqeue data
                    % corresponding to all unique IDs.
                    try
                        if  ~obj.Parent.SensorsRegistered
                            obj.Parent.RegisterStreamingObjectsEvent = 1; % Trigger the listeners, which will register all the sensor objects
                            obj.Parent.SensorsRegistered = true; % Once all the sensors are registered, make this flag true
                            dequeueStreamingSensorData(obj.Parent);
                            unRegisterStreamingObjects(obj.Parent);
                        end
                    catch ME
                        unRegisterStreamingObjects(obj.Parent);
                        throwAsCaller(ME);
                    end
                end
                if(data~=-1)
                    time = repelem(time,obj.BytesToRead);
                    if(~isempty(data))
                        % if data of size equal to BytestoRead is not available in buffer,
                        % target gives zeros, filter out the zeros.
                        noData = zeros(1,obj.BytesToRead);
                        RawGPSData = char(data(~ismember(data,noData)));
                        time = time(~ismember(data,noData));
                        % For first read,when there is data, initial
                        % bytes might be corrupted since target serial Buffer
                        % size is limited.
                        if(obj.IsFirstRead == 0)
                            if(numel(RawGPSData)>=obj.TargetSerialBufferSize)
                                RawGPSData = RawGPSData(obj.TargetSerialBufferSize:end);
                                time  = time(obj.TargetSerialBufferSize:end);
                            else
                                RawGPSData = [];
                            end
                            obj.IsFirstRead = 1;
                        end
                    end
                end
            else
                RawGPSData = readOnDemandGPSData(obj);
                time = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                time = repmat(time,size(RawGPSData));
            end
            varargout{1} = RawGPSData;
            varargout{2} = time;
        end
        
        function resetImpl(obj)
            % Clear all data stored in IO Protocol buffers as well as those
            % waiting in the transport layer buffer to be picked up.
            if(obj.streaming == 1)
                flushBuffers(obj.protocolObj);
            end
        end
        
        function releaseImpl(obj)
            if(obj.streaming == 1)
                if  obj.Parent.SensorsRegistered == false
                    % Listener is attached with RegisterObjects
                    % property. Trigger this only once when no
                    % sensors are registerd
                    obj.Parent.RegisterStreamingObjectsEvent = 1; % Trigger the listeners
                    obj.Parent.SensorsRegistered = true;
                    releaseAllStreamingObjects(obj.Parent,obj.CallingObj);
                    unRegisterStreamingObjects(obj.Parent);
                end
                obj.UniqueIds = [];
            end
        end
    end
    
    methods(Hidden)
        function showProperties(obj)
            fprintf('                         SerialPort: %d\t\n',obj.Device.SerialPort);
            fprintf('                           BaudRate: %d (bits/s)\n\n',obj.Device.BaudRate);
        end
        
        function flushBuffers(obj)
            if(obj.streaming == 1)
                flushBuffers(obj.protocolObj);
                clearTransportBuffer(obj.protocolObj);
            end
        end
        
        function delete(obj)
            if(obj.streaming == 1)
                if(isLocked(obj) && isvalid(obj))
                    release(obj);
                end
            end
            obj.Device = [];
            obj.StreamingObjRegister = [];
        end
        
        function writeBytes(obj,configmsg)
            if(obj.isLocked == 1 && obj.streaming)
                warning(message('matlab_sensors:general:configureGPSwhileLocked'));
            else
                obj.Device.write(configmsg);
                validateGpsData(obj)
            end
        end
        
        function recordStreamingRequest(obj)
            uniqueIdsBeforeConfig = obj.protocolObj.StoredUniqueId(bitget(obj.protocolObj.IsRawRead,1) == 1);
            % Streaming Rate of GPS depends on BaudRate.If multiple
            % streaming Objects are present same streaming rate is kept
            % for GPS to avoid performance degradation.
            getStreamingRateGPS(obj.Parent,obj);
            IOProtocolSPF = obj.CallingObj.SamplesPerRead*3000;
            try
                sciReceiveBytesInternal(obj.Device.SerialDriverObj,obj.protocolObj,obj.Device.SerialPort,obj.BytesToRead);
            catch ME
                stopConfigureStreaming(obj.protocolObj);
                obj.Device = [];
                throwAsCaller(ME);
            end
            obj.protocolObj.IOProtocolTimeoutThreshold = 2*obj.RateReadfromTarget*IOProtocolSPF+1;
            setRate(obj.protocolObj,1/obj.RateReadfromTarget);
            % Set the SPF value in IO Protocol.
            setSPFiOProtocol(obj.protocolObj, obj.TargetSamplesPerFrame);
            % setHostSamplesPerFrame(protocolObj,1000,obj.UniqueIds);
            uniqueIdsAfterConfig = obj.protocolObj.StoredUniqueId(bitget(obj.protocolObj.IsRawRead,1) == 1);
            % Find new uniqueIDs added
            obj.UniqueIds = setdiff(uniqueIdsAfterConfig, uniqueIdsBeforeConfig);
            setStreamingCallbackFunction(obj.protocolObj,@matlabshared.sensors.discardZeros);
            % The value 3000 is set just to avoid trashing the GPS data
            % points in IO protocol buffer for latest mode.
            setHostSamplesPerFrame(obj.protocolObj,IOProtocolSPF);
        end
    end
    
    
    methods( Access = private)
        function validateGpsData(obj)
            % The function checks if the data read from serial Device has
            % required NMEA sentences.
            rawData = '';
            timeForFirstRMC = 0;
            timeForSecondRMC = 0;
            idx = [];
            % Flush the initial bytes available. These bytes might be
            % accumulated from an older time instance and will cause
            % issues in the logic for calculating initial update rate
            bytesAvailable = obj.Device.NumBytesAvailable;
            [~,~] = sciReceiveBytesInternal(obj.Device.SerialDriverObj,obj.protocolObj,obj.Device.SerialPort,bytesAvailable);
            timeout = 5;
            ts = tic;
            while(numel(idx)<= 2 && toc(ts)< timeout)
                [data,status] = sciReceiveBytesInternal(obj.Device.SerialDriverObj, obj.protocolObj,obj.Device.SerialPort,obj.BytesToRead);
                if(status == 0)
                    rawData = [rawData,char(data)];
                end
                idx = strfind(rawData,"RMC");
                if(numel(idx) == 1 && obj.timeForFirstRMCSet == 0)
                    % time is taken here to get an approximate value of
                    % Update Rate during construction.
                    timeForFirstRMC = toc(ts);
                    obj.timeForFirstRMCSet = 1;
                elseif(numel(idx) > 1 && obj.timeForSecondRMCSet == 0)
                    timeForSecondRMC = toc(ts);
                    obj.timeForSecondRMCSet = 1;
                    break;
                end
            end
            if(~contains(rawData,"RMC") || ~contains(rawData,"GGA") || ~contains(rawData,"GSA"))
                error(message('matlab_sensors:general:validateGPS'));
            end
            obj.UpdateRate = timeForSecondRMC-timeForFirstRMC;
            obj.timeForFirstRMCSet = 0;
            obj.timeForSecondRMCSet = 0;
        end
        
        function unParsedData = readOnDemandGPSData(obj)
            % Remove the initial bytes that are available in target
            % buffer.This might contain partial data.
            bytesAvailable = obj.Device.NumBytesAvailable;
            if(bytesAvailable>round(obj.TargetSerialBufferSize/2))
                [~,~] = sciReceiveBytesInternal(obj.Device.SerialDriverObj,obj.protocolObj,obj.Device.SerialPort,bytesAvailable);
                obj.StoredData = '';
            end
            unParsedData = readGpsData(obj,obj.StoredData);
            % check if startMessage ID set is correct by comparing GGA time and RMC
            % time
            if obj.startMsgChanged == 0
                checkSync(obj,unParsedData);
            end
            % if start Message ID is changed
            if obj.startMsgChanged == 1
                unParsedData = readGpsData(obj,obj.StoredData);
                obj.startMsgChanged = 2;
            end
        end
        
        function rawData = readGpsData(obj,startData)
            startMsgIdx = [];
            otherMsgIdx = [];
            gsaIdx = [];
            timeOut = 5;
            bytesToRead = 32;% IO read appoximately takes 32 ms.Minimum Buffer size is 64 bytes on target.
            endChar = char(13);
            rawData = startData;
            startMsgID = ['\W[\w*]+',char(obj.startMsg)];
            if(obj.startMsg == "RMC")
                otherMsgId = "GGA";
            else
                otherMsgId ="RMC";
            end
            timer1 = tic;
            while(numel(startMsgIdx)<1 && toc(timer1)<=timeOut)
                % Read till RMC, GGA and GSA sentence are found.
                [data,status] = sciReceiveBytesInternal(obj.Device.SerialDriverObj, obj.protocolObj,obj.Device.SerialPort,  bytesToRead);
                if(status == 0)
                    % If data is returned status is 0
                    rawData = [rawData,char(data)];
                    startMsgIdx = regexp(rawData,startMsgID);
                end
                if numel(startMsgIdx) >= 1
                    rawData = rawData(startMsgIdx(1):end);
                    while(numel(otherMsgIdx)<1 || numel(gsaIdx)<1)
                        if(toc(timer1)>timeOut)
                            break;
                        end
                        % Read till RMC, GGA and GSA sentence are found.
                        [data,status] = sciReceiveBytesInternal(obj.Device.SerialDriverObj, obj.protocolObj,obj.Device.SerialPort,  bytesToRead);
                        if(status == 0)
                            % If data is returned status is 0
                            rawData = [rawData,char(data)];
                            otherMsgIdx = strfind(rawData,otherMsgId);
                            gsaIdx = strfind(rawData,"GSA");
                        end
                    end
                end
            end
            % Read till end of last sentence
            bytesToRead = 32;
            last_sentence = [];
            idx = [];
            timer2 = tic;
            while(numel(idx)<1 && toc(timer2)<timeOut)
                % Read data available in Buffer to get the end Character of
                % the sentence
                [data,status] = sciReceiveBytesInternal(obj.Device.SerialDriverObj, obj.protocolObj,obj.Device.SerialPort,bytesToRead);
                if(status == 0)
                    % If data is returned status is 0
                    last_sentence = [last_sentence,char(data)];
                    idx = strfind(last_sentence,endChar);
                    bytesToRead = 10;
                elseif(status == 32)
                    % if data is not available status returned is 32
                    bytesToRead = 10;
                else
                    % If requested number of bytes are not available, then
                    % status returned is number of bytes avaialble in the
                    % buffer.
                    bytesToRead = status;
                end
            end
            if(numel(startMsgIdx)<1 || numel(otherMsgIdx)<1 || numel(gsaIdx)<1 || numel(idx)<1)
                error(message('matlab_sensors:general:validateGPS'));
            end
            
            rawData = [rawData,last_sentence];
            idx = strfind(rawData,endChar);
            if(~isempty(idx))
                unParsedData = rawData(1:idx(end));
                if(numel(rawData)>idx(end))
                    % This could be part of next sentence, store it in the
                    % buffer
                    obj.StoredData = rawData(idx(end)+1:end);
                end
                rawData = unParsedData;
            end
        end
        
        function [rmcTime,ggaTime]=checkSync(obj,unParsedData)
            % This function contains minimal parsing to check
            % if the time of RMC and GGA are same, if not next sentence need to be read.
            ggaTime = NaT;
            rmcTime = NaT;
            try
                index = strfind(unParsedData,"RMC");
                commaIndex = strfind(unParsedData,",");
                DelimiterAfterRMC = commaIndex(commaIndex>index);
                DelimiterAftertime = DelimiterAfterRMC(2);
                rmcTime = unParsedData(DelimiterAfterRMC(1)+1:DelimiterAftertime-1);
                index = strfind(unParsedData,"GGA");
                commaIndex = strfind(unParsedData,",");
                DelimiterAfterGGA = commaIndex(commaIndex>index);
                DelimiterAftertime = DelimiterAfterGGA(2);
                ggaTime = unParsedData(DelimiterAfterGGA(1)+1:DelimiterAftertime-1);
                if ~isempty(rmcTime) && ~isempty(ggaTime)
                    if(~strcmp(ggaTime,rmcTime))
                        obj.startMsg = "GGA";
                        obj.startMsgChanged= 1;
                    else
                        obj.startMsgChanged= 3;
                    end
                end
            catch
            end
        end
    end
end
