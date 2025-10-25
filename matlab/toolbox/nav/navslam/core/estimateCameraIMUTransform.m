function [tform, params] = estimateCameraIMUTransform(imagePoints,patternPoints,...
    imuMeasurements,intrinsics,imuParams,options)
%

%   Copyright 2023-2024 The MathWorks, Inc.

arguments
    imagePoints {mustBeA(imagePoints,{'double', 'timetable'})}
    patternPoints double {mustBeNumeric, mustBeReal, mustBeNonempty, mustBeNonNan, mustBeFinite, validateattributes(patternPoints,{'numeric'},{'2d','ncols',2},'estimateCameraIMUTransform','patternPoints')}
    imuMeasurements {checkIMUMeasurementTable}
    intrinsics (1,1) {mustBeA(intrinsics,{'cameraIntrinsics'})}
    imuParams (1,1) {mustBeA(imuParams,{'factorIMUParameters'})}
    options (1,1) {mustBeA(options,{'cameraIMUCalibrationOptions'})} = cameraIMUCalibrationOptions
end
imagePointsTable = checkImagePoints(imagePoints,size(patternPoints,1),options.ImageSampleRate,...
    options.ImageTime,imuMeasurements.Properties.StartTime);

if options.UndistortPoints
    showUnDistortionProgressBar = any(strcmp(options.ShowProgress, {'all', 'undistortion'}));
    if coder.target('MATLAB') && showUnDistortionProgressBar
        pDlgTitle = getString(message('nav:navalgs:camimucalibration:UndistortImagePointsTitle'));
        dlg = waitbar(0, '', ...
            'Tag', 'UndistortCamIMUProgressBar',...
            'WindowStyle', 'modal',...
            'Name', pDlgTitle);
    end
    numImages = height(imagePointsTable);
    for k = 1:numImages
        pts = squeeze(imagePointsTable.imagePoints(k,:,:));
        v = ~isnan(pts(:,1));
        ptsu = undistortPoints(pts(v,:),intrinsics);
        imagePointsTable.imagePoints(k,v,:) = ptsu;
        if coder.target('MATLAB') && showUnDistortionProgressBar
            waitbar(k/numImages,dlg);
        end
    end
    if coder.target('MATLAB') && showUnDistortionProgressBar
        close(dlg)
    end
end


[T,errors,estimates,info] = nav.algs.internal.estimateCameraIMUTransform( ...
    imagePointsTable,patternPoints,imuMeasurements,intrinsics,imuParams, options);

if isa(options.InitialTransform,"se3")
    tform = T;
else
    tform = rigidtform3d(T.tform);
end

params = cameraIMUParameters.constructObject(tform, errors, estimates, info, ...
                                      imagePointsTable.Time, intrinsics, imuParams);
end

function checkIMUMeasurementTable(imuMeasurementTable)
%checkIMUMeasurementTable checks the validity of IMU measurements input.

% imu measurements must be a timetable with Accelerometer and Gyroscope column
valid = istimetable(imuMeasurementTable) && width(imuMeasurementTable)==2 && ...
    any(ismember(imuMeasurementTable.Properties.VariableNames,'Accelerometer')) && ...
    any(ismember(imuMeasurementTable.Properties.VariableNames,'Gyroscope')) && ...
    size(imuMeasurementTable.Accelerometer,2)==3 && size(imuMeasurementTable.Gyroscope,2)==3;

if ~valid
    coder.internal.error('nav:navalgs:factorgraph:InvalidInputIMUMeasurements');
end
end

function imagePointsTable = checkImagePoints(imagePoints, numLandmarks, ...
    sampleRate, imageTime, imuStart)
%checkImagePointTable checks the validity of image points input.

% image points must be a timetable with imagePoints column
formatTable = (istimetable(imagePoints) && width(imagePoints)==1 && ...
    size(imagePoints.(imagePoints.Properties.VariableNames{1}),2)==numLandmarks && ...
    size(imagePoints.(imagePoints.Properties.VariableNames{1}),3)==2);

formatMatrix = (isnumeric(imagePoints) && ...
    size(imagePoints,2)==2 && ~isempty(imagePoints) && size(imagePoints,1)==numLandmarks);

valid = formatTable || formatMatrix;

if ~valid
    coder.internal.error('nav:navalgs:camimucalibration:InvalidInputImagePoints');
end

if formatMatrix
    if isempty(imageTime) && isempty(sampleRate)
        coder.internal.error('nav:navalgs:camimucalibration:ImageSampleRateOrTimeMustBeSpecified');
    end
    numImages = size(imagePoints,3);

    if ~isempty(imageTime)
        Time = imageTime(:);
        if length(Time)~=size(imagePoints,3)
            coder.internal.error('nav:navalgs:camimucalibration:WrongImageTimeLength');
        end
        imagePointsTable = timetable(Time, permute(imagePoints,[3,1,2]), ...
            'VariableNames',{'imagePoints'});
    else
        Time = (imuStart:seconds(1/sampleRate):(imuStart + seconds((numImages-1)/sampleRate)))';
        imagePointsTable = timetable(Time, permute(imagePoints,[3,1,2]), ...
            'VariableNames',{'imagePoints'});
    end
else
    numImages = size(imagePoints.(imagePoints.Properties.VariableNames{1}),1);
    imagePointsTable = timetable(imagePoints.Properties.RowTimes,imagePoints.Variables,'VariableNames',{'imagePoints'});
    coder.internal.assert((length(unique(imagePointsTable.Time))==length(imagePointsTable.Time)),'nav:navalgs:camimucalibration:NonUniqueImagePointTable');
end
coder.internal.assert(numImages>1,'nav:navalgs:camimucalibration:MinImages');
end
