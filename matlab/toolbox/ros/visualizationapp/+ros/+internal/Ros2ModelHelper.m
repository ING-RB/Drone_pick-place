classdef Ros2ModelHelper
    %Ros2ModelHelper Helper class which contains implementations specific to ROS2

    %   Copyright 2023-2024 The MathWorks, Inc.

    methods
        function fieldMap = getFieldMap(~, dataType)
            fieldMap = [];
            switch dataType
                case "odometry"
                    fieldMap.position.x = "pose.pose.position.x";
                    fieldMap.position.y = "pose.pose.position.y";
                    fieldMap.position.z = "pose.pose.position.z";
                    fieldMap.orientation.x = "pose.pose.orientation.x";
                    fieldMap.orientation.y = "pose.pose.orientation.y";
                    fieldMap.orientation.z = "pose.pose.orientation.z";
                    fieldMap.orientation.w = "pose.pose.orientation.w";
                case "map"
                    fieldMap.latitude = "latitude";
                    fieldMap.longitude = "longitude";
                case "marker"
                    %fieldMap.marker.pose.orientation.w = 'Marker.Pose.Orientation.W';
                    fieldMap.messageType = 'MessageType';
                    fieldMap.markers = 'markers';
                    fieldMap.type = 'type';
                    fieldMap.Points = 'points'; % changed to upper P to remove conflict with points.x
                    fieldMap.x = 'x';
                    fieldMap.y = 'y';
                    fieldMap.z = 'z';
                    fieldMap.r = 'r';
                    fieldMap.g = 'g';
                    fieldMap.b = 'b';
                    fieldMap.a = 'a';
                    fieldMap.Colors = 'colors';
                    fieldMap.points.x = 'points.x';
                    fieldMap.points.y = 'points.y';
                    fieldMap.points.z= 'points.z';
                    fieldMap.scale.x = 'scale.x';
                    fieldMap.scale.y = 'scale.y';
                    fieldMap.scale.z = 'scale.z';
                    fieldMap.pose.position.x = 'pose.position.x';
                    fieldMap.pose.position.y = 'pose.position.y';
                    fieldMap.pose.position.z = 'pose.position.z';
                    fieldMap.pose.orientation.x = 'pose.orientation.x';
                    fieldMap.pose.orientation.y = 'pose.orientation.y';
                    fieldMap.pose.orientation.z = 'pose.orientation.z';
                    fieldMap.pose.orientation.w = 'pose.orientation.w';
                    fieldMap.color.r = 'color.r';
                    fieldMap.color.g = 'color.g';
                    fieldMap.color.b = 'color.b';
                    fieldMap.color.a = 'color.a';
                    fieldMap.colors.r = 'colors.r';
                    fieldMap.colors.g = 'colors.g';
                    fieldMap.colors.b = 'colors.b';
                    fieldMap.colors.a = 'colors.a';
                    fieldMap.text = 'text';
                otherwise
                    fieldMap = [];
            end
            % if(strcmp(dataType,"odometry"))
            %     fieldMap.position.x = "pose.pose.position.x";
            %     fieldMap.position.y = "pose.pose.position.y";
            %     fieldMap.position.z = "pose.pose.position.z";
            %     fieldMap.orientation.x = "pose.pose.orientation.x";
            %     fieldMap.orientation.y = "pose.pose.orientation.y";
            %     fieldMap.orientation.z = "pose.pose.orientation.z";
            %     fieldMap.orientation.w = "pose.pose.orientation.w";
            % elseif(strcmp(dataType, "map"))
            %     fieldMap.latitude = "latitude";
            %     fieldMap.longitude = "longitude";
            % end
        end


        function transformedMsg = transformMessage(obj, msg, dataType ,tfTree, destination_frame_id)
            %transformMessage transform message to destination frame
            
            transformedMsg = msg;
            source_frame_id = obj.getFrameID(msg, dataType);
            if canTransform(tfTree, destination_frame_id, source_frame_id)
                tf = getTransform(tfTree, destination_frame_id, source_frame_id);
                if strcmp(dataType, 'marker')
                    transformedMsg =  transformMarker(obj, msg, tf, source_frame_id);
                elseif strcmp(dataType, "pointcloud")
                    transformedMsg = msg;
                    transformedMsg.xyz = obj.transformPoints(tf, msg.xyz);
                elseif strcmp(dataType, "laserscan")
                    transformedMsg = msg;
                    transformedMsg.xy = obj.transformPoints(tf, msg.xy);
                end
                
            else
                error(message('ros:visualizationapp:model:CannotTransform', source_frame_id, destination_frame_id));
            end
        end

        function transformedPoints = transformPoints(~, transformMsg, points)
            % Apply a transformation to a collection of 2D or 3D points.
            %
            % Parameters:
            %   transformMsg - The ROS2 transformation message obtained from getTransform.
            %   points - An Nx2 or Nx3 matrix of xy or xyz points.
            %
            % Returns:
            %   transformedPoints - An Nx2 or Nx3 matrix of transformed points.
        
            % Extract the translation and rotation from the transform message
            translation = [transformMsg.transform.translation.x, ...
                           transformMsg.transform.translation.y, ...
                           transformMsg.transform.translation.z];
                       
            rotationQuat = [transformMsg.transform.rotation.w, ...
                            transformMsg.transform.rotation.x, ...
                            transformMsg.transform.rotation.y, ...
                            transformMsg.transform.rotation.z];
        
            % Use quat2rotm to convert quaternion to a rotation matrix
            rotationMatrix = quat2rotm(rotationQuat);
        
            % Determine the dimensionality of the points
            numDimensions = size(points, 2);
        
            if numDimensions == 2
                % 2D points: use only the first two rows and columns of the rotation matrix
                rotationMatrix2D = rotationMatrix(1:2, 1:2);
                translation2D = translation(1:2);
        
                % Create the 2D transformation matrix
                % | r1 r2 t1 |
                % | r3 r4 t2 |
                % | 0  0  1  | 
                transformationMatrix = eye(3);
                transformationMatrix(1:2, 1:2) = rotationMatrix2D;
                transformationMatrix(1:2, 3) = translation2D;
        
                % Convert points to homogeneous coordinates
                numPoints = size(points, 1);
                homogeneousPoints = [points, ones(numPoints, 1)];
        
                % Apply the transformation matrix
                transformedHomogeneousPoints = (transformationMatrix * homogeneousPoints')';
        
                % Convert back to non-homogeneous coordinates
                transformedPoints = transformedHomogeneousPoints(:, 1:2);
        
            elseif numDimensions == 3
                % Create the 3D transformation matrix
                % | r1 r2 r3 t1 |
                % | r4 r5 r6 t2 |
                % | r7 r8 r9 t3 |
                % |  0  0  0  1 |
                transformationMatrix = eye(4);
                transformationMatrix(1:3, 1:3) = rotationMatrix;
                transformationMatrix(1:3, 4) = translation;
        
                % Convert points to homogeneous coordinates
                numPoints = size(points, 1);
                homogeneousPoints = [points, ones(numPoints, 1)];
        
                % Apply the transformation matrix
                transformedHomogeneousPoints = (transformationMatrix * homogeneousPoints')';
        
                % Convert back to non-homogeneous coordinates
                transformedPoints = transformedHomogeneousPoints(:, 1:3);
        
            else
                transformedPoints = points;
            end
        end

        function transformedMarkerMessage = transformMarker(~, msg, tf, curFrameId)
            if ~isempty(msg.pose)
                if ~isempty(msg.pose.position)
                    pt = ros2message('geometry_msgs/PointStamped');

                    pt.header.frame_id = curFrameId;

                    pt.point.x = msg.pose.position.x;

                    pt.point.y = msg.pose.position.y;

                    pt.point.z = msg.pose.position.z;

                    pt = rosApplyTransform(tf,pt);

                    msg.pose.position.x = pt.point.x;

                    msg.pose.position.y = pt.point.y;

                    msg.pose.position.z = pt.point.z;
                end

                if ~isempty(msg.pose.orientation)
                    pt = ros2message('geometry_msgs/QuaternionStamped');

                    pt.header.frame_id = curFrameId;

                    pt.quaternion.x = msg.pose.orientation.x;

                    pt.quaternion.y = msg.pose.orientation.y;

                    pt.quaternion.z = msg.pose.orientation.z;

                    pt.quaternion.w = msg.pose.orientation.w;

                    pt = rosApplyTransform(tf,pt);

                    msg.pose.orientation.x = pt.quaternion.x;

                    msg.pose.orientation.y = pt.quaternion.y;

                    msg.pose.orientation.z = pt.quaternion.z;

                    msg.pose.orientation.w = pt.quaternion.w;
                end

                if ~isempty(msg.scale)
                    pt = ros2message('geometry_msgs/Vector3Stamped');

                    pt.header.frame_id = curFrameId;

                    pt.vector.x = msg.scale.x;

                    pt.vector.y = msg.scale.y;

                    pt.vector.z = msg.scale.z;

                    pt = rosApplyTransform(tf,pt);

                    msg.scale.x = pt.vector.x;

                    msg.scale.y = pt.vector.y;

                    msg.scale.z = pt.vector.z;
                end
            end
            transformedMarkerMessage = msg;
        end

        function transformMsg = transformMarkerMessage(obj, ros2bagModel, msg)
            if isequal(msg.MessageType, 'visualization_msgs/MarkerArray')
                for i = 1: length(msg.markers)
                    msg.markers(i) = obj.transformMarkerData(ros2bagModel, msg.markers(i));
                end
            else
                msg = obj.transformMarkerData(ros2bagModel, msg);
            end
            transformMsg = msg;
        end

        function transformedMsg = transformMarkerData(~ ,obj, msg)
            % check if marker field id specified by the
            % user and message's field id are different
            curFrameId = msg.header.frame_id;
            if isequal(class(obj), "ros.internal.RosbagModel")
                tfTreeField = 'Rosbag';
            else
                tfTreeField = 'CommonTf';
            end

            if ~isequal(obj.FrameIdSelected, curFrameId)
                % check if transform possible
                if canTransform(obj.(tfTreeField), obj.FrameIdSelected, curFrameId)
                    tf = getTransform(obj.(tfTreeField), obj.FrameIdSelected, curFrameId);
                    if ~isempty(msg.pose)
                        if ~isempty(msg.pose.position)
                            pt = ros2message('geometry_msgs/PointStamped');

                            pt.header.frame_id = curFrameId;

                            pt.point.x = msg.pose.position.x;

                            pt.point.y = msg.pose.position.y;

                            pt.point.z = msg.pose.position.z;

                            pt = rosApplyTransform(tf,pt);

                            msg.pose.position.x = pt.point.x;

                            msg.pose.position.y = pt.point.y;

                            msg.pose.position.z = pt.point.z;
                        end

                        if ~isempty(msg.pose.orientation)
                            pt = ros2message('geometry_msgs/QuaternionStamped');

                            pt.header.frame_id = curFrameId;

                            pt.quaternion.x = msg.pose.orientation.x;

                            pt.quaternion.y = msg.pose.orientation.y;

                            pt.quaternion.z = msg.pose.orientation.z;

                            pt.quaternion.w = msg.pose.orientation.w;

                            pt = rosApplyTransform(tf,pt);

                            msg.pose.orientation.x = pt.quaternion.x;

                            msg.pose.orientation.y = pt.quaternion.y;

                            msg.pose.orientation.z = pt.quaternion.z;

                            msg.pose.orientation.w = pt.quaternion.w;
                        end

                        if ~isempty(msg.scale)
                            pt = ros2message('geometry_msgs/Vector3Stamped');

                            pt.header.frame_id = curFrameId;

                            pt.vector.x = msg.scale.x;

                            pt.vector.y = msg.scale.y;

                            pt.vector.z = msg.scale.z;

                            pt = rosApplyTransform(tf,pt);

                            msg.scale.x = pt.vector.x;

                            msg.scale.y = pt.vector.y;

                            msg.scale.z = pt.vector.z;
                        end
                    end
                else
                    error('Transformation between frames "%s" and "%s" is not possible.', obj.FrameIdSelected, curFrameId);
                end
            end

            transformedMsg = msg;
        end

        function [msg, type] = getMsgFieldType(~, msgType, fieldName)
            % Get a default message and type of a field from a message type.

            msg = ros.internal.getEmptyMessage(msgType,'ros2');
            msg = msg.(fieldName);
            type = msg.MessageType;
        end

        function msgStruct = getMsgStructOfType(~, type)
            %Returns a default msg struct

            msgStruct = ros2message(type);
        end

        function [topicNames, topicMsgType] = getTopicNameAndType(~,rosDomainID)
            %getTopicNamesType Get topic names and messages for topics

            h = ros.ros2.internal.Introspection;
            ret = h.topiclisttypes([], rosDomainID);
            topicNames = ret(:,1);
            topicMsgType = cellfun(@(x)x{1}, ret(:,2), 'UniformOutput', false);
        end

        function hNode = createNode(~, name, rosDomainID)
            %create a node with given name

            hNode = ros2node(name,rosDomainID);
        end

        function hTf = createTfObj(~, ros2Node)
            hTf = ros2tf(ros2Node);
        end

        function subscriber = createSubscriber(~, hNode, topic, readOption, fieldPath)
            %Creates a subscriber for the topic using the given node

            subscriber = ros2subscriber(hNode,topic);

            if readOption == "message" && isempty(fieldPath)
                return;
            end

            subscriber.setMsgPreprocessing(readOption,fieldPath);
        end

        function [topicNames , topicTypes] = filterTopics(~,topicNames,topicTypes)
            %filterTopics validates and filters the topic list

            supportedMessageTypes = ros2type.getMessageList;
            topicsToRemove = false(numel(topicTypes), 1);
            for topicIdx = 1:numel(topicTypes)
                if ~any(ismember(topicTypes{topicIdx}, supportedMessageTypes))
                    topicsToRemove(topicIdx) = 1;
                end
            end

            topicNames(topicsToRemove) = [];
            topicTypes(topicsToRemove) = [];
        end

        function frame_id = getFrameID(~, msg, dataType)
            %getFrameID returns the frame_id of the ROS2 msg
            %if datatype is "message", retrieve frame id from header.
            
            %This is mainly required for live visualization. In live,
            %instead of processing messages in backend, we process them in
            %MATLAB so we have the raw message itself to get the frame_id.
            %The live model uses this function to retrieve based on correct
            %version ROS/ROS2.

            if strcmp(dataType, "marker") || strcmp(dataType, "message")
                frame_id = msg.header.frame_id;
            else
                frame_id = msg.frame_id;
            end
        end

        function rosver = getROSVersion(~)
            rosver = 'ros2';
        end

    end
end

% LocalWords:  Nx xyz quat rotm
