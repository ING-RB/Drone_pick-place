function outObj = transpose(obj)
%This method is for internal use only. It may be removed in the future.

%.' Transpose of se2 array

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Transpose the indices and then reassign data based on new indices
    transpInd = obj.MInd.';
    M = obj.M(:,:,transpInd);

    % Create new object with transposed data
    outObj = obj.fromMatrix(M, size(transpInd));

end
