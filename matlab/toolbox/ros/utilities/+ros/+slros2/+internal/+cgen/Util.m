classdef Util < ros.slros.internal.cgen.Util
    %This class is for internal use only. It may be removed in the future.
    
    %CGEN.UTIL - Utility functions for generating ROS2 C++ code
    
    % Copyright 2019-2024 The MathWorks, Inc.

    methods(Static)
        function [cppRosClass, msgType, headerName] = rosObjToCppClass(ros2Msg)
            msgType = ros2Msg.MessageType;
            if endsWith(msgType,'Request')
                msgInfo = ros.slros2.internal.cgen.Util.getMsgInfoFromType(msgType, 'Request');
            elseif endsWith(msgType,'Response')
                msgInfo = ros.slros2.internal.cgen.Util.getMsgInfoFromType(msgType, 'Response');
            elseif endsWith(msgType, 'Goal')
                msgInfo = ros.slros2.internal.cgen.Util.getMsgInfoFromType(msgType, 'Goal');
            elseif endsWith(msgType, 'Feedback')
                msgInfo = ros.slros2.internal.cgen.Util.getMsgInfoFromType(msgType, 'Feedback');
            elseif endsWith(msgType, 'Result')
                msgInfo = ros.slros2.internal.cgen.Util.getMsgInfoFromType(msgType, 'Result');
            else
                msgInfo = ros.internal.ros2.getMessageInfo(msgType);
            end
            cppRosClass = msgInfo.msgCppClassName;
            headerName = msgInfo.includeHeader;
        end

        function ret = getMsgInfoFromType(msgType, typeTag)
        %getMsgInfoFromType return service or action message info given
        %message type
            typeName = extractBefore(msgType, typeTag);
            isService = any(strcmp(ros.ros2.internal.Introspection.getAllServiceTypesStatic,typeName)) ...
                        && any(strcmp(typeTag, {'Request','Response'}));
            isAction = any(strcmp(ros.ros2.internal.Introspection.getAllActionTypesStatic,typeName)) ...
                        && any(strcmp(typeTag, {'Goal','Feedback','Result'}));
            if isService
                ret = ros.internal.ros2.getServiceInfo(msgType,typeName,typeTag);
            elseif isAction
                ret = ros.internal.ros2.getActionInfo(msgType,typeName,typeTag);
            else
                % Custom message ends with special characters normally used
                % in Service or Action
                ret = ros.internal.ros2.getMessageInfo(msgType);
            end
        end
        
        function ros2Header = rosCppClassToCppMsgHeader(cppClass)
            validateattributes(cppClass, {'char'}, {'nonempty'});
            assert(contains(cppClass, '::'));
            if contains(cppClass, '::srv::')
                % Remove trailing ::Request class name to derive
                % common header for services
                cppClass = regexprep(cppClass,'(\:\:Request)$','');
                % Remove trailing ::Response class name to derive
                % common header for services
                cppClass = regexprep(cppClass,'(\:\:Response)$','');
            elseif contains(cppClass, '::action::')
                % Remove trailing ::Goal class name to
                % derive common header for actions
                cppClass = regexprep(cppClass,'(\:\:Goal)$','');
                % Remove trailing ::Feedback class name to
                % derive common header for actions
                cppClass = regexprep(cppClass,'(\:\:Feedback)$','');
                % Remove trailing ::Result class name to
                % derive common header for actions
                cppClass = regexprep(cppClass,'(\:\:Result)$','');
            end
            rosHeader = [strrep(cppClass,'::', '/') '.hpp'];
            [fpath,msgName,ext]=fileparts(rosHeader);
            hdrName = ros.internal.utilities.convertCamelcaseToLowercaseUnderscore(msgName);
            ros2Header = [fpath, '/',hdrName, ext];
        end
        
        function ret = getBusToCppMsgDefString(~)
            ret = '%s& msgPtr';
        end
        
        function ret = getCppToBusMsgDefString(~)
            ret = 'const %s& msgPtr';
        end        
        
        function ret = getSimpleAssignmentString(convertFromBus2Cpp, isROSEntity)
            % GETSIMPLEASSIGNMENTSTRING Get the assignment string for converting between buses and
            % CPP messages with respect to direction and nested messages
            if convertFromBus2Cpp    
                if isROSEntity
                    % Example: convertFromBus(msgPtr.position, &busPtr->position);
                    ret = '%s(%s.%s, &%s->%s);';
                else
                    % Example: msgPtr.nanosec =  busPtr->nanosec;
                    ret = '%s.%s = %s %s->%s;';
                end
            else % convertToBusFromCpp
                if isROSEntity
                    % Example: convertToBus(&busPtr->header, msgPtr.header);
                    ret = '%s(&%s->%s, %s.%s);';
                else
                    % Example: busPtr->nanosec =  msgPtr.nanosec;
                    ret = '%s->%s = %s %s.%s;';
                end
            end
        end
        
        function ret = getCopyArrayString(convertFromBusToCpp, isVarSize)
            if isVarSize
                if convertFromBusToCpp
                    ret = 'convertFromBusVariable%s(%s.%s, %s->%s, %s->%s);';
                    
                else
                    ret = 'convertToBusVariable%s(%s->%s, %s->%s, %s.%s, %s);';
                end
            else
                if convertFromBusToCpp
                    ret = 'convertFromBusFixed%s(%s.%s, %s->%s);';
                else
                    ret = 'convertToBusFixed%s(%s->%s, %s.%s, %s);';
                end
            end
        end
        
        function ret = getConvFunctionSignature(isBus2Cpp)
            if isBus2Cpp
                ret = '[[maybe_unused]] static void %s(%s, %s const* busPtr)';
            else
                ret = '[[maybe_unused]] static void %s(%s* busPtr, %s)';
            end
        end
    end
end
