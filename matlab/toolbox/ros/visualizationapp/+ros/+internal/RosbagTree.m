classdef RosbagTree < handle
%This class is for internal use only. It may be removed in the future.

%RosbagTree This class is used to populate the tree view of the app

%   Copyright 2022-2024 The MathWorks, Inc.

    properties
        Rosbag
        RosbagHelper
        Topics
        MessageTypes
        ContainedTypes
        MessageTrees
    end

    properties (Constant)
        TimeType = 'time';
        NumericType = 'numeric'
        CharType = 'char';
        AnyMessageLabel = 'message'
    end

    methods
        function obj = RosbagTree(bagReader, bagHelper)
            obj.RosbagHelper = bagHelper;
            obj.Rosbag = bagReader;
        end

        function set.Rosbag(obj, bagReader)
            obj.Rosbag = bagReader;
            indexBag(obj)
        end

        function info = getInfoFromType(obj, type)
            if isKey(obj.MessageTrees, type)
                info = obj.MessageTrees(type);
            else
                error('Invalid type requested')
            end
        end

        function topicList = getTopicsWithTypes(obj, types)
            whichTopics = ismember(obj.MessageTypes, types);
            for k = 1:numel(types)
                whichTopics = whichTopics | ...
                    cellfun(@(c) ismember(types{k}, c), obj.ContainedTypes);
            end
            topicList = obj.Topics(whichTopics);
        end

        function fieldList = getFieldsWithTypes(obj, types, msgType)
            msgInfo = obj.MessageTrees(msgType);
            whichFields = ismember(msgInfo.Types, types);
            for k = 1:numel(types)
                whichFields = whichFields | ...
                    cellfun(@(c) ismember(types{k}, c), msgInfo.ContainedTypes);
            end
            fieldList = msgInfo.Names(whichFields);
        end

        function dataSourceList = getDataSourcesWithTypes(obj, types)
        % If any topics' message types meet criteria
            whichTopicsFlat = ismember(obj.MessageTypes, types) | ...
                (any(ismember(types, obj.AnyMessageLabel)) & true(size(obj.MessageTypes)));
            dataSourceList = obj.Topics(whichTopicsFlat);

            % Iterate through topics that contain the necessary types
            for k = 1:numel(obj.Topics)
                if any(ismember(types, obj.ContainedTypes{k})) || ...
                        any(ismember(types, obj.AnyMessageLabel))
                    % Check nested fields of messages
                    fieldList = getNestedFieldsWithType(obj, types, obj.MessageTypes{k});
                    fieldList = strcat(obj.Topics{k}, '.', fieldList);
                    dataSourceList = vertcat(dataSourceList, fieldList); %#ok<AGROW>
                end
            end
        end

        function nestedFieldList = getNestedFieldsWithType(obj, types, msgType)
        % If any fields' types meet criteria
            msgInfo = obj.MessageTrees(msgType);
            whichFieldsFlat = ismember(msgInfo.Types, types) | ...
                (any(ismember(types, obj.AnyMessageLabel)) & contains(msgInfo.Types, '/'));

            % Remove array fields. We don't need array fields in any visualizer
            whichFieldsFlat = whichFieldsFlat & ~msgInfo.IsArray; 
            
            nestedFieldList = msgInfo.Names(whichFieldsFlat);

            % Iterate through remaining fields that contain the types
            for k = 1:numel(msgInfo.Types)
                if (any(ismember(types, msgInfo.ContainedTypes{k})) || ...
                    (any(ismember(types, obj.AnyMessageLabel)) && ...
                     any(contains(msgInfo.ContainedTypes{k}, '/'))))
                    % Recurse to check nested fields
                    recursiveFieldList = getNestedFieldsWithType(obj, types, msgInfo.Types{k});
                    recursiveFieldList = strcat(msgInfo.Names{k}, '.', recursiveFieldList);
                    nestedFieldList = vertcat(nestedFieldList, recursiveFieldList); %#ok<AGROW>
                end
            end
        end

        function type = getTypeWithFieldPath(obj, fieldPath)
            type = '';
            splitPath = strsplit(fieldPath, '.');
            whichTopic = strcmp(obj.Topics, splitPath{1});
            if nnz(whichTopic) ~= 1
                return
            end
            currType = obj.MessageTypes(whichTopic);
            currType = currType{1};
            for k = 2:numel(splitPath)
                msgInfo = obj.MessageTrees(currType);
                whichField = strcmp(msgInfo.Names, splitPath{k});
                if nnz(whichField) ~= 1
                    fprintf('Field path %s not matching at field %s\n', fieldPath, splitPath{k})
                    return
                end
                currType = msgInfo.Types(whichField);
                currType = currType{1};
            end
            type = currType;
        end

        function frames = getAvailableTfFrames(obj)
            frames = obj.Rosbag.AvailableFrames;
        end
    end

    methods % (Access = protected)
        function indexBag(obj)
        % Basic properties
            obj.Topics = obj.Rosbag.AvailableTopics.Row;
            obj.MessageTypes = cellstr(obj.Rosbag.AvailableTopics.MessageType);
            obj.ContainedTypes = cell(size(obj.MessageTypes));
            obj.MessageTrees = containers.Map;

            % Determine which topics need mapping
            nTopics = numel(obj.Topics);
            idxFirstMsgs = zeros(nTopics, 1);
            topicsToRemove = false(nTopics, 1);
            for k = 1:nTopics
                messageType = string(obj.Rosbag.AvailableTopics.MessageType(k));
                whichInTopic = obj.Rosbag.AvailableTopics.Row{k} == obj.Rosbag.MessageList.Topic;
                if ~any(whichInTopic) || (strcmp(getROSVersion(obj.RosbagHelper),'ros2') && ~any(ismember(ros2('msg','list'),messageType),"all"))
                    topicsToRemove(k) = true;
                else
                    idxFirstMsgs(k) = find(whichInTopic, 1);
                end
            end

            % Remove any empty topics
            obj.Topics(topicsToRemove) = [];
            obj.MessageTypes(topicsToRemove) = [];
            obj.ContainedTypes(topicsToRemove) = [];
            idxFirstMsgs(topicsToRemove) = [];

            % Read example of each message type
            [types, idxUniqueTypes, idxMsgToTopics] = unique(obj.MessageTypes);
            
            msgs = readMessagesAtIdx(obj.Rosbag, idxFirstMsgs(idxUniqueTypes));
            
            % Construct tree for each message type recursively
            containedTypesByMsg = cell(numel(types), 1);
            for k = 1:numel(types)
                if ~isempty(msgs{k})
                    indexMessage(obj, types{k}, msgs{k})
                    msgInfo = obj.MessageTrees(types{k});
                    containedTypesByMsg{k} = unique(vertcat(msgInfo.Types, msgInfo.ContainedTypes{:}));
                end
            end
            obj.ContainedTypes = containedTypesByMsg(idxMsgToTopics);
        end

        function indexMessage(obj, msgType, msg)
        % Get message tree if type not seen before
            if ~isKey(obj.MessageTrees, msgType) && ~isempty(msg)
                % Determine field names, types, and array-status
                names = fieldnames(msg);
                nFields = numel(names);
                types = cell(nFields, 1);
                isArray = false(nFields, 1);
                isMsg = false(nFields, 1);
                containedTypes = cell(nFields, 1);
                for k = 1:nFields
                    val = msg.(names{k});
                    containedTypes{k} = {};
                    if ischar(val)
                        types{k} = obj.CharType;
                    else
                        isArray(k) = numel(val) ~= 1;
                        if isstruct(val)
                            if isempty(val)
                                [val, types{k}] = obj.RosbagHelper.getMsgFieldType(msg.MessageType, names{k});
                            elseif isfield(val, 'MessageType')
                                types{k} = val.MessageType;
                            elseif isfield(val, 'Nsec') || isfield(val, 'nanosec')
                                types{k} = obj.TimeType;
                            else
                                error('Poorly-formed message')
                            end
                            isMsg(k) = true;
                            % Recurse if necessary. Incase of val as array,
                            % send the only one element of array to
                            % understand its structure.
                            indexMessage(obj, types{k}, val(1))
                            fieldInfo = obj.MessageTrees(types{k});
                            containedTypes{k} = unique(vertcat(fieldInfo.Types, fieldInfo.ContainedTypes{:}));
                        else
                            isArray(k) = numel(val) ~= 1;
                            types{k} = obj.NumericType;
                        end
                    end
                end

                % Add to message tree map
                obj.MessageTrees(msgType) = struct('Names', {names}, ...
                                                   'Types', {types}, ...
                                                   'IsArray', isArray, ...
                                                   'IsMessage', isMsg, ...
                                                   'ContainedTypes', {containedTypes});
            end
        end
    end
end
