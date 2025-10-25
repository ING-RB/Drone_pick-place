classdef Util
%This class is for internal use only. It may be removed in the future.

%BUS.UTIL - Utility functions for working with Simulink buses of Gazebo Co-Simulation

%   Copyright 2019-2022 The MathWorks, Inc.

    properties

        %BusNamePrefix Select bus prefix name
        BusNamePrefix
        %MsgPackageName Name of message package
        MsgPackageName

    end

    %%  General Bus-related utilities
    methods

        function [busExists,busName,msgType] = checkForBus(obj,msgType, model)
            [busName,msgType] = obj.messageTypeToBusName(msgType, model, obj.BusNamePrefix);
            busExists = robotics.slcore.internal.util.existsInGlobalScope(bdroot(model), busName);
        end

        function busName = createBusIfNeeded(obj,msgType, model)
            validateattributes(msgType, {'char'}, {'nonempty'});
            validateattributes(model, {'char'}, {});

            [busExists,busName,msgType] = obj.checkForBus(msgType, model);
            if busExists
                return;
            end

            emptyStructMsg = obj.newMessageFromSimulinkMsgType(msgType,busName);

            robotics.slcore.internal.util.getBusDefnForStruct(emptyStructMsg, model, obj.BusNamePrefix);
        end

        function messageDefn = newMessageFromSimulinkMsgType(obj,msgType, busName)
        %newMessageFromSimulinkMsgType Create a new Gazebo message from message type
        %Currently we are using a class for each message type

            messageType = strrep(msgType,'/','_');
            if contains(messageType,'gazebo_msgs_JointState')
                msgSuffix = erase(messageType,'gazebo_msgs_JointState');
                if contains(msgSuffix,'fixed')
                    % the parent message is 'gazebo_msgs_JointState' so if
                    % message type contains suffix such as _fixed_1, which
                    % is added to support fixed dimension mode, then it
                    % should be removed as parent message definition is
                    % present in code base.
                    messageType = erase(messageType,msgSuffix);
                end
            end

            if contains(busName,'Gazebo_SL_Bus_gazebo_msgs_JointState')
                busSuffix = erase(busName,'Gazebo_SL_Bus_gazebo_msgs_JointState');
                if contains(busSuffix,'fixed')
                    % the parent bus name is
                    % 'Gazebo_SL_Bus_gazebo_msgs_JointState' so if
                    % bus contains suffix such as _fixed_1, which is added
                    % to support fixed dimension mode, then it should be
                    % removed as parent message definition is present in
                    % code base.
                    busName = erase(busName,busSuffix);
                end
            end

            msgClass = [obj.MsgPackageName,'G',messageType(2:end)];
            busClass = [obj.MsgPackageName,strrep(busName,'Gazebo_SL_Bus_g','G')];
            if(strcmp(msgClass,busClass))
                messageDefn = eval(msgClass);
            end
        end
    end


    methods (Static)
        function [datatype,busName] = messageTypeToDataTypeStr(messageType, model, busNamePrefix)

        %retain original bus prefix
            if nargin < 3
                busNamePrefix = 'SL_Bus_';
            end
            % This is used wherever a Simulink DataTypeStr is required
            % (e.g., for specifying the output datatype of a Constant block)
            % ** DOES NOT CREATE A BUS **
            busName = robotics.slcore.internal.bus.Util.messageTypeToBusName(messageType, model,busNamePrefix);
            datatype = ['Bus: ' busName];
        end

        function [busName,messageType] = messageTypeToBusName(messageType, model,busNamePrefix)
        %
        % messageTypeToBusName(MSGTYPE,MODEL) returns the bus name
        % corresponding to a message type MSGTYPE (e.g.,
        % 'std_msgs/Int32') and a Simulink model MODEL. The function
        % uses the following rules:
        %
        % Generate a name using the format: SL_Bus_<modelname>_<msgtype>
        %
        % Note: bus name should not exceed 60 char length.
        %
        % ** THIS FUNCTION DOES NOT CREATE A BUS OBJECT **

        %Keep original bus prefix name
            if nargin < 3
                busNamePrefix = 'SL_Bus_';
            end

            validateattributes(messageType, {'char'}, {'nonempty'});
            assert(ischar(model));

            busName = [busNamePrefix messageType];

            busName = matlab.lang.makeValidName(busName, 'ReplacementStyle', 'underscore');

        end
    end

end
