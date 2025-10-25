function [M,MInd] = parseTwoInputs(arg1, arg2)
%This method is for internal use only. It may be removed in the future.

%parseTwoInputs Parse the se2 constructor with two input arguments
%   Possible call syntax parsed here
%     se2(R,TRANSL) or
%     se2(SO2OBJ,TRANSL) or
%     se2(ANG, "theta") or
%     se2(TRANSL, "trvec") or
%     se2(POSE, "xytheta")

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if isfloat(arg2)
        % se2(R,TRANSL) or
        % se2(SO2OBJ,TRANSL) or

        rot = arg1;
        transl = arg2;

        % Parse and validate translation
        matlabshared.spatialmath.internal.SE2Base.parseTranslationInput(transl);

        % Parse and validate rotation
        if isa(rot, "float")
            % Rotation is specified as 2x2xN rotation matrix
            robotics.internal.validation.validateRotationMatrix2D(rot, "se2", "R");
            tf = robotics.internal.rotm2tform(rot);
            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl);
            validRot = true;
        elseif isa(rot, "so2")
            % Rotation is specified as so2 object array
            tf = robotics.internal.rotm2tform(rot.rotm);
            [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl, size(rot));
            validRot = true;
        else
            validRot = false;
        end
        coder.internal.errorIf(~validRot, "shared_spatialmath:se2:InvalidFirstArg");

    else
        % se2(ANG, "theta") or
        % se2(TRANSL, "trvec") or
        % se2(POSE, "xytheta")

        data = arg1;
        inputType = arg2;
        [tf,sz] = matlabshared.spatialmath.internal.SE2Base.parseConversionInputs(data, inputType);

        % Assign the object data based on the transformation matrix
        [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tf,sz);

    end

end
