function [tform, errors, estimates, solnInfo] = estimateCameraIMUTransform( ...
    imagePoints, patternPoints, imuMeasurements, cameraIntrinsics, imuParams, nvargs)
%estimateCameraIMUTransform estimates the transformation from camera
%   sensor to IMU sensor using calibration target board.
%
%   ESTIMATECAMERAIMUTRANSFORM estimates 3-D rotation and translation that
%   helps in transforming a quantity like a pose or a point from Camera to
%   IMU frame from input target board landmark corner point tracks and IMU
%   measurement data. Both Camera and IMU are rigidly attached to each
%   other. Capture image and IMU data by moving the Camera-IMU setup around
%   a target board in such a way to excite IMU along all axes. Use CVT
%   utilities to create image point tracks of target board corners.
%
%   estimateCameraIMUTransform(IMAGEPOINTS,WORLDPOINTS,IMUMEASUREMENTS,  
%                           CAMERAINTRINSICS,IMUPARAMS) specifies  
%   IMAGEPOINTS     - Undistorted image point tracks of calibration target
%                     specified as a timetable with one column 
%                     imagePoints of size N-by-P-by-2 where N is the number 
%                     of images, P is number of calibration target board 
%                     landmark points.
%
%   PATTERNPOINTS    - World points corresponding to target calibration
%                     board tag corners specified as a N-by-2 matrix.
%
%   IMUMEASUREMENTS - IMU accelerometer and gyroscope measurements acquired
%                     at different time stamps as a timetable with 2 
%                     columns Accelerometer and Gyroscope with size of 
%                     N-by-3, where N is the total number of IMU readings
%                     in the calibration data.
%       
%   IMUPARAMS       - IMU Parameters specified as a factorIMUParameters
%                     object.
%
%   CAMERAINTRINSICS- Camera intrinsic parameters must be specified as
%                     a cameraIntrinsics object.
%
%   NVARGS          - Name-Value arguments specified as a
%                     cameraIMUCalibrationOptions object
% 
%   [TFORM, ERRORS, ESTIMATES, SOLINFO] = estimateCameraIMUTransform(...)  
%           
%          TFORM - Camera to IMU transform containing a point rotation and
%                  translation from initial camera reference frame to
%                  initial IMU reference frame, returned as a se3 object.
%
%         ERRORS - Calibration errors returned as structure containing: 
%                  "ReprojectionError" - M-by-2-by-N double array, where
%                                        each element is absolute
%                                        difference between the projected
%                                        landmark points and image point
%                                        observations of the same in each
%                                        frame. N is the number of images
%                                        used and M is number of landmarks
%                                        in target calibration board.
%                  "RotationError" - (N-1)-by-3 double array, where each
%                                    element is absolute euler distance
%                                    between relative rotation computed
%                                    between consecutive image frames using
%                                    camera poses and IMU pre-integration.
%                                    pre-integration.
%                  "TranslationError" - (N-1)-by-3 double array, where each
%                                       element is absolute distance
%                                       between relative translation
%                                       computed between consecutive image
%                                       frames using camera poses and IMU
%                                       pre-integration.
%
%        ESTIMATES - Additional quantities estimated along with sensor
%                    transform specified as a structure containing:
%                  "CameraPoses" - Camera Pose estimates after
%                                  calibration optimization. They may be
%                                  slightly different from user specified
%                                  poses after optimization.
%                  "GravityRotation" - scalar se3 object, gravity rotation  
%                                       computed during calibration. 
%                  "IMUBias" - N-by-6 double matrix, IMU accelerometer and  
%                              gyroscope bias computed during calibration. 
%              "IMUVelocity" - N-by-3 double matrix, IMU velocities 
%                              computed during calibration. 
% 
%        SOLNINFO   - Factor graph solution information returned as   
%                     structure similar to factor graph optimize output. 
% 
%
%   [1] T. Qin and S. Shen, "Online Temporal Calibration for Monocular
%   Visual-Inertial Systems," 2018 IEEE/RSJ International Conference on
%   Intelligent Robots and Systems (IROS), Madrid, Spain, 2018, pp.
%   3662-3669, doi: 10.1109/IROS.2018.8593603.
%
%   [2] P. Furgale, J. Rehder and R. Siegwart, "Unified temporal and
%   spatial calibration for multi-sensor systems," 2013 IEEE/RSJ
%   International Conference on Intelligent Robots and Systems, Tokyo,
%   Japan, 2013, pp. 1280-1286, doi: 10.1109/IROS.2013.6696514.
%
%   [3] T. Qin, P. Li and S. Shen, "VINS-Mono: A Robust and Versatile
%   Monocular Visual-Inertial State Estimator," in IEEE Transactions on
%   Robotics, vol. 34, no. 4, pp. 1004-1020, Aug. 2018, doi:
%   10.1109/TRO.2018.2853729.
%
%   See also factorIMU, factorIMUParameters, estimateGravityRotation
%   estimateGravityRotationAndPoseScale, factorCameraSE3AndPointXYZ

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    narginchk(5,11);

    numLandmarks = size(patternPoints,1);
    imgPoints = imagePoints.imagePoints;
    cameraIntrinsicMatrix = cameraIntrinsics.K;
    
    if isa(nvargs.InitialTransform,'se3')
        initialTransform = nvargs.InitialTransform;
    else
        initialTransform = se3(nvargs.InitialTransform.A);
    end
    opts = nvargs.SolverOptions;
    cameraPoses = checkCameraPoses(nvargs.CameraPoses,height(imagePoints));

    % extract IMU data between images
    [validImageIds, accel, gyro] = extractIMUDataBetweenImages(imagePoints,imuMeasurements, imuParams);

    % compute the camera pose guess if not provided
    if isempty(cameraPoses)
        vSet = imageviewset();
        for k = 1:length(validImageIds)
            imgId = validImageIds(k);
            valid = ~isnan(squeeze(imgPoints(imgId,:,1)));
            if length(find(valid)) >= 3
                % at least 3 valid points are needed for pose estimation
                imPoints = squeeze(imgPoints(imgId,valid,1:2));
                Tr = estimateExtrinsics(imPoints,patternPoints(valid,1:2),cameraIntrinsics);
                T = extr2pose(Tr);
                vSet = addView(vSet,k,T);
            else
                coder.internal.error("nav:navalgs:factorgraph:WrongWorldPointTracks",imgId);
            end

            showCameraPoseEstimationProgress = any(strcmp(nvargs.ShowProgress, {'all', 'camera-poses'}));
            if coder.target("MATLAB") && showCameraPoseEstimationProgress
                % plot camera pose estimates
                if k == 1
                    ax = axes(figure("Tag","CameraIMUCalibration_CameraPoses"), ...
                        CameraPosition=[1000,1000,-1000],CameraUpVector=[0,1,0]);
                    title(ax,getString(message("nav:navalgs:factorgraph:CameraPosePlotTitle")))
                    hold(ax,"on");
                    legendPoints = getString(message('nav:navalgs:camimucalibration:LegendPatternPoints'));
                    legendTrajectory = getString(message('nav:navalgs:camimucalibration:LegendCameraTrajectory'));
                    plot3(ax,patternPoints(:,1),patternPoints(:,2),zeros(size(patternPoints,1),1),'.',SeriesIndex=5,DisplayName=legendPoints);
                    traj = plot3(ax, T.Translation(1),T.Translation(2),T.Translation(3),'.-',SeriesIndex=1,DisplayName=legendTrajectory);
                    cam = plotCamera("AbsolutePose",T,'Size',0.02,'Parent',ax,'AxesVisible',true);
                    hold(ax,"off");
                    % add axis label
                    xlabel(ax,getString(message('nav:navalgs:camimucalibration:AxisX')));
                    ylabel(ax,getString(message('nav:navalgs:camimucalibration:AxisY')));
                    zlabel(ax,getString(message('nav:navalgs:camimucalibration:AxisZ')));
                    legend(ax,"show");
                else
                    if ~isempty(traj) && ~isempty(cam)
                        cam.AbsolutePose = T;
                        set(traj, 'XData',[traj.XData,T.Translation(1)],...
                            'YData',[traj.YData,T.Translation(2)],'ZData',...
                            [traj.ZData,T.Translation(3)]);
                    end
                end
                drawnow limitrate;
            end
        end
        p = poses(vSet);
        pSe3 = se3(cat(3,p.AbsolutePose.R),vertcat(p.AbsolutePose.Translation));
        usedCameraPoses = xyzquat(pSe3);
        validImageIds = validImageIds(p.ViewId);
    else
        usedCameraPoses = cameraPoses(validImageIds,:);
    end
    numCams = size(usedCameraPoses,1);

    fg = factorGraph;
    % add camera projection factors to factor graph
    allObservations = zeros(numLandmarks*size(imgPoints,1),4);
    cnt = 1;
    wid = generateNodeID(fg,[numLandmarks,1]);
    pids = generateNodeID(fg,[numCams,1]);
    for k = 1:numCams
        pid = pids(k);
        ip = squeeze(imgPoints(validImageIds(k),:,:));
        valid = ~isnan(ip(:,1));
        ln = length(find(valid));
        allObservations(cnt:(cnt+ln-1),:) = [pid*ones(ln,1),wid(valid),ip(valid,1:2)];
        cnt = cnt + ln;
    end
    allObservations = allObservations(1:(cnt-1),:);
    cameraInformation = nvargs.CameraInformation;
    fCams = factorCameraSE3AndPointXYZ(allObservations(:,1:2),cameraIntrinsicMatrix,...
        Measurement=allObservations(:,3:4),Information=cameraInformation);
    addFactor(fg,fCams);
    % set world point and camera pose guess
    addedWorldPointIds = nodeIDs(fg,"NodeType","POINT_XYZ");
    nodeState(fg,addedWorldPointIds,[patternPoints(addedWorldPointIds+1,:),zeros(length(addedWorldPointIds),1)]);
    nodeState(fg,pids,usedCameraPoses);
    
    % assume that the landmark points are on a perfectly planar surface and
    % fix them during optimization.
    fixNode(fg,addedWorldPointIds);

    % add IMU factors to factor graph
    imuVelBiasIds = generateNodeID(fg,[numCams,2]);
    gravityId = generateNodeID(fg,1);
    scaleId = generateNodeID(fg,1);
    tformId = generateNodeID(fg,1);
    fIMUs = coder.nullcopy(cell(1,numCams-1));
    for k = 1:(numCams-1)
        accelerometerReadings = accel{k};
        gyroscopeReadings = gyro{k};
        if ~isempty(accelerometerReadings)
            imuNodeIds = [pids(k),imuVelBiasIds(k,1:2),pids(k+1),imuVelBiasIds(k+1,1:2),gravityId,scaleId,tformId];
            fIMU = nav.algs.internal.FactorIMUGST(imuNodeIds,gyroscopeReadings,accelerometerReadings,imuParams);
            addFactor(fg, fIMU);
            fIMUs{k} = fIMU;
        end
    end
    % specify initial guess
    nodeState(fg,tformId,xyzquat(initialTransform));
    % the camera pose measurements are expected to be already at known
    % metric scale. So fixing the scale at default value of 1.
    fixNode(fg,scaleId);

    % solve calibration optimization problem
    solnInfo = optimize(fg,opts);

    % extract results after optimization
    tformXyzQuat = nodeState(fg,tformId);
    tform = se3(tformXyzQuat,"xyzquat");
    g1 = nodeState(fg,gravityId);
    gRot = [g1(4),g1(1:3)];
    solvedPoses = nodeState(fg,pids);
    imuVel = nodeState(fg,imuVelBiasIds(:,1));
    imuBias = nodeState(fg,imuVelBiasIds(:,2));

    % compute errors
    errors = computeErrors(imgPoints(validImageIds,:,:),patternPoints,fIMUs,solvedPoses,cameraIntrinsicMatrix,tformXyzQuat,gRot,imuVel,imuBias);
    
    estimates.GravityRotation = se3(gRot,"quat");
    estimates.CameraPoses = struct('ImageIndex',validImageIds,'AbsolutePose',solvedPoses);
    estimates.IMUVelocity = imuVel;
    estimates.IMUBias = imuBias;
end

function poseNodeStates = checkCameraPoses(poses,expectedLength)
%checkCameraPoses checks the validity of input camera poses.

    % camera poses can be a table with AbsolutePose column or rigidtform3d
    % array or se3 array or N-by-7 matrix.
    isSe3 = isa(poses, 'se3');
    isCamPoseTable = istable(poses) && ismember('AbsolutePose',poses.Properties.VariableNames) && isa(poses.AbsolutePose, 'rigidtform3d');
    isRigid = isa(poses, 'rigidtform3d');
    isPoseMat = isnumeric(poses);
    % By default camera poses are not expected so poses is an empty se3
    % object.
    poseNodeStates = zeros(0,7);
    if  ~(isempty(poses) && (isSe3 || isPoseMat || isRigid || isCamPoseTable))
        if isCamPoseTable
            len = length(poses.AbsolutePose);
            poseNodeStates = [double(cat(1,poses.AbsolutePose.Translation)),double(rotm2quat(cat(3,poses.AbsolutePose.R)))];
        elseif isRigid
            len = length(poses);
            poseNodeStates = [double(cat(1,poses.Translation)),double(rotm2quat(cat(3,poses.R)))];
        elseif isSe3
            len = length(poses);
            poseNodeStates = [cat(1,poses.trvec),rotm2quat(cat(3,poses.rotm))];
        elseif isPoseMat
            validateattributes(poses, 'numeric', ...
                {'2d', 'ncols', 7, 'real', 'nonnan',...
                'finite','nonempty'},...
                'estimateCameraIMUTransform', 'poses');
            len = size(poses,1);
            poseNodeStates = double(poses(1:len,1:7));
        else
            coder.internal.error("nav:navalgs:factorgraph:InvalidCameraPoses");
        end
        coder.internal.assert(len==expectedLength,'nav:navalgs:factorgraph:InvalidCameraPoses');
    end
end

function [validImageIds, accel, gyro] = extractIMUDataBetweenImages(imagePoints,imuMeasurements, imuParams)
%extractIMUDataBetweenImages extracts accelerometer and gyroscope
%   readings between images.

% sort the data
[ipts, vipts] = sortrows(imagePoints,imagePoints.Properties.DimensionNames{1});
imus = sortrows(imuMeasurements,imuMeasurements.Properties.DimensionNames{1});

% valid calibration data should at least have some overlapping time range.
[valid,vids]= overlapsrange(ipts,imus);
validImageIds = vipts(vids);
iptsValid = ipts(vids,:);
numValidImages = height(iptsValid);
if ~(valid && numValidImages>1)
    coder.internal.error("nav:navalgs:factorgraph:WrongOverlapImageIMU");
end

% synchronize IMU readings with image data
syncTimes = (imagePoints.Properties.RowTimes(validImageIds(1)):seconds(1/imuParams.SampleRate):imagePoints.Properties.RowTimes(validImageIds(end)))';
imuSync = retime(imus,syncTimes,"linear");

% extract imu data between valid images
imgT = convertTo(iptsValid.Properties.RowTimes,"posixtime")*1e9;
imuT = convertTo(imuSync.Properties.RowTimes,"posixtime")*1e9;
accel = cell(1,numValidImages-1);
gyro = cell(1,numValidImages-1);
for k = 2:numValidImages
    [~,i1] = min(abs(imuT - imgT(k-1)));
    [~,i2] = min(abs(imuT - imgT(k)));
    accel{k-1} = imuSync.Accelerometer(i1:(i2-1),:);
    gyro{k-1} = imuSync.Gyroscope(i1:(i2-1),:);
end
end

function errors = computeErrors(imagePoints,worldPoints,fIMUs,camPoses,cameraIntrinsicMatrix,sensorTform,gRot,imuVel,imuBias)
%computeErrors computes re-projection, translation and rotational error
%   after calibration.

% project landmark points onto each image using camera pose and intrinsic
% matrix.
R = quat2rotm(camPoses(:,4:7));
Rt = pagetranspose(R);
t = reshape(camPoses(:,1:3)',3,1,size(camPoses,1));
tt = -1*pagemtimes(Rt,t);
camMatrix = pagemtimes(cameraIntrinsicMatrix,[Rt,tt]);
uv = pagemtimes(camMatrix,[worldPoints';zeros(1,size(worldPoints,1));ones(1,size(worldPoints,1))]);
projectedImagePoints = pagetranspose(uv(1:2,:,:)./uv(3,:,:));

rpe = nan(size(worldPoints,1),2,size(camPoses,1));
rote = zeros(size(camPoses,1)-1,3);
tre = zeros(size(camPoses,1)-1,3);

for k = 1:size(camPoses,1)
    ipts = squeeze(imagePoints(k,:,:));
    valid = ~isnan(ipts(:,1));
    rp = ipts(valid,:)-projectedImagePoints(valid,:,k);
    rpe(valid,:,k) = abs(rp);
    if k~=size(camPoses,1)
        actualPredictedPose = predict(fIMUs{k},camPoses(k,:),imuVel(k,:),imuBias(k,:),gRot,1,sensorTform);
        expectedPose = camPoses(k+1,1:7);
        % error = expected - actual
        rotDiff = se3(expectedPose(1,4:7),"quat")*(se3(actualPredictedPose(1,4:7),"quat").inv());
        rote(k,:) = abs(eul(rotDiff,"ZYX"));   
        tre(k,:) = abs(expectedPose(1,1:3) - actualPredictedPose(1,1:3));
    end
end

errors.ReprojectionError = rpe;
errors.RotationError = rote(:,[3,2,1]);
errors.TranslationError = tre;
end
