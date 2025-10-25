function outObj = reshape(obj,varargin)
%This method is for internal use only. It may be removed in the future.

%RESHAPE Reshape an se2 array

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Reshape the indices and then reassign data based on new indices
    reshapeInd = reshape(obj.MInd,varargin{:});
    M = obj.M(:,:,reshapeInd);

    % Create new object with reshaped dimensions
    outObj = obj.fromMatrix(M, size(reshapeInd));

end
