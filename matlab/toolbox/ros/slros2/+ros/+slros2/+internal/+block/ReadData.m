classdef ReadData < ros.slros.internal.block.ReadLogFileBase
    %This class is for internal use only. It may be removed in the future.

    %Play back data from a supported logfile
    %
    %   H = ros.slros2.internal.block.ReadData creates a system
    %   object, H, that accesses a supported logfile and plays back data
    %   from a topic.
    %
    %   This system object is intended for use with the MATLAB System
    %   block. In order to access the rosbag2 playback functionality from
    %   MATLAB, see ROS2BAGREADER.

    %   Copyright 2022-2023 The MathWorks, Inc.
    
    properties (Nontunable)
        %LogfileType Logfile type
        %   Type of logfile will be displayed on front of the block
        LogfileType = 'rosbag2';
    end    
    
    properties(Access=protected)
        %BusUtilObj Bus utility object used with Simulink bus conversion
        BusUtilObj = ros.slros2.internal.bus.Util;
    end
    
    properties (Access = protected, Transient)
        %DataObject Object containing or allowing for access to all logfile data
        DataObject = ros.slros2.internal.block.ReadData.getEmptyDataObject();

        %DataSelection Object containing or allowing access to applicable logfile data
        % (contained in topic, after offset, and before duration completes
        DataSelection = ros.slros2.internal.block.ReadData.getEmptyDataObject();


        %Converter Converts from logfile messages to struct for output to bus
        Converter = ros.slros2.internal.sim.ROSMsgToBusStructConverter.empty();
    end 
    
    methods (Access=protected)
        function ret = convertMessage(obj,msg)
            ret = convert(obj.Converter,msg);
        end
    end      
    methods (Static,Hidden)
        function ret = isValidLogdataObject(logObj)
            ret = false;
            if isa(logObj,'ros2bagreader')
                [~,~,extension] = fileparts(logObj.FilePath);
                if isempty(extension)
                    ros.internal.Parsing.validateFolderPath(logObj.FilePath);
                else
                    ros.internal.Parsing.validateFilePath(logObj.FilePath);
                end
                ret = true;
            end
        end
        
        function ret = getOutputDatatypeString(msgType,modelName)
            ros.slros2.internal.bus.Util.createBusIfNeeded(msgType,modelName);
            ret = ros.slros2.internal.bus.Util.rosMsgTypeToDataTypeStr(msgType);
        end
        
        function clearBusesOnModelClose(blk)
            ros.slros2.internal.bus.Util.clearSLBusesInGlobalScope(blk);
        end
        
        function ret = getBlockIcon()
            ret = 'rosicons.ros2lib_readdata';
        end
        
        function ret = getLogFileExtension()
            ret = '*.db3;*.mcap;metadata.yaml';
        end
        
        function ret = getEmptyMessage(msgType)
            ret = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType(msgType);
        end
        
        function ret = getEmptyDataObject()
            ret = ros2bagreader.empty();
        end
     
        function ret = getBusConverterObject(msgType,modelName)
            ret = ros.slros2.internal.sim.ROSMsgToBusStructConverter(msgType,...
                modelName);
        end
    end
end
