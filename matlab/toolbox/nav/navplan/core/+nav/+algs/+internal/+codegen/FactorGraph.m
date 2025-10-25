classdef FactorGraph < coder.ExternalDependency & nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%FactorIMU Codegen redirect class for nav.algs.internal.builtin.FactorGraph 

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen
    methods (Static)
        function name = getDescriptiveName(~)
            %getDescriptiveName
            name = 'FactorGraph';
        end

        function isSupported = isSupportedContext(~)
            %isSupportedContext Determine if build context supports external dependency
            isSupported = true;
        end

        function updateBuildInfo(buildInfo, buildConfig)
            %updateBuildInfo

            nav.algs.internal.codegen.portableCeresEigenBuildInfo(buildInfo, buildConfig);
        end
    end
    
    properties
        %GraphInternal
        GraphInternal
    end
    
    methods

        function obj = FactorGraph()
            %FactorIMU Constructor (for codegen redirect class)
            coder.cinclude('cerescodegen_api.hpp');
            obj.GraphInternal = coder.opaquePtr('void', coder.internal.null);
            obj.GraphInternal = coder.ceval('cerescodegen_constructFactorGraph');
        end
        
        function delete(obj)
            %delete
            coder.cinclude('cerescodegen_api.hpp');
            
            if ~isempty(obj.GraphInternal)
                coder.ceval('cerescodegen_destructFactorGraph', obj.GraphInternal);
            end
        end

        function ids = getNodeIDs(obj, GroupID, NodeType, FactorType)
            %getAllNodeIDs
            coder.cinclude('cerescodegen_api.hpp');

            nn = 0;
            nn = coder.ceval('cerescodegen_getNumNodes', obj.GraphInternal);
            output = zeros(1,nn);
            outputLen = 0;
            gidI = int32(GroupID);
            coder.ceval('cerescodegen_getNodeIDs', obj.GraphInternal, coder.ref(output), coder.ref(outputLen),...
                coder.rref(gidI), int32(length(gidI)), NodeType, length(NodeType), FactorType, length(FactorType));
            ids = output(1:outputLen);
        end

        function fID = addFactorIMU(obj, factor, groupID)
            %addFactor

            coder.cinclude('cerescodegen_api.hpp');
            
            gyroBiasN = factor.GyroscopeBiasNoise';
            accelBiasN = factor.AccelerometerBiasNoise';
            gyroN = factor.GyroscopeNoise';
            accelN = factor.AccelerometerNoise';
            gyroRaw = factor.GyroscopeReadings';
            accelRaw = factor.AccelerometerReadings';

            % Define gravitational vector to be added to rotated
            % accelerometer readings to obtain linear accelerations without
            % gravity.
            if strcmp(factor.ReferenceFrame, "ENU")
                gravitationalAcceleration = [0,0,fusion.internal.ConstantValue.Gravity];
            else % strcmp(obj.ReferenceFrame, "NED")
                gravitationalAcceleration = [0,0, -fusion.internal.ConstantValue.Gravity];
            end

            sensorTransform = tform(factor.SensorTransform)';

            fID = 0;
            if isa(factor, 'nav.algs.internal.FactorIMUGS')
                fID  = coder.ceval('cerescodegen_addFactorIMUGS',obj.GraphInternal,int32(factor.NodeID), ...
                    factor.SampleRate, gravitationalAcceleration(:), ...
                    gyroBiasN(:), ...
                    accelBiasN(:), ...
                    gyroN(:), ...
                    accelN(:), ...
                    gyroRaw(:), ...
                    accelRaw(:), numel(gyroRaw), coder.rref(groupID), int32(length(groupID)), sensorTransform(:));
            elseif isa(factor, 'nav.algs.internal.FactorIMUGST')
                fID  = coder.ceval('cerescodegen_addFactorIMUGST',obj.GraphInternal,int32(factor.NodeID), ...
                    factor.SampleRate, gravitationalAcceleration(:), ...
                    gyroBiasN(:), ...
                    accelBiasN(:), ...
                    gyroN(:), ...
                    accelN(:), ...
                    gyroRaw(:), ...
                    accelRaw(:), numel(gyroRaw), coder.rref(groupID), int32(length(groupID)), sensorTransform(:));
            else
                fID  = coder.ceval('cerescodegen_addFactorIMU',obj.GraphInternal,int32(factor.NodeID), ...
                    factor.SampleRate, gravitationalAcceleration(:), ...
                    gyroBiasN(:), ...
                    accelBiasN(:), ...
                    gyroN(:), ...
                    accelN(:), ...
                    gyroRaw(:), ...
                    accelRaw(:), numel(gyroRaw), coder.rref(groupID), int32(length(groupID)), sensorTransform(:));
            end
        end

        function fID = addFactorGaussianNoiseModel(obj, factorType, nodeID, measurement, information, numFactors, groupID)
            %addFactorGaussianNoiseModel
            coder.cinclude('cerescodegen_api.hpp');
            output = zeros(1, numFactors+1);
            len = 0;
            nidI = int32(nodeID);
            gidI = int32(groupID);
            coder.ceval('cerescodegen_addFactorGaussianNoiseModel', ...
                obj.GraphInternal, factorType, length(factorType), coder.rref(nidI), int32(length(nodeID)),...
                measurement, int32(length(measurement)), information, int32(length(information)), int32(numFactors),...
                coder.rref(gidI), int32(length(groupID)), coder.ref(output), coder.ref(len));
            fID = output(1:len);

        end

        function fID = addFactorCameraProjection(obj, factorType, nodeID, measurement, information, numFactors, groupID, sensorTform)
            %addFactorCameraProjection
            coder.cinclude('cerescodegen_api.hpp');
            output = zeros(1, numFactors+1);
            len = 0;
            nidI = int32(nodeID);
            gidI = int32(groupID);
            coder.ceval('cerescodegen_addFactorCameraProjection', ...
                obj.GraphInternal, factorType, length(factorType), coder.rref(nidI), int32(length(nodeID)),...
                measurement, int32(length(measurement)), information, int32(length(information)), int32(numFactors),...
                coder.rref(gidI), int32(length(groupID)), sensorTform, coder.ref(output), coder.ref(len));
            fID = output(1:len);

        end

        function fID = addFactorDistortedCameraProjection(obj, factorType, nodeID, measurement, information, numFactors, intrinsics, sensorTform, groupID)
            %addFactorDistortedCameraProjection
            coder.cinclude('cerescodegen_api.hpp');
            output = zeros(1, numFactors+1);
            len = 0;
            nidI = int32(nodeID);
            gidI = int32(groupID);
            coder.ceval('cerescodegen_addFactorDistortedCameraProjection', ...
                obj.GraphInternal, factorType, length(factorType), coder.rref(nidI), int32(length(nodeID)),...
                measurement, int32(length(measurement)), information, int32(length(information)), int32(numFactors),...
                intrinsics, int32(length(intrinsics)), sensorTform, int32(length(sensorTform)), coder.rref(gidI), int32(length(groupID)), coder.ref(output), coder.ref(len));
            fID = output(1:len);

        end

        function nn = getNumNodes(obj)
            %getNumNodes
            coder.cinclude('cerescodegen_api.hpp');

            nn = 0;
            nn = coder.ceval('cerescodegen_getNumNodes', obj.GraphInternal);
        end

        function nf = getNumFactors(obj)
            %getNumFactors
            coder.cinclude('cerescodegen_api.hpp');

            nf = 0;
            nf = coder.ceval('cerescodegen_getNumFactors', obj.GraphInternal);
        end

        function state = getNodeState(obj, id)
            %getNodeState
            coder.cinclude('cerescodegen_api.hpp');

            % initialize with a length more than all possible state lengths
            output = zeros(1,20*(numel(id)+2));
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_getNodeState', obj.GraphInternal, coder.rref(nidI), numel(id), coder.ref(output), coder.ref(len));
            
            state = output(1:len);
        end

        function type = getNodeType(obj, id)
            %getNodeType
            coder.cinclude('cerescodegen_api.hpp');

            output = repmat(' ',1,20);
            len = 0;
            coder.ceval('cerescodegen_getNodeType', obj.GraphInternal, id, coder.ref(output), coder.ref(len));
            type = output(1:len);
        end

        function covariance = getNodeCovariance(obj, id)
            %getNodeCovariance
            coder.cinclude('cerescodegen_api.hpp');

            % initialize with a length more than all possible state lengths
            output = zeros(1,50*(numel(id)+2));
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_getNodeCovariance', obj.GraphInternal, coder.rref(nidI), numel(id), coder.ref(output), coder.ref(len));
            
            covariance = output(1:len);
        end

        function status = setNodeState(obj, id, state, size)
            %setNodeState
            coder.cinclude('cerescodegen_api.hpp');
            idNum = numel(id);
            output = zeros(1, idNum+1);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_setNodeState', obj.GraphInternal, coder.rref(nidI), length(id), state, size,...
                coder.ref(output), coder.ref(len));
            status = output(1:len);
        end

        function removedNodeIDs = removeFactor(obj, id)
            %removeFactor
            coder.cinclude('cerescodegen_api.hpp');
            nn = 0;
            nn = coder.ceval('cerescodegen_getNumNodes', obj.GraphInternal);
            output = zeros(1, nn+1);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_removeFactor', obj.GraphInternal, coder.rref(nidI), length(id),...
                coder.ref(output), coder.ref(len));
            removedNodeIDs = output(1:len);
        end

        function output = removeNode(obj, id)
            %removeFactor
            coder.cinclude('cerescodegen_api.hpp');
            nn = 0;
            nn = coder.ceval('cerescodegen_getNumNodes', obj.GraphInternal);
            nf = 0;
            nf = coder.ceval('cerescodegen_getNumFactors', obj.GraphInternal);
            output = zeros(1, nn+1+nf);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_removeNode', obj.GraphInternal, coder.rref(nidI), length(id),...
                coder.ref(output), coder.ref(len));
            output = output(1:len);
        end

        function output = marginalizeFactor(obj, id)
            %marginalizeFactor
            coder.cinclude('cerescodegen_api.hpp');
            nn = 0;
            nn = coder.ceval('cerescodegen_getNumNodes', obj.GraphInternal);
            output = zeros(1, nn+2);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_marginalizeFactor', obj.GraphInternal, coder.rref(nidI), length(id),...
                coder.ref(output), coder.ref(len));
            output = output(1:len);
        end

        function output = marginalizeNode(obj, id)
            %marginalizeNode
            coder.cinclude('cerescodegen_api.hpp');
            nn = 0;
            nn = coder.ceval('cerescodegen_getNumNodes', obj.GraphInternal);
            nf = 0;
            nf = coder.ceval('cerescodegen_getNumFactors', obj.GraphInternal);
            output = zeros(1, nn+2+nf);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_marginalizeNode', obj.GraphInternal, nidI,...
                coder.ref(output), coder.ref(len));
            output = output(1:len);
        end

        function status = fixNode(obj, id)
            %fixNode
            coder.cinclude('cerescodegen_api.hpp');
            idNum = numel(id);
            output = zeros(1, idNum+1);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_fixNode', obj.GraphInternal, coder.rref(nidI), int32(idNum),...
                coder.ref(output), coder.ref(len));
            status = output(1:len);
        end

        function status = freeNode(obj, id)
            %freeNode
            coder.cinclude('cerescodegen_api.hpp');
            idNum = numel(id);
            output = zeros(1, idNum+1);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_freeNode', obj.GraphInternal, coder.rref(nidI), int32(idNum),...
                coder.ref(output), coder.ref(len));
            status = output(1:len);
        end

        function isFixed = isNodeFixed(obj, id)
            %isNodeFixed
            coder.cinclude('cerescodegen_api.hpp');
            idNum = numel(id);
            output = zeros(1, idNum+1);
            len = 0;
            nidI = int32(id);
            coder.ceval('cerescodegen_isNodeFixed', obj.GraphInternal, coder.rref(nidI),...
                int32(idNum), coder.ref(output), coder.ref(len));
            isFixed = output(1:len);
        end

        function flag = hasNode(obj, id)
            %hasNode
            coder.cinclude('cerescodegen_api.hpp');

            flag = false;
            flag = coder.ceval('cerescodegen_hasNode', obj.GraphInternal, id);
        end

        function flag = isConnected(obj, id)
            %isConnected
            coder.cinclude('cerescodegen_api.hpp');
            idNum = numel(id);
            nidI = int32(id);
            flag = false;
            flag = coder.ceval('cerescodegen_isConnected', obj.GraphInternal, coder.rref(nidI), int32(idNum));
        end

        function flag = isPoseNode(obj, id)
            %isPoseNode
            coder.cinclude('cerescodegen_api.hpp');
            idNum = numel(id);
            nidI = int32(id);
            flag = false;
            flag = coder.ceval('cerescodegen_isPoseNode', obj.GraphInternal, coder.rref(nidI), int32(idNum));
        end

        function solnInfo = optimize(obj, optsStruct, id)
            %optimize
            coder.cinclude('cerescodegen_api.hpp');
            idNum = numel(id);
            nidI = int32(id);
            % ["MaxIterations","FunctionTolerance","GradientTolerance","StepTolerance","VerbosityLevel","TrustRegionStrategyType","StateCovarianceTypes","InitialTrustRegionRadius"]
            opts = [optsStruct.MaxNumIterations, optsStruct.FunctionTolerance, ...
                        optsStruct.GradientTolerance, optsStruct.StepTolerance, ...
                        optsStruct.VerbosityLevel, optsStruct.TrustRegionStrategyType, ...
                        double(optsStruct.StateCovarianceTypes), optsStruct.InitialTrustRegionRadius];%, ...
%                         optsStruct.LinearSolverType, ...
%                         optsStruct.DoglegType];

            covTypeNum = numel(optsStruct.StateCovarianceTypes);
            info = zeros(1,7);
            nn = 0;
            nn = coder.ceval('cerescodegen_getNumNodes', obj.GraphInternal);
            output1 = zeros(1,nn);
            outputLen1 = 0;
            output2 = zeros(1,nn);
            outputLen2 = 0;
            coder.ceval('cerescodegen_optimize', obj.GraphInternal, opts, coder.ref(info), coder.rref(nidI), int32(idNum), ...
                int32(covTypeNum), coder.ref(output1), coder.ref(outputLen1), coder.ref(output2), coder.ref(outputLen2));
            solnInfo = struct("InitialCost", info(1),"FinalCost", info(2),"NumSuccessfulSteps", info(3), ...
                "NumUnsuccessfulSteps", info(4), "TotalTime", info(5), "TerminationType", info(6), ...
                "IsSolutionUsable", info(7), "OptimizedNodeIDs", output1(1:outputLen1), "FixedNodeIDs", output2(1:outputLen2));
        end
        
    end

end

