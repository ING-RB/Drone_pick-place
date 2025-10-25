classdef (Hidden, Abstract) MultiStreamingUtilities < matlabshared.sensors.internal.Accessor
    
    % This class provides the utility functions to be used by sensors to
    % facilitate single and multiple sensor streaming workflow. This should
    % be inherited by hardware class
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Access = {?matlabshared.sensors.internal.Accessor})
        StreamingObjects = {};
        NumOfStreamingObject = 0;
        SensorsRegistered = false;
        isStreaming = false;
    end
    
    properties(SetObservable, Access = {?matlabshared.sensors.internal.Accessor})
        RegisterStreamingObjectsEvent;
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % Codegen redirector class. During codegen the current class
            % will willbe replaced by the following class
            name = 'matlabshared.sensors.coder.matlab.MultiStreamingUtilities';
        end
    end
    
    methods(Access = {?matlabshared.sensors.internal.Accessor})
        
        function protocolObj = getProtocolObject(obj)
            % Returns the protocol object used by hardware object to
            % communicate with hardware
            protocolObj = getProtocolObjectHook(obj);
        end
        
        function registerStreamingObjects(obj,streamingObjectHandle)
            % Store the handle of streaming object.
            obj.NumOfStreamingObject =  obj.NumOfStreamingObject+1;
            obj.StreamingObjects{obj.NumOfStreamingObject} = streamingObjectHandle;
        end
        
        function unRegisterStreamingObjects(obj)
            obj.StreamingObjects = {};
            obj.NumOfStreamingObject  = 0;
            obj.SensorsRegistered = false;
        end
        
        function startStreamingAllObjects(obj,streamingObjectHandle)
            % Start streaming of one sensor should start streaming of all
            % sensors
            IOProtocoltimeout = [];
            readMode = [];
            % All the Streaming Objects should have same Read Mode
            for i=1:obj.NumOfStreamingObject
                readMode = [readMode, obj.StreamingObjects{i}.ReadMode];
            end
            if(numel(unique(readMode))>1)
                error(message('matlab_sensors:general:differentReadModeProperty'));
            end
            % Start Streaming Configuration
            try
                protocolObj = obj.getProtocolObject();
                setIgnoreOnetimeConfig(protocolObj, 0);
                setFlushBufferOnDemandWhileStreaming(protocolObj,1);
                startConfigureStreaming(protocolObj);
                % Record Requests of all the streaming Objects
                for i= 1:obj.NumOfStreamingObject
                    obj.StreamingObjects{i}.recordStreamingRequest;
                    if (obj.StreamingObjects{i}~= streamingObjectHandle)
                        % Except for the triggering object, call the
                        % setup function for other which will ensure the
                        % objects get locked so that non tunable
                        % properties cannot be changed afterwards
                        obj.StreamingObjects{i}.setup;
                    end
                    % SamplesPerRead used in IO Protocol for GPS is a very
                    % high value so as to avoid loss of samples.Determine
                    % the IOProtocol timeout from other streaming objects
                    if(~isa(obj.StreamingObjects{i},'sensors.internal.gpsdev'))
                        IOProtocoltimeout(end+1) = 2*max(obj.StreamingObjects{i}.SampleRate.*obj.StreamingObjects{i}.SamplesPerRead);
                    end
                    if(i==2)
                        setIgnoreOnetimeConfig(protocolObj, 1);
                    end
                end
            catch ME
                stopConfigureStreaming(protocolObj);
                releaseAllStreamingObjects(obj,streamingObjectHandle);
                unRegisterStreamingObjects(obj);
                throwAsCaller(ME);
            end
            % Stop Configuration and start Streaming
            setIgnoreOnetimeConfig(protocolObj, 0);
            stopConfigureStreaming(protocolObj);
            enableTimestamp(protocolObj,1);
            try
                startStreaming(protocolObj);
                obj.isStreaming = true;
            catch ME
                obj.isStreaming = false;
                throwAsCaller(ME);
            end
            % Set the default time out
            if(isempty(IOProtocoltimeout))
                % If there is a gps Object, keep the timout values as
                % default value which is 10;
                IOProtocoltimeout = 10;
            else
                IOProtocoltimeout = max(IOProtocoltimeout);
            end
            setIOProtocolTimeout(protocolObj,IOProtocoltimeout)
        end
        
        function releaseAllStreamingObjects(obj,streamingObjectHandle)
            % Release of one streaming Object will release all the
            % streaming objects
            protocolObj = obj.getProtocolObject();
            setIgnoreOnetimeConfig(protocolObj, 0);
            stopStreaming(protocolObj);
            obj.isStreaming = false;
            if(~isempty(obj.StreamingObjects))
                for i=1:obj.NumOfStreamingObject
                    if (obj.StreamingObjects{i}~= streamingObjectHandle)
                        obj.StreamingObjects{i}.release;
                    end
                end
            end
        end
        
        function dequeueStreamingSensorData(obj)
            % This will dequeue data from IO Protocol corresponding to all sensors.
            protocolObj = obj.getProtocolObject();
            for i=1:obj.NumOfStreamingObject
                if(isa(obj.StreamingObjects{i},'matlabshared.sensors.sensorBase'))
                    for j=1:length(obj.StreamingObjects{i}.UniqueIds)
                        dequeueStreamedDataAll(protocolObj,obj.StreamingObjects{i}.UniqueIds(j));
                    end
                end
            end
        end
    end
    
    methods(Access = protected)
        function protocolObj = getProtocolObjectHook(obj)
            % This method returns the Protocol object used by hardware
            % classs for all hwsdk based targets. For other targets, this
            % hook must be overloaded.
            if isa(obj, 'matlabshared.hwsdk.controller')
                protocolObj = obj.Protocol;
            else
                error(message('matlab_sensors:general:functionMissing', 'getProtocolObjectHook'));
            end
        end
    end
end