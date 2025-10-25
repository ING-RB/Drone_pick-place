function writeParamToCodegenInfo(parameterStruct)
%This function is for internal use only. It may be removed in the future.

%writeParamToCodegenInfo save node parameter to ROSMATLABCgenInfo object

%   Copyright 2022 The MathWorks, Inc.

    hObj = ros.codertarget.internal.ROSMATLABCgenInfo.getInstance;
    addNodeParameter(hObj,parameterStruct);
end
