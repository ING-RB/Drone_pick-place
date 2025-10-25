classdef ROSLoggerHelper 

%This class is for internal use only. It may be removed in the future.

    % ROSLoggerHelper class is used to get ROS2 properties to log ROS2 Bus
    % Signals

    % Copyright 2022-2024 The MathWorks, Inc.

    % ROS 2 Source Blocks
    properties 
        AllSrcBlk = {'ROS2 Subscribe','Read Data from ROS2 Bag','ROS2 Publish','ROS2 Blank Message', ...
                            'ROS2 Header','ros.slros2.internal.block.CurrentTime', ...
                            'ROS2 Call Service', ...
                            'ROS2 Write Point Cloud','ROS2 Write Image', ...
                            'ros.slros2.internal.block.GetTransform', ...
                            'ros.slros2.internal.block.ApplyTransform'};
    end
    methods
        % ROS2 Time
        function time = getTime(~,modelName)
            timeNode=ros2node([modelName '_timeLogging']);
            time = ros2time(timeNode,"now");
        end
        % Create Bag folder name & ROS2 bag writer object
        function [bagobj,bagFolderName] = getWriterObject(~,logInfo)
                if isempty(logInfo.ROSLoggingInfo.BagFileName)
                    bagFolderName = [char(datetime('now','Format','MMddyy_HH_mm_ss'))];
                else
                    bagFolderName = [logInfo.ROSLoggingInfo.BagFileName '_' char(datetime('now','Format','MMddyy_HH_mm_ss'))];
                end
                if strcmp(logInfo.ROSLoggingInfo.StorageFormat,'sqlite3')
                    bagobj=ros2bagwriter(bagFolderName,"CacheSize",logInfo.ROSLoggingInfo.CacheSize, ...
                        "CompressionFormat", logInfo.ROSLoggingInfo.CompressionFormat, ...
                        "CompressionMode", logInfo.ROSLoggingInfo.CompressionMode, ...
                        "SplitDuration", logInfo.ROSLoggingInfo.SplitDuration, ...
                        "SplitSize", logInfo.ROSLoggingInfo.SplitSize);
                elseif strcmp(logInfo.ROSLoggingInfo.StorageFormat,'mcap')
                    if strcmp(logInfo.ROSLoggingInfo.StorageProfile,'custom')
                        bagobj=ros2bagwriter(bagFolderName,"CacheSize",logInfo.ROSLoggingInfo.CacheSize, ...
                            "StorageFormat", logInfo.ROSLoggingInfo.StorageFormat, ...
                            "CompressionFormat", logInfo.ROSLoggingInfo.CompressionFormat, ...
                            "CompressionMode", logInfo.ROSLoggingInfo.CompressionMode, ...
                            "SplitDuration", logInfo.ROSLoggingInfo.SplitDuration, ...
                            "SplitSize", logInfo.ROSLoggingInfo.SplitSize, ...
                            "StorageConfigurationProfile",logInfo.ROSLoggingInfo.StorageProfile,...
                            "StorageConfigurationFile",logInfo.ROSLoggingInfo.StorageConfigFile);
                    else
                        bagobj=ros2bagwriter(bagFolderName,"CacheSize",logInfo.ROSLoggingInfo.CacheSize, ...
                            "StorageFormat", logInfo.ROSLoggingInfo.StorageFormat, ...
                            "CompressionFormat", logInfo.ROSLoggingInfo.CompressionFormat, ...
                            "CompressionMode", logInfo.ROSLoggingInfo.CompressionMode, ...
                            "SplitDuration", logInfo.ROSLoggingInfo.SplitDuration, ...
                            "SplitSize", logInfo.ROSLoggingInfo.SplitSize, ...
                            "StorageConfigurationProfile",logInfo.ROSLoggingInfo.StorageProfile);
                    end
                end
                
                % By default Serialization format and Storage format are
                % set to 'cdr' and 'sqlite3' respectively. Only Cache size
                % can be set     
        end
        % Create ROS2 message based on messageType
        function blankMessage = getBlankMessage(~,msgType)
            blankMessage = ros2message(msgType);
        end
    
        % Get all ROS2 Publish blocks in the model
        function allPubBlks = getPublishBlocks(~,modelName)
            allPubBlks = find_system(modelName, 'FindAll','on', ...
                             'type','block', ...
                             'MaskType','ROS2 Publish');
        end

        % Add TimeShift
        function currentTimeStamp = addTimeShift(~,startTimeStamp, timeStampShift)
            startTimeInSec = double(startTimeStamp.sec) + double(startTimeStamp.nanosec)*1e-9;
            currentTimeStamp = ros2time(startTimeInSec + timeStampShift);
        end 

        % Fill up variable-size message fields
        function msg = fillUpMsgFields(obj, msg, fieldLenInfo)
            structFields = fieldnames(msg);
            numOfFields = numel(structFields);
            for i = 1:numOfFields
                if isstruct(msg.(structFields{i})) && (fieldLenInfo.numEntries > 0)
                    % This field is an variable-size message struct that need to be filled
                    allKeys = fieldLenInfo.keys;
                    targetKeyIndex = find(contains(allKeys,[structFields{i} '_SL_Info.CurrentLength']));
                    if ~isempty(targetKeyIndex)
                        fieldActualLen = fieldLenInfo(allKeys(targetKeyIndex(1))); 
                        if numel(msg.(structFields{i}))<fieldActualLen
                            [~,info,~] = ros.internal.getEmptyMessage(msg.MessageType,'ros2');
                            currentFieldMsg = ros2message(info.(structFields{i}).MessageType);
                            currentFieldMsg = obj.fillUpMsgFields(currentFieldMsg, fieldLenInfo);
                            structMsgs(1:fieldActualLen,1) = currentFieldMsg;
                            msg.(structFields{i}) = structMsgs;
                            clear('structMsgs');
                        end
                    end
                end
            end
        end

        % Report Status
        function reportStatus(~,statusInfo, varargin)
            if strcmp(statusInfo, 'Start')
                sldiagviewer.reportInfo(getString(message('ros:slros:roslogging:StartLoggingInfo','ROS 2')));
            elseif strcmp(statusInfo, 'Completed')
                sldiagviewer.reportInfo(getString(message('ros:slros:roslogging:StopLoggingInfo',varargin{1},'ROS 2')));
            elseif strcmp(statusInfo, 'Error')
                sldiagviewer.reportError(getString(message('ros:slros:roslogging:NoSpaceForSave',varargin{1},'ROS 2')));
            end
        end

        % Convert current time in seconds to a builtin_interfaces/TimeStamp
        % message
        function tsp = convertToROSTime(~, currTime)
            tsp = ros2time( currTime );
        end

        % Convert from a Time stamp message to time in seconds.
        function out = convertFromROSTime(~, currTsp)
            out = double(currTsp.sec) + double(currTsp.nanosec) * 1e-9;
        end
    end
end
