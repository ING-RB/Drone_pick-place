classdef RosbagModel < ros.internal.mixin.ROSInternalAccess & handle
%This class is for internal use only. It may be removed in the future.

%RosbagModel This class contains APIs to interact with rosbagreader and
%exchange the buffered data with ModelEventHandler class

%   Copyright 2022-2024 The MathWorks, Inc.

    properties
        Rosbag
        BagTree
        BagHelper
        DataSources = {};
        ModelBuffer
        EventHandlerWeakRef

        RequestId = 0;
        RequestIdDataSourceMap
        DataRangeModelBuffer

        FrameIdSelected
    end

    methods
        function obj = RosbagModel(eventHandler)
        % Set up reactions to events
            obj.ModelBuffer = containers.Map('KeyType','char','ValueType','any');
            obj.RequestIdDataSourceMap = containers.Map('KeyType','double','ValueType','any');
            obj.DataRangeModelBuffer = containers.Map('KeyType','char','ValueType','any');
            obj.EventHandlerWeakRef = matlab.internal.WeakHandle(eventHandler);
        end
    end

    methods
        function [rosBag, bagTree] = loadRosbag(obj, bagPath)
            [pathstr, ~, ext] = fileparts(bagPath);

            if ~(strcmp(ext, '.bag') || strcmp(ext, '.db3') || strcmp(ext, '.mcap') || strcmp(ext, '.yaml'))
                me = ros.internal.utils.getMException(...
                    'ros:visualizationapp:model:InvalidFileFormat', ...
                    ext, '.bag,.db3,.mcap,.yaml');
                throw(me)
            end

            try
                if strcmp(ext, '.bag')
                    obj.Rosbag = rosbagreader(bagPath);
                    obj.BagHelper = ros.internal.RosModelHelper;
                elseif strcmp(ext, '.yaml')
                    obj.Rosbag = ros2bagreader(pathstr);
                    obj.BagHelper = ros.internal.Ros2ModelHelper;
                elseif strcmp(ext, '.db3') || strcmp(ext, '.mcap')
                    obj.Rosbag = ros2bagreader(bagPath);
                    obj.BagHelper = ros.internal.Ros2ModelHelper;
                end
            catch ex
                if strcmp('ros:mlros:bag:FileReadingError',ex.identifier)
                    me = ros.internal.utils.getMException(...
                    'ros:visualizationapp:model:InvalidFile',bagPath);
                    throw(me)
                else
                    rethrow(ex)
                end
            end

            %Check if bag file is empty
            if isempty(obj.Rosbag.MessageList)
                me = ros.internal.utils.getMException(...
                    'ros:visualizationapp:model:EmptyFile',obj.Rosbag.FilePath);
                throw(me)
            end

            obj.BagTree = ros.internal.RosbagTree(obj.Rosbag,obj.BagHelper);
            rosBag = obj.Rosbag;
            bagTree = obj.BagTree;
        end

        function [tNext, tStart, tEnd] = nextMessage(obj, currentTime, direction, rateMultiplier, mainSignal)

        % Find the index of the messages of main signal in the bag file
            whichMsgs = obj.Rosbag.MessageList.Topic == mainSignal;

            % Get all the timestamp of main signal
            mainSignalTimestamps = obj.Rosbag.MessageList.Time(whichMsgs);

            tStart = mainSignalTimestamps(1);
            tEnd = mainSignalTimestamps(numel(mainSignalTimestamps));
            
            % Find the index of current time among main signal messages
            idxNow = find(mainSignalTimestamps > currentTime, 1, 'first');

            if isempty(idxNow)
                % No more messages are there. So send the time stamp of
                % last message
                tNext = tEnd;
                return
            elseif idxNow > 1
                % As idxNow is index of next time stamp here, it is
                % decremented by 1
                idxNow = idxNow-1;
            end

            if rateMultiplier > 1
                idxMultiplier = rateMultiplier;
                timeMultiplier = 1;
            else
                idxMultiplier = 1;
                timeMultiplier = rateMultiplier;
            end

            % Find index of next frame
            idxNext = idxNow+direction*idxMultiplier;
            idxNext = min(max(idxNext, 1), numel(mainSignalTimestamps));

            % Find next time stamp
            if isequal(idxNext,1) && isequal(idxNow,1)
                tNext = tStart;
                return
            else
                tNext = mainSignalTimestamps(ceil(idxNext));
            end

            if timeMultiplier ~= 1
                tPrev = mainSignalTimestamps(idxNow);
                tNext = (tNext-tPrev)*timeMultiplier+currentTime;
            end
        end

        function extractDataRange(obj, dataSource, dataType)
            [topic, fieldPath] = splitTopicFieldPath(dataSource);
            
            if ~obj.DataRangeModelBuffer.isKey(topic)
                obj.DataRangeModelBuffer(topic) = struct('BagSelection',obj.Rosbag.select('Topic',topic),...
                                                        'DataType',dataType);
            end
            bagSelStr = obj.DataRangeModelBuffer(topic);
            bagSel = bagSelStr.BagSelection;

            obj.RequestId = obj.RequestId + 1;
            obj.RequestIdDataSourceMap(obj.RequestId) = dataSource;
            bagSel.readMessagesFromBuffer(obj.RequestId, dataType, fieldPath, ...
                                        obj, 'extractDataRangeResponse');
        end

        function extractDataRangeResponse(obj, requestId, varargin)
            dataSource = obj.RequestIdDataSourceMap(requestId);
            [topic, ~] = splitTopicFieldPath(dataSource);
            bagSelStr = obj.DataRangeModelBuffer(topic);
            bagSel = bagSelStr.BagSelection;
            dataType = bagSelStr.DataType;

            dataArray = [varargin{:}];
            timeArray = bagSel.MessageList.Time;
            hModelEv = obj.EventHandlerWeakRef.get;
            if ~isempty(hModelEv)
                extractDataRangeResponse(hModelEv, ...
                                            dataSource, ...
                                            dataArray, ...
                                            timeArray, ...
                                            getFieldMap(obj, dataType))
            end
        end
        
        function fieldMap = getFieldMap(obj, dataType)
            %Gives information about how to read a message struct
            
            fieldMap = obj.BagHelper.getFieldMap(dataType);
        end

        function dataStruct = getDataAtTime(obj, requestedTime)

            if ~isempty(obj.DataSources)
                for ii = 1:length(obj.DataSources.DataSource)
                    try
                        [topic, fieldPath] = splitTopicFieldPath(obj.DataSources.DataSource(ii));
                        if isempty(fieldPath)
                            fieldPath = '';
                        end

                        if obj.ModelBuffer.isKey(topic)
                            % TODO : Use same backend function for image & compressed image to remove this condition
                            dataType =  obj.DataSources.DataType(ii);
                            if strcmp(dataType,"compressedimage")
                                % As same image visualizer is used for
                                % image and compressed image, while sendong
                                % to view, send the type as "image"
                                dataType = "image";
                            end
                            dsReader = obj.ModelBuffer(topic);
                            msg = dsReader.readMessageFromBuffer(requestedTime,obj.DataSources.DataType(ii),true,fieldPath);
                            
                            % check if data type is marker and call the
                            % helper function to transform message
                            
                            % if isequal(obj.DataSources.DataType(ii), 'marker') && ~isempty(obj.FrameIdSelected)  && ~isempty(msg)
                            %     msg = obj.BagHelper.transformMarkerMessage(obj, msg);
                            % end

                            dataStruct(ii) = struct('Topic', obj.DataSources.DataSource(ii), ...
                                'Message', msg, ...
                                'DataType', dataType, ...
                                'FieldMap', getFieldMap(obj, dataType), ...
                                'Error', ''); %#ok<AGROW>
                        end
                    catch ex
                        dataStruct(ii) = struct('Topic', obj.DataSources.DataSource(ii), ...
                                                'Message', '', ...
                                                'DataType', dataType, ...
                                                'FieldMap', getFieldMap(obj, dataType), ...
                                                'Error', ex); %#ok<AGROW>
                        %rethrow(ex)
                    end
                end
            else
                dataStruct = [];
            end
        end


        function updateDataSources(obj, dataSources)
            
            %TODO add support to frameid
            obj.DataSources = dataSources;

            for ii = 1:length(obj.DataSources.DataSource)
                [topic, fieldPath] = splitTopicFieldPath(obj.DataSources.DataSource(ii));

                if ~obj.ModelBuffer.isKey(topic)
                    obj.ModelBuffer(topic) = select(obj.Rosbag , "topic", topic);
                    
                end

                if isequal(obj.DataSources.DataType(ii) , 'image')
                    % Check if it is image or compressed image
                    
                    checkMsg = obj.ModelBuffer(topic).readMessagesAtIdx(1);
                    checkMsg = checkMsg{1};

                    if ~isempty(fieldPath)
                        fieldPathCell = split(fieldPath,'.');
                        for jj = 1:length(fieldPathCell)
                            checkMsg = checkMsg.(fieldPathCell(jj));
                        end
                    end

                    if isfield(checkMsg, 'MessageType')
                        msgType = checkMsg.MessageType;
                        if isequal(msgType,'sensor_msgs/CompressedImage')
                            obj.DataSources.DataType(ii) = "compressedimage";
                        end
                    end

                end
            end
        end

        function updateSelectedFrame(obj,  data)
            % updateSelectedFrame update the FrameIdSelected property from
            % the presenter.

            obj.FrameIdSelected = data.FrameId;
        end
    end
end

function [topic, fieldPath] = splitTopicFieldPath(fullPath)
    splitPath = strsplit(fullPath, '.');
    topic = splitPath{1};
    fieldPath = {};
    if numel(splitPath) > 1
        fieldPath = splitPath(2:end);
    end
end
