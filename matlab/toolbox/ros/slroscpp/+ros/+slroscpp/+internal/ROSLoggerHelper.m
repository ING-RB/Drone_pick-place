classdef ROSLoggerHelper

    %This class is for internal use only. It may be removed in the future.

    % ROSLoggerHelper class is used to get ROS properties to log ROS Bus
    % Signals

    % Copyright 2022-2024 The MathWorks, Inc.

    % ROS Source Blocks
    properties
        AllSrcBlk = {'ROS Subscribe','Read Data from ROS Bag','ROS Publish','ROS Blank Message', ...
                            'ROS Header','ros.slros.internal.block.CurrentTime', ...
                            'ROS Call Service', ...
                            'ROS Write Point Cloud','ROS Write Image', ...
                            'ros.slroscpp.internal.block.GetTransform', ...
                            'ros.slroscpp.internal.block.ApplyTransform'};
    end
    methods

        % Get ROS Time
        function time = getTime(~,~)
            time = rostime("now","DataFormat","struct");
        end

        % Create ROS bag file name and ROS bag writer object
        function [bagWriter,bagFileName] = getWriterObject(~,logInfo)
            if isempty(logInfo.ROSLoggingInfo.BagFileName)
                bagFileName = [char(datetime('now','Format','MMddyy_HH_mm_ss')) '.bag'];
            else
                bagFileName = [logInfo.ROSLoggingInfo.BagFileName '_' char(datetime('now','Format','MMddyy_HH_mm_ss')) '.bag'];
            end
            bagWriter = rosbagwriter(bagFileName, ...
                             "Compression", logInfo.ROSLoggingInfo.CompressionFormat, ...
                             "ChunkSize", logInfo.ROSLoggingInfo.ChunkSize);
        end

        % Create ROS message based on messageType 
        function blankMessage = getBlankMessage(~,msgType)
            blankMessage = rosmessage(msgType,"DataFormat","struct");
        end

        % Get all ROS Publish blocks in the model
        function allPubBlks = getPublishBlocks(~,modelName)
            allPubBlks = find_system(modelName, 'FindAll','on', ...
                             'type','block', ...
                             'MaskType','ROS Publish');
        end

        % Add TimeShit to the signals
        function currentTimeStamp = addTimeShift(~,startTimeStamp,timeStampShift)
            startTimeInSec = double(startTimeStamp.Sec) + double(startTimeStamp.Nsec)*1e-9;
            currentTimeStamp = rostime(startTimeInSec + timeStampShift);
        end

        % Fill up variable-size message fields
        function msg = fillUpMsgFields(obj, msg, fieldLenInfo)
            structFields = fieldnames(msg);
            numOfFields = numel(structFields);
            for i = 1:numOfFields
                if isstruct(msg.(structFields{i})) && isempty(msg.(structFields{i}))
                    % This field is an variable-size message struct that need to be filled
                    allKeys = fieldLenInfo.keys;
                    targetKeyIndex = find(contains(allKeys,[structFields{i} '_SL_Info.CurrentLength']));
                    fieldActualLen = fieldLenInfo(allKeys(targetKeyIndex(1))); 
                    [~,info,~] = ros.internal.getEmptyMessage(msg.MessageType,'ros');
                    currentFieldMsg = rosmessage(info.(structFields{i}).MessageType,"DataFormat","struct");
                    currentFieldMsg = obj.fillUpMsgFields(currentFieldMsg, fieldLenInfo);
                    structMsgs(1:fieldActualLen,1) = currentFieldMsg;
                    msg.(structFields{i}) = structMsgs;
                    clear('structMsgs');
                end
            end
        end

        % Report Status
        function reportStatus(~,statusInfo, varargin)
            if strcmp(statusInfo, 'Start')
                sldiagviewer.reportInfo(getString(message('ros:slros:roslogging:StartLoggingInfo','ROS')));
            elseif strcmp(statusInfo, 'Completed')
                sldiagviewer.reportInfo(getString(message('ros:slros:roslogging:StopLoggingInfo',varargin{1},'ROS')));
            elseif strcmp(statusInfo, 'Error')
                sldiagviewer.reportError(getString(message('ros:slros:roslogging:NoSpaceForSave',varargin{1},'ROS')));
            end
        end
        
        % Convert given time(in seconds) to ROS Timestamp message
        function tsp = convertToROSTime(~, currTime)
            tsp = rostime( currTime, "DataFormat", "struct" );
        end
        
        % Convert from ROS Timestamp message to time in seconds
        function out = convertFromROSTime(~, currTsp)
            out = double(currTsp.Sec) + double(currTsp.Nsec) * 1e-9;
        end
    end
end
