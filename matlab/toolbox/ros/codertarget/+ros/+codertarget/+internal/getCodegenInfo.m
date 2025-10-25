function cgInfo = getCodegenInfo(topic,messageType,listToAdd, rosver)
%GETCODEGENINFO Return code generation information for

%   Copyright 2020-2022 The MathWorks, Inc.
    if nargin < 4
        rosver = 'ros';
    end

    [msgStructGen,~,~,msgInfo] = ros.codertarget.internal.getEmptyCodegenMsg(messageType,rosver);

    cgInfo.CppHeader = msgInfo.includeHeader;
    cgInfo.MsgClass = msgInfo.msgCppClassName;
    cgInfo.MsgClassPtr = [msgInfo.msgCppClassName '*'];
    if isequal(rosver, 'ros')
        cgInfo.CppClass = ['boost::shared_ptr<' msgInfo.msgCppClassName ' const>'];
    else
        cgInfo.CppClass = ['std::shared_ptr<' msgInfo.msgCppClassName '>'];
    end
    cgInfo.CppConstClassRef = ['const ' cgInfo.CppClass '&'];
    cgInfo.MsgStructGen = msgStructGen;

    % Create additional field - CppSvcType for Service messages
    % Services need this specific treatment since the actual header file we
    % want to include must contains both Request and Response definition.
    if strcmp(cgInfo.MsgClass(end-6:end),'Request')
        cgInfo.CppSvcType = cgInfo.MsgClass(1:end-7);
    end

    if strcmp(rosver,'ros2')
        if strcmp(cgInfo.MsgClass(end-6:end),'Request')
            % Special treatment for ROS 2 Service messages
            svcInfo = ros.internal.ros2.getServiceInfo(messageType,messageType(1:end-7),'Request');
            cgInfo.CppSvcType = svcInfo.msgBaseCppClassName;
            cgInfo.MsgClass = svcInfo.msgCppClassName;
        elseif strcmp(cgInfo.MsgClass(end-7:end),'Response')
            % Special treatment for ROS 2 Service messages
            svcInfo = ros.internal.ros2.getServiceInfo(messageType,messageType(1:end-8),'Response');
            cgInfo.MsgClass = svcInfo.msgCppClassName;
        elseif strcmp(cgInfo.MsgClass(end-3:end),'Goal')
            % Special treatment for ROS 2 Action Client
            cgInfo.ActionCppType = strrep(cgInfo.MsgClass(1:end-4),':msg:',':action:');
            actInfo = ros.internal.ros2.getActionInfo(messageType,extractBefore(messageType,'Goal'),'Goal');
            cgInfo.CppHeader = actInfo.includeHeader;
            cgInfo.MsgClass = actInfo.msgCppClassName;
            cgInfo.MsgClassPtr = [cgInfo.MsgClass '*'];
        elseif strcmp(cgInfo.MsgClass(end-7:end),'Feedback')
            % Special treatment for ROS 2 Action Client
            actInfo = ros.internal.ros2.getActionInfo(messageType,extractBefore(messageType,'Feedback'),'Feedback');
            cgInfo.CppHeader = actInfo.includeHeader;
            cgInfo.MsgClass = actInfo.msgCppClassName;
            cgInfo.MsgClassPtr = [cgInfo.MsgClass '*'];
        elseif strcmp(cgInfo.MsgClass(end-5:end),'Result')
            % Special treatment for ROS 2 Action Client
            actInfo = ros.internal.ros2.getActionInfo(messageType,extractBefore(messageType,'Result'),'Result');
            cgInfo.CppHeader = actInfo.includeHeader;
            cgInfo.MsgClass = actInfo.msgCppClassName;
            cgInfo.MsgClassPtr = [cgInfo.MsgClass '*'];
        end
    end

    hObj = ros.codertarget.internal.ROSMATLABCgenInfo.getInstance;
    if strcmp(listToAdd,'sub')
        % Add new subscriber to subscriber list
        addSubscriber(hObj,topic,messageType,cgInfo.MsgClass);
    elseif strcmp(listToAdd,'pub')
        % Add new publisher to publisher list
        addPublisher(hObj,topic,messageType,cgInfo.MsgClass);
    else
        % Do nothing for other situations since there is no need to track
        % them for now.
    end
end
