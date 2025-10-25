function [rotm,sz,inputTypeStr] = parseConversionInputs(data, inputType)
%This method is for internal use only. It may be removed in the future.

%PARSECONVERSIONINPUTS Parse so2 constructor inputs for conversions
%   ROTM = parseConversionInputs(DATA, "INPUTTYPE") parses the numeric
%   input data, DATA, and interprets it based on the provided INPUTTYPE
%   string. INPUTTYPE can be "theta". The return is ROTM, a 2-by-2 rotation
%   matrix that is equivalent to the input.
%
%   [ROTM,SIZE] = ... also returns the expected size of the output object
%   array. For most conversion types, the size will indicate a row vector,
%   but for some, e.g. "theta", the size might be different.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    validateattributes(inputType, {'char','string'}, "scalartext", "so2", "inputType");

    % Convert input to string object and make all lowercase

    inputTypeStr = string(inputType).lower;

    switch inputTypeStr
      case "theta"
        % so2(ANG,"theta")

        validStr = true;
        ang = data;
        validateattributes(ang, {'single','double'}, {'nonempty','real'}, "so2", "ang");
        rotm = robotics.internal.theta2rotm(ang);
        sz = size(ang);

      otherwise
        validStr = false;
        rotm = eye(2);

    end

    coder.internal.assert(validStr, "shared_spatialmath:so2:InputTypeInvalid", inputTypeStr);

end
