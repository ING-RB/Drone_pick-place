function [M,MInd] = parseOneInput(arg)
%This method is for internal use only. It may be removed in the future.

%PARSEONEINPUT Parse the so3 constructor with one input argument
%   Possible call syntax parsed here
%   - so3([])
%   - so3(RM)
%   - so3(SO2OBJ)
%   - so3(QUATERNION)
%   - so3(SO3OBJ)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isa(arg, "float") && coder.internal.isConstFalse(isequal(size(arg), [0 0]))
        % so3(RM) - constructor with 3x3xN matrix
        robotics.internal.validation.validateRotationMatrix(arg, "so3", "RM");
        [M,MInd] = matlabshared.spatialmath.internal.SOBase.rawDataFromRotm(arg);

    elseif isa(arg, "float") && coder.internal.isConstTrue(isequal(size(arg), [0 0]))
        % so3([])
        % This handles the explicit case of [] or known
        % (codegen constant) 0x0.
        M = zeros(3,3,0,"like",arg);
        MInd = zeros(size(arg),"like",arg);

    elseif isa(arg, "quaternion")
        % so3(QUATERNION) - constructor with quaternion object

        R = arg.rotmat("point");
        [M,MInd] = matlabshared.spatialmath.internal.SOBase.rawDataFromRotm(R,size(arg));

    elseif isa(arg, "so2")
        % so3(SO2OBJ) - constructor from 2D rotation object

        % The 2D rotation is a rotation around the z axis in 3D
        % which is blkdiag(arg.rotm,1). To work for paged
        % matrices, use rotm2tform for the same effect.
        rotm = robotics.internal.rotm2tform(arg.rotm);

        [M,MInd] = matlabshared.spatialmath.internal.SOBase.rawDataFromRotm(rotm,size(arg));

    elseif isa(arg, "matlabshared.spatialmath.internal.SO3Base")
        % so3(SO3obj) - copy constructor
        M = arg.M;
        MInd = arg.MInd;

    else
        % Use errorIf to ensure compile-time error
        coder.internal.errorIf(true, "shared_spatialmath:so3:InvalidFirstArg");
    end

end
