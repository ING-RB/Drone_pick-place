classdef ros2type

%   Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function messageList = getMessageList

            messageList = ros2("msg","list");
        end

        function serviceList = getServiceList

            h = ros.ros2.internal.Introspection;
            serviceList = h.getAllServiceTypesStatic;
        end

        function actionList = getActionList

            h = ros.ros2.internal.Introspection;
            actionList = h.getAllActionTypesStatic;
        end
    end
end