function [M,MInd] = parseOneInput(arg)
%This method is for internal use only. It may be removed in the future.

%PARSEONEINPUT Parse the se3 constructor with one input argument
%   Possible call syntax parsed here
%   - se3([])
%   - se3(R)
%   - se3(TF)
%   - se3(SO3OBJ)
%   - se3(QUATERNION)
%   - se3(SE2OBJ)
%   - se3(SE3OBJ)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isa(arg, "float") && coder.internal.isConstFalse(isequal(size(arg), [0 0]))
        if size(arg,1) == 4
            % se3(TF) - constructor with 4x4xN matrix
            robotics.internal.validation.validateHomogeneousTransform(arg, "se3", "TF");

            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(arg);
        else
            % se3(R) - constructor with 3x3xN rotation matrix
            robotics.internal.validation.validateRotationMatrix(arg, "se3", "R");
            tf = robotics.internal.rotm2tform(arg);

            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tf);
        end

    elseif isa(arg, "float") && coder.internal.isConstTrue(isequal(size(arg), [0 0]))
        % se3([])
        % This handles the explicit case of [] or known
        % (codegen constant) 0x0.

        M = zeros(4,4,0,"like",arg);
        MInd = zeros(size(arg),"like",arg);

    elseif isa(arg, "so3")
        % se3(SO3OBJ) - constructor with so3 object
        % Directly convert the underlying data. No extra
        % validation is needed.

        M = robotics.internal.rotm2tform(arg.rotm);
        [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(M, size(arg));

    elseif isa(arg, "quaternion")
        % se3(QUATERNION) - constructor with quaternion object

        R = arg.rotmat("point");
        tf = robotics.internal.rotm2tform(R);
        [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tf, size(arg));

    elseif isa(arg, "se2")
        % se3(SE2OBJ) - constructor from 2D transformation object

        % The 2D rotation is a rotation around the z axis in 3D
        % which is blkdiag(arg.rotm,1). To work for paged
        % matrices, use rotm2tform for the same effect.
        rotm = robotics.internal.rotm2tform(arg.rotm);
        % trvec has to be a 3xN matrix
        trvec = [arg.trvec.'; zeros(1, numel(arg), arg.underlyingType)];
        obj = se3.fromRotmTrvec(rotm, trvec, size(arg));
        M = obj.M;
        MInd = obj.MInd;

    elseif isa(arg, "matlabshared.spatialmath.internal.SE3Base")
        % se3(se3obj) - copy constructor
        M = arg.M;
        MInd = arg.MInd;
    else
        % Use errorIf to ensure compile-time error
        coder.internal.errorIf(true, "shared_spatialmath:se3:InvalidFirstArg");
    end


end
