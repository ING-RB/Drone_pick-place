function [M,MInd] = parseTwoInputs(arg1, arg2)
%This method is for internal use only. It may be removed in the future.

%parseTwoInputs Parse the se3 constructor with two input arguments
%   Possible call syntax parsed here
%     se3(R,TRANSL)
%     se3(SO3OBJ,TRANSL)
%     se3(QTN,TRANSL)
%     se3(E,"eul")
%     se3(Q,"quat")
%     se3(AXANG,"axang")
%     se3(ANG,"rotx")
%     se3(ANG,"roty")
%     se3(ANG,"rotz")
%     se3(TRANSL,"trvec")
%     se3(POSE,"xyzquat")


%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isfloat(arg2)
        % se3(R,TRANSL) or
        % se3(SO3OBJ,TRANSL) or
        % se3(QTN,TRANSL)

        rot = arg1;
        transl = arg2;
        matlabshared.spatialmath.internal.SE3Base.parseTranslationInput(transl);

        % Deal with rotation
        if isa(rot, "float")
            % Rotation is specified as 3x3xN rotation matrix
            robotics.internal.validation.validateRotationMatrix(rot, "se3", "R");
            tf = robotics.internal.rotm2tform(rot);
            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl);
            validRot = true;
        elseif isa(rot, "so3")
            % Rotation is specified as so3 object array
            tf = robotics.internal.rotm2tform(rot.rotm);
            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl, size(rot));
            validRot = true;
        elseif isa(rot, "quaternion")
            % Rotation is specified as quaternion object array
            R = rot.rotmat("point");
            tf = robotics.internal.rotm2tform(R);
            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl, size(rot));
            validRot = true;
        else
            validRot = false;
        end
        coder.internal.errorIf(~validRot, "shared_spatialmath:se3:InvalidFirstArg");

    else
        % se3(...,"eul"/"quat"/"axang"/"rotx"/"roty"/"rotz"/"trvec"/"xyzquat")

        data = arg1;
        inputType = arg2;
        [tf,sz] = matlabshared.spatialmath.internal.SE3Base.parseConversionInputs(data, inputType);

        % Assign the object data based on the transformation
        % matrix
        [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tf,sz);
    end

end
