function [tf,sz,inputTypeStr] = parseConversionInputs(data, inputType, convention)
%This method is for internal use only. It may be removed in the future.

%PARSECONVERSIONINPUTS Parse constructor inputs for conversions
%   TF = parseConversionInputs(DATA, "INPUTTYPE") parses the numeric input
%   data, DATA, and interprets it based on the provided INPUTTYPE
%   string. INPUTTYPE can be "eul", "quat", "axang", "rotx", "roty",
%   "rotz", "trvec", or "xyzquat". The return is TF, a 4-by-4 transformation
%   matrix that is equivalent to the input.
%
%   TF = parseConversionInputs(..., "CONVENTION") interprets the Euler
%   angles as following the axis order CONVENTION. CONVENTION can be one of
%   one of "YZY", "YXY", "ZYZ", "ZXZ", "XYX", "XZX", "XYZ", "YZX", "ZXY",
%   "XZY", "ZYX", or "YXZ".
%
%   [TF,SIZE] = ... also returns the expected size of the output object
%   array. For most conversion types, the size will indicate a row vector,
%   but for some, e.g. "rotx", the size might be different.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    validateattributes(inputType, {'char','string'}, "scalartext", "se3", "inputType");

    % Convert input to string object and make all lowercase

    inputTypeStr = string(inputType).lower;
    if nargin < 3
        % Standard Euler angle axis order is "ZYX"
        % If convention is provided, it will be parsed by eul2tform below.
        convention = "ZYX";
    end

    switch inputTypeStr
      case "eul"
        % se3(E,"eul")
        % se3(E,"eul","CONVENTION")

        validStr = true;
        e = data;
        robotics.internal.validation.validateNumericMatrix(e, "se3", "e", "ncols", 3);
        tf = robotics.internal.eul2tform(e, upper(char(convention)));
        sz = [1 size(e,1)];

      case "quat"
        % se3(Q,"quat")

        validStr = true;
        q = data;
        robotics.internal.validation.validateNumericMatrix(q, "se3", "q", "ncols", 4);
        tf = robotics.internal.quat2tform(q);
        sz = [1 size(q,1)];

      case "axang"
        % se3(AXANG,"axang")

        validStr = true;
        axang = data;
        robotics.internal.validation.validateNumericMatrix(axang, "se3", "axang", "ncols", 4);
        tf = robotics.internal.axang2tform(axang);
        sz = [1 size(axang,1)];

      case {"rotx", "roty", "rotz"}
        % se3(ANG,"rotx")
        % se3(ANG,"roty")
        % se3(ANG,"rotz")

        validStr = true;
        ang = data;

        % Extract axis as either "x", "y", or "z"
        axis = inputTypeStr.extractAfter(3);
        validateattributes(ang, {'single','double'}, {'nonempty','real'}, "se3", "ang");
        tf = robotics.internal.ang2tform(ang,axis);
        sz = size(ang);

      case "trvec"
        % se3(TRANSL,"trvec")

        validStr = true;
        transl = data;
        robotics.internal.validation.validateNumericMatrix(transl, "se3", "transl", "ncols", 3);
        tf = robotics.internal.trvec2tform(transl);
        sz = [1 size(transl,1)];

      case "xyzquat"
        % se3(POSE,"xyzquat")

        validStr = true;
        pose = data;
        robotics.internal.validation.validateNumericMatrix(pose, "se3", "pose", "ncols", 7);
        tf = robotics.internal.xyzquat2tform(pose);
        sz = [1 size(pose,1)];

      otherwise

        validStr = false;
        tf = eye(4);

    end

    coder.internal.assert(validStr, "shared_spatialmath:se3:InputTypeInvalid", inputTypeStr);

end
