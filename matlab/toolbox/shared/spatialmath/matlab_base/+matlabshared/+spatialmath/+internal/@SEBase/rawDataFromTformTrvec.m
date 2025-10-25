function [M,MInd] = rawDataFromTformTrvec(tf, transl, rotArraySize)
%This method is for internal use only. It may be removed in the future.

%rawDataFromTformTrvec Get the raw data property values when initializing object from a transformation matrix and a translation vector
%   Most common syntax: rawDataFromTformTrvec(tf, transl, rotArraySize)
%
%   The M and MInd outputs can be assigned directly to the properties of
%   the same name in the se2 and se3 objects.
%   The SZ input will preserve a certain array shape in the MInd output
%   (this will determine the object array shape).

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if nargin < 3
        [tfValid,arraySize] = matlabshared.spatialmath.internal.SEBase.alignTformTrvecSize(tf, transl);
    else
        [tfValid,arraySize] = matlabshared.spatialmath.internal.SEBase.alignTformTrvecSize(tf, transl, rotArraySize);
    end
    [M,MInd] = matlabshared.spatialmath.internal.SEBase.rawDataFromTform(tfValid,arraySize);

end
