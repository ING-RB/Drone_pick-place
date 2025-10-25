function [tf,sz,inputTypeStr] = parseConversionInputs(data, inputType)
%This method is for internal use only. It may be removed in the future.

%PARSECONVERSIONINPUTS Parse se2 constructor inputs for conversions
%   TF = parseConversionInputs(DATA, "INPUTTYPE") parses the numeric input
%   data, DATA, and interprets it based on the provided INPUTTYPE string.
%   INPUTTYPE can be "theta", "trvec", or "xytheta". The return is TF, a
%   3-by-3 transformation matrix that is equivalent to the input.
%
%   [TF,SIZE] = ... also returns the expected size of the output object
%   array. For most conversion types, the size will indicate a row vector,
%   but for some, e.g. "theta", the size might be different.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% se2(ANG, "theta") or
% se2(TRANSL, "trvec") or
% se2(POSE, "xytheta")

    validateattributes(inputType, {'char','string'}, "scalartext", "se2", "inputType");

    % Convert input to string object and make all lowercase

    inputTypeStr = string(inputType).lower;

    switch inputTypeStr
      case "theta"
        % se2(ANG,"theta")

        validStr = true;
        ang = data;
        validateattributes(ang, {'single','double'}, {'nonempty','real'}, "se2", "ang");
        rotm = robotics.internal.theta2rotm(ang);
        tf = robotics.internal.rotm2tform(rotm);
        sz = size(ang);

      case "trvec"

        % se2(TRANSL, "trvec")
        validStr = true;
        transl = data;
        matlabshared.spatialmath.internal.SE2Base.parseTranslationInput(transl);
        tf = robotics.internal.trvec2tform(transl);
        sz = [1 size(transl,1)];

      case "xytheta"

        % se2(POSE, "xytheta")
        validStr = true;
        pose = data;
        robotics.internal.validation.validateNumericMatrix(pose, "se2", "pose", "ncols", 3);
        tf = robotics.internal.xytheta2tform(pose);
        sz = [1 size(pose,1)];

      otherwise
        validStr = false;
        tf = eye(3);

    end

    coder.internal.assert(validStr, "shared_spatialmath:se2:InputTypeInvalid", inputTypeStr);

end
