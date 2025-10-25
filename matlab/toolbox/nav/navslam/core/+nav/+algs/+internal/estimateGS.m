function [gRot, scale, info] = estimateGS(computeScale, callerFuncName, poses, gyroscopeReadings, accelerometerReadings, varargin)
%This function is for internal use only. It may be removed in the future.

%estimateGS Implementation of estimate gravity rotation and scale.
%
%   [gRot, scale, posesTransformed, info] = estimateGS(computeScale, ...
%   callerFuncName, poses, gyroscopeReadings, accelerometerReadings, ...
%   Name=Value) estimates gravity rotation and scale. 
%
%   When computeScale is false then the scale is fixed during optimization
%   and constant scale of 1 will be returned. calledFuncName can either be
%   estimateGravityRotationAndPoseScale or estimateGravityRotation.

%   Copyright 2022-2024 The MathWorks, Inc.


%#codegen

    scale = 1;
    
    % parse Name-Value inputs
    if computeScale
        parameterNames = {'SolverOptions', 'SensorTransform', 'IMUParameters', 'FixPoses', 'InitialVelocity', 'PredictionThreshold', 'ScaleThreshold'};
        defaultValuesForParameters = {factorGraphSolverOptions, se3(), factorIMUParameters, true, [NaN,NaN,NaN], [5e-2,5e-2], 1e-3};
    else
        parameterNames = {'SolverOptions', 'SensorTransform', 'IMUParameters', 'FixPoses', 'InitialVelocity', 'PredictionThreshold'};
        defaultValuesForParameters = {factorGraphSolverOptions, se3(), factorIMUParameters, true, [NaN,NaN,NaN], [5e-2,5e-2]};
    end
    
    parser = robotics.core.internal.NameValueParser(parameterNames, defaultValuesForParameters);
    parse(parser, varargin{:});
    
    opts = parameterValue(parser, parameterNames{1});
    validateattributes(opts, {'factorGraphSolverOptions'}, {'nonempty', 'scalar'},callerFuncName, 'SolverOptions');
    sensorTransform = parameterValue(parser, parameterNames{2});
    validateattributes(sensorTransform, {'se3'}, {'nonempty', 'scalar'},callerFuncName, 'SensorTransform');
    imuParams = parameterValue(parser, parameterNames{3});
    validateattributes(imuParams, {'factorIMUParameters'}, {'nonempty', 'scalar'},callerFuncName, 'IMUParameters');
    fixPoses = parameterValue(parser, parameterNames{4});
    validateattributes(fixPoses, {'logical'}, {'nonempty', 'scalar'}, callerFuncName, 'FixPoses');
    initialVelocity = parameterValue(parser, parameterNames{5});
    validateattributes(initialVelocity, {'double'}, {'nonempty', 'vector', 'real', '2d', 'numel', 3}, callerFuncName, 'InitialVelocity');
    predictionThreshold = parameterValue(parser, parameterNames{6});
    validateattributes(predictionThreshold, {'double'}, {'nonempty', 'real', 'nonnan','finite', 'vector', '2d', '>', 0, 'numel', 2}, callerFuncName, 'PredictionThreshold');
    if computeScale
        scaleThreshold = parameterValue(parser, parameterNames{7});
        validateattributes(scaleThreshold, {'double'}, {'nonempty', 'scalar', 'real', 'nonnan','finite', '>', 0}, callerFuncName, 'ScaleThreshold');
    else
        % just assigning default value for codegen
        scaleThreshold = 1e-3;
    end
 
    
    isCamPoseTable = istable(poses) && any(strcmp(poses.Properties.VariableNames,'AbsolutePose')) && isa(poses.AbsolutePose, 'rigidtform3d');
    isSe3 = isa(poses, 'se3');
    isRigid = isa(poses, 'rigidtform3d');
    isPoseMat = isnumeric(poses);
    
    if isCamPoseTable
        [poseNodeStates, len] = rigidToMat(poses.AbsolutePose);
    elseif isRigid
        [poseNodeStates, len] = rigidToMat(poses);
    elseif isSe3
        len = length(poses);
        poseNodeStates = double([cat(1,poses.trvec),rotm2quat(cat(3,poses.rotm))]);
    elseif isPoseMat
        validateattributes(poses, 'numeric', ...
            {'2d', 'ncols', 7, 'real', 'nonnan',...
            'finite','nonempty'},...
            callerFuncName, 'poses');
        len = size(poses,1);
        poseNodeStates = double(poses(1:len,1:7));
    else
        poseNodeStates = zeros(0,7);
        coder.internal.error("nav:navalgs:factorgraph:InvalidInputPose");
    end
    coder.internal.assert(len>1,'nav:navalgs:factorgraph:PosesNotEnough');
    
    % validate gyroscope and accelerometer readings
    validateattributes(gyroscopeReadings,'cell',{'nonempty','vector'},callerFuncName, 'gyroscopeReadings');
    validateattributes(accelerometerReadings,'cell',{'nonempty','vector'},callerFuncName, 'accelerometerReadings');
    coder.internal.assert((length(accelerometerReadings)==(len-1)) && (length(gyroscopeReadings)==(len-1)),'nav:navalgs:factorgraph:MismatchPosesGyroAccelReadings', (len-1));
    for k = 1:length(accelerometerReadings)
        validateattributes(gyroscopeReadings{k},'numeric',{'2d', 'ncols', 3, 'real', 'nonnan','finite','nonempty'},callerFuncName, 'gyroscopeReadings');
        validateattributes(accelerometerReadings{k},'numeric',{'2d', 'ncols', 3, 'real', 'nonnan','finite','nonempty'},callerFuncName, 'accelerometerReadings');
        coder.internal.errorIf(size(gyroscopeReadings{k},1) ~= size(accelerometerReadings{k}, 1), ...
            'nav:navalgs:factorgraph:MismatchedIMUReadings');
    end
    
    f = factorGraph();
    
    % generate node ids
    scaleNodeID = generateNodeID(f,1);
    gravityNodeID = generateNodeID(f,1);
    tformID = generateNodeID(f,1);
    poseVelBiasNodeIDs = generateNodeID(f, [len,3]);
    
    
    % create IMU factor with readings between poses
    fIMUs = {};
    tt = zeros(len,1);
    for k = 2:len
        % create unique imu node ids
        nodeID = [poseVelBiasNodeIDs(k-1,:),poseVelBiasNodeIDs(k,:),gravityNodeID,scaleNodeID,tformID];
    
        % create imu factor with gravity and scale nodes
        fIMU = nav.algs.internal.FactorIMUGST( ...
            nodeID, ...
            gyroscopeReadings{k-1}(:,1:3), accelerometerReadings{k-1}(:,1:3), imuParams);
    
        % add imu factors to factor graph
        f.addFactor(fIMU);
        fIMUs{end+1} =fIMU;
        tt(k) = tt(k-1) + (1/imuParams.SampleRate)*size(gyroscopeReadings{k-1},1);
    end
    f.nodeState(tformID,sensorTransform.xyzquat);
    f.fixNode(tformID);
    
    % fix scale during optimization if the compute scale is false
    if ~computeScale
        f.fixNode(scaleNodeID);
    end
    % set node state
    kid = poseVelBiasNodeIDs(:,1);
    if fixPoses
        % fix pose nodes to only optimize IMU bias, scale and gravity direction
        f.fixNode(kid);
    else
        % fix only the first node.
        f.fixNode(kid(1));
        % add prior factors with large information to enable slight pose
        % refinement.
        for k = 1:length(kid)
            fPosePrior = factorPoseSE3Prior(kid(k),Measurement=poseNodeStates(k,:),Information=1e6*eye(6));
            addFactor(f,fPosePrior);
        end
    end
    % set input pose states 
    f.nodeState(kid,poseNodeStates(:,1:7));
    
    % add velocity prior on first imu velocity node
    if isfinite(initialVelocity)
        fVelPrior = factorVelocity3Prior(poseVelBiasNodeIDs(1,2),Measurement=initialVelocity(:)',Information=1e6*eye(3));
    else
        fVelPrior = factorVelocity3Prior(poseVelBiasNodeIDs(1,2));
    end
    f.addFactor(fVelPrior);
     
    % add bias prior on first bias node
    fBiasPrior = factorIMUBiasPrior(poseVelBiasNodeIDs(1,3));
    f.addFactor(fBiasPrior);
    
    % optimize factor graph
    solutionInfo = f.optimize(opts);
    
    if computeScale
        % extract computed scale
        scale = f.nodeState(scaleNodeID);
    end
    
    % extract computed gravity direction
    gDirQuat = f.nodeState(gravityNodeID);
    gDirRotm = quat2rotm([gDirQuat(4),gDirQuat(1),gDirQuat(2), gDirQuat(3)]);

    allBias = f.nodeState(poseVelBiasNodeIDs(:,3));
    allVel = f.nodeState(poseVelBiasNodeIDs(:,2));

    translationErrors = zeros(length(fIMUs),3);
    rotationErrors = zeros(length(fIMUs),3);
    refinedTform = f.nodeState(tformID);
    for k = 1:length(fIMUs)
        predictedPose = fIMUs{k}.predict([scale(1)*poseNodeStates(k,1:3),poseNodeStates(k,4:7)],scale(1)*allVel(k,:),allBias(k,:),gDirQuat([4,1,2,3]),1,refinedTform);
        translationErrors(k,:) = abs(scale(1)*poseNodeStates(k+1,1:3) - predictedPose(1,1:3));
        quatDiff = se3(poseNodeStates(k+1,4:7),"quat")*(se3(predictedPose(1,4:7),"quat").inv());
        rotationErrors(k,:) = abs(quatDiff.quaternion().rotvec());
    end
    
    refinedPoses = f.nodeState(kid);
    if isCamPoseTable 
        gRot = rigidtform3d(gDirRotm, [0,0,0]);
        posesOut = poses.AbsolutePose;
        posesOutSe3 = se3(gDirRotm).inv()*se3([scale(1)*refinedPoses(:,1:3),refinedPoses(:,4:7)],"xyzquat");
        for k = 1:length(posesOut)
            rotationMatrix = posesOutSe3(k).rotm;
            translation = posesOutSe3(k).trvec;
            posesOut(k) = rigidtform3d(rotationMatrix(1:3,1:3),translation(1,1:3));
        end
        posesInIMUReference = posesOut;
    elseif isRigid
        gRot = rigidtform3d(gDirRotm, [0,0,0]);
        posesOut = poses;
        posesOutSe3 = se3(gDirRotm).inv()*se3([scale(1)*refinedPoses(:,1:3),refinedPoses(:,4:7)],"xyzquat");
        for k = 1:length(posesOut)
            rotationMatrix = posesOutSe3(k).rotm;
            translation = posesOutSe3(k).trvec;
            posesOut(k) = rigidtform3d(rotationMatrix(1:3,1:3),translation(1,1:3));
        end
        posesInIMUReference = posesOut;
    elseif isSe3
        gRot = se3(gDirRotm);
        posesInIMUReference = se3(gDirRotm).inv()*se3([scale(1)*refinedPoses(:,1:3),refinedPoses(:,4:7)],"xyzquat");
    else
        gRot = gDirRotm;
        posesInIMUReference = xyzquat(se3(gDirRotm).inv()*se3([scale(1)*refinedPoses(:,1:3),refinedPoses(:,4:7)],"xyzquat"));
    end
       
    velocityInIMUReference = scale(1)*allVel;
    maxAllowedVariationFromInitialValue = 3*(sqrt([diag(imuParams.GyroscopeBiasNoise);diag(imuParams.AccelerometerBiasNoise)]').*sqrt(tt));
    biasUpperBounds = allBias(1,:) + maxAllowedVariationFromInitialValue;
    biasLowerBounds = allBias(1,:) - maxAllowedVariationFromInitialValue;
    poseToIMUTransform = se3(gDirRotm).inv();

    badScale = false;
    if scale(1) < scaleThreshold
        % scale below specified threshold.
        badScale = true;
    end

    badPrediction = false;
    if any(translationErrors>predictionThreshold(2),"all") || any(rotationErrors>predictionThreshold(1),"all")
        % prediction error above specified threshold
        badPrediction = true;
    end

    badBias = false;
    if any(allBias > biasUpperBounds, "all") || any(allBias < biasLowerBounds,"all")
        % estimated bias out of bounds
        badBias = true;
    end

    % validation status
    if (solutionInfo.IsSolutionUsable == 0) || (solutionInfo.TerminationType == 2)
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_OPTIMIZATION;
    elseif (solutionInfo.IsSolutionUsable == 1) && (solutionInfo.TerminationType == 1)
        status = nav.GravityRotationEstimationStatus.FAILURE_NO_CONVERGENCE;
    elseif (badPrediction & (~badBias) & (~badScale))
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_PREDICTION;
    elseif ((~badPrediction) & badBias & (~badScale))
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_BIAS;
    elseif ((~badPrediction) & (~badBias) & badScale)
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_SCALE;
    elseif (badPrediction & badBias & (~badScale))
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_PREDICTION_BIAS;
    elseif ((~badPrediction) & badBias & badScale)
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_SCALE_BIAS;
    elseif (badPrediction & (~badBias) & badScale)
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_SCALE_PREDICTION;
    elseif (badPrediction & badBias & badScale)
        status = nav.GravityRotationEstimationStatus.FAILURE_BAD_SCALE_PREDICTION_BIAS;
    else
        status = nav.GravityRotationEstimationStatus.SUCCESS;
    end

    info = struct('Status', status, 'TranslationErrors', translationErrors, ...
        'RotationErrors', rotationErrors, 'VelocityInIMUReference', velocityInIMUReference, ...
        'Bias', allBias, 'PoseToIMUTransform', poseToIMUTransform, ...
        'PosesInIMUReference', posesInIMUReference, 'InitialCost', solutionInfo.InitialCost, ...
        'FinalCost', solutionInfo.FinalCost, 'FixedNodeIDs', solutionInfo.FixedNodeIDs, ...
        'IsSolutionUsable', solutionInfo.IsSolutionUsable, 'NumSuccessfulSteps', solutionInfo.NumSuccessfulSteps, ...
        'NumUnsuccessfulSteps', solutionInfo.NumUnsuccessfulSteps, 'OptimizedNodeIDs', solutionInfo.OptimizedNodeIDs, ...
        'TerminationType', solutionInfo.TerminationType, 'TotalTime', solutionInfo.TotalTime);
end

function [m,numPoses] = rigidToMat(poses)
numPoses = length(poses);
if coder.target("MATLAB")
    t = double(vertcat(poses.Translation));
    R = double(cat(3,poses.R));
else
    % Dot indexing of rigidtform3d object array during code
    % generation produces single output.
    t = zeros(numPoses,3);
    R = zeros(3,3,numPoses);
    for p = 1:numPoses
        t(p,1:3) = double(poses(p).Translation);
        R(1:3,1:3,p) = double(poses(p).R);
    end
end
m = [t,rotm2quat(R)];
end
