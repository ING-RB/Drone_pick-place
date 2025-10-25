function obj = pagectranspose(obj)
%PAGECTRANSPOSE Page-wise complex conjugate transpose of se3 array
%   Y = PAGECTRANSPOSE(X) applies the complex conjugate transpose to each
%   page of N-D array X:
%                      Y(:,:,i) = X(:,:,i)'.
%
%   This is equivalent to calling permute(conj(X),[2 1 3:ndims(X)]).
%   For an se3 array, PAGECTRANSPOSE(X) behaves the same way as
%   pagetranspose(X).
%
%   See also CTRANSPOSE, PERMUTE, PAGETRANSPOSE.

%   Copyright 2022-2024 The MathWorks, Inc.

% Transpose the indices and then reassign data based on new indices
    transpInd = pagectranspose(obj.MInd);
    obj.M = obj.M(:,:,transpInd);

    % Regenerate indices
    obj.MInd = obj.newIndices(size(transpInd));

end
