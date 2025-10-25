function [M,MInd] = parseTwoInputs(arg1, arg2)
%This method is for internal use only. It may be removed in the future.

%parseTwoInputs Parse the so3 constructor with two input arguments
%   Possible call syntax parsed here
%     so3(E,"eul")
%     so3(Q,"quat")
%     so3(AXANG,"axang")
%     so3(ANG,"rotx")
%     so3(ANG,"roty")
%     so3(ANG,"rotz")

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    data = arg1;
    inputType = arg2;

    % Parse / validate inputs and convert to rotation matrix
    [rotm,sz] = matlabshared.spatialmath.internal.SO3Base.parseConversionInputs(data, inputType);

    % Assign the object data based on the rotation matrix
    [M,MInd] = matlabshared.spatialmath.internal.SOBase.rawDataFromRotm(rotm,sz);

end
