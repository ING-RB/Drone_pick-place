classdef ModelEventHandler < ros.internal.mixin.ROSInternalAccess & handle
    %This class is for internal use only. It may be removed in the future.

    %ModelEventHandler This class communicates with Presenter by exchanging
    %data using different events. This is interface between Presenter and
    %RosbagModel

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties
        EventObj
        DataSourceModelHandle
        AppSessionCacheModelHandle
    end

    methods
        function obj = ModelEventHandler(eventObj)
            % Set up reactions to events
            obj.EventObj = eventObj;

            addlistener(obj.EventObj, 'RosbagSelectedPM', @(~, eventData) loadRosbag(obj, eventData));
            addlistener(obj.EventObj, 'CurrentTimeChangedPM', @(~, eventData) reactToNewTime(obj, eventData));

            addlistener(obj.EventObj, 'DataSourcesRequiredPM', @(~, eventData) updateDataSources(obj, eventData));
            addlistener(obj.EventObj, 'MoveToNextMessagePM', @(~, eventData) nextMessage(obj, eventData));
            addlistener(obj.EventObj, 'DataRangeRequestedPM', @(~, eventData) extractDataRange(obj, eventData));
            addlistener(obj.EventObj, 'InputRosNetworkPM', @(~, eventData) getTopicInfoFromROSNetwork(obj, eventData));
            addlistener(obj.EventObj, 'UpdateFrameIdPM', @(~, eventData) updateSelectedFrame(obj, eventData));

            % App Session Cache related Events
            addlistener(obj.EventObj, 'CreateAppSessionCachePM', @(~, ~) createAppSessionCacheFile(obj));
            addlistener(obj.EventObj, 'UpdateAppSessionCachePM', @(~, eventData) updateAppSessionCacheFile(obj, eventData));
            addlistener(obj.EventObj, 'RequestAppSessionCacheDataPM', @(~, ~) returnCacheFileData(obj));
        end
    end

    methods
        function loadRosbag(obj, eventDataIn)
            %loadRosbag Load the rosbag information

            try
                obj.DataSourceModelHandle = ros.internal.RosbagModel(obj);
                [rosBag, bagTree] = loadRosbag(obj.DataSourceModelHandle, eventDataIn.Data.FilePath);
                obj.AppSessionCacheModelHandle = ros.internal.model.AppSessionCache(rosBag.FilePath);
                hasCache = obj.AppSessionCacheModelHandle.HasAppCache;
                if hasCache
                    cacheData = obj.AppSessionCacheModelHandle.CacheData;
                else
                    cacheData = [];
                    try
                        obj.createAppSessionCacheFile();
                    catch ME
                    end
                end
                error = '';
            catch ME
                error = ME;
                rosBag = '';
                bagTree = '';
                hasCache = false;
                cacheData = [];
            end
            eventDataOut = ros.internal.EventDataContainer(...
                struct('Rosbag', rosBag, ...
                'Tree', bagTree, 'Error', error, ...
                'HasCache', hasCache, 'CacheData', cacheData));
            notify(obj.EventObj, 'RosbagLoadedMP', eventDataOut);
        end

        function getTopicInfoFromROSNetwork(obj, eventDataIn)
            %getTopicInfoFromROSNetwork Fetch topic information from
            %network
            try
                hasCache = false;
                cacheData = [];
                if ~isempty(eventDataIn.Data)
                    %Creating new live connection.
                    rosNetworkInput = char(eventDataIn.Data.NetworkInput);
                    obj.DataSourceModelHandle = ros.internal.RosLiveTopicModel(eventDataIn.Data);

                    %Extract cache
                    obj.AppSessionCacheModelHandle = ros.internal.model.AppSessionCache(rosNetworkInput);
                    hasCache = obj.AppSessionCacheModelHandle.HasAppCache;
                    if hasCache
                        cacheData = obj.AppSessionCacheModelHandle.CacheData;
                    else
                        try
                            obj.createAppSessionCacheFile();
                        catch
                        end
                    end
                elseif ~isempty(obj.DataSourceModelHandle) && isequal(class(obj.DataSourceModelHandle),'ros.internal.RosLiveTopicModel')
                    obj.DataSourceModelHandle.updateTopicList();
                else
                    return
                end
                
                %Refreshing/Updating Topic list
                topicTree = obj.DataSourceModelHandle.TopicTree;
                topic = obj.DataSourceModelHandle.TopicNames; 
                type = obj.DataSourceModelHandle.TopicTypes;

                error = '';
            catch ME
                error = ME;
                topic = '';
                type = '';
                topicTree = '';
            end

            eventDataOut = ros.internal.EventDataContainer(...
                struct('Tree', topicTree, ...
                'Error', error, 'HasCache', hasCache, 'CacheData', cacheData));
            if isempty(error)
                eventDataOut.Data.topic = topic;
                eventDataOut.Data.type = type;
                eventDataOut.Data.rosVer = obj.DataSourceModelHandle.RosNetworkVersion;
                eventDataOut.Data.rosNetworkInput = obj.DataSourceModelHandle.RosNetwork;
            end
            notify(obj.EventObj, 'TopicsInfoMP', eventDataOut);
        end

        function nextMessage(obj, eventData)
             if isempty(obj.DataSourceModelHandle)
                 return
             end

             if isequal(class(obj.DataSourceModelHandle),'ros.internal.RosbagModel') && ...
                     ~isempty(eventData.Data.MainSignal)
                [tNext, tStart, tEnd]  = nextMessage(obj.DataSourceModelHandle, ...
                    eventData.Data.CurrentTime, ...
                    eventData.Data.Direction, ...
                    eventData.Data.Rate, ...
                    eventData.Data.MainSignal);

                reactToNewTimeForPlayBack(obj, tNext,tStart, tEnd)
             elseif isequal(class(obj.DataSourceModelHandle),'ros.internal.RosLiveTopicModel')
                dataStruct = getDataAtTime(obj.DataSourceModelHandle);
                if ~isempty(dataStruct)
                    eventDataStruct = struct(...
                        'TopicData', dataStruct);
                    eventDataOut = ros.internal.EventDataContainer(eventDataStruct);
                    notify(obj.EventObj, 'DataForTimeMP', eventDataOut);
                end
             end
        end

        function extractDataRange(obj, eventData)
            if isempty(obj.DataSourceModelHandle) || ~isequal(class(obj.DataSourceModelHandle),'ros.internal.RosbagModel')
                 return
            end
            dataSource = eventData.Data.DataSource;
            dataType = eventData.Data.DataType;
            extractDataRange(obj.DataSourceModelHandle, dataSource, dataType);
        end

        function extractDataRangeResponse(obj, dataSource, dataArray, timeArray, fieldMap)
            eventDataOutStruct = struct('DataSource', dataSource, 'Data', dataArray, 'Time', timeArray, 'FieldMap',fieldMap);
            notify(obj.EventObj, 'DataForTimeRangeMP', ros.internal.EventDataContainer(eventDataOutStruct));
        end

        function reactToNewTime(obj, eventData)
            %reactToNewTime get the data for a give a time
            if isempty(obj.DataSourceModelHandle) || ~isequal(class(obj.DataSourceModelHandle),'ros.internal.RosbagModel')
                 return
            end

            requestedTime = eventData.Data;

            dataStruct = getDataAtTime(obj.DataSourceModelHandle, requestedTime);
            if ~isempty(dataStruct)
                eventDataStruct = struct('Time', requestedTime, ...
                    'TopicData', dataStruct);
                eventDataOut = ros.internal.EventDataContainer(eventDataStruct);
                notify(obj.EventObj, 'DataForTimeMP', eventDataOut);
            end
        end
        
        function reactToNewTimeForPlayBack(obj, requestedTime,tStart, tEnd)
            %reactToNewTime get the data for a give a time
            if isempty(obj.DataSourceModelHandle) || ~isequal(class(obj.DataSourceModelHandle),'ros.internal.RosbagModel')
                 return
            end
            dataStruct = getDataAtTime(obj.DataSourceModelHandle, requestedTime);

            if ~isempty(dataStruct)
                eventDataStruct = struct('Time', requestedTime, ...
                    'MainSignalStartTime', tStart, ...
                    'MainSignalEndTime', tEnd, ...
                    'TopicData', dataStruct);
                eventDataOut = ros.internal.EventDataContainer(eventDataStruct);
                notify(obj.EventObj, 'DataForTimeMP', eventDataOut);
            end
        end

        function updateDataSources(obj, eventDataIn)
            if isempty(obj.DataSourceModelHandle) || ~isvalid(obj.DataSourceModelHandle)
                return
            end

            updateDataSources(obj.DataSourceModelHandle, eventDataIn.Data)
        end

        function updateSelectedFrame(obj, eventDataIn)
            
            updateSelectedFrame(obj.DataSourceModelHandle, eventDataIn.Data)
        end

        % App Session Cache File related methods
        function createAppSessionCacheFile(obj)
            %createAppSessionCacheFile create a session cache file

            obj.AppSessionCacheModelHandle.createCacheFile();
        end

        function updateAppSessionCacheFile(obj, eventDataIn)
            % update the session cache file
            obj.AppSessionCacheModelHandle.updateCacheFile(eventDataIn.Data);
        end

        function returnCacheFileData(obj)
            %returnCacheFileData 
            
            eventDataStruct = obj.AppSessionCacheModelHandle.getCacheFileDetails();
            eventDataOut = ros.internal.EventDataContainer(eventDataStruct);
            notify(obj.EventObj, 'ReturnAppSessionCacheDataMP', eventDataOut);
        end
    end
end
