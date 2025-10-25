classdef ApplyTransform < ros.slros.internal.block.ApplyTransformBase & ...
        ros.internal.mixin.InternalAccess
    %ApplyTransform Apply transform to input ROS 2 message
    %
    %   H = ros.slros2.internal.block.ApplyTransform creates a system
    %   object, H, that takes one geometry_msgs/TransformStamped message
    %   and one of the following messages as input, and return a message
    %   with the same type as output:
    %       - geometry_msgs/QuaternionStamped
    %       - geometry_msgs/Vector3Stamped
    %       - geometry_msgs/PointStamped
    %       - geometry_msgs/PoseStamped
    %
    %   This system object is intended for use with the MATLAB System
    %   block. In order to access the same functionality from MATLAB, see
    %   rosApplyTransform.
    %
    %   See also rosApplyTransform

    %   Copyright 2023 The MathWorks, Inc.
    %#codegen
    

    methods
        function obj = ApplyTransform(varargin)
        % Enable code to be generated even if this file is p-coded
            coder.allowpcode('plain');
            obj = obj@ros.slros.internal.block.ApplyTransformBase(varargin{:});
        end
    end

    methods (Access = protected)
        function num = getNumInputsImpl(~)
            num = 2;
        end

        function num = getNumOutputsImpl(~)
            num = 1;
        end

        function varargout = getOutputSizeImpl(~)
            varargout = {[1 1]};
        end

        function varargout = isOutputFixedSizeImpl(~)
            varargout = {true};
        end

        function varargout = getOutputDataTypeImpl(obj)
            varargout =  {obj.SLOutputBusName};
        end

        function varargout = isOutputComplexImpl(~)
            varargout = {false};
        end
    end

    methods (Access = protected, Static)
        function header = getHeaderImpl
        % Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"), ...
                'ShowSourceLink', false, ...
                'Title', message('ros:slros2:blockmask:ApplyTransformMaskTitle').getString, ...
                'Text', message('ros:slros2:blockmask:ApplyTransformDescription').getString);
        end

        function throwSimStateError()
            coder.internal.errorIf(true, 'ros:slros:sysobj:BlockSimStateNotSupported', 'ROS2 Apply Transform');
        end
    end

    methods (Access = protected)
        function sts = getSampleTimeImpl(obj)
        % Enable this system object to inherit constant ('inf') sample
        % times
            sts = createSampleTime(obj,'Type','Inherited','Allow','Constant');
        end

        function setupImpl(obj)
        % setupImpl is called when model is being initialized at the start
        % of a simulation
            if coder.target('MATLAB')
                % Note: there is no need to use ROS 2 Node since is block
                % does not need to connect to ROS 2 network.
                obj.OutputConverter = ros.slros2.internal.sim.ROSMsgToBusStructConverter(...
                    obj.EntityMsgType, obj.ModelName);
                obj.EmptyTFInputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType(obj.TFMsgType);
                obj.EmptyEntityInputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType(obj.EntityMsgType);
                emptySeedOutputMsg = ros.slros2.internal.bus.Util.newMessageFromSimulinkMsgType(obj.EntityMsgType);
                obj.EmptySeedOutputBusStruct = obj.OutputConverter.convert(emptySeedOutputMsg);
                [emptyTFMsg,TFMsgInfo]= ros.internal.getEmptyMessage(obj.TFMsgType,'ros2');
                % emptyEntityMsg and entityMsgInfo can be shared for both
                % input and output since they are always the same type
                [emptyEntityMsg,entityMsgInfo]= ros.internal.getEmptyMessage(obj.EntityMsgType,'ros2');
                
                cachedMap = containers.Map();
                % This map contains the values of empty message data which
                % can be reused when required.
                refCachedMapInStoragePath = fullfile(pwd, '+bus_conv_fcns','+ros2','+busToMsg','RefCachedMap.mat');
                refCachedMapIn = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapInStoragePath);
                refCachedMapOutStoragePath = fullfile(pwd, '+bus_conv_fcns','+ros2','+msgToBus','RefCachedMap.mat');
                refCachedMapOut = ros.slros.internal.bus.Util.getDataFromCacheFile(refCachedMapOutStoragePath);
                cachedMap(obj.TFMsgType) = emptyTFMsg;
                [pkgNameTF,msgNameTF] = fileparts(obj.TFMsgType);
                cachedMap(obj.EntityMsgType) = emptyEntityMsg;
                [pkgNameEntity,msgNameEntity] = fileparts(obj.EntityMsgType);
                obj.TFInputConversionFcn = generateStaticConversionFunctions(obj,emptyTFMsg,...
                                                                             TFMsgInfo,'ros2','busToMsg',pkgNameTF,msgNameTF,cachedMap,refCachedMapIn,refCachedMapInStoragePath);
                obj.EntityInputConversionFcn = generateStaticConversionFunctions(obj,emptyEntityMsg,...
                                                                             entityMsgInfo,'ros2','busToMsg',pkgNameEntity,msgNameEntity,cachedMap,refCachedMapIn,refCachedMapInStoragePath);
                obj.EntityOutputConversionFcn = generateStaticConversionFunctions(obj,emptyEntityMsg,...
                                                                             entityMsgInfo,'ros2','msgToBus',pkgNameEntity,msgNameEntity,cachedMap,refCachedMapOut,refCachedMapOutStoragePath);
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is important to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Apply Transform');
            elseif coder.target('Rtw')
                % Do nothing
            elseif coder.target('Sfun')
                % 'Sfun'  - Simulation through CodeGen target
                % Do nothing. MATLAB System block first does a pre-codegen
                % compile with 'Sfun' target, & then does the "proper"
                % codegen compile with Rtw or RtwForRapid, as appropriate.
            else
                % 'RtwForSim' - ModelReference SIM target
                % 'MEX', 'HDL', 'Custom' - Not applicable to MATLAB System block
                coder.internal.errorIf(true, 'ros:slros:sysobj:UnsupportedCodegenMode', coder.target);
            end
        end

        function tfEntity = stepImpl(obj, tfMsg, entity)
        % stepImpl Apply transform to entity and return a tfEntity

            tfEntity = coder.nullcopy(entity);

            % Get translation and rotation from TransformStamped
            tfQuat = obj.tfGetQuaternion(tfMsg.transform.rotation);
            tfRotMtx = quat2rotm(tfQuat);
            tfVec = obj.tfGetPosition(tfMsg.transform.translation, false);
            tfTranMtx = trvec2tform(tfVec)*rotm2tform(tfRotMtx);

            if isfield(entity,'quaternion')
                % geometry_msgs/QuaternionStamped
                entityQuat = obj.tfGetQuaternion(entity.quaternion);
                outQuat = robotics.utils.internal.quatMultiply(tfQuat,entityQuat);
                tfEntity.quaternion = obj.tfSetQuaternion(outQuat);
            elseif isfield(entity,'vector')
                % geometry_msgs/Vector3Stamped
                outVec = obj.tfGetPosition(entity.vector,false);
                outVec = tfRotMtx * outVec';
                tfEntity.vector = obj.tfSetPosition(outVec);
            elseif isfield(entity,'point')
                % geometry_msgs/PointStamped
                outPoint = obj.tfGetPosition(entity.point, true);
                outPoint = tfTranMtx * outPoint';
                tfEntity.point = obj.tfSetPosition(outPoint);
            elseif isfield(entity,'pose')
                % geometry_msgs/PoseStamped
                inQuat = obj.tfGetQuaternion(entity.pose.orientation);
                inPos = obj.tfGetPosition(entity.pose.position, false);
                poseTform = trvec2tform(inPos) * quat2tform(inQuat);
                tfPose = tfTranMtx * poseTform;
                outQuat = tform2quat(tfPose);
                tfEntity.pose.orientation = obj.tfSetQuaternion(outQuat);
                outPos = tform2trvec(tfPose);
                tfEntity.pose.position = obj.tfSetPosition(outPos);
            else
            end

            % Assign frame_id
            targetFrameLength = tfMsg.header.frame_id_SL_Info.CurrentLength;
            if (targetFrameLength>0)
                tfEntity.header.frame_id(1:targetFrameLength) = tfMsg.header.frame_id(1:targetFrameLength);
                tfEntity.header.frame_id_SL_Info.CurrentLength = targetFrameLength;
            end
        end

        function in = getInputNamesImpl(~)
        %getInputNamesImpl Return input port names for System block
            in = ["TFMsg";"Entity"];
        end

        function out = getOutputNamesImpl(~)
        %getOutputNamesImpl Return output port names for System block
            out = "TFEntity";
        end

        function maskDisplay = getMaskDisplayImpl(obj)
        % getMaskDisplayImpl Customize the mask icon display
        %   This method allows customization of the mask display code. Note
        %   that this works for both the base mask and the mask-on-mask.

            numInputs = obj.getNumInputsImpl;
            inputNames = obj.getInputNamesImpl;
            numOutputs = obj.getNumOutputsImpl;
            outputNames = obj.getOutputNamesImpl;

            portLabelText = {};
            for i = 1:numInputs
                portLabelText = [portLabelText ['port_label(''input'', ' num2str(i) ', ''' inputNames{i} ''');']]; %#ok<AGROW>
            end
            for i = 1:numOutputs
                portLabelText = [portLabelText ['port_label(''output'', ' num2str(i) ', ''' outputNames{i} ''');']]; %#ok<AGROW>
            end

            maskDisplay = { ...
                ['plot([110,110,110,110],[110,110,110,110]);', newline], ... % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([0,0,0,0],[0,0,0,0]);', newline],...
                'color(''black'')', ...
                '', ...
                portLabelText{:}};
        end

        function quat = tfGetQuaternion(~, msgStruct)
            coder.inline('never');
            quat = [msgStruct.w msgStruct.x msgStruct.y msgStruct.z];
            if norm(quat) < 1e-7
                quat = [1 0 0 0];
            else
                quat = robotics.internal.normalizeRows(quat);
            end
        end

        function quat = tfSetQuaternion(~, msgStruct)
            coder.inline('always');
            quat.x = msgStruct(2);
            quat.y = msgStruct(3);
            quat.z = msgStruct(4);
            quat.w = msgStruct(1);
        end
        
        function vec = tfGetPosition(~, msgStruct, homog)
            coder.inline('always');
            if homog
                vec = [msgStruct.x msgStruct.y msgStruct.z 1];
            else
                vec = [msgStruct.x msgStruct.y msgStruct.z];
            end
        end
        
        function vec = tfSetPosition(~, msgStruct)
            coder.inline('always');
            vec.x = msgStruct(1);
            vec.y = msgStruct(2);
            vec.z = msgStruct(3);
        end
    end

    

end