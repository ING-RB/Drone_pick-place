function [M,MInd] = parseFourInputs(arg1, arg2, arg3, arg4)
%This method is for internal use only. It may be removed in the future.

%parseFourInputs Parse the se3 constructor with four input arguments
%   Possible call syntax parsed here
%     se3(E,"eul","SEQ",TRANSL)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen


% The parsing / validation of arg1, arg2, and arg3 happen in
% parseConversionInputs method.
    [tf,sz] = matlabshared.spatialmath.internal.SE3Base.parseConversionInputs(arg1, arg2, arg3);
    transl = arg4;
    matlabshared.spatialmath.internal.SE3Base.parseTranslationInput(transl);
    [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl, sz);

end
