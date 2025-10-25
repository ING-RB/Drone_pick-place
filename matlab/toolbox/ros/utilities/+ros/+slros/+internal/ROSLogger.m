classdef ROSLogger
%This class is for internal use only. It may be removed in the future.

%  ROSLogger - Used to check the version of the ROS and initiate the
%  respective class methods and properties. ROSLogger constructor creates
%  ROSLoggerHelper obj of either ROS or ROS 2 Logger helper.

%   Copyright 2022-2024 The MathWorks, Inc.

    properties
        %ROSLoggerHelper Used to initiate the Logger helper object
        ROSLoggerHelper
    end

    methods
        % Constructor
        function obj = ROSLogger(modelName)
            activeConfigObj = getActiveConfigSet(modelName);
            version=get_param(activeConfigObj,'HardwareBoard');
            if strcmp(version,'Robot Operating System (ROS)')
                obj.ROSLoggerHelper=ros.slroscpp.internal.ROSLoggerHelper;
            elseif strcmp(version,'Robot Operating System 2 (ROS 2)')
                obj.ROSLoggerHelper=ros.slros2.internal.ROSLoggerHelper;
            end
        end

        % Src block properties
        function allSrcBlk = getAllSrcBlk(obj)
            allSrcBlk = obj.ROSLoggerHelper.AllSrcBlk;
        end
        
        % Store the Simulation start time in the singleton
        function setStartTime(obj, modelName)
            inst = ros.slros.internal.TimeStamp.getInstance();
            inst.startTimeStamp = obj.ROSLoggerHelper.getTime(modelName);
        end

        % Get the Simulation start time from the singleton
        function tsp = getStartTime(obj)
            inst = ros.slros.internal.TimeStamp.getInstance();
            tsp = obj.ROSLoggerHelper.convertFromROSTime(inst.startTimeStamp);
        end

        % Time object
        function time = getTime(obj,modelName)
            time = obj.ROSLoggerHelper.getTime(modelName);
        end

        function tsp = convertToROSTime(obj, currTime)
            tsp = obj.ROSLoggerHelper.convertToROSTime( currTime );
        end

        % Bag Writer Object 
        function [bagobj,bagFolderName] = getWriterObject(obj,logInfo)
            [bagobj,bagFolderName] = obj.ROSLoggerHelper.getWriterObject(logInfo);
        end

        % Blank message based on the msg Type
        function blankMessage = getBlankMessage(obj,msgType)
            blankMessage = obj.ROSLoggerHelper.getBlankMessage(msgType);
        end

        function allPubBlks = getPublishBlocks(obj,modelName)
            allPubBlks = obj.ROSLoggerHelper.getPublishBlocks(modelName);
        end

        function msg = fillUpMsgFields(obj, msg, fieldLenInfo)
            msg = obj.ROSLoggerHelper.fillUpMsgFields(msg, fieldLenInfo);
        end

        function reportStatus(obj, statusInfo, varargin)
            obj.ROSLoggerHelper.reportStatus(statusInfo, varargin{:});
        end

        % Log signals to the bag file/folder
        function writeMessage(obj,timeStampShift,startTimeStamp,numOfMsgs,bagWriter,topicName,currentMsgArray)
            currentTimeStamp=startTimeStamp;
            for timeIndex = 1:numOfMsgs
                if numOfMsgs > 1
                    currentTimeStamp = obj.ROSLoggerHelper.addTimeShift(startTimeStamp,timeStampShift(timeIndex));
                end
                write(bagWriter, topicName, currentTimeStamp, currentMsgArray(timeIndex));
            end
        end
    end
end
