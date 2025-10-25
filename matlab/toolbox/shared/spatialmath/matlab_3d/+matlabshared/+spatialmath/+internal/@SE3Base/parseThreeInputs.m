function [M,MInd] = parseThreeInputs(arg1, arg2, arg3)
%This method is for internal use only. It may be removed in the future.

%parseThreeInputs Parse the se3 constructor with three input arguments
%   Possible call syntax parsed here
%     se3(E,"eul","SEQ")
%     se3(...,"...",TRANSL)

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen


    data = arg1;
    inputType = arg2;

    % The parsing / validation of varargin{1} and varargin{2}
    % happen in parseConversionInputs method.

    if isfloat(arg3)
        % se3(...,"...",TRANSL)
        [tf,sz,typeStr] = matlabshared.spatialmath.internal.SE3Base.parseConversionInputs(data, inputType);
        transl = arg3;
        matlabshared.spatialmath.internal.SE3Base.parseTranslationInput(transl);
        % se3(...,"xyzquat",TRANSL) and se3(...,"trvec",TRANSL)
        % are invalid constructor syntaxes.
        coder.internal.errorIf(isequal(typeStr,"xyzquat") || isequal(typeStr,"trvec"), ...
                               "shared_spatialmath:se3:TranslationInputNotAllowed");

        [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTformTrvec(tf, transl, sz);
    else
        % se3(E,"eul","SEQ")
        [tf,sz] = matlabshared.spatialmath.internal.SE3Base.parseConversionInputs(data, inputType, arg3);
        [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tf,sz);
    end
end
