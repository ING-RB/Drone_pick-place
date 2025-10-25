function outObj = pagectranspose(obj)
%This method is for internal use only. It may be removed in the future.

%PAGECTRANSPOSE Page-wise complex conjugate transpose of so3 array

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Transpose the indices and then reassign data based on new indices
    transpInd = pagectranspose(obj.MInd);
    M = obj.M(:,:,transpInd);

    outObj = obj.fromMatrix(M, size(transpInd));

end
