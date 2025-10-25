function outObj = permute(obj,order)
%This method is for internal use only. It may be removed in the future.

%PERMUTE Permute dimensions of se2 array

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Permute the indices and then reassign data based on new indices
    permInd = permute(obj.MInd,order);
    M = obj.M(:,:,permInd);

    % Create new object with permuted dimensions
    outObj = obj.fromMatrix(M, size(permInd));

end
