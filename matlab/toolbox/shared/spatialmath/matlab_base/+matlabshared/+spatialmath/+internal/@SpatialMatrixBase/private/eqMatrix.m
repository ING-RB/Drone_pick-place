function tf = eqMatrix(M1, MInd1, M2, MInd2)
%This function is for internal use only. It may be removed in the future.

%eqMatrix Check for equality of spatial matrix arrays
%   The indices to check in M1 and M2 are provided in MInd1 and MInd2.
%   These should be computed to support implicit expansion.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    numMat = numel(MInd1);
    tf = false(1,numMat);

    for i = 1:numMat
        tf(i) = isequal(M1(:,:,MInd1(i)), M2(:,:,MInd2(i)));
    end

end
