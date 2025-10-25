function [rotm,sz,inputTypeStr] = parseConversionInputs(data, inputType, convention)
%This method is for internal use only. It may be removed in the future.

%PARSECONVERSIONINPUTS Parse so3 constructor inputs for conversions
%   ROTM = parseConversionInputs(DATA, "INPUTTYPE") parses the numeric
%   input data, DATA, and interprets it based on the provided INPUTTYPE
%   string. INPUTTYPE can be "eul", "quat", "axang", "rotx", "roty", or
%   "rotz". The return is ROTM, a 3-by-3 rotation matrix that is equivalent
%   to the input.
%
%   ROTM = parseConversionInputs(..., "CONVENTION") interprets the Euler
%   angles as following the axis order CONVENTION. CONVENTION can be one of
%   one of "YZY", "YXY", "ZYZ", "ZXZ", "XYX", "XZX", "XYZ", "YZX", "ZXY",
%   "XZY", "ZYX", or "YXZ".
%
%   [ROTM,SIZE] = ... also returns the expected size of the output object
%   array. For most conversion types, the size will indicate a row vector,
%   but for some, e.g. "rotx", the size might be different.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    validateattributes(inputType, {'char','string'}, "scalartext", "so3", "inputType");

    % Convert input to string object and make all lowercase

    inputTypeStr = string(inputType).lower;
    if nargin < 3
        % Standard Euler angle axis order is "ZYX"
        % If convention is provided, it will be parsed by eul2rotm below.
        convention = "ZYX";
    end

    switch inputTypeStr
      case "eul"
        % so3(E,"eul")
        % so3(E,"eul","CONVENTION")

        validStr = true;
        e = data;
        robotics.internal.validation.validateNumericMatrix(e, "so3", "e", "ncols", 3);
        rotm = robotics.internal.eul2rotm(e, upper(char(convention)));
        sz = [1 size(e,1)];

      case "quat"
        % so3(Q,"quat")

        validStr = true;
        q = data;
        robotics.internal.validation.validateNumericMatrix(q, "so3", "q", "ncols", 4);
        rotm = robotics.internal.quat2rotm(q);
        sz = [1 size(q,1)];

      case "axang"
        % so3(AXANG,"axang")

        validStr = true;
        axang = data;
        robotics.internal.validation.validateNumericMatrix(axang, "so3", "axang", "ncols", 4);
        rotm = robotics.internal.axang2rotm(axang);
        sz = [1 size(axang,1)];

      case {"rotx", "roty", "rotz"}
        % so3(ANG,"rotx")
        % so3(ANG,"roty")
        % so3(ANG,"rotz")

        validStr = true;
        ang = data;

        % Extract axis as either "x", "y", or "z"
        axis = inputTypeStr.extractAfter(3);
        validateattributes(ang, {'single','double'}, {'nonempty','real'}, "so3", "ang");
        rotm = robotics.internal.ang2rotm(ang,axis);
        sz = size(ang);

      otherwise
        validStr = false;
        rotm = eye(3);

    end

    coder.internal.assert(validStr, "shared_spatialmath:so3:InputTypeInvalid", inputTypeStr);

end
