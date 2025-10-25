classdef cameraIMUCalibrationOptions
%

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen
    properties
        InitialTransform (1,1) {...
            mustBeA(InitialTransform,{'se3','rigidtform3d'}) } = se3

        SolverOptions (1,1) {...
            mustBeA(SolverOptions,{'factorGraphSolverOptions'})} = factorGraphSolverOptions

        CameraPoses {checkCameraPoses} = zeros(0,7)

        ImageSampleRate double {mustBeReal,mustBeNonNan,mustBeFinite,mustBeInteger,mustBePositive,mustBeScalarOrEmpty} = []

        ImageTime {mustBeA(ImageTime,{'datetime'}), mustBeVector, checkImageTimeLength} = datetime.empty(1,0)

        UndistortPoints (1,1) logical = true

        CameraInformation double {mustBeReal,mustBeNonNan, mustBeFinite, validateattributes(CameraInformation,{'numeric'},{'2d','size',[2,2]},'cameraIMUCalibrationOptions','CameraInformation') } = eye(2)

        ShowProgress (1,1) string {mustBeMember(ShowProgress,{'all', 'undistortion', 'camera-poses', 'none'})} = "all"
    end

    methods
        function obj=cameraIMUCalibrationOptions(nvargs)
        
            arguments
                nvargs.InitialTransform
                nvargs.SolverOptions
                nvargs.CameraPoses
                nvargs.ImageSampleRate
                nvargs.ImageTime
                nvargs.UndistortPoints
                nvargs.CameraInformation
                nvargs.ShowProgress
            end
            userProvidedProperties=fieldnames(nvargs);
            for i=coder.unroll(1:length(userProvidedProperties))
                obj.(userProvidedProperties{i})=nvargs.(userProvidedProperties{i});
            end
        end
    end

end

function checkCameraPoses(poses)
%checkCameraPoses checks the validity of input camera poses.

    % camera poses can be a table with AbsolutePose column or rigidtform3d
    % array or se3 array or N-by-7 matrix.
    isSe3 = isa(poses, 'se3');
    isCamPoseTable = istable(poses) && isa(poses.AbsolutePose, 'rigidtform3d');
    if isCamPoseTable
        isAbsolutePoseMember = false;
        for k = 1: length(poses.Properties.VariableNames)
            if strcmp('AbsolutePose', poses.Properties.VariableNames{k})
                isAbsolutePoseMember = true;
                break;
            end
        end
        isCamPoseTable = isCamPoseTable && isAbsolutePoseMember;
    end
    isRigid = isa(poses, 'rigidtform3d');
    isPoseMat = isnumeric(poses) && size(poses,2)==7;
    valid = (isSe3 || isPoseMat || isRigid || isCamPoseTable);

    if ~valid
        coder.internal.error("nav:navalgs:factorgraph:InvalidCameraPoses");
    end

    if isRigid || isSe3
        len = length(poses);
    elseif isCamPoseTable
        len = length(poses.AbsolutePose);
    else
        len = size(poses,1);
    end
    if len>0
        coder.internal.assert(len>1,'nav:navalgs:camimucalibration:PosesOptionNotEnough');
    end
end

function checkImageTimeLength(imageTime)
%checkImageTimeLength verifies that the imageTime length is greater than 1.

% accept default empty imageTime
if ~isempty(imageTime)
    % user specified default time must have length greater than 1
    coder.internal.assert(~isscalar(imageTime),'nav:navalgs:camimucalibration:MinImageTimeLength');
    % image times must be unique.
    coder.internal.assert((length(unique(imageTime))==length(imageTime)),'nav:navalgs:camimucalibration:NonUniqueImageTime');
end
end
