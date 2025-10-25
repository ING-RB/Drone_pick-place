classdef RosModelHelper
    %ROSBAGHELPER Helper class which contains implementations specific to ROS1

    %   Copyright 2023-2024 The MathWorks, Inc.

    methods
        function fieldMap = getFieldMap(~, dataType)
            fieldMap = [];
            switch dataType
                case "odometry"
                    fieldMap.position.x = 'Pose.Pose.Position.X';
                    fieldMap.position.y = 'Pose.Pose.Position.Y';
                    fieldMap.position.z = 'Pose.Pose.Position.Z';
                    fieldMap.orientation.x = 'Pose.Pose.Orientation.X';
                    fieldMap.orientation.y = 'Pose.Pose.Orientation.Y';
                    fieldMap.orientation.z = 'Pose.Pose.Orientation.Z';
                    fieldMap.orientation.w = 'Pose.Pose.Orientation.W';
                case "map"
                    fieldMap.latitude = 'Latitude';
                    fieldMap.longitude = 'Longitude';
                case "marker"
                    %fieldMap.marker.pose.orientation.w = 'Marker.Pose.Orientation.W';
                    fieldMap.messageType = 'MessageType';
                    fieldMap.markers = 'Markers';
                    fieldMap.type = 'Type';
                    fieldMap.Points = 'Points'; % changed to upper P to remove conflict with points.x
                    fieldMap.x = 'X';
                    fieldMap.y = 'Y';
                    fieldMap.z = 'Z';
                    fieldMap.r = 'R';
                    fieldMap.g = 'G';
                    fieldMap.b = 'B';
                    fieldMap.a = 'A';
                    fieldMap.Colors = 'Colors';
                    fieldMap.points.x = 'Points.X';
                    fieldMap.points.y = 'Points.Y';
                    fieldMap.points.z= 'Points.Z';
                    fieldMap.scale.x = 'Scale.X';
                    fieldMap.scale.y = 'Scale.Y';
                    fieldMap.scale.z = 'Scale.Z';
                    fieldMap.pose.position.x = 'Pose.Position.X';
                    fieldMap.pose.position.y = 'Pose.Position.Y';
                    fieldMap.pose.position.z = 'Pose.Position.Z';
                    fieldMap.pose.orientation.x = 'Pose.Orientation.X';
                    fieldMap.pose.orientation.y = 'Pose.Orientation.Y';
                    fieldMap.pose.orientation.z = 'Pose.Orientation.Z';
                    fieldMap.pose.orientation.w = 'Pose.Orientation.W';
                    fieldMap.color.r = 'Color.R';
                    fieldMap.color.g = 'Color.G';
                    fieldMap.color.b = 'Color.B';
                    fieldMap.color.a = 'Color.A';
                    fieldMap.colors.r = 'Colors.R';
                    fieldMap.colors.g = 'Colors.G';
                    fieldMap.colors.b = 'Colors.B';
                    fieldMap.colors.a = 'Colors.A';
                    fieldMap.text = 'Text';
                otherwise
                    fieldMap = [];
            end

            %
            % if(strcmp(dataType,"odometry"))
            %     fieldMap.position.x = "Pose.Pose.Position.X";
            %     fieldMap.position.y = "Pose.Pose.Position.Y";
            %     fieldMap.position.z = "Pose.Pose.Position.Z";
            %     fieldMap.orientation.x = "Pose.Pose.Orientation.X";
            %     fieldMap.orientation.y = "Pose.Pose.Orientation.Y";
            %     fieldMap.orientation.z = "Pose.Pose.Orientation.Z";
            %     fieldMap.orientation.w = "Pose.Pose.Orientation.W";
            % elseif(strcmp(dataType, "map"))
            %     fieldMap.latitude = "Latitude";
            %     fieldMap.longitude = "Longitude";
            % elseif(strcmp(dataType, "marker"))
            %
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
            translation = [transformMsg.Transform.Translation.X, ...
                           transformMsg.Transform.Translation.Y, ...
                           transformMsg.Transform.Translation.Z];
                       
            rotationQuat = [transformMsg.Transform.Rotation.W, ...
                            transformMsg.Transform.Rotation.X, ...
                            transformMsg.Transform.Rotation.Y, ...
                            transformMsg.Transform.Rotation.Z];
        
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
            if ~isempty(msg.Pose)
                if ~isempty(msg.Pose.Position)
                    pt = rosmessage('geometry_msgs/PointStamped');

                    pt.Header.FrameId = curFrameId;

                    pt.Point.X = msg.Pose.Position.X;

                    pt.Point.Y = msg.Pose.Position.Y;

                    pt.Point.Z = msg.Pose.Position.Z;

                    pt = apply(tf,pt);

                    msg.Pose.Position.X = pt.Point.X;

                    msg.Pose.Position.Y = pt.Point.Y;

                    msg.Pose.Position.Z = pt.Point.Z;
                end

                if ~isempty(msg.Pose.Orientation)
                    pt = rosmessage('geometry_msgs/QuaternionStamped');

                    pt.Header.FrameId = curFrameId;

                    pt.Quaternion.X = msg.Pose.Orientation.X;

                    pt.Quaternion.Y = msg.Pose.Orientation.Y;

                    pt.Quaternion.Z = msg.Pose.Orientation.Z;

                    pt.Quaternion.W = msg.Pose.Orientation.W;

                    pt = apply(tf,pt);

                    msg.Pose.Orientation.X = pt.Quaternion.X;

                    msg.Pose.Orientation.Y = pt.Quaternion.Y;

                    msg.Pose.Orientation.Z = pt.Quaternion.Z;

                    msg.Pose.Orientation.W = pt.Quaternion.W;
                end

                if ~isempty(msg.Scale)
                    pt = rosmessage('geometry_msgs/Vector3Stamped');

                    pt.Header.FrameId = curFrameId;

                    pt.Vector.X = msg.Scale.X;

                    pt.Vector.Y = msg.Scale.Y;

                    pt.Vector.Z = msg.Scale.Z;

                    pt = apply(tf,pt);

                    msg.Scale.X = pt.Vector.X;

                    msg.Scale.Y = pt.Vector.Y;

                    msg.Scale.Z = pt.Vector.Z;
                end
            end
            transformedMarkerMessage = msg;
        end

        function transformMsg = transformMarkerMessage(obj, rosbagModel, msg)
            if isequal(msg.MessageType, 'visualization_msgs/MarkerArray')
                for i = 1: length(msg.Markers)
                    msg.Markers(i) = obj.transformMarkerData(rosbagModel, msg.Markers(i));
                end
            else
                msg = obj.transformMarkerData(rosbagModel, msg);
            end
            transformMsg = msg;
        end

        function transformedMsg = transformMarkerData(~ ,obj, msg)
            % check if marker field id specified by the
            % user and message's field id are different
            curFrameId = msg.Header.FrameId;
            if isequal(class(obj), "ros.internal.RosbagModel")
                tfTreeField = 'Rosbag';
            else
                tfTreeField = 'CommonTf';
            end
            if ~isequal(obj.FrameIdSelected, curFrameId)
                % check if transform possible
                if canTransform(obj.(tfTreeField), obj.FrameIdSelected, curFrameId)
                    tf = getTransform(obj.(tfTreeField), obj.FrameIdSelected, curFrameId);
                    if ~isempty(msg.Pose)
                        if ~isempty(msg.Pose.Position)
                            pt = rosmessage('geometry_msgs/PointStamped');

                            pt.Header.FrameId = curFrameId;

                            pt.Point.X = msg.Pose.Position.X;

                            pt.Point.Y = msg.Pose.Position.Y;

                            pt.Point.Z = msg.Pose.Position.Z;

                            pt = apply(tf,pt);

                            msg.Pose.Position.X = pt.Point.X;

                            msg.Pose.Position.Y = pt.Point.Y;

                            msg.Pose.Position.Z = pt.Point.Z;
                        end

                        if ~isempty(msg.Pose.Orientation)
                            pt = rosmessage('geometry_msgs/QuaternionStamped');

                            pt.Header.FrameId = curFrameId;

                            pt.Quaternion.X = msg.Pose.Orientation.X;

                            pt.Quaternion.Y = msg.Pose.Orientation.Y;

                            pt.Quaternion.Z = msg.Pose.Orientation.Z;

                            pt.Quaternion.W = msg.Pose.Orientation.W;

                            pt = apply(tf,pt);

                            msg.Pose.Orientation.X = pt.Quaternion.X;

                            msg.Pose.Orientation.Y = pt.Quaternion.Y;

                            msg.Pose.Orientation.Z = pt.Quaternion.Z;

                            msg.Pose.Orientation.W = pt.Quaternion.W;
                        end

                        if ~isempty(msg.Scale)
                            pt = rosmessage('geometry_msgs/Vector3Stamped');

                            pt.Header.FrameId = curFrameId;

                            pt.Vector.X = msg.Scale.X;

                            pt.Vector.Y = msg.Scale.Y;

                            pt.Vector.Z = msg.Scale.Z;

                            pt = apply(tf,pt);

                            msg.Scale.X = pt.Vector.X;

                            msg.Scale.Y = pt.Vector.Y;

                            msg.Scale.Z = pt.Vector.Z;
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

            msgInfo = ros.internal.ros.getMessageInfo(msgType);
            [~, info] = eval(msgInfo.msgStructGen);
            val = info.(fieldName);

            type = val.MessageType;
            msgInfo = ros.internal.ros.getMessageInfo(type);
            [msg, ~] = eval(msgInfo.msgStructGen);
        end

        function msgStruct = getMsgStructOfType(~, type)
            %Returns a default msg struct

            msgStruct = rosmessage(type,"DataFormat","struct");
        end

        function [topicName, topicType] = getTopicNameAndType(obj,rosMasterURI)
            %getTopicNamesType Get topic names and messages for topics

            [topicName, topicType] = ros.internal.NetworkIntrospection.getPublishedTopicNamesTypes(rosMasterURI);
            [topicName, topicType] = filterTopics(obj,topicName, topicType);
        end

        function hNode = createNode(~, name, rosMasterURI)
            %create a node with given name

            hNode = ros.Node(name,rosMasterURI);
        end

        function hTf = createTfObj(~, rosNode)
            hTf = ros.TransformationTree(rosNode, "DataFormat", "struct");
        end

        function subscriber = createSubscriber(~, hNode, topic, readOption, fieldPath)
            %Creates a subscriber for the topic using the given node

            subscriber = ros.Subscriber(hNode,topic,'DataFormat','struct');

            if readOption == "message" && isempty(fieldPath)
                return;
            end

            subscriber.setMsgPreprocessing(readOption,fieldPath);

        end

        function [topicNames , topicTypes] = filterTopics(~,topicNames,topicTypes)
            supportedMessageTypes = rostype.getMessageList;
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
            %getFrameID returns the frame_id of the ROS msg
            %if datatype is "message", retrieve frame id from header.
            if strcmp(dataType, "marker") || strcmp(dataType, "message")
                frame_id = msg.Header.FrameId;
            else
                frame_id = msg.frame_id;
            end
        end

        function rosver = getROSVersion(~)
            rosver = 'ros';
        end
    end
end

% LocalWords:  ROSBAGHELPER Nx xyz quat rotm
