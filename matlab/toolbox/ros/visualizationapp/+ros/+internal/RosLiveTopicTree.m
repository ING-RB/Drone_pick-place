classdef RosLiveTopicTree < handle
%This class is for internal use only. It may be removed in the future.

%RosLiveTopicTree This class is used to parse the message structure

%   Copyright 2023 The MathWorks, Inc.

    properties
        Topics
        MessageTypes
        ContainedTypes
        MessageTrees
        Network
        Helper
        TfTree
    end

    properties (Constant)
        TimeType = 'time';
        NumericType = 'numeric'
        CharType = 'char';
        AnyMessageLabel = 'message'
        NumericTypeDataTypes = ["double", "single", "int8", ...
            "int16", "int32", "int64" , "uint8", ...
            "uint16", "uint32", "uint64"];
    end

    methods
        function obj = RosLiveTopicTree(liveHandle)
            % RosLiveTopicTree constructor

            obj.Topics = liveHandle.TopicNames;
            obj.Network = liveHandle.RosNetwork;
            obj.MessageTypes = liveHandle.TopicTypes;
            obj.Helper = liveHandle.ModelHelper;
            obj.TfTree = liveHandle.CommonTf;
            indexTopicDetails(obj)
        end

        function info = getInfoFromType(obj, type)
            % 
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
    end

    methods
        function indexTopicDetails(obj)
        
            obj.ContainedTypes = cell(size(obj.MessageTypes));
            obj.MessageTrees = containers.Map;

            % Read example of each message type
            [types, ~, idxMsgToTopics] = unique(obj.MessageTypes);

            % Construct tree for each message type recursively
            containedTypesByMsg = cell(numel(types), 1);
            for k = 1:numel(types)
                msgStruct = obj.Helper.getMsgStructOfType(types{k});
                indexMessage(obj, types{k}, msgStruct)
                msgInfo = obj.MessageTrees(types{k});
                 containedTypesByMsg{k} = unique(vertcat(msgInfo.Types, msgInfo.ContainedTypes{:}));
            end
            obj.ContainedTypes = containedTypesByMsg(idxMsgToTopics);
        end

        function indexMessage(obj, msgType, msg)
        % Get message tree if type not seen before

            if ~isKey(obj.MessageTrees, msgType)
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
                                [val,types{k}] = getMsgFieldType(msgType,names{k});
                            elseif isfield(val, 'MessageType')
                                types{k} = val.MessageType;
                            elseif isfield(val, 'Nsec')
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

        function frames = getAvailableTfFrames(obj)
            frames = obj.TfTree.AvailableFrames;
        end
    end
end

function  [msg,type] = getMsgFieldType(msgType, fieldName)
    msgInfo = ros.internal.ros.getMessageInfo(msgType);
    [msg, info] = eval(msgInfo.msgStructGen);
    val = info.(fieldName);
    type = val.MessageType;
    msgInfo = ros.internal.ros.getMessageInfo(type);
    [msg, info] = eval(msgInfo.msgStructGen);
end