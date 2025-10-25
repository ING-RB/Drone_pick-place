function [M,MInd] = parseThreeInputs(arg1, arg2, arg3)
%This method is for internal use only. It may be removed in the future.

%parseThreeInputs Parse the so3 constructor with three input arguments
%   Possible call syntax parsed here
%     se3(E,"eul","SEQ")

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Parse / validate inputs and convert to rotation matrix
    [tf,sz] = matlabshared.spatialmath.internal.SO3Base.parseConversionInputs(arg1, arg2, arg3);
    [M,MInd] = matlabshared.spatialmath.internal.SOBase.rawDataFromRotm(tf,sz);

end
