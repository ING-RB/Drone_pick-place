classdef RosLiveTopicModel < ros.internal.mixin.ROSInternalAccess & handle
%This class is for internal use only. It may be removed in the future.

%RosLiveTopicModel This class contains APIs to interact with live ros(2) network
% and exchange the data with ModelEventHandler class

%   Copyright 2023-2024 The MathWorks, Inc. 
    
    properties
        TopicNames
        TopicTypes
        RosNetwork
        DataSources = {};
        ModelBuffer
        %SubscriberMessageCountMap
        CommonNode
        CommonTf
        NodeName = "/MLNode"
        ModelHelper
        RosNetworkVersion
        TopicTree
        ProcessedDatatypes = ["image","laserscan","pointcloud"];
        FrameIdSelected
    end
    
    methods
        function obj = RosLiveTopicModel(rosNetworkDetails)
            %RosLiveTopicModel Construct an instance of this class
            
            obj.RosNetwork = rosNetworkDetails.NetworkInput;
            obj.RosNetworkVersion = rosNetworkDetails.NetworkType;
            if strcmp(obj.RosNetworkVersion,'ros1')
                obj.ModelHelper = ros.internal.RosModelHelper;
            else
                try
                    obj.RosNetwork = str2double(obj.RosNetwork);
                catch
                    %If cannot be converted to double, let ros2node throw the
                    %error.
                end

                obj.ModelHelper = ros.internal.Ros2ModelHelper;
            end
            
            obj.CommonNode = obj.ModelHelper.createNode(obj.NodeName + getTimeStamp(), obj.RosNetwork);
            %Common Tf object to store all incoming transformations.
            obj.CommonTf = obj.ModelHelper.createTfObj(obj.CommonNode);
            obj.ModelBuffer = containers.Map('KeyType','char','ValueType','any');

            [obj.TopicNames, obj.TopicTypes] = getTopicNameAndType(obj.ModelHelper,obj.RosNetwork);
            obj.TopicTree = ros.internal.RosLiveTopicTree(obj);
        end
        
        function updateTopicList(obj)
            %function is used to update Topicnames and TopicTypes

            [obj.TopicNames, obj.TopicTypes] = getTopicNameAndType(obj.ModelHelper,obj.RosNetwork);

            % Create new tree based on updated list
            obj.TopicTree = ros.internal.RosLiveTopicTree(obj);
        end
        
        function fieldMap = getFieldMap(obj, dataType)
            %Gives information about how to read a message struct
            
            fieldMap = obj.ModelHelper.getFieldMap(dataType);
        end

        function updateDataSources(obj, dataSources)
            % Update the data sources selected in the visualizer dropdowns

            obj.DataSources = dataSources;

            for ii = 1:length(obj.DataSources.DataSource)
                currentDataSource = char(obj.DataSources.DataSource(ii)); 
                [topic, fieldPath] = splitTopicFieldPath(currentDataSource);
                
                bufferKey = obj.DataSources.DataSource(ii) + obj.DataSources.DataType(ii);
                % TODO : When backend c++ will be used, if a data source
                % type is image, check if it is compressed image. If so,
                % change the type to "compressedimage"
                
                if ~obj.ModelBuffer.isKey(bufferKey)
                    readOption = "message";
                    if ismember(obj.DataSources.DataType(ii), obj.ProcessedDatatypes)
                        readOption = obj.DataSources.DataType(ii);
                    end
                    obj.ModelBuffer(bufferKey) = createSubscriber(obj.ModelHelper, obj.CommonNode, topic, readOption, fieldPath);
                end
            end
        end
        
        function dataStruct = getDataAtTime(obj)
            if ~isempty(obj.DataSources)
                for ii = 1:length(obj.DataSources.DataSource)
                    try
                        [topic, fieldPath] = splitTopicFieldPath(obj.DataSources.DataSource(ii));
                        if isempty(fieldPath)
                            fieldPath = '';
                        end
                        bufferKey = obj.DataSources.DataSource(ii) + obj.DataSources.DataType(ii);
                        if obj.ModelBuffer.isKey(bufferKey)
                            
                            dataType =  obj.DataSources.DataType(ii);
                            
                            % if strcmp(dataType,"compressedimage")
                            %     % TODO when c++ will be used: As same image
                            %     % visualizer is used for image and compressed 
                            %     % image, while sendong to view, send the
                            %     % type as "image"
                            %
                            %     dataType = "image";
                            % end

                            dsReader = obj.ModelBuffer(bufferKey);
                            msg = dsReader.LatestMessage;
                            if isempty(msg)
                                % dataStruct(ii) = struct('Topic', obj.DataSources.DataSource(ii), ...
                                % 'Message', msg, ...
                                % 'DataType', dataType, ...
                                % 'Error', MException(message('ros:mlroscpp:subscriber:GetLatestMessageError'))); %#ok<AGROW>
                                continue
                            end
                            %msg = messageParser(msg, fieldPath);

                            if strcmp(dataType,"pointcloud")

                                if isfield(msg,'xyz')
                                    xyz = msg.xyz;
                                    rgb = msg.rgb;
                                    frame_id = msg.frame_id;
                                else
                                    xyz = rosReadXYZ(msg);
                                    try
                                        rgb = rosReadRGB(msg);
                                    catch
                                        rgb = [];
                                    end
                                    frame_id = obj.ModelHelper.getFrameID(msg, "message");
                                end

                                % Add a frame_id field. Required for 3D
                                % visualizer.
                                msg = struct("xyz",xyz,...
                                    "rgb",rgb, ...
                                    "frame_id", frame_id);
                            
                            elseif strcmp(dataType,"image")
                                % if-block is used to differentiate between
                                % compressed image and image data types.
                                if isfield(msg,'img')
                                    img = msg.img;
                                    alpha = msg.alpha;
                                else
                                    [img,alpha] = rosReadImage(msg);
                                end
                                
                                msg = struct("img",img,...
                                    "alpha",alpha);
                           
                            elseif strcmp(dataType,"laserscan")

                                if isfield(msg,'xy')
                                    xy = msg.xy;
                                    intensity = msg.intensity;
                                    frame_id = msg.frame_id;
                                else
                                    xy = rosReadCartesian(msg);
                                    if isequal(obj.RosNetworkVersion,'ros1')
                                        intensity = msg.Intensities;
                                    else
                                        intensity = msg.intensities;
                                    end
                                    frame_id = obj.ModelHelper.getFrameID(msg, "message");
                                end

                                % Add a frame_id field. Required for 3D
                                % visualizer.
                                msg = struct("xy",xy,...
                                    "intensity",intensity, ...
                                    "frame_id", frame_id);
                            elseif ~isempty(fieldPath)
                                msg = msg.(fieldPath(end));
                            
                            end

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
            end

            if ~exist('dataStruct', 'var')
                dataStruct = [];
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

function parsedMsg = messageParser(msg, fieldPath)
    parsedMsg = msg;
    for i= 1:numel(fieldPath)
        parsedMsg = parsedMsg.(fieldPath(i));
    end
end

function timeStamp = getTimeStamp()
    curTime = datetime('now','Format','HHmmss');
    timeStamp = string(hour(curTime)*1e4 + minute(curTime)*1e2 + floor(second(curTime)));
end

% LocalWords:  Topicnames dropdowns compressedimage sendong mlroscpp xyz HHmmss
