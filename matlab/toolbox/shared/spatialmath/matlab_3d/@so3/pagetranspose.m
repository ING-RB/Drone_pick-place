function obj = pagetranspose(obj)
%PAGETRANSPOSE Page-wise transpose of so3 array
%   Y = PAGETRANSPOSE(X) applies the non-conjugate transpose to each page
%   of N-D array X:
%                      Y(:,:,i) = X(:,:,i).'.
%
%   This is equivalent to calling permute(X,[2 1 3:ndims(X)]).
%
%   See also TRANSPOSE, PERMUTE, PAGECTRANSPOSE.

%   Copyright 2022-2024 The MathWorks, Inc.

% Transpose the indices and then reassign data based on new indices
    transpInd = pagetranspose(obj.MInd);
    obj.M = obj.M(:,:,transpInd);

    % Regenerate indices
    obj.MInd = obj.newIndices(size(transpInd));

end
