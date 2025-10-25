function [M,MInd] = parseThreeInputs(arg1, arg2, arg3)
%This method is for internal use only. It may be removed in the future.

%parseThreeInputs Parse the se2 constructor with three input arguments
%   Possible call syntax parsed here
%     se2(ANG, "theta", TRANSL)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% se2(ANG, "theta", TRANSL)

% The parsing / validation of arg1 and arg2 happen in
% parseConversionInputs method.
    [tf,sz,typeStr] = matlabshared.spatialmath.internal.SE2Base.parseConversionInputs(arg1, arg2);

    transl = arg3;
    matlabshared.spatialmath.internal.SE2Base.parseTranslationInput(transl);
    % se2(...,"xytheta",TRANSL) and se3(...,"trvec",TRANSL)
    % are invalid constructor syntaxes.
    coder.internal.errorIf(isequal(typeStr,"xytheta") || isequal(typeStr,"trvec"), ...
                           "shared_spatialmath:se2:TranslationInputNotAllowed");

    [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl, sz);

end
