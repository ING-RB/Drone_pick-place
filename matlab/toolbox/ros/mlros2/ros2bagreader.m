classdef ros2bagreader
%ROS2BAGREADER Access ros2bag log file information
%   The ROS2BAGREADER object is an index of the messages within a ros2bag
%   file. It supports both sqlite3 and MCAP file format
%   You can use it to extract message data from a ros2bag file or select messages based on specific criteria.
%   BAGREADER = ROS2BAGREADER(FILEPATH) creates an indexable ros2bagreader object, BAGREADER,
%   that contains all the messages from the ros2bag file at the input path FILEPATH.
%   The FILEPATH input argument sets the FilePath property.
%
%   ROS 2 bag files are used for storing message data. Their primary
%   use is in the logging of messages transmitted over a ROS 2 network.
%   The resulting bag file can be used for offline analysis, visualization,
%   and storage. MATLAB provides functionality for reading both existing
%   uncompressed and compressed bag files.
%
%
%   ros2bagreader properties:
%      FilePath         — (Read-Only) Absolute path to ros2bag file
%      AvailableBags    — (Read-Only) List of available bags
%      StartTime        — (Read-Only) Timestamp of first message
%      EndTime          — (Read-Only) Timestamp of last message
%      NumMessages      — (Read-Only) Number of messages
%      AvailableTopics  — (Read-Only) Table of available topics
%      AvailableFrames  - (Read-Only) List of available coordinate frames
%      MessageList      — (Read-Only) List of messages
%
%   ros2bagreader methods:
%      readMessages — Read messages from ros2bagreader object
%      select       — Select subset of messages in ros2bagreader object
%      getTransform - Return transformation between two coordinate frames
%      canTransform - Verify transformation is available
%      timetable    - Return a timetable object for message properties
%
%
%   Example:
%      % Open a rosbag and retrieve information about its contents.
%      folderPath = "path/to/bagfolder";
%
%      % Create a ros2bagreader object.
%      bag = ros2bagreader(folderPath);
%
%      % Retrieve the messages in the ros2bagreader object as a cell array.
%      msgs = readMessages(bag)
%
%      % Select a subset of the messages by time and topic.
%      bagSelection = select(bag,"Time",...
%          [bag.MessageList(1,1).Time,bag.MessageList(2,1).Time],"Topic","/odom")
%
%      % Retrieve the messages in the selection as cell array.
%      msgsFiltered = readMessages(bagSelection)

%  Copyright 2020-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        %FilePath - Absolute path to ros2bag file,
        %   Absolute path to the ros2bag file, specified as a character vector.
        %   This property is read-only.
        FilePath = ''

        %AvailableBags - List of available bag files
        AvailableBags = []

        %StartTime - Timestamp of first message
        %   Timestamp of the first message, specified as a scalar in seconds.
        %   This property is read-only.
        StartTime = 0

        %EndTime - Timestamp of last message
        %   Timestamp of the last message, specified as a scalar in seconds.
        %   This property is read-only.
        EndTime = 0

        %AvailableTopics - Table of topics
        %   Table of available topics, specified as a table.
        %   Each row in the table lists one topic, the number of messages 
        %   for this topic, the message type, and the message definition.
        %   This property is read-only.
        AvailableTopics = table.empty(0,3)

        %AvailableFrames - List of available coordinate frames
        AvailableFrames = {}

        %MessageList - The list of messages
        %   List of messages, specified as a table. Each row in the table lists one message.
        %   This property is read-only.
        MessageList = table.empty(0,3)
    end

    properties (Dependent)
        %NumMessages - Number of messages
        % Number of messages, specified as a scalar.
        %   This property is read-only.
        NumMessages
    end

    properties (Access = private)
        %TopicTypeMap - Mapping from topic name to message type of topic
        TopicTypeMap

        %TopicDefinitionMap - Mapping from topic name to message definition
        TopicDefinitionMap
        
        %SelectionId - Unique id for current bag selection
        SelectionId = 0;

        %FilterMessagesByTopicsCell - Filter bag messages based on topic
        FilterMessagesByTopicsCell = {}

        %FilterMessagesByTypesCell - Filter bag messages based on message
        %type
        FilterMessagesByTypesCell = {}

        %FilterMessageStartTime - Start times of all the time filters
        FilterMessageStartTime = {}

        %FilterMessageEndTime - End times of all the time filters
        FilterMessageEndTime = {}

        %DoubleToUint64TimeStampDict - Map Double values to Uint64 timestamps
        % used to handle precision loss when converting uint64 to double value
        DoubleToUint64TimeStampDict
    end

    properties (Transient, Access = private)
        %AvailableTopicsCell - Cell array of topic names
        %   This is pre-cached for fast access.
        AvailableTopicsCell
    end

    properties (Transient, Access = protected)
        %BagTF - MCOS C++ object for accessing TF information in rosbag2
        BagTF

        %Bag - MCOS C++ object for reading from ros2bagreader
        Bag
    end
    
    properties (Hidden = true)
        %RawMessageBuffer - Stores raw messages as buffer
        RawMessageBuffer

        %ImgMessageBuffer - Stores images as buffer
        ImgMessageBuffer

        %PointCloudBuffer - Stores point cloud as buffer
        PointCloudBuffer
        
        %LaserScanBuffer - Stores laser scan as buffer
        LaserScanBuffer

        %NumMessagesInSeg - Number of messages available in each segment
        NumMessagesInSeg = 10; %later determine based on bag file
    end

    properties (Constant , Hidden = true)
        %NumSegsInBuffer - Number of messages available in each segment
        NumSegsInBuffer = 5;
    end

    methods (Static)
        function obj = loadobj(s)
            %loadobj Custom behavior on bag file load
            % This custom method ensures that the MCOS C++ object is always
            % initialized as part of the ros2bagreader construction.
            obj = ros2bagreader(s.FilePath);
        end
    end

    methods(Static , Hidden = true)
        function readMessagesInBackgroundCB(messageBuffer, segId, varargin)
            %readMessagesInBackgroundCB Callback function invoked in the
            %background after the messages are fetched from bag file.
            
            % Message buffer is a map of segment-id and segment-messages.
            % To limit the Buffer-Size we are limiting the number of
            % segments not to exceed 'NumSegsInBuffer'. So when ever it
            % reaches the limit, we must remove the oldest segment and add
            % the latest one. To know the oldest segment we must know the
            % order in which segments are added. In all buffer the key-0
            % stores the order of the segment-ids(ex. [2,5,3,7,4]) in an array.
            % For the first time, if key-0 is not there create it.
            if ~messageBuffer.isKey(0)
                messageBuffer(0) = [];
            end

            % Get key '0' which contains the currently available keys in
            % order. Add the new segment id in the array.
            bufferSegs = messageBuffer(0);
            bufferSegs(end+1) = segId;

            % Fill the segment with messages
            segment = messageBuffer(segId);
            segment.Messages = varargin;
            
            % If the number of segments has crossed the limit, get the segment
            % order array from key-0 and delete the oldest segment based 
            % on the order
            if length(bufferSegs) > ros2bagreader.NumSegsInBuffer
                segToBeDeleted = messageBuffer(bufferSegs(1));
                segToBeDeleted.Messages = {}; 
                delete(segToBeDeleted);
                messageBuffer.remove(bufferSegs(1));
                bufferSegs = bufferSegs(2:end);
            end

            % After buffers are deleted, update key '0' in map
            messageBuffer(0) = bufferSegs; %#ok<NASGU>
            segment.IsLoaded = true;
        end
    end

    methods(Access = private)
        function readMessagesInBackground(obj, segId, readMessageOption, dataSource, msgSegBuffer, numMsgsInSeg,segStartIdx,callbackFun)
            %readMessagesInBackground Reads the ros messages in background. 

            readMessageOptions = ["message", "image", "compressedimage", "pointcloud", "laserscan"];
            idxReadMessageOption = int32(find(readMessageOptions == readMessageOption));

            % If the read type is not supported, read as raw-message
            if isempty(idxReadMessageOption)
                idxReadMessageOption = 1;
            end
            
            if nargin < 6
                if msgSegBuffer.isKey(segId)
                    return;
                end
                noOfMsgsInSeg = obj.NumMessagesInSeg;
            
                % validate segId and ignore if it is invalid
                if (noOfMsgsInSeg*(segId-1) + 1) > obj.NumMessages || segId <= 0
                    return;
                end
    
                segment = ros.internal.RosBagSegment;
                segment.Id = segId;
                segment.ReadType = readMessageOption;
                  
                segStartIdx = noOfMsgsInSeg*(segId-1) + 1;
                segEndIdx = noOfMsgsInSeg*segId;
                if segEndIdx > obj.NumMessages
                    segEndIdx = obj.NumMessages;
                end
                numMsgsInSeg = segEndIdx - segStartIdx + 1;
                msgSegBuffer(segId) = segment;
                callbackFun = 'ros2bagreader.readMessagesInBackgroundCB';
            end

            dataSourceCell = split(dataSource,'.');
            % Instead of using dictonary, revert back to previous strategy
            % as segment start was calculated incorrectly for tMapViewer
            % using dictionary.
            segStartTtime = obj.MessageList.Time(segStartIdx) * 1e9;
            segStartTtime = segStartTtime - eps(segStartTtime);
            obj.Bag.readInBackground(msgSegBuffer, ...
                                     callbackFun, ...
                                     segId, ...                         
                                     uint64(segStartTtime),...
                                     segStartIdx, ...
                                     numMsgsInSeg, ...
                                     idxReadMessageOption, ...
                                     dataSourceCell, ...
                                     obj.SelectionId);
        end
        
        function msgSegBuffer = getSegBuffer(obj, readMessageOption, dataSource)
            if isequal(readMessageOption,"image") || isequal(readMessageOption,"compressedimage")
                messageBuffer = obj.ImgMessageBuffer;
            elseif isequal(readMessageOption,"pointcloud")
                messageBuffer = obj.PointCloudBuffer;
            elseif isequal(readMessageOption,"laserscan")
                messageBuffer = obj.LaserScanBuffer;
            else
                messageBuffer = obj.RawMessageBuffer;
            end
            dataSourceStr = '';
            if ischar(dataSource) || (isstring(dataSource) && isscalar(dataSource))
                dataSourceStr = char(dataSource);
            elseif isstring(dataSource) && ~isscalar(dataSource)
                for ii = 1:length(dataSource)
                    dataSourceStr = [dataSourceStr '.' char(dataSource(ii))]; %#ok<AGROW> 
                end
            else
                for ii = 1:length(dataSource)
                    dataSourceStr = [dataSourceStr '.' char(dataSource{ii})]; %#ok<AGROW> 
                end
            end
            if messageBuffer.isKey(dataSourceStr)
                msgSegBuffer = messageBuffer(dataSourceStr);
            else
                msgSegBuffer = containers.Map('KeyType','double','ValueType','any');
                messageBuffer(dataSourceStr)  = msgSegBuffer; %#ok<NASGU> 
            end
        end

        function msg = readMessageFromBag(obj, msgIdx, readMessageOption, dataSource)
            
            msgStructCell = readMessages(obj,msgIdx);
            msgStruct = msgStructCell{1};
            dataSourceCell = split(dataSource,'.');
            for fIdx = 1:length(dataSourceCell)
                if isempty(dataSourceCell{fIdx})
                    break;
                end
                if ~isempty(msgStruct)
                    msgStruct = msgStruct.(dataSourceCell{fIdx});
                end
            end
            
            if isequal(readMessageOption,'image') || isequal(readMessageOption,'compressedimage')
               [img, alpha] = rosReadImage(msgStruct);
               if isequal(readMessageOption,'image') && isa(img,"float")
                   % As per g2826880, Needs to be rescaled if the data is a floating point 
                   img = rescale(img);
               end
               msg.img = img;
               msg.alpha = alpha;
            elseif isequal(readMessageOption,'pointcloud')
               xyz = rosReadXYZ(msgStruct);
               rgb = [];
               try
                   rgb = rosReadRGB(msgStruct);
               catch
               end
               msg.xyz = xyz;
               msg.rgb = rgb;
               msg.frame_id = msgStruct.header.frame_id;
            elseif isequal(readMessageOption,'laserscan')
               msg.xy = rosReadCartesian(msgStruct);
               msg.intensity = msgStruct.intensities;
               msg.frame_id = msgStruct.header.frame_id;
            else
               msg = msgStruct; 
            end
        end
    end

    methods(Hidden = true)
        function msgs = readMessagesAtIdx(obj,indexes)
            % read messages from given indexes
            
            msgs = readMessages(obj, indexes);
        end
        
        function sizeInByte = getBagSize(obj)
            sizeInByte = 0;
            if isfile(fullfile(obj.FilePath))
                bagFile = dir(obj.FilePath);
                sizeInByte = bagFile.bytes;
            else
                for idx = 1:numel(obj.AvailableBags)
                    bagFile = dir(fullfile(obj.FilePath,obj.AvailableBags(idx)));
                    sizeInByte = sizeInByte + bagFile.bytes;
                end
            end
        end

        function readMessagesFromBuffer(obj, requestId, readMessageOption, dataSource,callbackArg,callbackFun)
            segId = requestId;
            readMsgsFromIdx = 1;
            obj.readMessagesInBackground(segId, readMessageOption, dataSource,callbackArg,obj.NumMessages,readMsgsFromIdx,callbackFun);
        end

        function msg = readMessageFromBuffer(obj, timeStamp, readMessageOption, enableDirectReading, dataSource)
            [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = ros.internal.ros2.setupRos2Env(); %#ok<ASGLU>
            messageIdxInSelection = find(obj.MessageList.Time >= timeStamp , 1);
            if isempty(messageIdxInSelection)
                messageIdxInSelection = numel(obj.MessageList.Time);
            end

            segId = messageIdxInSelection/obj.NumMessagesInSeg;
            if rem(messageIdxInSelection,obj.NumMessagesInSeg) > 0
                segId = segId + 1;
            end
            segId = floor(segId);
    
            messageIdxInSeg = messageIdxInSelection - (segId - 1)*obj.NumMessagesInSeg;

            msgSegBuffer = getSegBuffer(obj, readMessageOption, dataSource);

            if msgSegBuffer.isKey(segId)
                msgSeg = msgSegBuffer(segId);
                if msgSeg.IsLoaded == true 
                    msg = msgSeg.getMessage(messageIdxInSeg);     
                    obj.readMessagesInBackground(segId - 1, readMessageOption, dataSource, msgSegBuffer);
                    obj.readMessagesInBackground(segId + 1, readMessageOption, dataSource, msgSegBuffer);
                elseif enableDirectReading
                    msg = readMessageFromBag(obj, messageIdxInSelection, readMessageOption, dataSource);
                else
                    waitfor(msgSeg,'IsLoaded',true);
                    msg = msgSeg.getMessage(messageIdxInSeg);
                end
            else
                if enableDirectReading
                    msg = readMessageFromBag(obj, messageIdxInSelection, readMessageOption, dataSource);
                    obj.readMessagesInBackground(segId, readMessageOption, dataSource, msgSegBuffer);
                else
                    obj.readMessagesInBackground(segId, readMessageOption, dataSource, msgSegBuffer);
                    msgSeg = msgSegBuffer(segId);
                    waitfor(msgSeg,'IsLoaded',true);
                    msg = msgSeg.getMessage(messageIdxInSeg);
                end
            end
        end
    end
    
    methods(Static)
        function [uriPath, storageFormat] = getFileURIAndStorageFormat(uriPath)

            % Validate inputs
            uriPath = convertStringsToChars(uriPath);

            if isfile(uriPath)
                uriPath = ros.internal.Parsing.validateFilePath(uriPath);
                [~,~,extension] = fileparts(uriPath);
                if ~isempty(extension) 
                    if isequal(lower(extension),'.zstd')
                        error(message('ros:mlros2:bag:InvalidPath'));
                    elseif ~ismember(lower(extension),{'.db3','.mcap'})
                        error(message('ros:mlros2:bag:UnSupportedFileExtension', extension));
                    end
                elseif isempty(extension)
                    error(message('ros:mlros2:bag:InvalidBagFile'));
                end
                
                if strcmpi(extension,'.db3')
                    storageFormat = 'sqlite3';
                elseif strcmpi(extension,'.mcap')
                    storageFormat = 'mcap';
                end
            else
                uriFolderPath = ros.internal.Parsing.validateFolderPath(uriPath);

                % Throw the error if input folder does not exist.
                dirInfo = dir(uriFolderPath);
                whichPkgs = ~ismember({dirInfo.name}, {'.', '..'});
                fList = {dirInfo(whichPkgs).name};

                db3Found = false;
                mcapFound = false;
                yamlFound = false;
                storageFormat = '';
                for fi = 1:length(fList)
                    if endsWith(fList{fi},'.db3') || endsWith(fList{fi},'.db3.zstd')
                        db3Found = true;
                        storageFormat = 'sqlite3';
                    elseif endsWith(fList{fi},'.mcap') || endsWith(fList{fi},'.mcap.zstd')
                        mcapFound = true;
                        storageFormat = 'mcap';
                    elseif(isequal(fList{fi},'metadata.yaml'))
                        yamlFound = true;
                    else
                        continue;
                    end
                end

                % Folder should contain both yaml and db3/mcap. It should
                % not contain both db3 and mcap
                if ~((db3Found || mcapFound) && yamlFound) || (db3Found && mcapFound)
                   error(message('ros:mlros2:bag:InvalidBagFolder', uriFolderPath));
                end

                uriPath = fullfile(uriFolderPath,'.');
            end

            uriPath = strrep(uriPath,'\','/');
        end
    end

    methods
        
        function obj = ros2bagreader(uriPath)

            [uriPath, storageFormat] = ros2bagreader.getFileURIAndStorageFormat(uriPath);
            
            [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = ros.internal.ros2.setupRos2Env(); %#ok<ASGLU>

            try
                obj.Bag = rosbag2.bag2.internal.Ros2bagWrapper(uriPath, "", storageFormat);
            catch ex
                if strcmp(ex.identifier, 'ros:mlros2:bag:FileReadingError')...
                        || strcmp(ex.identifier, 'ros:mlros2:bag:InvalidYAMLFile')...
                        || strcmp(ex.identifier, 'ros:mlros2:bag:YAMLFileNotFound')...
                        || strcmp(ex.identifier, 'ros:mlros2:bag:ErrorCalculatingBagDirSize')...
                        || strcmp(ex.identifier, 'ros:mlros2:bag:ReadException')...
                        || strcmp(ex.identifier, 'ros:mlros2:bag:UnknownExceptionOccurred')
                    error(ex.identifier, ex.message)
                else
                    rethrow(ex)
                end
            end
            % Initialize the maps
            obj.TopicTypeMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
            obj.TopicDefinitionMap = containers.Map('KeyType', 'char', 'ValueType', 'char');

            bag = obj.Bag;

            % Extract file path and available files 
            % in the specified location using MCOS properties
            obj.FilePath = bag.FilePath;
            obj.AvailableBags = bag.AvailableFiles;
            topics = bag.topics('.*');
            topicTypes = bag.topicType(topics);

            % Populate TopicTypeMap and TopicDefinitionMap
            for i = 1:numel(topics)
                rosMessageType = topicTypes{i};
                obj.TopicTypeMap(topics{i}) = rosMessageType;

                try
                    if ~bag.ifMessageTypeRegistered(rosMessageType)
                        minfo = ros.internal.ros2.getMessageInfo(rosMessageType);
                        [cppFactoryClass , cppElementType] = ...
                            ros.internal.ros2.getCPPFactoryClassAndType(rosMessageType);
                        dllPaths = ros.internal.utilities.getPathOfDependentDlls(rosMessageType,'ros2');
                        dllPaths{end + 1} = minfo.path; %#ok<AGROW>
                        bag.registerMessageType(rosMessageType,cppFactoryClass,cppElementType,dllPaths);
                    end
    
                    % Get message definition and MATLAB-compatible definition
                    rosMsgDef = ros2("msg","show",topicTypes{i});
                    rosMsgDefLines = string(rosMsgDef).splitlines;
                    obj.TopicDefinitionMap(topics{i}) = ros.msg.internal.formatMessageDefinition(...
                        char(strjoin(rosMsgDefLines(2:end), newline)), {}, {});
                catch ex
                    % warning(message('ros:mlros2:bag:UnknownMessageType',topics{i},rosMessageType))
                    obj.TopicDefinitionMap(topics{i}) = '';
                end
            end

            % Get list of all the messages in the bag, along with relevant
            % meta-data
            msgListInfo = bag.getMessageList;
            msgTime = double(msgListInfo{1})/1e9;
            obj.DoubleToUint64TimeStampDict = dictionary(msgTime,msgListInfo{1});
            msgTopic = categorical(msgListInfo{2}, 1:numel(msgListInfo{3}), msgListInfo{3});
            msgType = categorical(msgListInfo{2}, 1:numel(msgListInfo{4}), msgListInfo{4});

            % Populate MessageList
            % Add the message indices to the table. Note that all the
            % table entries are already sorted by message time.
            obj.MessageList = table(msgTime, msgTopic, ...
                                    msgType, 'VariableNames', ...
                                    {'Time', 'Topic', 'MessageType'});

            % Assign object properties that are derived from the full
            % message list
            if obj.NumMessages == 0
                % No point of further processing
                return;
            end

            obj.StartTime = obj.MessageList(1,1).Time;
            obj.EndTime = obj.MessageList(end,1).Time;

            % Recover the topics contained within the message list
            topics = categories(obj.MessageList.Topic);

            types = cellfun(@obj.TopicTypeMap, topics, 'UniformOutput', false);
            defs = cellfun(@obj.TopicDefinitionMap, topics, 'UniformOutput', false);

            % Build table of all topics contained in selection and sort the
            % table rows by alphabetical topic name
            numMessagePerTopic = histcounts(obj.MessageList.Topic);
            obj.AvailableTopics = table( numMessagePerTopic', ...
                                         categorical(types), defs, 'RowNames', topics, 'VariableNames', ...
                                         {'NumMessages', 'MessageType', 'MessageDefinition'});
            obj.AvailableTopics = sortrows(obj.AvailableTopics, 'RowNames');
            obj.AvailableTopicsCell = obj.AvailableTopics.Row;

            obj.BagTF = rosbag2.bag2.internal.Ros2bagTfWrapper(uriPath, storageFormat);
            obj.BagTF.build(obj.StartTime, obj.EndTime, "/tf");
            obj.AvailableFrames = sort(obj.BagTF.AvailableFrames);

            % Initialize the buffers
            obj.RawMessageBuffer = containers.Map;
            obj.ImgMessageBuffer = containers.Map;
            obj.PointCloudBuffer = containers.Map;
            obj.LaserScanBuffer = containers.Map;
        end

        function msgs = readMessages(obj, rows)
        %readMessages Read messages from ros2bagreader object.
        %   MSGS = readMessages(BAG) returns data from all of the
        %   messages in the ros2bagreader object, ROS2BAGREADER. The messages are returned
        %   as a cell array of structures.
        %
        %   MSGS = readMessages(BAG, ROWS) returns data from messages
        %   in the rows specified by the ROWS argument. All elements of
        %   ROWS must be within the range [1 BAG.NumMessages].
        %
        %   Example:
        %         % create ros2bagreader and read messages from ROS 2
        %         % bag log file present in user-specified bag folder.
        %         folderPath = "ros2_sensor_data/rosbag2_2020_09_02-21_19_47"
        %         bag = ros2bagreader(folderPath);
        %
        %         % Return all sensor_msgs/Image messages as a cell array
        %         of structures.
        %         imageStructs = readMessages(bag);
        %         imageStructs{1}
        %
        %         % Return only the first 10 messages
        %         firstImageStructs = readMessages(bag, 1:10);
        %

            if nargin < 2
                readAll = true;
                rows = 1:height(obj.MessageList);
            else
                validateattributes(rows, {'numeric'}, {'vector', 'integer'}, 'readMessages', 'rows')
                readAll = false;
            end

            % Return right away if there is nothing to read
            if isempty(rows)
                msgs = {};
                return;
            end

            if (min(rows) < 1) || (max(rows) > height(obj.MessageList))
                error(message('ros:mlros2:bag:MsgIndicesInvalid', ...
                              num2str(1), height(obj.MessageList)));
            end

            [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = ros.internal.ros2.setupRos2Env(); %#ok<ASGLU>
            if readAll && numel(obj.FilterMessageStartTime) < 2
                
                %If multiple time filters are given by user, instead of
                %readall, read  subset api is used. It is because
                %the new 3p does not support filtering multiple time stamp
                %at once.

                % Retrieve all messages if user did not specify rows
                msgs = obj.Bag.readAll(height(obj.MessageList),obj.SelectionId);
            else
                sizeIdx = numel(rows);
                diffIdx = zeros(1,sizeIdx);
                for ii=1:sizeIdx
                    leastTimeStamp = find(obj.MessageList.Time == obj.MessageList.Time(rows(ii)),1);
                    diffIdx(ii) = rows(ii) - leastTimeStamp;
                end
                
                % Retrieve subset of messages that user specified
                timeStampsInUint64 = obj.DoubleToUint64TimeStampDict(obj.MessageList.Time(rows));
                msgs = obj.Bag.readSubset(timeStampsInUint64,diffIdx,obj.SelectionId);
            end
        end

        function bagSelect = select(obj, varargin)
        %select Select subset of messages in ros2bagreader object
        %   BAGSEL = SELECT(OBJ) returns an object, BAGSEL, that
        %   contains all of the messages in the ros2bagreader object,
        %   OBJ.
        %
        %   BAGSEL = select(___,Name=Value) specifies options using one or
        %   more name-value arguments in addition to any combination of 
        %   input arguments from previous syntaxes.You can specify several
        %   name-value pair arguments in any order as
        %   Name1,Value1,...,NameN,ValueN:
        %
        %      "Time"     -   Start and end times of ros2bagreader selection
        %                     Start and end times of the ros2bagreader selection,
        %                     specified as an n-by-2 vector.
        %      "Topic"    -   ROS 2 topic name, specified as a string scalar,
        %                     character vector, cell array of string scalars,
        %                     or cell array of character vectors. Multiple topic
        %                     names can be specified with a cell array.
        %      "MessageType" - ROS 2 message type
        %                      ROS 2 message type, specified as a string scalar,
        %                      character vector, cell array of string scalars, 
        %                      or cell array of character vectors. Multiple
        %                      message types can be specified with a cell array.
        %
        %   Use SELECT to filter the messages available in the returned ros2bagreader object.
        %   You can use name-value pairs to specify a subset of the
        %   ros2bagreader messages.
        %
        %   This function does not change the contents of the original
        %   ros2bagreader object. It returns a new object that contains
        %   the specified message selection.
        %
        %
        %   Example:
        %      % Select messages in the first second of the ros2bagreader
        %      bagMsgs2 = SELECT(bagMsgs,Time=[bagMsgs.MessageList(1,1).Time, ...
        %         bagMsgs.MessageList(2,1).Time])
        %
        %      % Select one topic
        %      bagMsgs2 = SELECT(bagMsgs,Topic="/odom")
        %
        %      % Select multiple topics
        %      bagMsgs2 = SELECT(bagMsgs,Topic={"/odom", "/scan"})
        %
        %      % Select by multiple time intervals and message type
        %      bagMsgs2 = SELECT(bagMsgs,Time=[0 1; 5 7],...
        %         MessageType="std_msgs/String")

        % If no selection occurs, return the selection as-is
            if nargin == 1
                bagSelect = obj;
                return;
            end

            % Parse the inputs to the function
            defaults.Time = [];
            defaults.Topic = cell.empty;
            defaults.MessageType = cell.empty;

            select = obj.getSelectArguments(defaults, varargin{:});

            % Create a new reader object
            bagSelect = obj;

            % Combine indexing vectors depending on conditions set in the
            % function inputs
            indexOp = logical(ones(height(obj.MessageList),1)); %#ok<LOGL>
            unionOp = ~indexOp;

            % Filter given time interval
            if ~isempty(select.Time)
                timeOp = unionOp;
                for i = 1:size(select.Time,1)
                    % The interval union is considered for selection
                    timeOp = timeOp | (obj.MessageList.Time >= select.Time(i,1) ...
                                       & obj.MessageList.Time <= select.Time(i,2));

                    %Store the time selection
                    bagSelect.FilterMessageStartTime{end+1} = select.Time(i,1);
                    bagSelect.FilterMessageEndTime{end+1} = select.Time(i,2);
                end
                indexOp = indexOp & timeOp;
            end

            % Filter by topic name(s)
            if ~isempty(select.Topic)
                topicOp = unionOp;
                for i = 1:numel(select.Topic)
                    % The topic name union is considered for selection
                    topicOp = topicOp | (obj.MessageList.Topic == select.Topic{i});
                end
                indexOp = indexOp & topicOp;
            end

            % Filter by message type(s)
            if ~isempty(select.MessageType)
                typeOp = unionOp;
                for i = 1:numel(select.MessageType)
                    % The messageType union is considered for selection
                    typeOp = typeOp | (obj.MessageList.MessageType == select.MessageType{i});
                end
                indexOp = indexOp & typeOp;
            end

            % Apply the filtering criteria to the newly created ros2bagreader.
            bagSelect.StartTime = 0;
            bagSelect.EndTime = 0;
            bagSelect.AvailableTopics = table.empty(0,3);
            bagSelect.MessageList = obj.MessageList(indexOp,:);

            persistent selectionId;
            if isempty(selectionId)
                selectionId = 0;
            end
            selectionId = selectionId + 1;
            bagSelect.SelectionId = selectionId;

            if bagSelect.NumMessages == 0
                % No point of further processing
                return;
            end

            bagSelect.StartTime = min(bagSelect.MessageList.Time);
            bagSelect.EndTime = max(bagSelect.MessageList.Time);

            % Recover the topics contained within the message list
            topics = cellstr(unique(bagSelect.MessageList.Topic));
            types = cellfun(@bagSelect.TopicTypeMap, topics, 'UniformOutput', false);
            defs = cellfun(@bagSelect.TopicDefinitionMap, topics, 'UniformOutput', false);

            % Build table of all topics contained in selection and sort the
            % table rows by alphabetical topic name
            numMessagePerTopic = histcounts(bagSelect.MessageList.Topic);
            numMessagePerTopic = numMessagePerTopic(numMessagePerTopic~=0);
            bagSelect.AvailableTopics = table( numMessagePerTopic', ...
                                               categorical(types), defs, 'RowNames', topics, 'VariableNames', ...
                                               {'NumMessages', 'MessageType', 'MessageDefinition'});
            bagSelect.AvailableTopics = sortrows(bagSelect.AvailableTopics, 'RowNames');
            bagSelect.AvailableTopicsCell = bagSelect.AvailableTopics.Row;

            % Initialize the buffers
            bagSelect.RawMessageBuffer = containers.Map;
            bagSelect.ImgMessageBuffer = containers.Map;
            bagSelect.PointCloudBuffer = containers.Map;
            bagSelect.LaserScanBuffer = containers.Map;

            [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = ros.internal.ros2.setupRos2Env(); %#ok<ASGLU>
            bagSelect.Bag.resetView(bagSelect.AvailableTopicsCell, ...
                              bagSelect.DoubleToUint64TimeStampDict(bagSelect.StartTime), ...
                              bagSelect.DoubleToUint64TimeStampDict(bagSelect.EndTime), ...
                              bagSelect.SelectionId, ...
                              bagSelect.NumMessages);
        end

        function tf = getTransform(obj, targetFrame, sourceFrame, varargin)
        %getTransform Return transformation between two coordinate frames
        %   TF = getTransform(BAG,'TARGETFRAME','SOURCEFRAME') returns
        %   the latest known transformation between two coordinate frames in
        %   the ros2bagreader object.
        %   TF represents the transformation that takes coordinates
        %   in the SOURCEFRAME into the corresponding coordinates in
        %   the TARGETFRAME. An error is displayed if no
        %   transformation between these frames exists in the bag.
        %
        %   TF = getTransform(BAG,'TARGETFRAME','SOURCEFRAME',SOURCETIME)
        %   returns the transformation at the given SOURCETIME. An error
        %   is displayed if the transformation at that time is not
        %   available.
        %
        %   Example:
        %       % Load ros2bagreader
        %       bag = ros2bagreader(folderPath);
        %
        %       % Get list of all available frames
        %       frames = bag.AvailableFrames
        %
        %       % Get the latest transformation between two coordinate frames
        %       tfMsg = getTransform(bag,frames{2},frames{1})
        %
        %       % Get transformation at specific time
        %       tfMsgAtTime = getTransform(bag,frames{2},frames{1},ros2time(bag.StartTime + 1))
        %
        %   See also canTransform.
            
            import ros.internal.Parsing.validateROS2Time;

            narginchk(3, 4);

            % Validate frame names
            validTargetFrame = obj.validateFrame(targetFrame, 'getTransform', 'targetFrame');
            validSourceFrame = obj.validateFrame(sourceFrame, 'getTransform', 'sourceFrame');
            
            % Validate source time
            switch length(varargin)
                case 0
                    % Syntax: getTransform('TARGETFRAME', 'SOURCEFRAME')
                    % Return defaults.
                    sourceTime = ros2time(0);

                case 1
                    % Syntax: getTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME)
                    sourceTime = validateROS2Time(varargin{1}, 'getTransform', 'sourceTime');
            end
            validSourceTime = double(sourceTime.sec) + double(sourceTime.nanosec)*1e-9;

            % Retrieve transformation
            transform = obj.BagTF.lookupTransform(validTargetFrame, validSourceFrame, validSourceTime);

            % Return TransformStamped message
            tf = ros2message('geometry_msgs/TransformStamped');
            tf.child_frame_id = sourceFrame;
            tf.header.frame_id = targetFrame;
            tf.header.stamp = sourceTime;

            tf.transform.translation.x = transform.translation(1);
            tf.transform.translation.y = transform.translation(2);
            tf.transform.translation.z = transform.translation(3);

            tf.transform.rotation.w = transform.rotation(4);
            tf.transform.rotation.x = transform.rotation(1);
            tf.transform.rotation.y = transform.rotation(2);
            tf.transform.rotation.z = transform.rotation(3);
        end

        function isAvailable = canTransform(obj, targetFrame, sourceFrame, varargin)
        %canTransform Verify if transformation is available
        %   ISAVAILABLE = canTransform(BAG,TARGETFRAME,SOURCEFRAME)
        %   verifies if a transformation that takes coordinates
        %   in the SOURCEFRAME into the corresponding coordinates in
        %   the TARGETFRAME is available. ISAVAILABLE is TRUE if that
        %   transformation is available and FALSE otherwise.
        %   Use getTransform to retrieve the transformation.
        %
        %   ISAVAILABLE = canTransform(BAG,TARGETFRAME,SOURCEFRAME,SOURCETIME)
        %   verifies that the transformation is available for the time
        %   SOURCETIME. If SOURCETIME is outside of the buffer window
        %   for the transformation tree, the function returns FALSE.
        %   Use getTransform with the SOURCETIME argument to retrieve
        %   the transformation.

            import ros.internal.Parsing.validateROS2Time;

            narginchk(3, 4);

            % Validate frame names
            validTargetFrame = obj.validateFrame(targetFrame, 'canTransform', 'targetFrame');
            validSourceFrame = obj.validateFrame(sourceFrame, 'canTransform', 'sourceFrame');
            
            % Validate source time
            switch length(varargin)
                case 0
                    % Syntax: canTransform('TARGETFRAME', 'SOURCEFRAME')
                    % Return defaults.
                    sourceTime = ros2time(0);

                case 1
                    % Syntax: canTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME)
                    sourceTime = validateROS2Time(varargin{1}, 'canTransform', 'sourceTime');
            end
            % Create double nano source time
            validSourceTime = double(sourceTime.sec) + double(sourceTime.nanosec)*1e-9;

            isAvailable = obj.BagTF.canTransform(validTargetFrame, validSourceFrame, validSourceTime);
        end


        function tb = timetable(obj, varargin)
            %TIMETABLE Returns a timetable object for message properties
            %   TB = TIMETABLE(OBJ) returns a time table object for all
            %   numeric and scalar message properties. The method evaluates
            %   each message in the current ros2bagreader object, OBJ, and
            %   returns a Timetable object, TB.
            %
            %   TB = TIMETABLE(OBJ, 'PROP') returns a time table
            %   for a specific message property, PROP.
            %
            %   TB = TIMETABLE(OBJ, 'PROP1', ..., 'PROPN') returns
            %   a time table for a range of message properties, from PROP1
            %   to PROPN. Each property is a different column in the
            %   timetable object, TB.
            %
            %   TIMETABLE is a type of table that associates a time with
            %   each row. Like table, the timetable data type can store
            %   column-oriented data variables that have the same number
            %   of rows. All table functions work with timetables.
            %   In addition, timetables provide time-specific functions to
            %   align, combine, and perform calculations with one or more
            %   timetables.
            %
            %   The TIMETABLE object returned by this method is
            %   memory-efficient because it only stores particular message
            %   properties, not whole messages.
            %
            %
            %   Example:
            %      % Call with a single property
            %      tb = TIMETABLE(bagMsgs, 'pose.pose.position.x')
            %
            %      % Extract timetable with multiple properties
            %      tb = TIMETABLE(bagMsgs, 'twist.twist.angular.x', ...
            %         'twist.twist.angular.y', 'twist.twist.angular.z')
            %
            %      % Extract timetable for multiple topics
            %
            %      % Open a rosbag and retrieve information about its contents
            %      folderPath = 'path/to/ros2bags';
            %
            %      % The parsing returns a selection of all messages
            %      bagMsgs = ros2bagreader(folderPath)
            %
            %      % Select a subset of the messages by time and multiple topic
            %      bagMsgs2 = select(bagMsgs, 'Time', ...
            %          [bagMsgs.StartTime bagMsgs.StartTime + 1], ...
            %                       'Topic', {'/odom', '/imu/data')
            %
            %      tb = TIMETABLE(bagMsgs2, 'twist.twist.angular.x', ...
            %         'twist.twist.angular.y', 'twist.twist.angular.z')
            %
            %      % Access the first element if bagMsgs2 is array message 
            %      arraymsg1 = tb('/odom_twist.twist.angular.x')(1)

          tb = timetable.empty;

            % If message selection is empty return right away
            if isempty(obj.MessageList)
                return;
            end
            allTopics = obj.AvailableTopics.Row;
            numTopics = length(allTopics);
            for indx = 1:numTopics
                % Extract and validate property arguments
                selobj = obj.select('Topic', allTopics(indx));
                topicCell = allTopics(indx);
                if selobj.NumMessages <= 0
                    warning(message('ros:mlros2:bag:TopicHasNoMsg',topicCell{1}))
                    continue;
                end
                messageType = char(categories(selobj.AvailableTopics.MessageType));
                if ~any(ismember(ros2('msg','list'),messageType),"all")
                    warning(message('ros:mlros2:bag:UnknownMessageType',topicCell{1},messageType))
                    continue;
                end
                props = selobj.getTimeTableArguments(messageType, varargin{:});

                % Time needs to be in sorted order
                index = selobj.MessageList;
                time = seconds(index.Time);
                numMsg = selobj.NumMessages;
                data = cell(numMsg, numel(props));
                % Extract messages in chunks of 50 messages
                %Should be reasonably fast, while still preserving memory
                msgIdx = 1: 50: numMsg;
                for i = 1: length(msgIdx)
                    if i == length(msgIdx)
                        msgs = selobj.readMessages(msgIdx(i):numMsg);
                    else
                        msgs = selobj.readMessages(msgIdx(i):msgIdx(i+1)-1);
                    end
                    % Extract properties from messages
                    results = cellfun(@(msg) obj.evaluateProperties(msg, props), msgs, 'UniformOutput', false);

                    % Determine the row indices
                    row_indices = msgIdx(i) + (1:length(msgs)) - 1;

                    % Assign the results to the appropriate rows in the data cell array
                    data(row_indices, 1:numel(props)) = num2cell(vertcat(results{:}));
                end                
                propertyName = cellfun(@(x) [[allTopics{indx} '_'], x], props, 'UniformOutput', false);
                tbj = array2timetable(data, 'VariableNames', propertyName, 'RowTimes', time);

                if indx == 1
                    tb = tbj;
                else
                   tb=synchronize(tb, tbj, 'union', 'fillwithconstant', 'Constant', {0});
                end
            end
        end
    end

    methods(Hidden)
        function res = isequal(self, other)
            % override isequal method to compare only user facing
            % properties to determine if two objects are equal. Other
            % hidden and private class fields which is used for internal
            % implementation(such as SelectionId) should not be compared.

            res = isequal(self.FilePath,other.FilePath) ...
                    && isequal(self.AvailableBags,other.AvailableBags) ...
                    && isequal(self.StartTime,other.StartTime) ...
                    && isequal(self.EndTime,other.EndTime) ...
                    && isequal(self.NumMessages,other.NumMessages) ...
                    && isequal(self.AvailableTopics,other.AvailableTopics) ...
                    && isequal(self.AvailableFrames,other.AvailableFrames) ...
                    && isequal(self.MessageList,other.MessageList);
        end
    end

    methods
        function NumMessages = get.NumMessages(obj)
        % get the number of messages
            NumMessages = height(obj.MessageList);
        end
    end

    methods (Static, Access = private)
        function select = getSelectArguments(defaults, varargin)
        %getSelectArguments Parse arguments of the select function

            parser = inputParser;

            % Convert all strings to character vectors or cell arrays of
            % character vectors.
            [varargin{:}] = convertStringsToChars(varargin{:});

            % Specify valid Name-Value pairs
            addParameter(parser, 'Time', defaults.Time, @(x) validateattributes(x, ...
                                                              {'double'}, {'nonempty', 'ncols', 2}));
            addParameter(parser, 'Topic', defaults.Topic, @(x) validateattributes(x, ...
                                                              {'char', 'cell', 'string'}, {'nonempty', 'vector'}));
            addParameter(parser, 'MessageType', defaults.MessageType, @(x) validateattributes(x, ...
                                                              {'char', 'cell', 'string'}, {'nonempty', 'vector'}));

            % Parse the input and assign outputs
            parse(parser, varargin{:});

            select.Time = parser.Results.Time;
            select.Topic = parser.Results.Topic;
            select.MessageType = parser.Results.MessageType;

            % If single topic input, convert to cell
            % Also verifies that all cell elements are strings
            try
                select.Topic = cellstr(select.Topic);
            catch
                error(message('ros:mlros2:bag:CellStringInvalid', 'Topic'));
            end

            % Add leading slashes to the topic names (if they don't exist)
            select.Topic = cellfun(@(x) ros.ros2.internal.addLeadingSlash(x), ...
                                   select.Topic, 'UniformOutput', false);

            % If single message type input, convert to cell
            % Also verifies that all cell elements are strings
            try
                select.MessageType = cellstr(select.MessageType);
            catch
                error(message('ros:mlros2:bag:CellStringInvalid', 'MessageType'));
            end
        end

        function validFrameName = validateFrame(frameName, funcName, varName)
        %validateFrame Validate a frame name and return a name that is always valid
        %   This function will remove a leading slash (/) if it exists
        %   (consistent with ROS C++ and Python). If the frame name
        %   starts with two slashes, an error is displayed.

            % Filter out non-string, non-char input
            validateattributes(frameName, {'char','string'}, {'nonempty','scalartext'}, funcName, varName);

            frameNameChar = convertStringsToChars(frameName);
            validFrameName = regexprep(frameNameChar,'^/+','');
            
            % Verify again to avoid empty string after removing leading
            % slashes
            validateattributes(validFrameName, {'char','string'}, {'nonempty','scalartext'}, funcName, varName);

        end

        function props = getTimeTableArguments(messageType, varargin)
        %gettimetableArguments Extract and validate property arguments
        %   These properties are given as input arguments to the
        %   timetable function.

            numProps = numel(varargin);
            props = cell(numProps, 1);

            % Retrieve cell array of valid properties
            validProps = ros2bagreader.getNumericScalarProperties(messageType);

            % If no properties are specified return a timetable containing
            % all numeric, scalar properties
            if nargin == 1
                props = validProps;
                return;
            end

            for i = 1:numProps
                % All properties have to be strings
                prop = robotics.internal.validation.validateString(varargin{i}, false, 'timeseries', 'Property');

                % Validate that the given property is accessible and
                % a numeric scalar
                if ~ismember(prop, validProps)
                    error(message('ros:mlros:bag:MsgPropertyInvalid', ...
                                  prop, messageType));
                end

                props{i} = prop;
            end
        end

        function props = getNumericScalarProperties(messageType)
            %getNumericScalarProperties Get all properties for message type
            %
            %   PROPS = getNumericScalarProperties(MESSAGETYPE) retrieves a
            %   cell array of strings of valid numeric, scalar properties
            %   in a message of type MESSAGETYPE.

            structMsg = ros2message(messageType);
            % List all valid properties
            props = ros2bagreader.listStructProperties(structMsg, '');
        end

        function props = listStructProperties(structMsg, prefix)
        %evaluateStructProperties Recursively list all numeric props
        %
        %   PROPS = listStructProperties(STRUCTMSG, PREFIX) recursively
        %   evaluates the input structure STRUCTMSG and extract all
        %   numeric, scalar properties. The property name will be
        %   prefixed by the PREFIX namespace. All valid properties are
        %   returned as cell array of strings PROPS.

            props = {};

            % Look through all structure fields
            strFields = fields(structMsg);
            for i = 1:length(strFields)
                % Extract field name and value
                fieldName = strFields{i};
                fieldValue = structMsg.(fieldName);

                % End of recursion
                % If property is numeric and a scalar, add to return list
                if isnumeric(fieldValue) && isscalar(fieldValue)
                    props{end+1,1} = [prefix fieldName]; %#ok<AGROW>
                    continue;
                end

                % Recurse into nested structures
                if isa(fieldValue, 'struct')
                    props = [props; ros2bagreader.listStructProperties( ...
                        fieldValue, [prefix fieldName '.'])]; %#ok<AGROW>
                end
            end

        end

        function data = evaluateProperties(msg, props) %#ok<INUSL>
        %evaluateProperties Evaluate properties for a message object

            data = cell(1, numel(props));

            for i = 1:length(props)
                propName = props{i};

                splitProp = strsplit(['msg.' propName], '.');
                firstFields = splitProp(1:2);
                lastProps = cellfun(@(vi) ['.' splitProp{vi+2}], num2cell(1:length(splitProp)-2), 'UniformOutput', false);
                if ~isscalar(msg.(firstFields{2})) && ~isempty(lastProps)
                    lastProps = strcat(lastProps{:});
                    for di=1:numel(msg.(firstFields{2}))
                        try
                            fieldname = strrep(['msg.' firstFields{2} '(' num2str(di) ')' lastProps], ' ', '');
                            dataArray{di} = eval(fieldname);
                        catch ME
                            if strcmp(ME.identifier, 'MATLAB:needMoreRhsOutputs')
                                dataArray{di} = nan;
                            end
                        end
                    end
                    value = dataArray';
                else
                    value = eval(['msg.' propName]);
                end

                % Have to use eval here since propName potentially
                % contains multiple indirections / namespaces
                
                %value = msg.(propName);
                if isempty(value)
                    data{1,i} = nan;
                else
                    data{1,i} = value;
                end
            end

        end
    end
end

% LocalWords:  MCAP Seg Segs compressedimage laserscan seg zstd mcap readall TARGETFRAME SOURCEFRAME
% LocalWords:  SOURCETIME ISAVAILABLE nano PROPN imu arraymsg fillwithconstant gettimetable
% LocalWords:  STRUCTMSG
